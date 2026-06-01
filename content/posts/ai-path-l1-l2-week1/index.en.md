---
title: "AI Path L1→L2 Upgrade Guide (1): Your First API Call"
slug: "ai-path-l1-l2-week1"
date: "2026-06-01T07:00:00+08:00"
draft: true
description: "First part of the AI Path L1→L2 Upgrade Guide series. Learn what APIs are, how they differ from chat windows, register for API accounts (DeepSeek/OpenRouter/Claude), set up Python, run your first API call, and build intuition for token, temperature, context window, and max_tokens."
tags: ["AI", "toolchain", "evolution-path", "tutorial", "API"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.jpeg"
  alt: "Watercolor: chat bubbles dissolving into a token stream flowing into a notebook and brass key on a desk"
---

> **TL;DR:** This is Part 1 of the "AI Path L1→L2 Upgrade Guide" series. Four parts total, one per week of practice. This article takes you from chat windows to APIs—automating your AI interactions through code, laying the foundation for batch processing and autonomous task-execution AI.

## Introduction: From "I Ask AI" to "Programs Ask AI"

If you finished the L0→L1 graduation checklist, you might remember one line from the graduation post: "Register for an API account and use Python to print your first AI reply." Today is that day.

Chat windows have two limitations. First, they're one-off—each task starts fresh. Second, they require you at the keyboard. No automation.

The core difference at L2 is **programs call AI instead of you**. You write the logic once; it runs a hundred times, a thousand times. You have 100 documents to summarize? L0→L1 means sending 100 manual requests. L2 means writing a script that processes all 100 automatically. You just wait for the results.

From L1 to L2, the key step is learning APIs. An API is the bridge between your program and AI—like you talking to AI in a chat window, except this time your program does the talking.

This guide takes 4 weeks to walk you through this path:

| Part | Topic | Core Content |
|------|-------|--------------|
| **Part 1** (this article) | **Your First API Call** | API vs chat window, register accounts, Python setup, first code run, understand token / temperature |
| **Part 2** | Batch Processing | Handle 100 documents, batch prompt design, error handling and retry mechanisms |
| **Part 3** | Autonomous Execution AI | Claude Code / OpenCode basics, read files, edit files, run commands |
| **Part 4** | Toolkit | Common tools and best practices (logging, caching, evaluation) |

Ready? Let's begin.

---

## What Is an API, and How Is It Different From a Chat Window?

**Why it matters:** This is the hurdle you must cross from L1 to L2. Many people think APIs are just "advanced chat windows," but they're built for fundamentally different users—one for humans, the other for programs.

**How to think about it:** A chat window is simple—you type, AI replies. You ask questions, add instructions, ask AI to adjust the output, back and forth.

| | Chat Window | API |
|---|------------|-----|
| Who operates | You | Your code |
| Tasks at once | One | Can be hundreds |
| Automatable | No | Yes |
| Best for | Exploration, trial-and-error, daily Q&A | Batch processing, scheduled tasks, embedding in tools |

Use an analogy: chat window = you stand at the counter and order in person, one item at a time. API = you send a written order to the kitchen—they prepare everything and deliver it when ready. You write the order once; they handle the rest.

**Practice:** No need to write code yet, just build intuition. Think back to the last AI task you manually repeated 3+ times—like translating 10 text segments to English, summarizing 5 articles, writing personalized welcome emails for 20 clients. Imagine if a program could do this automatically. How much time would that save? That scenario is your goal in learning APIs.

---

## Registering for API Accounts

**Why it matters:** Without an API Key, your program can't talk to AI services. The process of getting one also helps you understand the basic flow—adding credits, choosing models, billing methods. These concepts will directly affect how efficiently you use APIs later.

**How to think about it:** API accounts and chat accounts are usually separate. You need to register a "developer account," then get an API Key—a credential string that your program uses to authenticate.

The process is similar across platforms: register → add credits → get API Key → choose model.

| Platform | Sign-up URL | Payment | Notes |
|----------|-------------|---------|-------|
| **DeepSeek** | [platform.deepseek.com](https://platform.deepseek.com) | Alipay/WeChat, ¥10 goes far | Cheap, great for beginners |
| **OpenRouter** | [openrouter.ai](https://openrouter.ai) | Credit card / crypto | One Key, dozens of models |
| **Claude (Anthropic)** | [console.anthropic.com](https://console.anthropic.com) | Credit card | Claude model family |
| **OpenAI** | [platform.openai.com](https://platform.openai.com) | Credit card | GPT model family |

> Button locations may change with version updates. If you can't find something, check the platform's official docs for a step-by-step guide.

**Aggregation Platforms (Based on NewAPI / OneAPI Frameworks)**

China has several aggregation platforms. Their underlying frameworks are all NewAPI or OneAPI, so the process is similar:

1. Register → 2. Add credits → 3. Get API Key → 4. Select model in "Model List."

These platforms primarily offer OpenAI and Anthropic models, letting you switch between them on one platform. Prices are usually a bit higher than using the original platform directly.

### API Key Security Rules

An API Key is like your bank card password—**never leak it**. Once leaked, others can use your account for billing, even malicious use leading to account suspension.

Three security rules:

1. **Don't write API Keys in code.** Use environment variables or config files, and don't commit to Git repos.
2. **Don't paste API Keys in public chat windows, blog posts, or Stack Overflow.**
3. **Rotate API Keys regularly.** If your Key is accidentally leaked, revoke it immediately in the console and generate a new one.

**Practice:** Pick a platform—I recommend starting with DeepSeek; it's cheap and simple. Complete registration and get an API Key. Save the Key to a text file named `.env`, content like this:

```
DEEPSEEK_API_KEY=paste your key here
```

This file will be used next.

---

## Python Environment Setup

**Why it matters:** Python is the most straightforward language for calling APIs. Node.js or curl work too, but Python has the shortest path from zero to running code. The `openai` library provides a unified interface—almost all mainstream AI platforms are compatible. Once you learn the DeepSeek call pattern, switching to OpenRouter or Claude only requires changing two parameters.

**How to think about it:** You need three things: Python interpreter, `openai` library, your API Key.

### Install Python

I recommend using [uv](https://docs.astral.sh/uv/)—a Python toolchain manager that handles both Python installation and package management.

- **macOS / Linux:** Run `curl -LsSf https://astral.sh/uv/install.sh | sh` in terminal.
- **Windows:** Run `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"` in PowerShell.

After installing uv, run `uv python install 3.12`—it automatically downloads and installs Python 3.12. Confirm with `python3 --version`.

If you prefer not to use uv, you can install Python directly: `brew install python3` on macOS, download the installer from python.org on Windows, or use your system package manager on Linux. Same result; uv just makes ongoing management easier.

### About Terminal and Editor

If you've never opened a terminal: macOS users should try [Warp](https://www.warp.dev/) (a modern terminal, download and use), Windows users should get Windows Terminal (search in Microsoft Store). Linux users typically already have a preferred terminal, so no specific recommendation there. A terminal lets you control your computer using text commands.

You'll need a plain text editor to write code. macOS's built-in "TextEdit" doesn't work (it adds formatting). I recommend VS Code (free, download and use) or just type `nano hello_api.py` in terminal to create and edit files. When I say "create a file" or "run a command" later, you'll know what to do.

### Install openai Library

Run in terminal:

```bash
uv pip install openai python-dotenv
```

`openai` is the core library for calling APIs, `python-dotenv` is for loading `.env` files.

### Create a Virtual Environment

Before installing packages, create an isolated Python environment for this project:

```bash
uv venv --python 3.12 .venv
```

This creates a `.venv` folder in the current directory containing a clean Python environment.

**Why use a virtual environment?** Two reasons. First, the packages you install won't pollute your system Python—if something breaks, just delete `.venv` and recreate it. Second, different projects can use different package versions without conflicting. This is a fundamental Python development habit worth building from day one.

No need to manually activate the virtual environment—`uv` looks for `.venv` in the current directory. So make sure you're in your project directory first:

```bash
uv pip install openai python-dotenv
```

The same applies when running Python scripts later:

```bash
uv run python chat.py
```
### Your First Code

Create a new file `hello_api.py`, content like this:

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

# Load environment variables from .env file
load_dotenv()

# Read API Key from environment variable
api_key = os.environ.get("DEEPSEEK_API_KEY")

if not api_key:
    raise ValueError("DEEPSEEK_API_KEY environment variable not set")

# Create client
# The only difference is base_url needs to point to DeepSeek's address
# Model name: deepseek-v4-flash (deepseek-chat is the old name, still works but will be deprecated)
# The only difference is base_url needs to point to DeepSeek's address
client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"  # DeepSeek's API address
)

# Send request
response = client.chat.completions.create(
    model="deepseek-v4-flash",  # DeepSeek's model name (deepseek-chat is the old name, still works)
    messages=[
        {"role": "user", "content": "Hello, introduce yourself in one sentence."}
    ]
)

# Print AI's reply
print(response.choices[0].message.content)
```

Save the file, run in terminal:

```bash
uv run python hello_api.py
```

If everything works, you'll see the AI reply with a sentence.

**One thing worth noting:** Although we're using DeepSeek's API, the code uses OpenAI's `openai` library. This is because most modern AI platforms are compatible with OpenAI's API interface standard. Once you learn this calling pattern, switching to other platforms only requires changing `base_url` and `model` parameters.

For example, switching to OpenRouter:

```python
client = OpenAI(
    api_key=os.environ.get("OPENROUTER_API_KEY"),
    base_url="https://openrouter.ai/api/v1"
)

response = client.chat.completions.create(
    model="deepseek/deepseek-v4-flash",  # OpenRouter model format: provider/model
    messages=[...]
)
```

However, Anthropic (Claude) is an exception. It has its own API format that isn't compatible with the OpenAI standard. If you want to use Claude's API, check the Anthropic official documentation, or simply ask AI: "How do I call the Claude API with Python?"

**Practice:**

1. Run the above `hello_api.py`, make sure it outputs normally.
2. Modify the question content, like change to "Write a Python function to determine if a number is prime."
3. Try changing `max_tokens` to 500, observe output length changes.
4. (Optional) If you have an OpenRouter account, try modifying `base_url` and `model`, use OpenRouter to call DeepSeek.

---

## Billing: Token

Before diving into API parameters, you need to understand one concept—Token. It's not a parameter you pass to the API, but the billing unit AI platforms use. Without understanding tokens, you can't read your bill.

A token is the smallest unit the AI uses to process text. Think of it as roughly equivalent to a word or character—in English, one word is about 1 token; in Chinese, one character is about 1–2 tokens (Chinese encoding is more complex).

**Input and output are billed separately.** The question you send AI is input tokens, AI's reply is output tokens. For example, your question is 100 tokens, AI replies 200 tokens, this call consumes 300 tokens total.

Different platforms have different billing methods (May 2026 prices, subject to change):

| Platform / Model | Input Price (/ 1M tokens) | Output Price (/ 1M tokens) |
|-----------------|--------------------------|---------------------------|
| DeepSeek V4-Flash | $0.14 | $0.28 |
| OpenRouter | Same as official prices | Plus 5.5% platform fee |
| Claude Sonnet 4.6 | $3 | $15 |
| Claude Opus 4.8 | $5 | $25 |
| GPT-5.5 | $5 | $30 |

**How to check the latest prices:** Every platform has a pricing page—DeepSeek at [api-docs.deepseek.com/quick_start/pricing](https://api-docs.deepseek.com/quick_start/pricing), Anthropic at [docs.anthropic.com](https://docs.anthropic.com), OpenAI at [platform.openai.com](https://platform.openai.com) under Pricing. Can't find it? Just ask AI.

**How to estimate:** A simple rule of thumb—Chinese roughly 1 character = 1.5 tokens, English roughly 1 word = 1 token. If you send AI a 1000-character article, it consumes about 1500 tokens.

---

## Understanding API Parameters

**Why it matters:** API parameters directly determine output quality, cost, and speed. Building intuition for them helps you tune settings for different scenarios—when to set temperature low, when to set max_tokens high.

Here are the three most commonly used parameters: temperature, max_tokens, and model. We'll also cover a related concept—context window—which isn't a parameter you pass to the API, but directly affects how much content you can send.

**A good habit:** Parameter names and value ranges differ across platforms, and they change with version updates. Before using one, check the official docs—or just ask AI: "What's the valid range for the temperature parameter on DeepSeek's V4-Flash API?" That's faster than guessing.

### Temperature: Control Randomness

Temperature controls AI output's "creativity" level. Range is 0 to 2, but common values are 0 to 1.

| Value | Effect | Best for |
|-------|--------|----------|
| **0** | Deterministic—same question 100 times gives 100 identical answers | Code generation, data extraction |
| **0.7** (recommended) | Some randomness, but not divergent | Most scenarios |
| **1** | Very random—same question can yield very different answers | Creative writing, brainstorming |

Another way to put it: low temperature makes the AI a photocopier—same input, same output, every time. High temperature makes it an improviser.

**Practice:** Run this code twice—once with `temperature=0`, once with `temperature=1`—using the same prompt both times. Observe the difference:

```python
response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=[
        {"role": "user", "content": "Write a short story about a cat"}
    ],
    temperature=0  # Try changing to 1, run again
)
```

### Context Window

The context window is the maximum content an API can "see" at once. Different models have different context window sizes:

- DeepSeek V4: 1M tokens
- Claude Sonnet 4.6: 1M tokens
- GPT-5.5: 1M tokens

All three models have a 1M token context window. Using the 1 character ≈ 1.5 tokens estimate, that's roughly 650,000 Chinese characters.

If your input exceeds the model's context window, the API will throw an error. Even without error, input too long causes AI to "forget" early content—like people forgetting what they talked about after chatting too long.

**Practical advice:** If your input exceeds 5K tokens, consider chunked processing or using a long-context model.

### max_tokens: Control Output Length

`max_tokens` limits the maximum length of the AI's reply. Set it to 100, and the AI replies with at most 100 tokens. Set it to 1000, and the cap is 1000 tokens.

**Why does this parameter exist?** Two reasons:

1. **Control cost:** The longer the output, the higher the cost. If you only need a short answer, setting max_tokens small saves money.
2. **Avoid infinite generation:** In some scenarios, AI might keep generating forever (like you ask it to "write an infinitely long story"), max_tokens forces it to stop.

**Note:** Parameter names differ across platforms. DeepSeek and Anthropic use `max_tokens`, while OpenAI changed to `max_completion_tokens` for newer models. When in doubt, just ask AI.

---

## What's Next

Today you did two things: understood the essential difference between APIs and chat windows, and ran your first piece of code. Along the way, you learned the billing unit Token, three API parameters (temperature, max_tokens, model), and the context window concept. They directly determine your future API cost and effectiveness. This is just the beginning—your script is still single-call, processing one task per run.

Next article, we'll learn **batch processing**: how to write loops to handle 100 documents, how to design batch prompts, how to handle retry mechanisms after API call failures. That's where APIs really show their power.

---

*Week 1 wraps up here. Next week we enter batch processing—where your program handles 100 tasks automatically. (Part 2 coming soon)*