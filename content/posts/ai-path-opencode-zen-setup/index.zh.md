---
title: "OpenCode 冷启动：五分钟用上免费的 DeepSeek V4 Flash"
slug: "ai-path-opencode-zen-setup"
date: 2026-07-06T06:00:00+08:00
draft: false
description: "AI 之路番外篇：OpenCode 安装、注册 Zen 账号、配置 API Key、选择免费 DeepSeek V4 Flash 模型，完整冷启动流程。"
tags: ["AI", "opencode", "教程", "zen", "deepseek", "冷启动"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.png"
  alt: "水彩风格：一台打开的笔记本电脑，屏幕上显示终端界面，旁边漂浮着 OpenCode 和 Zen 的图标，一只手持钥匙插入锁孔"
---

> 这是「AI 之路进阶升级指南」的番外篇。如果你还没有安装 OpenCode，这篇帮你从零跑通。

你从这一系列的前面几篇了解了自主执行型 AI 的能力。但要真正用起来，第一步是安装和配置工具。OpenCode 是一个开源 AI 编程助手，完全免费，支持多模型切换和技能系统。配合 OpenCode Zen 服务，你可以在不配置任何第三方 API Key 的情况下，直接用上经过测试的精选模型，包括免费的 DeepSeek V4 Flash。

整个过程五分钟。

---

## 第一步：安装 OpenCode

以下命令均在**终端**（macOS 的「终端」应用 / Windows 的 PowerShell）中执行。推荐用 bun 安装。先装 bun：

- **macOS / Linux**：`curl -fsSL https://bun.sh/install | bash`
- **Windows**（PowerShell）：`powershell -c "irm bun.sh/install.ps1 | iex"`

装完验证 `bun --version`，然后安装 OpenCode：

```bash
bun install -g opencode
```

验证 `opencode --version`（v1.14.x 以上即成功）。习惯 npm 的话：`npm install -g opencode`。

> `opencode` 找不到：将全局 bin 目录加入 PATH。bun 的在 `~/.bun/bin`（Windows: `%USERPROFILE%\.bun\bin`），npm 的在 `$(npm prefix -g)/bin`（Windows: 该目录下的 `node_modules\.bin`）。

---

## 第二步：注册 OpenCode Zen 并获取 API Key

OpenCode Zen 是 OpenCode 团队提供的精选模型网关。你不需要配置任何第三方 API Key，注册一个 Zen 账号就能直接用。

1. 打开浏览器，访问 [opencode.ai/zen](https://opencode.ai/zen)
2. 点击 Sign Up 注册账号（支持 GitHub 或 Google 快速登录）
3. 登录后进入 Zen 仪表盘，点击 **Create API Key**
4. 给你的密钥起个名字，比如 `my-zen-key`，点击 Create
5. 复制生成的 API Key（格式类似 `sk-zen-xxxxxxxx`）

> 密钥完整内容只会显示一次，之后只能看到掩码版本（但可以复制）。建议生成后立刻保存。

---

## 第三步：在 OpenCode 中配置 Zen 提供商

回到终端，启动 OpenCode：

```bash
opencode
```

第一次启动会进入配置界面。在底部的输入框中输入：

```
/connect
```

从列表中选择 **Zen**（OpenCode Zen），然后粘贴你刚才复制的 API Key。

或者你也可以通过配置文件手动添加。配置文件位于 `~/.config/opencode/opencode.json`（macOS/Linux），添加以下内容：

```json
{
  "provider": {
    "zen": {
      "type": "opencode-zen",
      "apiKey": "sk-zen-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
  }
}
```

把 `apiKey` 替换成你自己的密钥。

---

## 第四步：选择免费模型

配置完提供商后，在 OpenCode 中输入：

```
/model
```

你会看到一个包含数十个模型的列表。找到 **DeepSeek V4 Flash Free**，选中它。

带有 "Free" 标签的模型都是限时免费的。DeepSeek V4 Flash Free 是当前性价比最高的免费模型之一，上下文 200K，足以满足大多数初级 Agent 自动化任务的需要。

你也可以切换到其他免费模型试试：

- **MiMo-V2.5 Free** — 多模态模型
- **Nemotron 3 Ultra Free** — NVIDIA 提供的免费模型
- **Big Pickle** — 隐身模型，免费

---

## 第五步：验证

选择模型后，输入一个简单指令验证是否正常工作：

```
你好，请用 Python 打印 Hello World
```

如果 OpenCode 能正常回复，说明配置完成了。你也可以查看当前使用的模型：

```
/model
```

应该显示 `opencode/deepseek-v4-flash-free`。

---

## 完整安装检查清单

- [ ] 安装 bun (`curl -fsSL https://bun.sh/install | bash`)
- [ ] 安装 OpenCode (`bun install -g opencode`)
- [ ] 验证安装 (`opencode --version`)
- [ ] 注册 Zen 账号 (opencode.ai/zen)
- [ ] 创建并保存 API Key
- [ ] 在 OpenCode 中配置 Zen (`/connect`)
- [ ] 选择 DeepSeek V4 Flash Free (`/model`)
- [ ] 发送第一条指令验证可用性

---

## 接下来可以做什么

一切就绪后，在终端敲入 `opencode` 启动。你会进入一个干净的界面，底部是输入区，顶部是对话区。

先了解最关键的概念：**Plan 模式**和 **Build 模式**。Tab 键可以来回切换，左下角会显示当前处于什么模式。

- **Plan 模式**：你说目标，它出方案。Agent 不会真的执行操作，而是跟你讨论怎么干。适合先对齐思路。
- **Build 模式**：你说指令，它直接动手。Agent 会边执行边展示每一步的结果。

![Plan 和 Build 模式对比示意图](illustration.png)

### 试试整理下载文件夹

如果你跟着 Day 8 学完了基础操作，现在可以拿「整理下载文件夹」来体验这套工作流：

1. 确保当前是 **Plan 模式**（左下角显示 Plan，若在 Build 则按 Tab 切换）
2. 告诉它目标："帮我整理下载文件夹，把文件按类型分类放好"
3. Agent 会给出一个方案——比如按文档、图片、压缩包、安装包分类，每种放到对应子目录
4. 如果对方案有不同想法，直接回复修改意见
5. 满意的话直接按 **Tab 键切换到 Build 模式**，输入"按方案执行"
6. Agent 开始动手，你看着它创建文件夹、移动文件

这只是一个开始。日常工作里那些重复操作——批量重命名、整理项目结构、写脚本——都可以用同样的流程：Plan 对齐方案，Build 交给它干。

**如果将来觉得 DeepSeek V4 Flash Free 的上下文不够用或者想试试别的模型**，OpenCode 还有订阅制的 [Go 方案](https://opencode.ai/docs/go/#usage-limits)，可以使用如 GLM-5.2、DeepSeek V4 Pro、Qwen3.7、Kimi K2.7/2.6、Mimo 2.5、Minimax M3 等最新的开源模型，支持 1M 上下文或者多模态。如果想订阅的话，通过这个邀请链接注册首月可以有 **5 美元的优惠**：<https://opencode.ai/go?ref=CGNQ69YARZ>

---

> 这是「AI 之路进阶升级指南」的番外篇。上篇是 [Day 8 自主执行型 AI](../ai-path-l1-l2-week2-day8/)。配置完成后，你也可以阅读 [三套 OpenCode 配置方案](../opencode-triple-config-switch/) 了解更进阶的用法。
