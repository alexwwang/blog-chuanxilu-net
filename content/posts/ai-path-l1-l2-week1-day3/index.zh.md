---
title: "Day 3 练习：API 参数实验"
slug: "ai-path-l1-l2-week1-day3"
date: 2026-06-08T07:00:00+08:00
draft: false
description: "L1→L2 第一周配套练习 Day 3：动手实验 temperature 和 max_tokens 参数，观察 AI 输出的变化，建立对参数的直觉。"
tags: ["AI", "工具链", "教程", "API"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.jpeg"
  alt: "水彩插画：笔记本上的温度参数实验记录"
  relative: true
---

> 这是「AI 之路进阶升级指南」第一周 Day 3 的配套练习。你需要先完成 [Day 1](../ai-path-l1-l2-week1-day1/)。Part 1 里讲了参数的理论（「理解 API 参数」），今天动手验证。

Part 1 读了参数理论，但没有亲手试过，那些只是文字。今天做三个实验，**亲眼看看参数如何影响输出**。

---

## 准备工作

确保 Day 1 的项目能跑：

```bash
uv run python hello_api.py
```

看到 AI 回复就说明环境没问题。接下来的实验都基于这段代码改。

---

## 实验一：temperature 从 0 到 1

把 `hello_api.py` 复制为 `experiment_temp.py`，改成这样：

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY 环境变量未设置，检查 .env 文件")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

question = "写一个关于猫的短故事（三句话以内）"

for temp in [0, 0.5, 1.0]:
    print(f"\n{'='*40}")
    print(f"temperature = {temp}")
    print('='*40)

    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[{"role": "user", "content": question}],
        temperature=temp
    )

    print(response.choices[0].message.content)
```

运行：

```bash
uv run python experiment_temp.py
```

**观察什么**：

- `temperature=0`：每次跑出来的结果几乎一样。AI 选了概率最高的词，没有随机性。
- `temperature=0.5`：有些变化，但逻辑依然连贯。
- `temperature=1.0`：每次跑出来差异明显。用词、风格、故事走向都可能不同。

**动手试**：把同一段代码跑两三遍，对比 `temperature=0` 和 `temperature=1.0` 的输出稳定性。

**什么时候用哪个**：
- 要确定性结果（代码、数据提取）→ `temperature=0`
- 要有点变化但可控（日常对话、翻译）→ `temperature=0.5-0.7`
- 要创意发散（写作、头脑风暴）→ `temperature=0.8-1.0`

---

## 实验二：max_tokens 截断效果

新建 `experiment_tokens.py`：

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY 环境变量未设置，检查 .env 文件")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

question = "解释什么是机器学习，举三个生活中的例子"

for limit in [50, 200, 1000]:
    print(f"\n{'='*40}")
    print(f"max_tokens = {limit}")
    print('='*40)

    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[{"role": "user", "content": question}],
        max_tokens=limit
    )

    print(response.choices[0].message.content)
    print(f"\n(实际输出 tokens: {response.usage.completion_tokens})")
```

运行：

```bash
uv run python experiment_tokens.py
```

**观察什么**：

- `max_tokens=50`：AI 刚开始解释就被截断了，句子可能不完整。
- `max_tokens=200`：能给出一个简短的回答，但三个例子可能写不完。
- `max_tokens=1000`：完整回答，三个例子都能展开。

**注意**：`max_tokens` 是上限，不是目标长度。AI 不一定会用满。如果问题只需要 100 tokens 的回答，设成 1000 也不会输出更多。

---

## 实验三：算一下你花了多少钱

在实验二的代码末尾加一段：

```python
    # 最后一次请求的费用估算
    usage = response.usage
    input_tokens = usage.prompt_tokens
    output_tokens = usage.completion_tokens

    # DeepSeek V4-Flash 价格（2026年5月，随时可能变）
    input_price = 0.14 / 1_000_000   # $/token
    output_price = 0.28 / 1_000_000

    cost = (input_tokens * input_price) + (output_tokens * output_price)
    print(f"\n本次请求费用: ${cost:.6f} (约 ¥{cost * 7.2:.4f})")
    print(f"  输入: {input_tokens} tokens, 输出: {output_tokens} tokens")
```

**建立直觉**：

- 一次简单的问答（100 输入 + 200 输出 tokens）大约花 ¥0.0006，不到一厘钱
- 10 元可以跑大约 15,000-20,000 次这样的请求
- 真正花钱的是长文本：一篇 5000 字文章的摘要可能消耗 7,500 输入 tokens

---

## 今天的收获

- [ ] 跑了 temperature 实验，看到了 0 和 1 的输出差异
- [ ] 跑了 max_tokens 实验，看到了截断效果
- [ ] 算了一次请求的实际费用

**下一步**：Day 4 是 Part 2 骨干教程——从单次调用进阶到批量处理。你将学会让 API 自动处理 100 个文件。

---

*不确定参数怎么调？把你想要的效果用自然语言描述，直接问 AI："我想让输出更稳定/更有创意/更短，temperature 和 max_tokens 应该怎么设？"*
