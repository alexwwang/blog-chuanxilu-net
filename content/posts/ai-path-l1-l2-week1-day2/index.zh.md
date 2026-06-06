---
title: "Day 2 练习：用聚合平台跑通同一个请求"
slug: "ai-path-l1-l2-week1-day2"
date: 2026-06-06T07:00:00+08:00
draft: false
description: "L1→L2 第一周配套练习 Day 2：注册聚合平台，修改两个参数让昨天的代码对接新地址，对比聚合平台和官方直连的区别。"
tags: ["AI", "工具链", "教程", "API"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.jpeg"
  alt: "水彩风格：笔记本屏幕并排两个终端窗口，左暖琥珀右冷蓝绿，桌上有笔记本、token珠子、茶杯和两张打勾便利贴"
---

> 这是「AI 之路进阶升级指南」第一周 Day 2 的配套练习。你需要先完成 [Day 1](../ai-path-l1-l2-week1-day1/)。

昨天你用 DeepSeek 官方 API 跑通了第一段代码。今天做一件事：**换一个平台，用同样的代码，改两个参数，再跑一次。**

你会发现，学会一个平台的调用方式，等于学会了所有兼容 OpenAI 接口的平台。

---

## 什么是聚合平台

聚合平台是一个中间层——你注册一个账号、充值一次，就能在一个平台上调用几十个不同的 AI 模型（OpenAI、Anthropic、Google 等），不需要分别去每个官方平台注册。

底层都是 NewAPI 或 OneAPI 框架，所以不管你用的是哪家聚合平台，操作流程大同小异：

1. 注册账号
2. 充值
3. 获取 API Key
4. 在"模型列表"里选模型

**优点**：一个 Key 调多模型，不用分别注册国际平台，支持支付宝/微信充值。

**缺点**：比官方直连略贵一点（加了平台服务费），稳定性取决于平台方。

---

## 动手"写"代码

这次不需要从零开始。把昨天的 `hello_api.py` 复制一份，命名为 `hello_aggregator.py`，只改两处：

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

# 改动 1：换成聚合平台的 Key
api_key = os.environ.get("AGGREGATOR_API_KEY")
if not api_key:
    raise ValueError("AGGREGATOR_API_KEY 环境变量未设置，检查 .env 文件")

# 改动 2：换成聚合平台的 API 地址
client = OpenAI(
    api_key=api_key,
    base_url="https://你的聚合平台地址/v1"
)

# 其他完全不变
response = client.chat.completions.create(
    model="deepseek-v4-flash",       # 聚合平台上的模型名可能不同，看平台文档
    messages=[
        {"role": "user", "content": "你好，请用一句话介绍你自己。"}
    ]
)

print(response.choices[0].message.content)
```

**只改了两个地方**：`api_key` 和 `base_url`。代码逻辑一模一样。

在 `.env` 文件里加上聚合平台的 Key：

```
DEEPSEEK_API_KEY=sk-xxx
AGGREGATOR_API_KEY=sk-你的聚合平台key
```

运行：

```bash
uv run python hello_aggregator.py
```

看到 AI 回复了？**同一套代码，改两个参数，切到了另一个平台。** 这就是 OpenAI 兼容接口的好处。

---

## 注意事项

**模型名称可能不同**

聚合平台上的模型名不一定是 `deepseek-v4-flash`。有些平台用 `deepseek/deepseek-v4-flash`（带 provider 前缀），有些用别的格式。去平台的"模型列表"或"模型价格"页面确认可用名称。

**base_url 末尾**

聚合平台一般需要 `/v1` 后缀，比如 `https://example.com/v1`。官方直连（如 DeepSeek）一般不需要。不确定就查平台文档的"API 地址"说明。

**不确定就问 AI**

L0→L1 阶段你学会了和 AI 对话——现在该用上了。遇到不确定的事情，直接在聊天窗口问："用 Python 的 openai 库对接 [平台名] 的 API，base_url 应该怎么写？""这个平台上 deepseek-v4-flash 的模型名叫什么？"比自己翻文档快得多。

---

## 对比：聚合平台 vs 官方直连

| | 官方直连（如 DeepSeek） | 聚合平台 |
|---|---|---|
| 注册 | 每个平台分别注册 | 一个账号调多模型 |
| 充值 | 每个平台分别充 | 充一次，按模型扣费 |
| 价格 | 官方价 | 官方价基础上通常有折扣 |
| 模型选择 | 只有自家模型 | 几十个模型可切换 |
| 稳定性 | 取决于官方 | 取决于平台和官方两环 |
| 适合 | 长期使用某个模型 | 想试用多个模型、不想分别注册 |

**建议**：学习阶段用聚合平台试用不同模型，确定主力模型后再考虑官方直连省钱。

---

## 如果出错了

**"Model not found"**
- 聚合平台上的模型名和官方不一样，去平台文档查正确的模型名

**"Invalid API key"**
- 确认用的是聚合平台的 Key，不是 DeepSeek 的 Key

**"Insufficient balance"**
- 聚合平台余额不足，充值后重试

**"Connection refused"**
- `base_url` 检查：确保有 `/v1` 后缀（聚合平台通常需要）
- 确认域名拼写正确

---

## 今天的收获

- [ ] 在聚合平台注册并获取 API Key
- [ ] 用昨天的代码，改两个参数，跑通了聚合平台的请求
- [ ] 理解了聚合平台和官方直连的区别

**下一步**：Day 3 开始玩参数——`temperature` 从 0 调到 1，看 AI 的回答有什么变化。

---

*我目前使用 yylx 聚合平台，通过我购买有额外折扣，需要的话私信公众号「这也终会过去」回复"yylx"*
