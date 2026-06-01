---
title: "AI 之路进阶升级指南（一）：API 初体验——第一次用代码调用 AI"
slug: "ai-path-l1-l2-week1"
date: 2026-06-01T07:00:00+08:00
draft: false
description: "AI 之路进阶系列第一篇：API 是什么、和聊天窗口有什么不同、怎么注册账号（DeepSeek/OpenRouter/Claude）、Python 环境搭建、第一段代码跑通，以及 token、temperature 等核心参数的直觉理解。"
tags: ["AI", "工具链", "进化路径", "教程", "API"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.jpeg"
  alt: "水彩风格：聊天气泡化为 token 流，流入桌面上的笔记本和铜钥匙"
---

> **TL;DR：** 这是「AI 之路进阶升级指南」系列的第一篇。整个系列共 4 篇，每篇对应一周练习。本篇带你从聊天窗口走到 API——让程序帮你自动化地调用 AI，为后续的批量处理和自主执行型 AI 打基础。

## 引言：从"我问 AI"到"程序问 AI"

如果你读完了 L0→L1 的毕业考核清单，还记得毕业篇里预告的那句话——"注册一个 API 账号，用 Python 打印你的第一条 AI 回复"——没错，就是今天。

你在 L0→L1 阶段用聊天窗口和 AI 对话。这种方式有两个局限：第一，它是单次的，每个任务都要重新开始；第二，它需要你人工介入，没法自动化。

L2 的核心区别在于**"让程序代替你去问 AI"**。你写好一次逻辑，然后让它重复执行一百次、一千次。比如你有一百个文档需要总结，L0→L1 的做法是手动发一百次请求，而 L2 的做法是写个脚本，让它自动处理这一百个文档，你只需要等结果。

从 L1 到 L2，关键一步是学会用 API。API 是程序和 AI 之间对话的通道——就像你和 AI 在聊天窗口对话一样，只是这一次，你的程序在代替你说话。

这份教程会用 4 周时间带你走完这条路：

| 篇 | 主题 | 核心内容 |
|----|------|---------|
| **Part 1**（即本文） | **API 初体验** | API vs 聊天窗口、注册账号、Python 环境、第一段代码跑通、理解 token / temperature |
| **Part 2** | 批量处理 | 处理 100 个文档、批量提示词设计、错误处理与重试机制 |
| **Part 3** | 自主执行型 AI | Claude Code / OpenCode 概念入门、读文件、改文件、跑命令 |
| **Part 4** | 工具箱 | 常用工具与最佳实践（日志、缓存、评估） |

准备好了吗？我们开始。

---

## 什么是 API，和聊天窗口有什么不同

**为什么重要**：这是 L1 到 L2 必须跨过的一道坎。很多人以为 API 只是"高级版的聊天窗口"，但它们的设计逻辑完全不同——一个是给人用的，一个是给程序用的。

**怎么理解**：聊天窗口是你打字，AI 回复。你在这个对话框里问问题、追加指令、要求 AI 调整输出，一来一回。

| | 聊天窗口 | API |
|---|---------|-----|
| 谁在操作 | 你自己 | 你写的程序 |
| 一次能处理几个任务 | 一个 | 可以几百个 |
| 能不能自动化 | 不能 | 能 |
| 适合什么场景 | 探索、试错、日常问答 | 批量处理、定时任务、嵌入工具 |

用一个类比：聊天窗口 = 你亲自去餐厅点菜，每道菜都要你自己说、自己等、自己拿。API = 你在外卖 App 上下单，商家做好了送到你门口，你只需要点一次，系统自动完成剩下的所有事情。

**怎么练习**：现在还不需要写代码，只需要建立直觉。回想一下你最近手动重复 3 次以上的 AI 任务——比如把 10 段文字翻译成英文、总结 5 篇文章、给 20 个客户写个性化的欢迎邮件。想一想，如果这件事能让程序自动做，能节省你多少时间？这个场景就是你接下来学习 API 的目标。

---

## 注册 API 账号

**为什么重要**：没有 API Key，你的程序就没法和 AI 服务对话。获取 API Key 的过程本身也能帮你理解 API 服务的基本流程——充值、选择模型、计费方式，这些概念后续会直接影响你如何高效使用 API。

**怎么理解**：API 账号和聊天账号通常是分开的。你需要单独注册一个"开发者账号"，然后获取一个 API Key——这是一串像密钥一样的字符串，你的程序需要用它来验证身份。

各平台流程大同小异，核心四步：注册 → 充值 → 拿 Key → 选模型。

| 平台 | 注册地址 | 充值方式 | 特点 |
|------|---------|---------|------|
| **DeepSeek** | [platform.deepseek.com](https://platform.deepseek.com) | 支付宝/微信，充 10 元练很久 | 便宜，适合入门 |
| **OpenRouter** | [openrouter.ai](https://openrouter.ai) | 信用卡/加密货币 | 一个 Key 调几十个模型 |
| **Claude（Anthropic）** | [console.anthropic.com](https://console.anthropic.com) | 信用卡 | Claude 系列模型 |
| **OpenAI** | [platform.openai.com](https://platform.openai.com) | 信用卡 | GPT 系列模型 |

> 具体按钮位置可能随版本更新变化。找不到就看官方文档的"首次调用 API"图文引导。

**聚合平台（基于 NewAPI / OneAPI 框架）**

中国有不少聚合平台，底层都是 NewAPI 或 OneAPI 框架，流程大同小异：

1. 注册账号 → 2. 充值 → 3. 获取 API Key → 4. 在"模型列表"里选择模型。

这些平台主要提供 OpenAI 和 Anthropic 的模型，你可以在一个平台上切换使用。不过价格通常比直接用原平台贵一点。

### API Key 安全须知

API Key 就像你的银行卡密码，**绝不能泄露**。一旦泄露，别人可以用你的账号消费，甚至恶意使用导致账号被封。

三条安全规则：

1. **不要把 API Key 写在代码里**。用环境变量或配置文件，而且不要提交到 Git 仓库。
2. **不要在公开的聊天窗口、博客文章、Stack Overflow 里贴出 API Key**。
3. **定期轮换 API Key**。如果你的 Key 不小心泄露了，立刻在控制台撤销它，生成新的。

**怎么练习**：选一个平台（推荐从 DeepSeek 开始，因为便宜且简单），完成注册并获取 API Key。把 Key 保存到一个文本文件里，命名为 `.env`，内容如下：

```
DEEPSEEK_API_KEY=你的key贴在这里
```

这个文件接下来会用到。

---

## Python 环境准备

**为什么重要**：Python 是调用 API 最简单直接的语言。虽然你也可以用 Node.js、curl 等其他方式，但 Python 最简单。`openai` 库提供了一套统一接口，几乎所有主流 AI 平台都兼容——学会了 DeepSeek 的调用方式，换到 OpenRouter、Claude 只需要改两个参数。

**怎么理解**：你需要三样东西：Python 解释器、`openai` 库、你的 API Key。

### 安装 Python

推荐用 [uv](https://docs.astral.sh/uv/)——一个 Python 工具链管理器，装 Python 和装库一步搞定。

- **macOS / Linux**：在终端运行 `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Windows**：在 PowerShell 运行 `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"`

安装完后，运行 `uv python install 3.12`，它会自动下载并安装 Python 3.12。再用 `python3 --version` 确认能看到版本号。

如果你不想用 uv，也可以直接装 Python：macOS 用 `brew install python3`，Windows 去 python.org 下载安装包，Linux 用系统包管理器。效果一样，只是 uv 后续管理更方便。

### 关于终端和编辑器

如果你从没打开过终端：macOS 推荐 [Warp](https://www.warp.dev/)（现代终端，下载即用），Windows 推荐 Windows Terminal（在 Microsoft Store 搜索安装）。Linux 用户一般已有自己习惯的终端工具，就不特别推荐了。终端就是你和电脑用文字对话的窗口。

写代码需要一个纯文本编辑器。macOS 自带的"文本编辑"不行（它会加格式），推荐用 VS Code（免费，下载即用）或者直接在终端里输入 `nano hello_api.py` 来创建和编辑文件。后面我让你"创建文件"或"运行命令"时，你知道在哪操作就行。

### 创建虚拟环境

先给这个项目建一个独立的 Python 环境：

```bash
uv venv --python 3.12 .venv
```

这会在当前目录下创建一个 `.venv` 文件夹，里面是一个干净的 Python 环境。

**为什么要用虚拟环境？** 两个好处：第一，你装的各种库不会污染系统 Python，以后出问题了直接删掉 `.venv` 重建就行；第二，不同项目可以用不同版本的库，互不干扰。这是 Python 开发的基本习惯，从一开始就养成。

### 安装 openai 库

装库不需要手动激活虚拟环境，`uv` 会自动在当前目录查找 `.venv`。所以先确保你在项目目录下：

```bash
uv pip install openai python-dotenv
```

`openai` 是调用 API 的核心库，`python-dotenv` 是用来加载 `.env` 文件的工具。

后面运行 Python 脚本也一样，用 `uv run` 即可：

```bash
uv run python chat.py
```

### 第一段代码

创建一个新文件 `hello_api.py`，内容如下：

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

# 加载 .env 文件里的环境变量
load_dotenv()

# 从环境变量读取 API Key
api_key = os.environ.get("DEEPSEEK_API_KEY")

if not api_key:
    raise ValueError("DEEPSEEK_API_KEY 环境变量未设置")

# 创建客户端
# 注意：DeepSeek 兼容 OpenAI 的 API 接口，所以可以用 openai 库
# 唯一的区别是 base_url 需要指定为 DeepSeek 的地址
# 模型名用 deepseek-v4-flash（旧名 deepseek-chat 仍可用，但将来会废弃）
client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"  # DeepSeek 的 API 地址
)

# 发送请求
response = client.chat.completions.create(
    model="deepseek-v4-flash",  # DeepSeek 的模型名称（deepseek-chat 是旧名，仍可用）
    messages=[
        {"role": "user", "content": "你好，请用一句话介绍你自己。"}
    ]
)

# 打印 AI 的回复
print(response.choices[0].message.content)
```

保存文件，在终端运行：

```bash
uv run python hello_api.py
```

如果一切正常，你会看到 AI 回复了一句话。

**有个地方值得注意**：虽然我们用的是 DeepSeek 的 API，但代码里用的是 OpenAI 的 `openai` 库。这是因为大部分现代 AI 平台都兼容 OpenAI 的 API 接口标准——你学会了这套调用方式，换到其他平台只需要改 `base_url` 和 `model` 两个参数。

比如换成 OpenRouter：

```python
client = OpenAI(
    api_key=os.environ.get("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1"
)

response = client.chat.completions.create(
    model="deepseek/deepseek-v4-flash",  # OpenRouter 的模型名称格式：provider/model
    messages=[...]
)
```

不过，Anthropic（Claude）是个例外。它有自己的 API 格式，不兼容 OpenAI 标准。如果你要用 Claude 的 API，需要查 Anthropic 官方文档，或者直接问 AI："用 Python 调 Claude API 怎么写？"

**怎么练习**：

1. 运行上面的 `hello_api.py`，确保能正常输出。
2. 修改问题内容，比如改成"写一个 Python 函数来判断一个数字是不是质数"。
3. 尝试把 `max_tokens` 改成 500，观察输出长度的变化。
4. （可选）如果你有 OpenRouter 的账号，尝试修改 `base_url` 和 `model`，用 OpenRouter 调用 DeepSeek。

---

## 计费方式：Token

在讲 API 参数之前，你需要先理解一个概念——Token。它不是你传给 API 的参数，而是 AI 平台的计费单位。不知道 Token 是什么，你就看不懂账单。

Token 是 AI 处理文本的最小单位。你可以粗略理解为"字或词"——英文中一个词大约是 1 个 token，中文中一个字大约是 1-2 个 token（因为中文编码更复杂）。

**输入和输出分别计费**。你发给 AI 的问题算输入 tokens，AI 的回复算输出 tokens。比如你发的问题是 100 tokens，AI 回复了 200 tokens，那么这次调用总共消耗 300 tokens。

不同平台的计费方式不同（2026 年 5 月价格，各家随时可能调整）：

| 平台 / 模型 | 输入价格（/ 1M tokens） | 输出价格（/ 1M tokens） |
|------------|----------------------|----------------------|
| DeepSeek V4-Flash | $0.14（≈¥1） | $0.28（≈¥2） |
| OpenRouter | 与官方价格一致 | 额外收 5.5% 平台费 |
| Claude Sonnet 4.6 | $3 | $15 |
| Claude Opus 4.8 | $5 | $25 |
| GPT-5.5 | $5 | $30 |

**怎么查最新价格**：每个平台都有定价页面——DeepSeek 在 [api-docs.deepseek.com/quick_start/pricing](https://api-docs.deepseek.com/quick_start/pricing)，Anthropic 在 [docs.anthropic.com](https://docs.anthropic.com)，OpenAI 在 [platform.openai.com](https://platform.openai.com) 的 Pricing 页面。找不到的时候，直接问 AI 也行。

**怎么估算**：一个简单的经验值是——中文大概 1 字 = 1.5 tokens，英文大概 1 词 = 1 token。如果你发给 AI 一篇 1000 字的文章，大概消耗 1500 tokens。

---

## 理解 API 参数

**为什么重要**：API 的参数直接决定了 AI 的输出质量、费用、速度。建立这些参数的直觉，能帮你在不同场景下做出正确的选择——比如什么时候该把 temperature 设低，什么时候该把 max_tokens 设大。

这里介绍三个最常用的参数：temperature、max_tokens、model。另外还会讲一个相关概念——上下文窗口，它不是你传给 API 的参数，但直接影响你能发多少内容。

**一个习惯**：不同平台的参数名和取值范围可能不一样，而且会随版本更新变化。用之前查一下官方文档，或者直接问 AI："用 DeepSeek API 调 V4-Flash，temperature 参数的范围是多少？"——这比猜快得多。

### Temperature：控制随机性

Temperature 控制的是 AI 输出的"创造性"程度。范围是 0 到 2，常用值是 0 到 1。

| 值 | 效果 | 适合场景 |
|---|------|---------|
| **0** | 确定性输出，同一问题问 100 遍得到 100 个相同答案 | 代码生成、数据提取 |
| **0.7**（推荐） | 有一定随机性，但不发散 | 大多数场景 |
| **1** | 很随机，同一问题可能得到差异很大的答案 | 创意写作、头脑风暴 |

换个说法：temperature 越低，AI 越像"复读机"；temperature 越高，AI 越像"艺术家"。

**怎么练习**：修改之前的代码，在 `client.chat.completions.create()` 里加一个参数，分别用 `temperature=0` 和 `temperature=1` 调用同一个问题（比如"写一个关于猫的短故事"），观察两次输出的差异：

```python
response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=[
        {"role": "user", "content": "写一个关于猫的短故事"}
    ],
    temperature=0  # 试着改成 1，再跑一次
)
```

### 上下文窗口（Context Window）

上下文窗口是 API 一次能"看到"的最大内容量。不同模型有不同的上下文窗口大小：

- DeepSeek V4：1M tokens
- Claude Sonnet 4.6：1M tokens
- GPT-5.5：1M tokens

这三个模型的上下文窗口都是 1M tokens，按 1 字 ≈ 1.5 tokens 估算，约 65 万中文字。

如果你的输入超过了模型的上下文窗口，API 会报错。但即使没报错，输入太长也会导致 AI "遗忘"早期的内容——就像人聊得太久会忘记开头聊了什么一样。

**实际建议**：如果你的输入超过 5K tokens，考虑分段处理或用长上下文模型。

### max_tokens：控制输出长度

`max_tokens` 限制的是 AI 回复的最大长度。设为 100，AI 最多回 100 tokens；设为 1000，AI 最多回 1000 tokens。

**为什么需要这个参数**？两个原因：

1. **控制费用**：输出越长，费用越高。如果你只需要一个简短的答案，把 max_tokens 设小可以省钱。
2. **避免无限生成**：某些场景下，AI 可能会一直生成下去（比如你让它"写一个无限长的故事"），max_tokens 能强制停止。

**实际建议**：大多数场景设为 500-1000 足够；如果你需要长文档生成，可以设到 2000-4000。

**注意**：不同平台的参数名不一样。DeepSeek 和 Anthropic 用 `max_tokens`，OpenAI 在新模型上改成了 `max_completion_tokens`。不确定时，问一句 AI 就行。

---

## 下一步

今天做了两件事：理解了 API 和聊天窗口的本质区别，跑通了第一段代码。中间学了计费单位 Token、三个 API 参数（temperature、max_tokens、model），以及上下文窗口的概念。它们直接决定你后续用 API 的成本和效果。这只是一个开始——你现在的脚本还是单次调用，每次运行只处理一个任务。

下一篇文章，我们会学习**批量处理**：怎么写循环处理 100 个文档，怎么设计批量提示词，怎么处理 API 调用失败后的重试机制。这才是 API 真正发挥威力的场景。

---

*第一周到此结束。下周我们进入批量处理——让程序自动处理 100 个任务。（第二篇即将发布）*