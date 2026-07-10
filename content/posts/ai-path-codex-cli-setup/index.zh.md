---
title: "Codex CLI 冷启动：从安装到跑通第一条指令"
slug: "ai-path-codex-cli-setup"
date: 2026-07-09T12:00:00+08:00
draft: false
description: "AI 之路番外篇：GPT-5.6 发布后，Codex 的新装法——ChatGPT 桌面版自带 Codex 模式，CLI 也仍在更新。"
tags: ["AI", "codex", "教程", "chatgpt", "openai", "冷启动", "GPT-5.6"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.png"
  alt: "水彩风格：一个终端窗口，光标闪烁，旁边是 Codex 标志和 ChatGPT 对话气泡，下方有一只手在键盘上输入"
---

> 这是「AI 之路进阶升级指南」的番外篇。如果你还没装 Codex，这篇帮你从零跑通。

2026年7月9日，OpenAI 同时做了两件事：GPT-5.6 公开发布，Codex 并入 ChatGPT 桌面版。新的 ChatGPT 桌面应用有 Chat、Work、Codex 三种模式，装一个 app 就能切换。已装独立 Codex 桌面应用的用户直接更新，项目、设置和工作流都会保留。

Codex CLI 在同一天更新到 v0.144.0/v0.144.1，给终端用户和 CI/CD 场景。两条路都走得通，看你的工作习惯。

这是 Day 8 之后的第一次实操，从账号准备到跑通第一条指令。

---

## GPT-5.6 模型家族与定价

GPT-5.6 系列有三款模型，覆盖不同场景：

| 模型 | 定位 | 输入价格（per 1M tokens） | 输出价格 |
|------|------|--------------------------|---------|
| Sol | 旗舰推理 | $5 | $30 |
| Terra | 日常平衡 | $2.50 | $15 |
| Luna | 经济高效 | $1 | $6 |

Sol 在 Coding Agent Index 上得了 80 分，超过 Claude Fable 5 的 77.2。但三款模型不是所有用户都能选——Free 和 Go 用户只能用 Terra，Plus 及以上的方案可以在三者间自由选择。

Codex 桌面版和 CLI 都使用 ChatGPT 计划附带的消费额度，没有独立的免费档。不同方案对应的可用模型和额度如下：

| 方案 | 价格 | Codex 可用模型 | 说明 |
|------|------|---------------|------|
| Free | 免费 | Terra only，有限额度 | 够体验，重度不够 |
| Plus | $20/月 | Sol/Terra/Luna，更高额度 | 个人日常推荐 |
| Pro | $200/月 | 同左，更高额度，ultra 可用 | 深度使用 |

个人用户选 Plus 最经济。下文从 Plus 方案开始讲。

---

## 第一部分：ChatGPT 账号注册与付费

如果你已有 ChatGPT Plus 或更高等级付费账号，直接跳到安装部分。

### 注册账号

1. 打开浏览器访问 [chatgpt.com](https://chatgpt.com)
2. 点击 **Sign Up**，用邮箱或 Google / Microsoft 账号注册
3. 验证邮箱（查收验证邮件）
4. 完成注册后进入免费版 ChatGPT

### 升级到 Plus

1. 登录 chatgpt.com
2. 点击左下角头像 → **My Plan** → **Upgrade to Plus**
3. 选择 **Plus** 方案（$20/月）
4. 填写支付信息

### 支付方式

OpenAI 支持以下支付方式：

- **国际信用卡**：Visa、Mastercard、American Express
- **PayPal**：绑定 PayPal 账户直接支付（中国大陆用户可用）

信用卡被拒的常见原因：

- **发卡行限制了跨境支付**：致电银行开通境外支付功能
- **IP 所在地区不支持**：确保 IP 地址在支持区域
- **虚拟信用卡**：部分虚拟信用卡可正常使用，但存在被拒风险

付款完成，账号升级为 Plus，Codex 的额度就在里面了。

---

## 第二部分：安装 Codex——桌面版（推荐）

ChatGPT 桌面版是现在用 Codex 最直接的方式。

### 下载安装

访问 [chatgpt.com/download](https://chatgpt.com/download)，下载对应系统的版本。如果你之前装过独立 Codex 桌面应用，打开就会自动更新，项目和设置都会保留。

### 切换到 Codex 模式

打开 ChatGPT 桌面版，在窗口顶部切换到 **Codex** 模式。桌面版的能力包括：

- 访问本地文件系统，直接在项目目录上工作
- 内联编辑（diff 格式展示每一处改动）
- 侧栏 PR review
- 支持多仓库

如果你习惯用之前的 ChatGPT 桌面版，旧版本已更名为 ChatGPT Classic，同样可以切换。Codex 模式可以设为默认视图，macOS 上也可以保留独立 Codex 图标。

---

## 第三部分：或者用 Codex CLI

桌面版之外，OpenAI 继续维护 Codex CLI，面向终端优先的开发者、CI/CD 和脚本自动化场景。

### 前提条件

- Node.js v18 以上（推荐 v22）
- Git（Codex 在 Git 仓库中效果最好）

验证 Node.js 版本：

```bash
node --version
# 需要显示 v18.x.x 或更高
```

### 安装

```bash
npm install -g @openai/codex
```

macOS 也可以用 Homebrew：

```bash
brew install --cask codex
```

### 验证安装

```bash
codex --version
```

输出版本号即安装成功。

### 关联账号

进入项目目录（建议在 Git 仓库中），执行：

```bash
cd /path/to/your/project
codex
```

第一次运行会触发浏览器认证，登录 ChatGPT 账号后自动授权。认证完成后进入全屏 TUI 界面。

桌面版和 CLI 使用同一套额度，账号关联一次就行。桌面版已登录则无需额外认证。

---

## 第四部分：跑通第一条指令

桌面版和 CLI 都可以直接输入自然语言指令。试试这个：

```
解释一下这个项目的文件结构，指出可能有问题的代码
```

Codex 会读取当前目录的文件，分析后给出回答。也可以试试更具体的：

```
把这个 README.md 翻译成中文，保持 Markdown 格式
```

第一次用可以从简单的只读指令开始，熟悉之后再让 Codex 改代码。

---

## 常见问题

**Codex 桌面版和 CLI 有什么区别？**

桌面版整合在 ChatGPT 桌面应用中，有图形化的 diff 审阅和 PR review 侧栏，适合日常开发。CLI 是终端工具，适合 CI/CD 和脚本化场景。底层能力一致，桌面版多了图形功能。桌面版用 ChatGPT 账号已登录即完成认证，CLI 需要额外走一次 OAuth 流程。

**Free 用户能用 Codex 吗？**

可以用，在 ChatGPT 桌面版切换到 Codex 模式就能用，但只能用 Terra 模型且额度有限。重度使用建议升级到 Plus。Free 账号在 CLI 上不可用。

**"Command not found: codex"**

npm 全局包不在 PATH 中。在 `~/.zshrc` 或 `~/.bashrc` 中添加：

```bash
export PATH="$PATH:$(npm prefix -g)/bin"
```

**认证失败**

桌面版检查 ChatGPT 是否已登录。CLI 检查账号是否为 Plus 或更高方案。

**Codex 不愿意修改文件**

Codex 默认是 Suggest 模式，给出建议但不直接执行。切换到 Auto-Edit 模式：

```bash
codex --approval-policy on-failure
```

桌面版可以在设置中调整审批策略。

---

## 安装检查清单

### 桌面版

- [ ] ChatGPT Plus 或 Free 账号（已登录）
- [ ] 下载 ChatGPT 桌面版 (chatgpt.com/download)
- [ ] 切换到 Codex 模式
- [ ] 发送第一条指令验证可用性

### CLI（备选）

- [ ] ChatGPT Plus 或更高方案
- [ ] Node.js v18+ (`node --version`)
- [ ] Git 已安装 (`git --version`)
- [ ] Codex CLI 已安装 (`npm install -g @openai/codex`)
- [ ] 验证安装 (`codex --version`)
- [ ] 首次运行并完成 OAuth 认证 (`codex`)
- [ ] 发送第一条指令验证可用性

---

> 这是「AI 之路进阶升级指南」的番外篇。上篇 [Day 8 自主执行型 AI](../ai-path-l1-l2-week2-day8/) 对比了 Codex、Claude Code 和 OpenCode 三款工具。如果你更倾向开源方案，可以看另一篇番外 [OpenCode 冷启动](../ai-path-opencode-zen-setup/)。
