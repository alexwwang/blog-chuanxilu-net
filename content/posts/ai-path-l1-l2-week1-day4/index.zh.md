---
title: "AI 之路进阶升级指南（二）：从一次调用到批量处理——让程序替你干 100 件事"
slug: "ai-path-l1-l2-week1-day4"
date: 2026-06-10T07:00:00+08:00
draft: false
description: "AI 之路进阶系列第二篇：学会用 Python 读取文件、调用 API、保存结果，再用循环批量处理整个文件夹，写一个能自动总结 100 篇文档的完整脚本。"
tags: ["AI", "工具链", "教程", "API", "Python"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.jpeg"
  alt: "水彩插画：传送带将杂乱纸张送入笔记本电脑，另一侧输出整齐汇总表"
  relative: true
---

> 这是「AI 之路进阶升级指南」系列第二篇。你需要先完成 [Part 1](../ai-path-l1-l2-week1/) 和前三天的练习（[Day 1](../ai-path-l1-l2-week1-day1/)、[Day 2](../ai-path-l1-l2-week1-day2/)、[Day 3](../ai-path-l1-l2-week1-day3/)）。

Part 1 里你学会了让程序帮你问 AI 一个问题。今天要做点不一样的：**让程序替你问 AI 一百个问题**。

手动问一百次和写脚本跑一百次，是完全不同的工作方式。前者是体力活，后者是杠杆。花 10 分钟写脚本，程序花 10 分钟跑完，你省下的时间可以做别的。

今天聊三件事：读文件、写循环、搭脚本。走完这三步，你就拥有了一个能自动处理任意文件夹的通用工具。

---

## 文件 I/O + API：给 API 喂数据

Part 1 的代码里，问题的内容直接写在代码里（`content="你好..."`）。现实场景完全不是这样。你要处理的可能是 10 篇会议纪要、50 条用户反馈，它们都存在文件里。程序需要先读文件，把内容塞进 API 请求，再把结果存回去。

直接写在代码里的问题，相当于你亲口对 AI 说一句话；从文件读取，相当于你把一叠纸递给 AI，让它看完再回答；写入文件，就是 AI 把回答写在纸上，你事后慢慢看。

先来最基础的一步：读一个文件，发给 API，保存回复。

在项目目录下创建 `read_file_api.py`：

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

# 读取文件内容
with open("input.txt", "r", encoding="utf-8") as f:
    file_content = f.read()

# 把文件内容发给 AI
response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=[
        {"role": "user", "content": f"请总结以下内容，用3个要点：\n\n{file_content}"}
    ]
)

# 获取 AI 回复
summary = response.choices[0].message.content

# 把回复写入新文件
with open("output.txt", "w", encoding="utf-8") as f:
    f.write(summary)

print("总结已保存到 output.txt")
```

在同级目录下创建一个测试文件 `input.txt`，随便写点什么：

```
今天团队讨论了三个议题：第一，Q3 产品路线图需要提前两周定稿；第二，技术债务清理排期 conflicts 了 feature 开发，需要协调；第三，新 hire 的 onboarding 流程要简化，目前步骤太多导致前两周效率很低。
```

运行：

```bash
uv run python read_file_api.py
```

看到"总结已保存到 output.txt"，打开 `output.txt` 检查内容。这个流程就是所有批量处理的核心模式：**读 → 处理 → 写**。

几个细节别漏掉：

- `encoding="utf-8"` 不能省。Python 默认编码在不同系统上不一样，不写的话中文可能乱码。
- `with open(...)` 是上下文管理器，文件会在代码块结束时自动关闭，不用手动调用 `f.close()`。
- 提示词里 `f"...{file_content}"` 是 f-string，Python 最方便的字符串格式化方式。它会自动把变量内容嵌入字符串。

把 `input.txt` 换成你自己的任意文本文件试试，看看总结效果。也可以改改提示词，比如把 "请总结以下内容，用3个要点" 改成 "请提取以下内容的行动项" 或 "请把以下内容翻译成英文"，观察输出有什么不同。

---

## 循环 + 批量处理：自动化核心

上一节处理了一个文件。文件夹里有 10 个文件怎么办？复制粘贴 10 次代码，每次改文件名？当然不是。用循环遍历文件夹，程序自己逐个处理。

Python 获取文件列表常用两种方式：`os.listdir()` 和 `glob`。`glob` 更灵活，可以用通配符匹配特定类型的文件，推荐用它。

在项目目录下创建 `batch_basic.py`：

```python
import os
import glob
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

