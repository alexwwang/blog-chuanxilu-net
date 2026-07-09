---
title: "Codex CLI Cold Start: From Installation to Your First Command"
slug: "ai-path-codex-cli-setup"
date: "2026-07-06T06:00:00+08:00"
draft: false
description: "AI Path bonus article: install Codex CLI, register and upgrade ChatGPT, link your account, and run your first instruction."
tags: ["AI", "codex", "tutorial", "chatgpt", "openai", "cold-start"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor: a terminal window with a blinking cursor, Codex logo and ChatGPT speech bubble nearby, hands typing on a keyboard below"
---

> This is a bonus article for the "AI Path L1→L2 Upgrade Guide." If you haven't installed Codex CLI yet, this guide gets you from zero to running.

Day 8 introduced three autonomous execution AI tools. Among them, Codex is OpenAI's official coding agent. It runs directly in your terminal. You tell it what to do in plain English, and it reads files, edits code, and runs commands.

You only need one thing: a paid ChatGPT account. We will cover account setup first, then Codex CLI installation.

---

## Part 1: ChatGPT Account Registration and Payment

If you already have a ChatGPT Plus or higher subscription, skip to Part 2.

### Create an Account

1. Open a browser and go to [chatgpt.com](https://chatgpt.com)
2. Click **Sign Up** with your email, Google, or Microsoft account
3. Verify your email
4. Once registered, you'll be on the free tier

### Choose a Plan

Codex CLI requires ChatGPT Plus ($20/month) or a higher tier. Here are the current plans (as of July 2026):

| Plan | Price | Codex Access | Best For |
|------|-------|-------------|----------|
| Plus | $20/mo | Yes, basic quota | Personal use |
| Pro | $200/mo | Yes, higher quota | Heavy use |
| Business | $25/user/mo | Yes | Team use |

Plus is sufficient for most users. To upgrade:

1. Log in at chatgpt.com
2. Click your avatar (bottom-left) → **My Plan** → **Upgrade to Plus**
3. Select **Plus**
4. Enter payment details

### Payment Methods

OpenAI supports:

- **International credit cards**: Visa, Mastercard, American Express
- **PayPal**: Works with PayPal accounts, including for users in China

If your card is declined, common causes:

- **Card issuer blocks cross-border payments**: Call your bank to enable international transactions
- **IP region is not supported**: Make sure your IP is in a supported region
- **Virtual cards**: Some virtual cards work, but some are rejected

After payment, your account is upgraded and Codex access is included at no extra charge.

---

## Part 2: Install Codex CLI

### Prerequisites

- Node.js v18+ (v22 recommended)
- Git (Codex works best inside a Git repository)
- A ChatGPT Plus or higher account

Verify Node.js:

```bash
node --version
# Must return v18.x.x or higher
```

### Installation

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

If you see a version number, installation succeeded.

---

## Part 3: Link Your ChatGPT Account

Navigate to a project directory (a Git repo is best) and run:

```bash
cd /path/to/your/project
codex
```

On first launch, you'll go through authentication:

1. The terminal shows a link and a verification code
2. Your browser opens to the ChatGPT login page
3. Sign in with your ChatGPT Plus account
4. Confirm authorization
5. Return to your terminal. Authentication is now complete

Codex then starts its full-screen terminal UI (TUI). You can type natural language instructions directly.

---

## Part 4: Your First Command

In the Codex TUI, type:

```
Explain this project's file structure and point out any problematic code
```

Codex reads the current directory's files and provides an analysis. Try more specific tasks:

```
Translate this README.md to Spanish, keep the Markdown format
```

---

## Troubleshooting

**"Command not found: codex"**

npm global binaries aren't in your PATH. Add this to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$PATH:$(npm prefix -g)/bin"
```

**Authentication fails**

Check that your ChatGPT account is on the Plus plan or higher. Free accounts cannot use Codex CLI.

**Codex won't edit files**

By default, Codex runs in Suggest mode. It proposes changes but doesn't apply them. Switch to Auto-Edit:

```bash
codex --approval-policy on-failure
```

---

## Setup Checklist

- [ ] ChatGPT Plus or higher (paid and activated)
- [ ] Node.js v18+ (`node --version`)
- [ ] Git installed (`git --version`)
- [ ] Codex CLI installed (`npm install -g @openai/codex`)
- [ ] Installation verified (`codex --version`)
- [ ] First run + OAuth authentication completed (`codex`)
- [ ] First instruction sent and verified

---

> This is a bonus article for the "AI Path L1→L2 Upgrade Guide." Previous: [Day 8: Autonomous Execution AI](../ai-path-l1-l2-week2-day8/) compared Codex, Claude Code, and OpenCode. If you prefer an open-source alternative, see the companion article [OpenCode Cold Start](../ai-path-opencode-zen-setup/).
