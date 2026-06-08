---
title: "Day 3 Exercise: API Parameter Experiments"
slug: "ai-path-l1-l2-week1-day3"
date: "2026-06-08T07:00:00+08:00"
draft: false
description: "Day 3 companion exercise for the AI Path L1→L2 Upgrade Guide: experiment with temperature and max_tokens, observe how they change AI output, and calculate actual API costs."
tags: ["AI", "toolchain", "tutorial", "API"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.jpeg"
  alt: "Watercolor illustration: a notebook with temperature parameter experiment records"
  relative: true
---

> This is the Day 3 companion exercise. Complete [Day 1](../ai-path-l1-l2-week1-day1/) first. Part 1 covers the theory ("Understanding API Parameters")—today you verify it with your own eyes.

Part 1 explained parameters in theory. But theory without practice is just noise. Today you run three experiments and **see for yourself how parameters affect output**.

---

## Setup

Make sure your Day 1 project still works:

```bash
uv run python hello_api.py
```

If the AI replies, your environment is ready. All experiments below build on this code.

---

## Experiment 1: Temperature from 0 to 1

Copy `hello_api.py` as `experiment_temp.py` and change it to:

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

question = "Write a short story about a cat (three sentences max)"

for temp in [0, 0.5, 1.0]:
    print(f"\n{'='*40}")
    print(f"temperature = {temp}")
    print('='*40)

    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[{"role": "user", "content": question}],
        temperature=temp
    )

    print(response.choices[0].message.content)
```

Run it:

```bash
uv run python experiment_temp.py
```

**What to observe**:

- `temperature=0`: Nearly identical output every time. AI picks the highest-probability word. No randomness.
- `temperature=0.5`: Some variation, but the logic remains coherent.
- `temperature=1.0`: Noticeably different each run. Word choice, style, and story direction may vary.

**Try it**: Run the same code two or three times and compare the stability of `temperature=0` vs `temperature=1.0`.

**When to use which**:
- Deterministic output (code, data extraction) → `temperature=0`
- Some variation but controlled (daily conversation, translation) → `temperature=0.5-0.7`
- Creative work (writing, brainstorming) → `temperature=0.8-1.0`

---

## Experiment 2: max_tokens Truncation

Create `experiment_tokens.py`:

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

question = "Explain what machine learning is, with three real-life examples"

for limit in [50, 200, 1000]:
    print(f"\n{'='*40}")
    print(f"max_tokens = {limit}")
    print('='*40)

    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[{"role": "user", "content": question}],
        max_tokens=limit
    )

    print(response.choices[0].message.content)
    print(f"\n(actual output tokens: {response.usage.completion_tokens})")
```

Run it:

```bash
uv run python experiment_tokens.py
```

**What to observe**:

- `max_tokens=50`: AI starts explaining but gets cut off mid-sentence.
- `max_tokens=200`: A short answer, but probably not enough room for all three examples.
- `max_tokens=1000`: Full answer with all three examples expanded.

**Note**: `max_tokens` is a ceiling, not a target. AI won't pad output to fill the limit. A 100-token answer won't grow to 1000 tokens just because you raised the ceiling.

---

## Experiment 3: Calculate Your Actual Cost

Add this to the end of experiment 2:

```python
    # Cost estimate for the last request
    usage = response.usage
    input_tokens = usage.prompt_tokens
    output_tokens = usage.completion_tokens

    # DeepSeek V4-Flash pricing (May 2026, subject to change)
    input_price = 0.14 / 1_000_000   # $/token
    output_price = 0.28 / 1_000_000

    cost = (input_tokens * input_price) + (output_tokens * output_price)
    print(f"\nRequest cost: ${cost:.6f} (approx ¥{cost * 7.2:.4f})")
    print(f"  Input: {input_tokens} tokens, Output: {output_tokens} tokens")
```

**Build Your Intuition**

- A simple Q&A (100 input + 200 output tokens) costs about $0.00008 (roughly ¥0.0006)
- $1.50 (roughly ¥10) can fund roughly 15,000–20,000 such requests
- Long texts are where costs add up: summarizing a 5,000-character article may consume 7,500 input tokens

---

## What You Did Today

- [ ] Ran the temperature experiment and saw the difference between 0 and 1.0
- [ ] Ran the max_tokens experiment and saw truncation in action
- [ ] Calculated the actual cost of one API request

**Tip**: Not sure how to tune parameters? Describe the output you want in plain language and ask AI: "I want more stable/creative/shorter output, what should I set temperature and max_tokens to?"

**Next up**: Day 4 is Part 2 of the main tutorial—moving from single calls to batch processing. You'll learn to have the API process 100 files automatically.
