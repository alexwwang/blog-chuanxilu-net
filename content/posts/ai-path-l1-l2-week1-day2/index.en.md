---
title: "Day 2 Exercise: Run the Same Request on an Aggregator Platform"
slug: "ai-path-l1-l2-week1-day2"
date: "2026-06-06T07:00:00+08:00"
draft: false
description: "Day 2 companion exercise for the AI Path L1→L2 Upgrade Guide: register on an aggregator platform, change two parameters, and see how the same code works across platforms."
tags: ["AI", "toolchain", "tutorial", "API"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.jpeg"
  alt: "Watercolor: laptop with two side-by-side terminals glowing amber and teal, notebook with token beads, tea cup, and two checkmark sticky notes"
---

> This is the Day 2 companion exercise. Complete [Day 1](../ai-path-l1-l2-week1-day1/) first.

Yesterday you ran your first API call through DeepSeek's official API. Today we do one thing: **switch to a different platform, change two parameters in the same code, and run it again.**

You'll see that learning one platform's API means you've learned them all—as long as they're compatible with the OpenAI interface.

---

## What Is an Aggregator Platform

An aggregator platform is a middle layer. You register one account, top up once, and get access to dozens of AI models (OpenAI, Anthropic, Google, etc.) without signing up at each official platform separately.

Under the hood, most aggregators run on NewAPI or OneAPI frameworks, so the workflow is nearly identical across platforms:

1. Register an account
2. Top up your balance
3. Get your API Key
4. Pick a model from the model list

**Pros**: One key for many models, no need to register at each official platform separately, supports local payment methods.

**Cons**: Slightly more expensive than official APIs (platform service fee on top), stability depends on the aggregator.

---

## "Write" Your Code

No need to start from scratch. Copy yesterday's `hello_api.py` as `hello_aggregator.py` and change exactly two things:

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

# Change 1: Use the aggregator's key
api_key = os.environ.get("AGGREGATOR_API_KEY")
if not api_key:
    raise ValueError("AGGREGATOR_API_KEY not set. Check your .env file.")

# Change 2: Use the aggregator's API endpoint
client = OpenAI(
    api_key=api_key,
    base_url="https://your-aggregator-url/v1"
)

# Everything else stays the same
response = client.chat.completions.create(
    model="deepseek-v4-flash",       # Model name may differ on aggregator—check their docs
    messages=[
        {"role": "user", "content": "Hello, introduce yourself in one sentence."}
    ]
)

print(response.choices[0].message.content)
```

**Only two changes**: `api_key` and `base_url`. The logic is identical.

Add the aggregator key to your `.env` file:

```
DEEPSEEK_API_KEY=sk-xxx
AGGREGATOR_API_KEY=sk-your-aggregator-key
```

Run it:

```bash
uv run python hello_aggregator.py
```

AI replied? **Same code, two parameters changed, different platform.** That's the benefit of OpenAI-compatible interfaces.

---

## Things to Watch Out For

**Model names may differ**

The model name on an aggregator might not be `deepseek-v4-flash`. Some use `deepseek/deepseek-v4-flash` (with a provider prefix), others use different formats. Check the aggregator's model list or pricing page for the correct name.

**base_url trailing slash**

Aggregators usually need a `/v1` suffix, e.g. `https://example.com/v1`. Official APIs (like DeepSeek) usually don't need it. When in doubt, check the aggregator's documentation for the correct API endpoint format.

**When in doubt, ask AI**

In L0→L1 you learned how to chat with AI—now put that to use. Not sure about something? Ask in a chat window: "How do I set the base_url for [platform name] using the Python openai library?" or "What's the model name for deepseek-v4-flash on this platform?" It's faster than digging through docs yourself.

---

## Comparison: Aggregator vs Official API

| | Official API (e.g. DeepSeek) | Aggregator Platform |
|---|---|---|
| Registration | Separate account per platform | One account, many models |
| Payment | Top up at each platform separately | Top up once, pay per model |
| Pricing | Official rate | Discounted rate (typically cheaper than official) |
| Model selection | Only their own models | Dozens of models to switch between |
| Stability | Depends on the provider | Depends on both aggregator and provider |
| Best for | Long-term use of a specific model | Trying out multiple models without separate signups |

**Recommendation**: Use an aggregator during the learning phase to try different models, then switch to the official API for your primary model to save on costs.

---

## Troubleshooting

**"Model not found"**
- Model names differ from official APIs—check the aggregator's documentation

**"Invalid API key"**
- Make sure you're using the aggregator's key, not DeepSeek's

**"Insufficient balance"**
- Top up your aggregator account and retry

**"Connection refused"**
- Check `base_url`: make sure it has `/v1` suffix (aggregators usually need it)
- Double-check the domain spelling

---

## What You Did Today

- [ ] Registered on an aggregator platform and got an API Key
- [ ] Changed two parameters in yesterday's code and ran it on the aggregator
- [ ] Understood the difference between aggregator and official APIs

**Next up**: Day 3 is all about parameters—turn `temperature` from 0 to 1 and see how the AI's responses change.
