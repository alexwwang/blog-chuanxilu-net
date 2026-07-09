---
title: "Codex CLI 冷启动：从安装到跑通第一条指令"
slug: "ai-path-codex-cli-setup"
date: 2026-07-06T06:00:00+08:00
draft: false
description: "AI 之路番外篇：Codex CLI 安装、ChatGPT 账号注册与付费、关联账号，完整冷启动流程。"
tags: ["AI", "codex", "教程", "chatgpt", "openai", "冷启动"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.png"
  alt: "水彩风格：一个终端窗口，光标闪烁，旁边是 Codex 标志和 ChatGPT 对话气泡，下方有一只手在键盘上输入"
---

> 这是「AI 之路进阶升级指南」的番外篇。如果你还没有安装 Codex CLI，这篇帮你从零跑通。

Day 8 介绍了三款自主执行型 AI 工具，其中 Codex 是 OpenAI 官方出品的编程代理，在终端里用自然语言直接指挥它读文件、改代码、执行命令。

用 Codex 只有一个前提：ChatGPT 付费账号。下面从账号准备开始，再到安装和配置。

---

## 第一部分：ChatGPT 账号注册与付费

如果你已经有 ChatGPT Plus 或更高等级的付费账号，直接跳到第二部分。

### 注册账号

1. 打开浏览器访问 [chatgpt.com](https://chatgpt.com)
2. 点击 **Sign Up**，用邮箱或 Google / Microsoft 账号注册
3. 验证邮箱（查收验证邮件）
4. 完成注册后，你会进入免费版 ChatGPT

### 选择付费方案

Codex CLI 需要 ChatGPT Plus（每月 $20）或更高等级的方案才能使用。2026 年 7 月的方案对比：

| 方案 | 价格 | Codex 可用 | 适用场景 |
|------|------|-----------|---------|
| Plus | $20/月 | 是，基础额度 | 个人日常使用 |
| Pro | $200/月 | 是，更高额度 | 深度使用 |
| Business | $25/人/月 | 是 | 团队使用 |

个人用户选 Plus 就够了。升级步骤：

1. 登录 chatgpt.com
2. 点击左下角头像 → **My Plan** → **Upgrade to Plus**
3. 选择 **Plus** 方案
4. 填写支付信息

### 支付方式

OpenAI 支持以下支付方式：

- **国际信用卡**：Visa、Mastercard、American Express
- **PayPal**：绑定 PayPal 账户直接支付（中国大陆用户可用）

如果信用卡被拒，常见原因和解决方法：

- **发卡行限制了跨境支付**：致电银行开通境外支付功能
- **IP 所在地区不支持**：确保 IP 地址在支持区域
- **虚拟信用卡**：部分虚拟信用卡可正常使用，但存在被拒的风险

付款完成，账号就升级为 Plus 了。Codex 包含在方案里，不用额外付钱。

---

## 第二部分：安装 Codex CLI

### 前提条件

- Node.js v18 以上（推荐 v22）
- Git（Codex 在 Git 仓库中效果最好）
- 一个 ChatGPT Plus 或更高等级的账号

验证 Node.js 版本：

```bash
node --version
# 需要显示 v18.x.x 或更高
```

### 安装

```bash
npm install -g @openai/codex
```

macOS 用户也可以用 Homebrew：

```bash
brew install --cask codex
```

### 验证安装

```bash
codex --version
```

输出版本号即安装成功。

---

## 第三部分：关联 ChatGPT 账号

安装完成后，进入项目目录（建议在 Git 仓库中），执行：

```bash
cd /path/to/your/project
codex
```

第一次运行会进入认证流程：

1. 终端显示一个链接和一个验证码
2. 自动打开浏览器，跳转到 ChatGPT 登录页
3. 登录你的 ChatGPT Plus 账号
4. 确认授权
5. 回到终端，认证完成

认证完成，Codex 以全屏终端界面（TUI）启动，之后直接输入自然语言指令。

---

## 第四部分：跑通第一条指令

在 Codex TUI 中输入：

```
解释一下这个项目的文件结构，指出可能有问题的代码
```

Codex 会读取当前目录的文件，分析后给出回答。你也可以试试更具体的指令：

```
把这个 README.md 翻译成中文，保持 Markdown 格式
```

---

## 常见问题

**"Command not found: codex"**

npm 全局包不在 PATH 中。在 `~/.zshrc` 或 `~/.bashrc` 中添加：

```bash
export PATH="$PATH:$(npm prefix -g)/bin"
```

**认证失败**

检查你的 ChatGPT 账号是否为 Plus 或更高方案。免费版无法使用 Codex CLI。

**Codex 不愿意修改文件**

Codex 默认是 Suggest 模式，给出建议但不直接执行。切换到 Auto-Edit 模式：

```bash
codex --approval-policy on-failure
```

---

## 完整安装检查清单

- [ ] ChatGPT Plus 或更高方案（已付费激活）
- [ ] Node.js v18+ (`node --version`)
- [ ] Git 已安装 (`git --version`)
- [ ] Codex CLI 已安装 (`npm install -g @openai/codex`)
- [ ] 验证安装 (`codex --version`)
- [ ] 首次运行并完成 OAuth 认证 (`codex`)
- [ ] 发送第一条指令验证可用性

---

> 这是「AI 之路进阶升级指南」的番外篇。上篇 [Day 8 自主执行型 AI](../ai-path-l1-l2-week2-day8/) 对比了 Codex、Claude Code 和 OpenCode 三款工具。如果你更倾向开源方案，可以看另一篇番外 [OpenCode 冷启动](../ai-path-opencode-zen-setup/)。
