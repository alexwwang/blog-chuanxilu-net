---
title: "Day 1 Exercise: Run Your First API Code"
slug: "ai-path-l1-l2-week1-day1"
date: "2026-06-02T07:00:00+08:00"
draft: false
description: "Day 1 companion exercise for the AI Path L1→L2 Upgrade Guide: run the hello_api.py from Part 1, see AI reply in your terminal, with a troubleshooting guide for common errors."
tags: ["AI", "toolchain", "tutorial", "API", "DeepSeek"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.jpeg"
  alt: "Watercolor: laptop terminal glowing with a golden line of AI response, notebook with token beads, tea cup, and sticky note with checkmark on desk"
---

> This is the Day 1 companion exercise for the AI Path L1→L2 Upgrade Guide. Read [Part 1](../ai-path-l1-l2-week1/) first, then come back here to practice.

Today we do exactly one thing: **run the `hello_api.py` from Part 1 and see AI reply in your terminal.**

---

## Prerequisites

Complete these steps from Part 1 (skip if already done):

- [ ] Register a DeepSeek developer account (Part 1, "Register for API Accounts")
- [ ] Get your API Key and save it to a `.env` file (Part 1, "API Key Safety")
- [ ] Install uv and Python 3.12 (Part 1, "Install Python")
- [ ] Create a virtual environment and install dependencies (Part 1, "Create a Virtual Environment")

Confirm your project directory looks like this:

```
your-project/
├── .env                  # DEEPSEEK_API_KEY=sk-xxx
└── .venv/                # uv-managed virtual environment
```

Ready? Let's go.

---

## "Write" Your Code

Create `hello_api.py` in your project directory and paste this in:

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

# Load .env file
load_dotenv()

# Read API Key
api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

# Create client
client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

# Send request
response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=[
        {"role": "user", "content": "Hello, introduce yourself in one sentence."}
    ]
)

# Print response
print(response.choices[0].message.content)
```

Run it:

```bash
uv run python hello_api.py
```

AI replied with a sentence? You're done. Now try this: **change the question to anything you want and run it again.** For example, `"Write a Python number-guessing game"` or `"Explain what an API is."`

---

## Troubleshooting

**"DEEPSEEK_API_KEY not set"**
- Is `.env` in the same directory as `hello_api.py`? Move it there if not.
- Is the Key complete? It should start with `sk-`, no extra spaces.
- Is the filename exactly `.env`? Check for leading spaces or hidden extensions.

**"Connection refused" or network errors**
- Is your network working? Can you open `platform.deepseek.com` in a browser?
- Is `base_url` correct: `https://api.deepseek.com` (note: `https`, no `/v1` at the end)?

**"Insufficient balance"**
- New accounts get a small free credit. Once it runs out, top up in the console.
- A few dollars (or 10 RMB) lasts a long time for practice.

**"Model not found"**
- Double-check the model name: `deepseek-v4-flash`. The old name `deepseek-chat` still works but the new name is recommended.

**"Authentication failed" / "Invalid API key"**
- Key might be incomplete or have trailing spaces.
- Create a new Key in the console and replace the value in `.env`.

---

## What You Did Today

- [ ] Ran your first API code
- [ ] Saw AI reply in your terminal
- [ ] Changed the question and ran it again

**Next up**: Day 2 switches to a different platform (an aggregator). Same code, change two parameters, different AI service. You'll see how portable your skills are.

---

*Stuck on an error? Share the error message and your `.env` file structure (never the Key itself) in the reader group.*
