---
title: "Day 7 练习：给脚本加上错误处理"
slug: "ai-path-l1-l2-week2-day7"
date: 2026-06-18T07:00:00+08:00
draft: false
description: "L1→L2 第二周 Day 7 练习：给批量处理脚本加上超时重试、限流等待、异常日志，让脚本在真实网络环境下不再轻易中断。"
tags: ["AI", "工具链", "教程", "API", "Python"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.png"
  alt: "水彩插画：书桌上放着一台笔记本电脑，屏幕显示绿色进度条和完成标记"
  relative: true
---

> 这是「AI 之路进阶升级指南」第二周 Day 7 的配套练习。你需要先完成 [Day 6](../ai-path-l1-l2-week2-day6/)。

[Day 6](../ai-path-l1-l2-week2-day6/) 你写了一个能跑通的批量处理脚本。选一个场景、遍历文件、调 API、保存结果。跑起来的时候觉得一切都很顺利。

但那个脚本是在理想环境里跑的。真实网络不是这样。

你的脚本大概率遇到过这些问题：

- **网络超时**：API 响应超过 60 秒，程序直接报错退出
- **限流**：API 返回 429，告诉你请求太快了，你的脚本没有等待逻辑
- **单文件失败**：一个文件处理失败，整个批处理直接中断，前面的白跑了

这些问题加在一起，就是从"脚本能跑"到"脚本能用于生产"之间的鸿沟。

今天做一件事：**给脚本加上错误处理**。超时重试、限流等待、异常日志。

---

## 问题一：超时重试

API 偶尔会超时。网络抖动、服务繁忙、模型冷启动，都能让一次请求卡住不动。你的脚本应该等一会儿再试，不要一报错就退出。

```python
import time
import logging
from openai import APIConnectionError, APITimeoutError

logging.basicConfig(level=logging.INFO)

MAX_RETRIES = 3
RETRY_DELAY = 2  # 秒

def call_api_with_retry(client, prompt, text, temperature=0.3, max_tokens=500):
    """带重试的 API 调用。"""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.chat.completions.create(
                model="deepseek-v4-flash",
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": text}
                ],
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=120  # 120 秒超时
            )
            return response.choices[0].message.content
        except (APIConnectionError, APITimeoutError, TimeoutError) as e:
            if attempt == MAX_RETRIES:
                logging.error(f"API 调用失败，已重试 {MAX_RETRIES} 次: {e}")
                raise
            wait = RETRY_DELAY * attempt
            logging.warning(f"API 调用失败 ({attempt}/{MAX_RETRIES})，{wait} 秒后重试: {e}")
            time.sleep(wait)
```

**递增退避**：第一次失败等 2 秒，第二次等 4 秒，第三次等 6 秒。不固定等待时间，是因为如果 API 暂时不可用，多等一会儿更可能等到它恢复。

**只重试可恢复错误**：网络超时、连接错误、`TimeoutError`，这些都是暂时的，再试一次可能就好。400 错误是你的请求写错了，401 是密钥不对，这些重试也没用。

**超时时间设长一点**：默认 30 秒太短了。长文本处理、模型冷启动都可能超过这个时间。120 秒更保险。

---

## 问题二：限流等待

API 通常有速率限制。每分钟最多 N 次请求。超过之后 API 会返回 429 状态码。

你的脚本如果以最快的速度连续发请求，很可能会撞上限流。加上限流处理逻辑：

```python
import time
import logging
from openai import RateLimitError

def call_api_with_rate_limit(client, prompt, text, temperature=0.3, max_tokens=500):
    """带限流处理的 API 调用（教学片段，展示限流等待逻辑）。"""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.chat.completions.create(
                model="deepseek-v4-flash",
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": text}
                ],
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=120
            )
            return response.choices[0].message.content
        except RateLimitError as e:
            if attempt == MAX_RETRIES:
                logging.error(f"限流，已重试 {MAX_RETRIES} 次: {e}")
                raise
            wait = RETRY_DELAY * attempt * 2  # 限流等待时间翻倍
            logging.warning(f"限流 ({attempt}/{MAX_RETRIES})，{wait} 秒后重试: {e}")
            time.sleep(wait)
```

**等待时间翻倍**：被限流之后，等的时间应该比超时重试更长。限流是 API 在明确告诉你"你太急了"，你需要更大幅度地降速。

**记录日志**：限流发生的时候，你应该知道。不是默默跳过，也不是直接报错退出。`logging.warning()` 会在日志里留下一条记录，跑完批处理之后回头看，能知道总共撞了几次限流。

---

## 问题三：异常日志与失败追踪

一个文件失败了，你的脚本不应该直接崩溃。它应该记录这个文件的失败原因，跳过它继续处理后面的文件。等所有文件处理完，报告一下哪些文件失败了。

```python
import os
from datetime import datetime

def process_file_safe(filepath, output_dir, prompt, results_log):
    """安全地处理单个文件，失败时记录日志并跳过。"""
    filename = os.path.basename(filepath)
    try:
        result = call_api_with_retry(client, prompt, read_file(filepath))
        output_path = os.path.join(output_dir, os.path.splitext(filename)[0] + ".zh.md")
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(result)
        results_log["success"].append(filename)
        logging.info(f"处理成功: {filename}")
    except Exception as e:
        results_log["failed"].append({
            "filename": filename,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        })
        logging.error(f"处理失败: {filename} — {e}")
```

失败日志要记三样东西：哪个文件出错了，错误信息是什么，什么时候失败的。时间戳方便回头对照 API 控制台看当时的状态。

---

## 完整的错误处理脚本

把上面的三个部分合在一起：

```python
import os
import glob
import re
import time
import json
import logging
from datetime import datetime
from dotenv import load_dotenv
from openai import OpenAI, APIConnectionError, APITimeoutError, RateLimitError

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("未设置 DEEPSEEK_API_KEY，请检查 .env 文件。")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)

MAX_RETRIES = 3
RETRY_DELAY = 2
MAX_CHARS = 4000

def split_into_sentences(text, max_chars):
    """按句子边界切分文本。"""
    paragraphs = text.split("\n\n")
    chunks = []
    current_chunk = ""

    for para in paragraphs:
        para = para.strip()
        if not para:
            continue
        sentences = re.split(r'(?<=[.!?。！？])\s*', para)
        for sentence in sentences:
            sentence = sentence.strip()
            if not sentence:
                continue
            if len(current_chunk) + len(sentence) > max_chars:
                if current_chunk:
                    chunks.append(current_chunk)
                current_chunk = sentence
            else:
                if current_chunk:
                    current_chunk += "\n\n" + sentence
                else:
                    current_chunk = sentence

    if current_chunk:
        chunks.append(current_chunk)

    return chunks

def call_api_with_retry(prompt, text, temperature=0.3, max_tokens=500):
    """带重试的 API 调用。"""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.chat.completions.create(
                model="deepseek-v4-flash",
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": text}
                ],
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=120
            )
            return response.choices[0].message.content
        except (APIConnectionError, APITimeoutError, TimeoutError, RateLimitError) as e:
            if attempt == MAX_RETRIES:
                logging.error(f"API 调用失败，已重试 {MAX_RETRIES} 次: {e}")
                raise
            multiplier = 2 if isinstance(e, RateLimitError) else 1
            wait = RETRY_DELAY * attempt * multiplier
            logging.warning(f"API 调用失败 ({attempt}/{MAX_RETRIES})，{wait} 秒后重试: {e}")
            time.sleep(wait)

def translate_file_safe(filepath, output_dir, results_log):
    """安全地翻译单个文件。"""
    filename = os.path.basename(filepath)
    try:
        text = read_file(filepath)
        if not text.strip():
            logging.info(f"跳过（内容为空）: {filename}")
            return

        prompt = "你是一个翻译助手。将用户提供的文本翻译成中文，保留原始格式。"
        chunks = split_into_sentences(text, MAX_CHARS)
        translated_chunks = []

        for i, chunk in enumerate(chunks, 1):
            logging.info(f"  [{i}/{len(chunks)}] 翻译片段")
            translation = call_api_with_retry(prompt, chunk)
            translated_chunks.append(translation)

        full_translation = "\n\n".join(translated_chunks)
        if len(translated_chunks) > 1:
            full_translation += f"\n\n> 注：原文较长，已分段翻译，共 {len(translated_chunks)} 个片段。"

        out_filename = os.path.splitext(filename)[0] + ".zh.md"
        output_path = os.path.join(output_dir, out_filename)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(full_translation)

        results_log["success"].append(filename)
        logging.info(f"处理成功: {filename}")

    except Exception as e:
        results_log["failed"].append({
            "filename": filename,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        })
        logging.error(f"处理失败: {filename} — {e}")

def read_file(filepath):
    """读取纯文本文件内容。"""
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()

def main():
    input_dir = "docs"
    output_dir = "translations"
    log_file = "results.json"

    results_log = {"success": [], "failed": []}

    if not os.path.exists(input_dir):
        logging.error(f"找不到输入目录 '{input_dir}'")
        return

    files = glob.glob(os.path.join(input_dir, "*.md"))
    if not files:
        logging.error(f"'{input_dir}' 里没有 .md 文件")
        return

    os.makedirs(output_dir, exist_ok=True)

    logging.info(f"准备处理 {len(files)} 个文件...")
    logging.info(f"输入: {input_dir}/")
    logging.info(f"输出: {output_dir}/")
    logging.info("-" * 40)

    for i, filepath in enumerate(files, 1):
        filename = os.path.basename(filepath)
        logging.info(f"[{i}/{len(files)}] {filename}")
        translate_file_safe(filepath, output_dir, results_log)

    # 写结果日志
    with open(log_file, "w", encoding="utf-8") as f:
        json.dump(results_log, f, ensure_ascii=False, indent=2)

    logging.info("-" * 40)
    logging.info(f"完成！成功 {len(results_log['success'])} 个，失败 {len(results_log['failed'])} 个。")
    logging.info(f"结果日志: {log_file}")

if __name__ == "__main__":
    main()
```

这个脚本的关键改进：

用 `logging` 模块代替 `print`。`print` 只能看到输出，`logging` 可以分级（INFO、WARNING、ERROR），跑完批处理之后回看日志，能精确找到哪里出了问题。

成功和失败的文件分别记录，脚本结束后写入 `results.json`。即使中途有文件失败，日志也告诉你哪些成功了、哪些失败了、失败原因是什么。

每个文件的处理在独立的 `try/except` 块里。一个文件失败了不会阻止处理下一个文件。

`APIConnectionError`、`APITimeoutError`、`TimeoutError`、`RateLimitError` 都纳入重试范围。限流、超时和网络抖动都是暂时性问题，重试通常能恢复。

---

## 动手试试

用你的真实文件跑一次这个脚本。看看日志输出。

**成功的时候**：

```
10:23:45 [INFO] 准备处理 4 个文件...
10:23:45 [INFO] ----------------------------------------
10:23:45 [INFO] [1/4] feature-overview.md
10:23:48 [INFO]   [1/3] 翻译片段
10:23:52 [INFO]   [2/3] 翻译片段
10:23:56 [INFO]   [3/3] 翻译片段
10:23:58 [INFO] 处理成功: feature-overview.md
```

**被限流的时候**：

```
10:24:15 [WARNING] API 调用失败 (1/3)，4 秒后重试: Rate limit exceeded
10:24:19 [INFO]   [1/3] 翻译片段
```

**失败的时候**：

```
10:25:30 [ERROR] 处理失败: broken-file.md — API 调用失败，已重试 3 次
```

看看 `results.json` 里记录了什么。

---

## 进阶挑战

你的脚本现在能处理 `.md` 文件了。但真实场景里还会有 PDF、Word 文档、甚至是网页（`.html`）。

把 [Day 5](../ai-path-l1-l2-week2-day5/) 的 `read_file()` 函数接进来，让它能读取更多格式。但有一个陷阱：PDF 文件可能很大，直接传给 API 可能触发长度限制或超时。

你可以：

1. 在 `translate_file_safe()` 里加一个文件大小检查，超过 50KB 的 PDF 先输出警告
2. 给每个文件类型设不同的超时时间，大文件给更长的超时时间
3. 在 `results.json` 里区分不同的失败原因，文件大小超限、API 调用失败、格式不支持

---

## 今天做到的事

- [ ] 理解了 API 调用可能遇到的三种真实问题：超时、限流、单文件失败
- [ ] 给脚本加了超时重试（递增退避）
- [ ] 给脚本加了限流等待（等待时间翻倍）
- [ ] 给脚本加了异常日志和失败追踪（`results.json`）
- [ ] 理解了 `logging` 模块比 `print` 更适合批处理场景

**下一步**：脚本现在健壮了不少。Day 8 我们换个思路——不写代码，让 AI 自己完成自动化任务。自主执行型 AI 入门。

---

*脚本有问题？先看看 `results.json`。它记录了每个文件的处理结果和失败原因。*
