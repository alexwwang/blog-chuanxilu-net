---
title: "Day 1 练习：跑通你的第一段 API 代码"
slug: "ai-path-l1-l2-week1-day1"
date: 2026-06-02T07:00:00+08:00
draft: false
description: "L1→L2 第一周配套练习 Day 1：动手跑通 Part 1 里的第一段代码，附带常见错误排查。"
tags: ["AI", "工具链", "教程", "API", "DeepSeek"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.jpeg"
  alt: "水彩风格：笔记本电脑终端亮起一行金色AI回复，桌上有笔记本、token珠子、茶杯和打勾的便利贴"
---

> 这是「AI 之路进阶升级指南」第一周 Day 1 的配套练习。你需要先读完 [Part 1](../ai-path-l1-l2-week1/)，再回来动手。

今天只做一件事：**跑通 Part 1 里的 `hello_api.py`，在终端看到 AI 回复你一句话。**

---

## 前置准备

按 Part 1 完成以下步骤（如果已经做过，跳过）：

- [ ] 注册 DeepSeek 开发者账号（Part 1「注册 API 账号」）
- [ ] 获取 API Key，保存到 `.env` 文件（Part 1「API Key 安全须知」）
- [ ] 安装 uv 和 Python 3.12（Part 1「安装 Python」）
- [ ] 创建虚拟环境并安装依赖（Part 1「创建虚拟环境」）

确认一下你的项目目录结构长这样：

```
your-project/
├── .env                  # 里面是 DEEPSEEK_API_KEY=sk-xxx
└── .venv/                # uv 创建的虚拟环境
```

准备好了就开始。

---

## 动手"写"代码

在项目目录下创建 `hello_api.py`，把以下内容完整复制进去：

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

# 加载 .env 文件
load_dotenv()

# 读取 API Key
api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY 环境变量未设置，检查 .env 文件")

# 创建客户端
client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

# 发送请求
response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=[
        {"role": "user", "content": "你好，请用一句话介绍你自己。"}
    ]
)

# 打印回复
print(response.choices[0].message.content)
```

运行：

```bash
uv run python hello_api.py
```

看到 AI 回复了一句话？恭喜，你跑通了。接下来做一个小练习：**把问题改成你想问的任何问题，再跑一次。** 比如改成 `"用 Python 写一个猜数字游戏"` 或者 `"解释一下什么是 API"`。

---

## 如果出错了

**"DEEPSEEK_API_KEY 环境变量未设置"**
- `.env` 文件是否和 `hello_api.py` 在同一目录？不在就移过去
- Key 是否复制完整？应该以 `sk-` 开头，没有多余空格
- 文件名是不是正好 `.env`？检查前面有没有多余空格或隐藏了扩展名

**"Connection refused" 或网络相关错误**
- 网络是否正常？浏览器能打开 `platform.deepseek.com` 吗
- `base_url` 是否写对：`https://api.deepseek.com`（注意是 `https`，末尾没有 `/v1`）

**"Insufficient balance"（余额不足）**
- 新账号有少量赠送额度，用完需要充值
- 在控制台找「充值」，支付宝/微信充 10 元够练习很久

**"Model not found"**
- 模型名写错了。确认是 `deepseek-v4-flash`，不是 `deepseek-chat`（旧名仍可用但建议用新名）

**"Authentication failed" / "Invalid API key"**
- Key 复制不完整或有多余空格
- 重新到控制台创建一个新 Key，替换 `.env` 里的值

---

## 今天的收获

- [ ] 跑通了第一段 API 代码
- [ ] 在终端看到了 AI 的回复
- [ ] 换了一个问题又跑了一次

**下一步**：Day 2 我们换一个平台（聚合平台），你会发现——同样的代码，改两个参数就能切到另一个 AI 服务。

---

*遇到报错？把错误信息和你的 `.env` 文件结构（不要贴 Key 本身）截图发到读者群，我来帮你看。*
