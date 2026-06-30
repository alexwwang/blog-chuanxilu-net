---
title: "Day 9: API Caching Basics and Why You Shouldn't Compare Only Unit Prices"
slug: "ai-path-l1-l2-week2-day9"
date: "2026-06-30T07:00:00+08:00"
draft: false
description: "L1→L2 Week 2 Day 9: Understand how API caching works, evaluate providers by cache hit rate and pricing, and pick a provider that fits your workload."
tags: ["AI", "toolchain", "tutorial", "API", "caching", "cost-optimization"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor: a scale balancing a price tag on one side and a cache symbol on the other, representing the trade-off between cost and efficiency"
---

> This is Day 9 of Week 2 in the "AI Path L1→L2 Upgrade Guide." You should have completed [Day 7](../ai-path-l1-l2-week2-day7/) first.

[Day 7](../ai-path-l1-l2-week2-day7/) added error handling to your script, so it's resilient now. But there's a bigger cost factor you might have missed: **the API provider you picked could cost a lot more than you think.**

DeepSeek V4-Flash charges $0.14 per million input tokens. OpenAI GPT-5.5 charges $5.00. That's a 35x difference. If you ignore **caching**, the gap widens further.

---

## What is provider prompt cache

Prompt cache is a mechanism where the API provider caches your prompt prefix on their server. When the system prompt and context repeat, there's no need to recompute the KV cache, so responses get faster and pricing drops. The provider manages the infrastructure; you don't implement it yourself.

---

## How caching works

Take OpenAI's prompt cache as an example. The core rule is prefix matching.

Your prompt consists of two parts:

```
[System prompt] ← same on every call
[User input]    ← different for each file
```

The provider builds a KV cache for the prefix of your entire prompt. That means the system prompt portion gets cached. Any subsequent request with the same system prompt hits that cache.

{{< figure src="illustration.png" alt="Prefix caching diagram: shared System Prompt feeding multiple User Inputs" class="img-medium" caption="Once the System Prompt is cached, different User Inputs reuse the same prefix. Longer prompts with a larger system prompt get bigger caching benefits" >}}

A few details worth knowing:

1. OpenAI requires the entire prompt (system prompt + user input + tools + images) to be at least 1024 tokens. Anthropic's threshold varies by model: Opus 4.8 and Sonnet 4.6 require 1,024 tokens, while Fable 5 requires only 512. DeepSeek and GLM-5.2 don't publish thresholds and use a best-effort approach.
2. OpenAI routes requests to the same machine based on a hash of the first ~256 tokens of the prompt. (Official docs note: "the exact length varies depending on the model.") Same prefix means same machine, which means a cache hit.

So if your system prompt is short (say 50 tokens) and each file's user input is also short (say 200 tokens), the total prompt is under 300 tokens. That's well below OpenAI's 1024-token threshold and Anthropic's 1024-token threshold for Opus 4.8/Sonnet 4.6 (or 512 for Fable 5). DeepSeek and GLM-5.2 don't publish thresholds, but a prompt this short has no prefix worth caching anyway.

---

## The cost impact of caching

Suppose you're batch-translating 1000 English files, each averaging 500 words (~750 tokens). Your system prompt grows to 1100 tokens to cover detailed translation rules, format requirements, and examples:

```
You are a professional translation assistant. Translate the provided English text into Chinese, strictly preserving the original format (including line breaks, indentation, HTML tags, etc.).
Translation rules:
1. Proper nouns (names, places, company names) remain in English
2. Technical terms use industry-standard translations
3. Maintain the original tone and style
4. Do not add or omit any content
5. The output should read naturally in Chinese
```

Total input: 1850 tokens, above the cache threshold for all mainstream providers.

OpenAI GPT-5.5: If the system prompt changes every call, no cache hits. All 1850 tokens at full $5.00:

1000 × 1850 × $5.00/million = **$9.25**.

If the system prompt is the same, 1100 tokens hit cache at $0.50, 750 tokens at full $5.00:

1000 × (1100 × $0.50 + 750 × $5.00) / million = **$4.30**.

That's a 54% saving from caching.

GLM-5.2 (Z.AI): Without caching, all 1850 tokens at $1.40:

1000 × 1850 × $1.40/million = **$2.59**.

With caching:

1000 × (1100 × $0.26 + 750 × $1.40) / million = **$1.34**.

That's a 48% saving.

DeepSeek V4-Pro: Without caching, all 1850 tokens at $0.435:

1000 × 1850 × $0.435/million = **$0.80**.

With caching:

1000 × (1100 × $0.003625 + 750 × $0.435) / million ≈ **$0.33**.

That's a 59% saving.

The discount magnitude varies by provider. With the same prompt and the same cache hit rate, OpenAI and Anthropic save 54%, GLM-5.2 saves 48%, DeepSeek saves 59%. DeepSeek's cache hit price is so low ($0.003625/million) that even with a smaller discount percentage, the absolute cost is the lowest.

The larger your batch and the longer your system prompt, the more caching matters.

Providers differ on thresholds, discounts, and hit rates. Caching strategy itself is worth weighing when you choose a provider.

---

## Proxy cache pricing

Provider cache policies are fixed, but you rarely connect directly to a provider. You go through a proxy or gateway, and different proxies handle caching and pricing differently.

The same provider can show different cache prices depending on the proxy. Proxy A forwards your request to OpenAI, OpenAI caches the prefix, and Proxy A bills you at the cached rate. Proxy B intercepts the request at its own layer, serves from its own cache, and sets its own pricing. That price may or may not reflect the provider's cached rate.

When you evaluate a proxy's cache pricing, look at four things:

1. Does the proxy forward cache hits to the provider, or intercept at its own layer?
2. Even with passthrough, the proxy may add a cache fee or bill at the provider's raw rate.
3. Some proxies report cache hit rates, others don't. Reporting lets you see where your money goes.
4. Proxy-level cache TTL may differ from the provider's TTL.

In practice, that means checking whether your bill distinguishes cached from non-cached tokens, whether the proxy provides hit-rate data, how long the proxy's cache lasts, and whether cache pricing is public. Opaque proxies may hide cache markups.

---

## Evaluating providers by caching

Providers take different approaches:

| Provider | Cache Method | Min Threshold | Cached Price | Hit Rate |
|----------|-------------|---------------|--------------|----------|
| OpenAI | Automatic prefix cache | 1024 tokens | 1/10 of regular | High (when system prompt is constant) |
| Anthropic | Auto or manual `cache_control` | No hard threshold | Reads 0.1x, writes 1.25x-2x | Medium-High |
| Z.AI GLM-5.2 | Automatic prefix cache | No public threshold | $0.26/million cached | High |
| DeepSeek V4-Pro | Automatic Context Caching on Disk | No public threshold | $0.003625/million cached | High |

OpenAI's cache threshold is 1024 tokens for all models. If your system prompt is short and each file's user input is also short, caching won't help.

Anthropic requires manual or top-level `cache_control` configuration. When configured correctly, cache reads cost 0.1x and writes cost 1.25x-2x.

DeepSeek V4-Pro's Context Caching on Disk is enabled by default with no public threshold. Cache hit costs just $0.003625/million tokens, so batch jobs get near-zero caching costs automatically.

Z.AI GLM-5.2's cached input price is $0.26/million tokens. Not as extreme as DeepSeek, but lower than most other domestic models.

---

## An evaluation framework

When choosing an API provider, don't look only at unit price. Work through these questions.

1. **How long is your typical request?** If system prompt + user input totals under 1024 tokens, OpenAI's cache won't help you.

2. **Does your system prompt change?** If the system prompt differs on every call (e.g., dynamically generated), prefix cache hit rate approaches zero.

3. **How large is your batch workload?** With 10 files, caching barely matters. With 1000 files, it can cut costs by half or more.

4. **Is the proxy's cache pricing transparent?** Provider cache policies are fixed, but proxies may add markup or hide cache fees. Check if your bill distinguishes cached and non-cached tokens, and whether the proxy reports hit rates.

5. **How do you use it?** OpenAI, DeepSeek, and GLM-5.2 caching needs no setup from you: the provider handles it. Anthropic supports both automatic and manual modes. Automatic mode requires adding one line of `cache_control` at the top level of your request. Manual mode lets you decide what to cache and what not to, but cache writes carry a premium (1.25x-2x write cost), and placing breakpoints in the wrong spot wastes money. If you're new to this, start with automatic mode.

---

## Today's takeaway

- [ ] Know the minimum thresholds and hit conditions for caching
- [ ] Understand how provider cache strategies affect real costs
- [ ] Apply an evaluation framework when choosing providers and proxies
- [ ] Remember that unit price is not the only cost factor

---

What matters most to you when choosing an API provider? Price, caching, or something else?

---

> This is Day 9 of Week 2 in the "AI Path L1→L2 Upgrade Guide." Previous: [Day 8 Autonomous AI](../ai-path-l1-l2-week2-day8/). [Read original](https://blog.chuanxilu.net/en/ai-path-l1-l2-week2-day9/) for the full evaluation framework.