# 获取所有 .txt 文件
input_files = glob.glob("input/*.txt")
print(f"找到 {len(input_files)} 个文件")

# 确保输出目录存在
os.makedirs("output", exist_ok=True)

# 逐个处理
for i, filepath in enumerate(input_files, 1):
    filename = os.path.basename(filepath)
    print(f"\n处理 {i}/{len(input_files)}: {filename}")

    # 读取文件
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # 调用 API
    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[
            {"role": "user", "content": f"请总结以下内容，用3个要点：\n\n{content}"}
        ]
    )

    # 保存结果
    summary = response.choices[0].message.content
    output_path = os.path.join("output", filename)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(summary)

print(f"\n全部完成！{len(input_files)} 个文件已处理")
```

运行之前，先准备测试数据：

```bash
mkdir -p input
echo "会议记录一的内容..." > input/meeting_01.txt
echo "会议记录二的内容..." > input/meeting_02.txt
echo "会议记录三的内容..." > input/meeting_03.txt
```

当然，你可以把自己真实的 `.txt` 或 `.md` 文件放进 `input/` 文件夹。然后运行：

```bash
uv run python batch_basic.py
```

你会看到类似这样的输出：

```
找到 3 个文件

处理 1/3: meeting_01.txt
处理 2/3: meeting_02.txt
处理 3/3: meeting_03.txt

全部完成！3 个文件已处理
```

打开 `output/` 文件夹，每个输入文件都对应一个输出文件。

`glob.glob("input/*.txt")` 返回所有匹配的文件路径。把 `"*.txt"` 改成 `"*.md"` 就能处理 Markdown 文件。`enumerate(input_files, 1)` 给循环加计数器，从 1 开始。`os.path.basename(filepath)` 从完整路径里提取文件名。

关于速度：这个脚本会一个接一个地调用 API。如果文件夹里有 10 个文件，每个请求 2 秒，总共大约 20 秒。这是串行处理。Day 6 我们会学并行处理（同时发多个请求），但串行更简单、更稳定，也更容易调试，先掌握串行再进阶。

试试把 `glob.glob("input/*.txt")` 改成 `"input/*.md"`，在 `input/` 里放几个 Markdown 文件，重新运行。

---

## 完整实战脚本：批量总结文档

前两节把批量处理拆成了步骤，现在组装成一个真正可用的工具。这个脚本的场景很通用：**你有一堆文档，想让 AI 给每个文档生成摘要，结果存到新文件夹**。

会议记录、文章草稿、用户反馈、调研笔记——任何文本集合都能用。

创建 `batch_summarize.py`：

```python
import os
import glob
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

def summarize_file(input_path, output_dir):
    """读取单个文件，调用 API 总结，保存结果"""
    # 读取原文
    with open(input_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 调用 API
    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[
            {"role": "system", "content": "你是一个文档总结助手。请用3个简洁的要点总结用户提供的文本。"},
            {"role": "user", "content": content}
        ],
        temperature=0.3,
        max_tokens=500
    )

    # 保存结果
    filename = os.path.basename(input_path)
    output_path = os.path.join(output_dir, filename)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(response.choices[0].message.content)

def main():
    input_dir = "documents"
    output_dir = "summaries"

    # 检查输入目录
    if not os.path.exists(input_dir):
        print(f"错误：找不到输入目录 '{input_dir}'")
        print("请创建一个文件夹，把你的文档放进去")
        return

    # 获取要处理的文件
    files = glob.glob(os.path.join(input_dir, "*.md"))
    files += glob.glob(os.path.join(input_dir, "*.txt"))

    if not files:
        print(f"错误：'{input_dir}' 里没有 .md 或 .txt 文件")
        return

    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)

    print(f"准备处理 {len(files)} 个文件...")
    print(f"输入: {input_dir}/")
    print(f"输出: {output_dir}/")
    print("-" * 40)

    # 批量处理
    for i, filepath in enumerate(files, 1):
        filename = os.path.basename(filepath)
        print(f"[{i}/{len(files)}] {filename}", end=" ")

        try:
            summarize_file(filepath, output_dir)
            print("OK")
        except Exception as e:
            print(f"失败: {e}")
            continue

    print("-" * 40)
    print(f"完成！结果保存在 {output_dir}/")

if __name__ == "__main__":
    main()
