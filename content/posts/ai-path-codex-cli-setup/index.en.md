---
title: "Codex Cold Start: From Installation to Your First Command"
slug: "ai-path-codex-cli-setup"
date: "2026-07-09T12:00:00+08:00"
draft: false
description: "AI Path bonus article: with GPT-5.6 out and Codex merged into the ChatGPT desktop app, here's how to get started — desktop or CLI, from account setup to your first instruction."
tags: ["AI", "codex", "tutorial", "chatgpt", "openai", "cold-start", "GPT-5.6"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor: a terminal window with a blinking cursor, Codex logo and ChatGPT speech bubble nearby, hands typing on a keyboard below"
---

> This is a bonus article for the "AI Path L1→L2 Upgrade Guide." If you haven't set up Codex yet, this guide gets you from zero to running.

On July 9, 2026, OpenAI made two announcements at once: GPT-5.6 went public, and Codex was merged into the ChatGPT desktop app. The new desktop app has three modes — Chat, Work, and Codex — all in a single installation. If you already have the standalone Codex desktop app, it updates in place. Your projects, settings, and workflows carry over.

Codex CLI also updated on the same day to v0.144.0/v0.144.1, for terminal-first developers and CI/CD pipelines. Both paths work. Pick the one that fits your workflow.

This is the first hands-on article since Day 8 — from account setup to running your first instruction.

---

## GPT-5.6 Models and Pricing

The GPT-5.6 family has three models, each for a different use case:

| Model | Role | Input (per 1M tokens) | Output |
|-------|------|----------------------|--------|
| Sol | Flagship reasoning | $5 | $30 |
| Terra | Daily balance | $2.50 | $15 |
| Luna | Cost-efficient | $1 | $6 |

Sol scored 80 on the Coding Agent Index, above Claude Fable 5's 77.2. But not all plans give you access to every model — Free and Go users are limited to Terra. Plus and above can choose freely.

Both the Codex desktop app and CLI draw from your ChatGPT plan's credits. There's no separate free tier for Codex. Here's what each plan offers:

| Plan | Price | Codex Models | Notes |
|------|-------|-------------|-------|
| Free | $0 | Terra only, limited quota | Enough to try, not for heavy use |
| Plus | $20/mo | Sol/Terra/Luna, higher quota | Best for personal daily use |
| Pro | $200/mo | Same, higher quota, ultra available | Heavy daily use |

For most individuals, Plus is the most economical choice. The rest of this guide assumes a Plus account.

---

## Part 1: ChatGPT Plus Account

If you already have a ChatGPT Plus or higher subscription, skip to Part 2.

### Create an Account

1. Open a browser and go to [chatgpt.com](https://chatgpt.com)
2. Click **Sign Up** with your email, Google, or Microsoft account
3. Verify your email
4. You're now on the free tier

### Upgrade to Plus

1. Log in at chatgpt.com
2. Click your avatar (bottom-left) → **My Plan** → **Upgrade to Plus**
3. Select **Plus** ($20/month)
4. Enter payment details

### Payment Methods

OpenAI supports:

- **International credit cards**: Visa, Mastercard, American Express
- **PayPal**: Works with PayPal accounts, including for users in China

If your card is declined, common causes:

- **Card issuer blocks cross-border payments**: Call your bank to enable international transactions
- **IP region is not supported**: Make sure your IP is in a supported region
- **Virtual cards**: Some work, but some are rejected

Payment done, your account is upgraded. Codex credits are included.

---

## Part 2: Install Codex — Desktop App (Recommended)

The ChatGPT desktop app is now the most straightforward way to use Codex.

### Download and Install

Go to [chatgpt.com/download](https://chatgpt.com/download) and download the version for your system. If you already have the standalone Codex desktop app, opening it triggers an automatic update — your projects and settings carry over.

### Switch to Codex Mode

Open the ChatGPT desktop app and switch to **Codex** mode at the top of the window. Desktop mode gives you:

- **Local file system access** — work directly on project directories
- **Inline diff editing** — every change shown as a diff
- **PR review sidebar**
- **Multi-repo support**

If you're used to the old ChatGPT desktop, it's now called ChatGPT Classic. You can switch between them freely. Codex mode can be set as your default view. On macOS, you can keep a standalone Codex icon in the dock.

---

## Part 3: Or Use Codex CLI

If you prefer the terminal, OpenAI continues to maintain Codex CLI for terminal-first development, CI/CD, and scripting.

### Prerequisites

- Node.js v18+ (v22 recommended)
- Git (Codex works best inside a Git repository)

Verify your Node.js version:

```bash
node --version
# Must return v18.x.x or higher
```

### Install

```bash
npm install -g @openai/codex
```

macOS users can also use Homebrew:

```bash
brew install --cask codex
```

### Verify

```bash
codex --version
```

A version number means installation succeeded.

### Link Your Account

Navigate to a project directory (a Git repo is best) and run:

```bash
cd /path/to/your/project
codex
```

On first launch, your browser opens for ChatGPT authentication. Once authorized, Codex starts its full-screen TUI.

The desktop app and CLI share the same credit pool. Authenticate once and you're set. If you're already logged into the desktop app, you don't need extra authentication for the CLI.

---

## Part 4: Your First Command

Both the desktop app and CLI let you type natural language instructions. Try this:

```
Explain this project's file structure and point out any problematic code
```

Codex reads the current directory's files and returns an analysis. Try something more specific:

```
Translate this README.md to Spanish, keep the Markdown format
```

Start with read-only instructions to get a feel for how Codex handles your project. Let it edit code once you're comfortable.

---

## FAQ

**What's the difference between Codex desktop and Codex CLI?**

The desktop app is integrated into ChatGPT with graphical diff review and a PR review sidebar — suited for everyday development. The CLI is a terminal tool for CI/CD and scripting. The underlying capabilities are the same; the desktop app adds GUI features. The desktop app authenticates through your ChatGPT login, while the CLI requires a one-time OAuth flow.

**Can Free users use Codex?**

Yes, but with restrictions. You can switch to Codex mode in the ChatGPT desktop app with a Free account, but you're limited to the Terra model with a reduced quota. Free accounts cannot use Codex CLI.

**"Command not found: codex"**

npm global binaries aren't in your PATH. Add this to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$PATH:$(npm prefix -g)/bin"
```

**Authentication fails**

For the desktop app, check that you're logged into ChatGPT. For the CLI, verify your account is on Plus or higher.

**Codex won't edit files**

By default, Codex runs in Suggest mode — it proposes changes but doesn't apply them. Switch to Auto-Edit:

```bash
codex --approval-policy on-failure
```

In the desktop app, you can adjust the approval policy in Settings.

---

## Setup Checklist

### Desktop App

- [ ] ChatGPT Plus or Free account (logged in)
- [ ] Downloaded ChatGPT desktop app (chatgpt.com/download)
- [ ] Switched to Codex mode
- [ ] Sent first instruction to verify

### CLI (Alternative)

- [ ] ChatGPT Plus or higher
- [ ] Node.js v18+ (`node --version`)
- [ ] Git installed (`git --version`)
- [ ] Codex CLI installed (`npm install -g @openai/codex`)
- [ ] Installation verified (`codex --version`)
- [ ] First run + OAuth authentication completed (`codex`)
- [ ] Sent first instruction to verify

---

> This is a bonus article for the "AI Path L1→L2 Upgrade Guide." Previous: [Day 8: Autonomous Execution AI](../ai-path-l1-l2-week2-day8/) compared Codex, Claude Code, and OpenCode. If you prefer an open-source alternative, see [OpenCode Cold Start](../ai-path-opencode-zen-setup/).
