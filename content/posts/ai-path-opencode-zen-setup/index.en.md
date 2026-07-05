---
title: "OpenCode Cold Start: DeepSeek V4 Flash Free in 5 Minutes"
slug: "ai-path-opencode-zen-setup"
date: "2026-07-06T06:00:00+08:00"
draft: false
description: "AI Path bonus article: install OpenCode, register a Zen account, configure your API key, and select the free DeepSeek V4 Flash model -- a complete cold-start walkthrough."
tags: ["AI", "opencode", "tutorial", "zen", "deepseek", "cold-start"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor: an open laptop with a terminal screen, OpenCode and Zen icons floating nearby, a hand inserting a key into a lock"
---

> This is a bonus article for the "AI Path L1→L2 Upgrade Guide." If you have not installed OpenCode yet, this guide gets you from zero to running.

In Day 8 you learned about autonomous execution AI. The next step is actually installing the thing. OpenCode is an open-source AI coding assistant. It is free, supports multiple models, and has a skill system. Paired with OpenCode Zen, you can use tested models without setting up third-party API keys, including the free DeepSeek V4 Flash.

The whole process takes five minutes.

---

## Step 1: Install OpenCode

All commands below run in the **terminal** (Terminal.app on macOS, PowerShell on Windows). Install bun first:

- **macOS / Linux**: `curl -fsSL https://bun.sh/install | bash`
- **Windows** (PowerShell): `powershell -c "irm bun.sh/install.ps1 | iex"`

Verify with `bun --version`, then install OpenCode:

```bash
bun install -g opencode
```

Verify with `opencode --version` (v1.14.x+). Prefer npm? `npm install -g opencode`.

> `opencode` not found: add the global bin dir to your PATH. For bun: `~/.bun/bin` (Windows: `%USERPROFILE%\.bun\bin`). For npm: `$(npm prefix -g)/bin` (Windows: the `node_modules\.bin` subdirectory under it).

---

## Step 2: Register OpenCode Zen and Get an API Key

OpenCode Zen is a model gateway from the OpenCode team. You do not need third-party API keys. Just register a Zen account.

1. Open your browser and go to [opencode.ai/zen](https://opencode.ai/zen)
2. Click **Sign Up** (GitHub or Google login supported)
3. Once logged in, go to the Zen dashboard and click **Create API Key**
4. Name your key (e.g., `my-zen-key`) and click Create
5. Copy the generated API key (format: `sk-zen-xxxxxxxx`)

> The full key is only shown once. After that, only a masked version is displayed (but you can still copy it). Save it somewhere safe right after creation.

---

## Step 3: Configure Zen Provider in OpenCode

Go back to your terminal and start OpenCode:

```bash
opencode
```

On first launch, you enter the configuration flow. Type this in the input bar:

```
/connect
```

Select **Zen** from the list, then paste your API key.

Alternatively, add it manually to the config file at `~/.config/opencode/opencode.json`:

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

Replace the `apiKey` value with your actual key.

---

## Step 4: Select the Free Model

After configuring the provider, type this in OpenCode:

```
/model
```

Browse the model list and find **DeepSeek V4 Flash Free**. Select it.

Models labeled "Free" are available at no cost for a limited time. DeepSeek V4 Flash Free has a 200K context window, enough for basic agent automation tasks.

Or try other free models:

- **MiMo-V2.5 Free** -- multimodal model
- **Nemotron 3 Ultra Free** -- NVIDIA's free offering
- **Big Pickle** -- a stealth model, free

---

## Step 5: Verify

Send a simple instruction to confirm everything works:

```
Hello, print Hello World using Python
```

If OpenCode responds correctly, your setup is complete. Check your current model anytime with:

```
/model
```

It should show `opencode/deepseek-v4-flash-free`.

---

## Setup Checklist

- [ ] Bun installed (`curl -fsSL https://bun.sh/install | bash`)
- [ ] OpenCode installed (`bun install -g opencode`)
- [ ] Installation verified (`opencode --version`)
- [ ] Zen account registered (opencode.ai/zen)
- [ ] API key created and saved
- [ ] Zen provider configured in OpenCode (`/connect`)
- [ ] DeepSeek V4 Flash Free selected (`/model`)
- [ ] First instruction sent and verified

---

## What's Next

Ready? Type `opencode` in your terminal. You will see a clean interface with input at the bottom and conversation history at the top.

First, the two key modes: **Plan mode** and **Build mode**. Press **Tab** to switch between them. The bottom-left corner shows the current mode.

- **Plan mode**: You state the goal, it proposes a plan. The agent discusses the approach without executing anything. Good for aligning on strategy first.
- **Build mode**: You give instructions, it takes action. The agent executes and shows results step by step.

![Plan vs Build mode illustration](illustration.png)

### Try Organizing Your Downloads Folder

If you followed Day 8, here is a good way to test this workflow:

1. Make sure you are in **Plan mode** (the bottom-left corner shows "Plan". Press Tab if it says "Build").
2. Tell it: "Organize my downloads folder, sort files by type."
3. The agent will propose a plan. For example, it might suggest subfolders for documents, images, archives, and installers, each getting the right files.
4. If you have different ideas, just reply with changes.
5. If it looks good, press **Tab to switch to Build mode** and say "Execute the plan."
6. Watch the agent create folders and move files in real time.

This is just the start. For everyday repetitive tasks like batch renaming, organizing projects, or writing scripts, the same flow works: Plan to align on approach, Build to get it done.

**If DeepSeek V4 Flash Free's context window is not enough, or you want to try other models**, OpenCode also has a subscription-based [Go plan](https://opencode.ai/docs/go/#usage-limits). It includes the latest open-source models like GLM-5.2, DeepSeek V4 Pro, Qwen3.7, Kimi K2.7/2.6, Mimo 2.5, and Minimax M3, with 1M context windows or multimodal support. If you would like to subscribe, signing up through this invite link gives you **$5 off your first month**: <https://opencode.ai/go?ref=CGNQ69YARZ>

---

> This is a bonus article for the "AI Path L1→L2 Upgrade Guide." Previous: [Day 8: Autonomous Execution AI](../ai-path-l1-l2-week2-day8/). After setting up, check out [Triple Config for OpenCode](../opencode-triple-config-switch/) for more advanced usage.