```

使用步骤：

1. 创建输入文件夹：`mkdir documents`
2. 把你要总结的 `.md` 或 `.txt` 文件复制进去
3. 运行：`uv run python batch_summarize.py`
4. 查看 `summaries/` 文件夹里的结果

这个脚本相比之前有几个改进：

**函数封装**。`summarize_file()` 把"读-调-写"的完整逻辑包起来，`main()` 负责流程控制。函数让代码更清晰，也方便复用。

**加了系统提示词**。`messages` 列表里增加了 `"role": "system"` 的消息，用来给 AI 设定身份和任务规则。系统提示词按输入 tokens 正常计费。虽然占用了一点对话消息长度，但能保证输出结果质量更好、更稳定，避免返工的浪费。`temperature=0.3` 让总结结果更一致，`max_tokens=500` 控制输出长度。

**错误保护**。每个文件处理都包在 `try/except` 里，一个文件失败不会导致整个程序崩溃，而是打印错误信息后继续处理下一个。

预期的文件夹结构：

```
your-project/
├── .env
├── .venv/
├── batch_summarize.py
├── documents/          # 放你的原文
│   ├── article_01.md
│   ├── article_02.md
│   └── notes.txt
└── summaries/          # 自动生成
    ├── article_01.md
    ├── article_02.md
    └── notes.txt
```

找 3-5 篇你自己的文档放进去跑一遍。如果文档比较长，注意一下费用，长文本的输入 tokens 会比较多。

---

## 错误处理入门：让脚本更皮实

真实的脚本一定会遇到意外。网络波动、API 暂时不可用、文件被占用——这些不是"如果"，而是"什么时候"。没有错误处理的脚本，遇到一次异常就全盘崩溃，你得从头再来。

前两节的代码已经包了一层 `try/except`，但那只是兜底。真正的健壮脚本需要处理几种常见情况：网络超时、API 返回错误、文件读写失败。

这里不展开全部方案（Day 7 会专门讲），只给两个马上能用的技巧。

**区分错误类型**

不是所有错误都一样。网络问题可以重试，API Key 错误重试也没用。Python 的异常类型能帮你区分：

```python
from openai import APIError, APITimeoutError

try:
    response = client.chat.completions.create(...)
except APITimeoutError:
    print("请求超时，等几秒再试")
except APIError as e:
    print(f"API 错误: {e}")
except Exception as e:
    print(f"其他错误: {e}")
```

**遇到网络问题自动重试**

Day 7 会讲更完整的重试机制（带指数退避和最大重试次数），现在先用一个简单版本：

```python
import time

def call_api_with_retry(client, **kwargs):
    """简单重试：失败等 3 秒再试一次"""
    for attempt in range(2):
        try:
            return client.chat.completions.create(**kwargs)
        except APITimeoutError:
            if attempt == 0:
                print("  超时，等待 3 秒后重试...")
                time.sleep(3)
            else:
                raise
```

把这个函数替换掉脚本里的直接调用，网络抖动就不会导致任务失败了。

至少给你的 API 调用包一层 `try/except`。一个文件失败不该导致整个批量任务中断——这是批量处理和单次调用最大的心态差异。

另外，批量处理时还会遇到一个 Day 7 要细讲的问题：**API 速率限制**。大多数平台限制你每秒能发多少个请求（比如每秒 2 个）。如果文件很多、循环很快，你可能会触发限制，API 返回 429 错误。现在的简单处理办法：如果报错 429，等几秒再试。更优雅的方案在 Day 7 完整讲。

---

## 今天做到的事

用 Python 读取文件并发给 API，用 `glob` 加 `for` 循环批量处理了整个文件夹，搭了一个能处理任意文档文件夹的完整脚本，还加了 `try/except` 保证一个文件失败不会搞崩全部任务。

代码量不大，但概念上是一次关键跨越。从"调一次 API"到"批量处理文件夹"，你不再是在"用 API"，而是在"用 API 做工具"。这个差别就是 L1 和 L2 的分界线。

---

## 下一步

今天写了骨干代码，接下来三天是配套练习：

- **Day 5**：写一个读取多种格式文件的脚本（不只是 `.md` 和 `.txt`）
- **Day 6**：给批量脚本加上进度条和费用统计
- **Day 7**：完整的错误处理——重试、日志、超时控制

Part 3 我们会进入另一个维度：**自主执行型 AI**——让 AI 不仅能读文件、写文件，还能自己规划步骤、调用工具、完成复杂任务。

---

*脚本跑不起来？先看错误信息（不要贴 API Key），检查 `.env` 文件位置、文件夹名、网络连接。*
