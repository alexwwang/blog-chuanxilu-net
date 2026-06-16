---
title: "Day 6 练习：批量处理实战——选一个场景跑通"
slug: "ai-path-l1-l2-week2-day6"
date: 2026-06-13T07:00:00+08:00
draft: false
description: "L1→L2 第二周 Day 6 练习：选一个真实场景（翻译、摘要或改写），跑通完整的批量处理流程。"
tags: ["AI", "工具链", "教程", "API", "Python"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.png"
  alt: "水彩插画：木质书桌上的笔记本电脑，屏幕显示批量处理脚本，左侧输入文件，右侧输出文件"
  relative: true
---

> 这是「AI 之路进阶升级指南」第二周 Day 6 的配套练习。你需要先完成 [Day 5](../ai-path-l1-l2-week2-day5/)，再回来动手。

[Day 5](../ai-path-l1-l2-week2-day5/) 你写了 `read_file()` 函数和批量脚本骨架。现在脚本能识别各种格式的文件了。但还没真正跑过一次完整流程：选场景、调 API、保存结果，这个链路还没串起来。

今天做一件事：**选一个真实场景（批量翻译、批量摘要、或批量改写），把整个批量处理流程跑通。**

---

## 三选一：选你最需要的

批量处理的价值在于重复劳动自动化。三个常见场景：

**批量翻译**：一批英文文档需要翻成中文，或者反过来。比如产品文档、用户评论、技术笔记。

**批量摘要**：一堆会议记录、用户反馈、研究论文，需要提炼要点。

**批量改写**：一批文档需要统一格式或语气——比如把口语化的笔记改成正式的报告，或者统一产品描述的措辞。

选一个你当下最需要的场景，后面跟着做。

---

## 批量翻译：一个完整可跑的脚本

以批量翻译为例。假设你有一个 `docs/` 文件夹，里面是一批英文产品文档：

```
docs/
  feature-overview.md
  faq-en.md
  changelog-v2.md
```

目标：每篇文档翻译成中文，结果存到 `translations/` 文件夹。

**API 调用有输入长度限制**：不能把整篇长文档一次性塞进去。

模型处理超长输入时质量会下降，很多 API 也有 token 上限，硬塞进去可能直接报错。

正确的做法是：**分块翻译**：把文档切成一段一段，每段单独调 API 翻译，最后拼回去。但翻译和摘要不同——**不能按固定字符数截断，必须保证句子完整**：截断在句子中间，翻译出来的东西谁也看不懂。

下面的脚本实现了这个逻辑：

```python
import os
import glob
import re
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("未设置 DEEPSEEK_API_KEY，请检查 .env 文件。")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

MAX_CHARS = 4000  # 每个片段最大字符数

def split_into_sentences(text, max_chars):
    """按句子边界切分文本，保证每个片段不超过 max_chars。
    
    先按段落分割，段内再按句子标点分割，确保不截断在句子中间。"""
    paragraphs = text.split("\n\n")
    chunks = []
    current_chunk = ""

    for para in paragraphs:
        para = para.strip()
        if not para:
            continue

        # 段内按句子标点分割（中英文标点都支持）
        sentences = re.split(r'(?<=[.!?。！？])\s*', para)

        for sentence in sentences:
            sentence = sentence.strip()
            if not sentence:
                continue

            # 如果加上这个句子会超出限制，先保存当前块
            if len(current_chunk) + len(sentence) > max_chars:
                chunks.append(current_chunk)
                current_chunk = sentence
            else:
                if current_chunk:
                    current_chunk += "\n\n" + sentence
                else:
                    current_chunk = sentence

    # 保存最后一个块
    if current_chunk:
        chunks.append(current_chunk)

    return chunks

def translate_chunk(chunk_text, prompt):
    """调用 API 翻译单个片段"""
    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": chunk_text}
        ],
        temperature=0.3,
        max_tokens=500
    )
    return response.choices[0].message.content

def translate_file(input_path, output_dir):
    """分块翻译文件，逐块调用 API，拼接结果"""
    prompt = "你是一个翻译助手。将用户提供的文本翻译成中文，保留原始格式。"

    # 内层循环：按句子分块 + 逐块翻译
    with open(input_path, "r", encoding="utf-8") as f:
        text = f.read()

    if not text.strip():
        print("  跳过（内容为空）")
        return

    sentences = split_into_sentences(text, MAX_CHARS)

    if not sentences:
        print("  跳过（内容为空）")
        return

    translated_chunks = []
    for chunk in sentences:
        translation = translate_chunk(chunk, prompt)
        translated_chunks.append(translation)

    # 拼接所有块的翻译结果
    full_translation = "\n\n".join(translated_chunks)

    # 如果原文被分成了多个块，加注记
    if len(translated_chunks) > 1:
        full_translation += f"\n\n> 注：原文较长，已分段翻译，共 {len(translated_chunks)} 个片段。"

    filename = os.path.splitext(os.path.basename(input_path))[0] + ".zh.md"
    output_path = os.path.join(output_dir, filename)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(full_translation)

def main():
    input_dir = "docs"
    output_dir = "translations"

    if not os.path.exists(input_dir):
        print(f"错误：找不到输入目录 '{input_dir}'")
        return

    files = glob.glob(os.path.join(input_dir, "*.md"))

    if not files:
        print(f"错误：'{input_dir}' 里没有 .md 文件")
        return

    os.makedirs(output_dir, exist_ok=True)

    print(f"准备处理 {len(files)} 个文件...")
    print(f"输入: {input_dir}/")
    print(f"输出: {output_dir}/")
    print("-" * 40)

    # 外层循环：遍历所有文件
    for i, filepath in enumerate(files, 1):
        filename = os.path.basename(filepath)
        print(f"[{i}/{len(files)}] {filename}", end=" ")

        translate_file(filepath, output_dir)
        print("OK")

    print("-" * 40)
    print(f"完成！结果保存在 {output_dir}/")

if __name__ == "__main__":
    main()
```

脚本的关键逻辑：

**翻译指令**：`system` 提示词指定"翻译成中文，保留原始格式"。

**句子边界切分**：`split_into_sentences()` 函数先按段落分割（`\n\n`），段内再按中英文句子标点（`.!?。！？`）切分，保证不截断在句子中间。这是翻译分块的核心——不能像摘要那样随便截。

**进度显示**：`[1/4]`, `[2/4]`... 批量跑的时候知道进度，比干等着强。

**输出文件名加 `.zh` 后缀**：比如 `feature-overview.md` → `feature-overview.zh.md`，在原名和扩展名之间插入 `.zh` 标记翻译文件。

**分块翻译**：按句子分块，每块调 API 翻译，循环直到文件读完。长文件会被切成多个片段分别翻译，结果拼接在一起。超过 4000 字符时会在输出中加注记提醒读者。

---

## 批量摘要：改两行就能跑

摘要场景和翻译脚本结构一样，区别只在两处：

**1. 提示词换成摘要指令：**

```python
prompt = "你是一个摘要助手。将用户提供的文本提炼为简洁的要点，保留关键信息。"
```

**2. 输出目录改为：**

```python
output_dir = "summaries"
```

一个重要的区别：摘要可以使用**固定字符数分块**：翻译必须尊重句子边界，因为半句话在任何语言里都看不懂。但摘要是有意丢失信息的——你本来就在精简内容。按固定字符数（比如每 4000 字符）切分，逐块摘要，最后得到的是"摘要的摘要"，边界精度没那么重要。

如果想简化，可以为摘要场景把 `split_into_sentences()` 替换成简单的定长分块器。不过保留句子分块也行——只是会更保守一些。

## 批量改写：统一文档语气

改写的场景也很常见——比如你把会议笔记快速写成草稿，但语气太随意，需要 AI 帮你改成正式报告的风格。

同样可以用上面的脚本，改两处就行：

提示词改成：
```python
prompt = "你是一个文案改写助手。将用户提供的文本改写成正式、专业的书面报告风格，保留所有关键信息。"
```

输出目录：`output_dir = "rewrites"`。

---

## 动手试试

在 `docs/` 文件夹里放几篇你的真实英文文档，然后运行：

```bash
uv run python batch_translate.py
```

你会看到进度条式输出，每个文件处理完显示 `OK`。到 `translations/` 文件夹看结果。

试试换一个场景——把提示词改成摘要或改写，再跑一次。看看同一个脚本，换个提示词，效果差多少。

---

## 进阶挑战

如果你手上有英文电子书（`.epub` 格式），可以试着用 AI 写一段代码来翻译它。

思路：先搜一下 "Python 读 epub 文件"，找个现成的库把 `.epub` 里每一章的 HTML 内容抽出来，然后接进今天的翻译脚本。`split_into_sentences()` 需要稍作修改——HTML 里的句子被 `<p>`、`<br>` 等标签打断，不能直接用 `\n\n` 分段。

这是 Day 6 没覆盖的场景，但用的是今天学到的同一个模式：**分块、调 API、拼接**：你已经有模板了，试试能不能跑起来。

---

## 今天做到的事

- [ ] 选了一个批量处理场景（翻译/摘要/改写）
- [ ] 写了完整的批量脚本，能遍历文件夹、逐个处理、保存结果
- [ ] 加了进度显示，跑批处理时知道进度
- [ ] 理解了 API 有长度限制，长文件需要分块处理

**下一步**：脚本跑起来后你会发现一些问题——网络超时、API 报错、单个文件处理失败导致整个批处理中断。Day 7 给脚本加上错误处理：超时重试、限流等待、异常日志。

---

*脚本跑不起来？先看错误信息（不要贴 API Key），检查 .env 文件位置、文件夹名、网络连接。*
