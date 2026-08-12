---
title: "Benchmarking OpenCode's Free Tier: 450-766 Requests/Day, Not the Rumored 200"
slug: "opencode-zen-go-misconceptions"
date: 2026-08-10T16:00:00+08:00
draft: false
description: "Online rumors about OpenCode's free models and subscriptions, checked against real data: how one API key splits Zen from Go, the measured limits of the free tier, whether OpenCode's ds4f is a downgrade, and how the Go subscription quota is calculated."
tags: ["AI", "opencode", "zen", "go", "deepseek"]
categories: ["opencode"]
toc: true
cover:
  image: cover.png
  alt: "Watercolor painting of a brass key before two arched doors, representing the Zen and Go services"
---

If you build with, or are thinking of using, OpenCode.ai (oc, for short) for development or agent work, you've probably felt this anxiety: worried the models won't match the official ones, worried the free tier will hit its limit every day, or puzzled over how the Go subscription quota is even calculated, especially when users claim they "burned through half a month's quota in 5 minutes," an assertion that sounds dubious.

Then DeepSeek V4 Flash (ds4f, for short) went stable, and my token anxiety evaporated. I analyzed over 3,000 API call logs from my local machine across three months of active usage and cross-checked them against the numbers online. Here's the truth behind these five misconceptions. Once you get these straight, your workflow runs steadier, and you stop worrying about burning through your token quota.

## Myth 1: Zen and Go Are Identical Because They Share One Key

OpenCode runs two model services: Zen and Go.

They share the same entry point and admin panel. The API key creation page makes no distinction. The same key can call both services [1][2]. As a result, users frequently assume that Go is simply Zen's subscription tier, and that Zen's free models apply to Go as well.

They're not. The difference is the base URL, not the key:

- Zen: `https://opencode.ai/zen/v1`
- Go: `https://opencode.ai/zen/go/v1`

One `/go` in the URL. Entirely different billing.

| | Zen | Go |
|---|---|---|
| base URL | `https://opencode.ai/zen/v1` | `https://opencode.ai/zen/go/v1` |
| Model ID | `opencode/<model>` | `opencode-go/<model>` |
| Billing | Pay-as-you-go + limited-time free tier | Subscription quota |

Zen is a pay-as-you-go gateway: top up a balance, pay per token. Free models with the `-free` suffix (like `deepseek-v4-flash-free`) live here [1]. Go is a subscription: $5 for the first month, $10/month after that, quota denominated in dollars [2].

The base URL you configure determines which billing model applies. Side by side, the difference is obvious.

## Myth 2: The Free Tier Is Enough, So Skip the Go Subscription

The free tier is genuinely free. It is also a limited-time trial tier, not a permanent service offering.

**The time limit.** The docs say free models are "available for a limited time", to collect feedback and improve the models [1]. The free list itself changes: in June it was Nemotron 3 Super, MiniMax M2.5, Qwen3.6 Plus. By August the official list had rotated to a different set [3][1].

**The capability limits.** Two hard boundaries: a 200K context window [4], and no vision (code/text modalities only) [4].

**The usage limits.** The claim online is "about 200 requests a day" [5]. I pulled my own call logs to check. Between July 27 and August 7, 2026, I recorded 3,606 call failures triggered by rate limits. The measured boundaries:

![Free-tier limit: a measuring cup and an hourglass](illustration-2.png)

- The quota resets at **UTC 0:00** (08:00 Beijing). All three rate-limit hits came with a retry-after pointing exactly at the next UTC midnight, and the first successful call after each reset came after it.
- Call volume fluctuates with token consumption and how much inference capacity the platform has that day. Measured: about **450 to 766 requests/day** (mean 605), or **49-72M tok/day**. On average, each request processed roughly 94.5K cached input tokens, 6.5K uncached input tokens, and 0.8K output tokens. Overall cache hit rate: 93.6%. Median hit rate per request: 99.6%. Most requests hit cache almost entirely; a few new-context requests drag the average down.
- One of the three limit hits was rate-triggered: 450+ calls in three hours late at night (about 250 in the last hour), before the daily total had hit the cap. So there's a request-frequency boundary on top of the daily total. Batch jobs hammering the API in quick succession hit it before the cumulative usage does. The other two hits (7/28 and 8/5) were cumulative-cap triggers.

> Data source: local `~/.omp/stats.db`, `opencode-zen` provider, 2026-07-27 to 08-07.

"200 a day" undersells the free tier. I had days at 544 and 665 requests with no limit triggered. But "use it freely" is also false: a batch run at 250 requests per hour hits the wall.

So the free tier can't replace the subscription. For trials and light use, it's fine. For high-volume agent batch jobs, extended context windows, and operational stability, opting for the Go subscription becomes essential. The Go ds4f gets a 1M context window (matching the official native spec [6]); the free tier gets a fifth of that.

## Myth 3: OpenCode's ds4f Is a Downgraded Version

The rumor: OpenCode's ds4f has a cut context window, an old version, worse quality.

The reality: Both services run the exact same model and version.

DeepSeek V4 Flash's official API updated to the 0731 version on 2026-07-31, featuring a retrained setup, the same architecture (284B total / 13B active MoE parameters), a native 1M context window, and support for up to 384K output tokens per request [6]. OpenCode's ds4f connects directly to DeepSeek's official service (community corroboration [7]), priced internally at $0.14 / $0.28 per 1M token [2], matching the official RMB price of roughly ¥1 / ¥2 [6].

There is one real detail that *looks* like a downgrade: the 0731 version is deployed in China only. You have to explicitly enable "models deployed in China" in the Go console, or you get a 403 RegionError [7]. That's a deployment-location choice, not a watered-down model.

The watered-down part is the free tier: 200K context, daily limits, no vision. But that's Zen's free tier, not the Go subscription's ds4f.

## Myth 4: ds4f Can't See Images, So OpenCode Can't Handle Them

ds4f natively lacks vision and multimodal capabilities: the official Responses API rejects image and file inputs [6], and the free tier's modalities are code/text [4]. That's a model capability boundary.

But handling images doesn't require switching tools. It requires switching models. Different apps route differently:

### Option A: Manual Model Switching in OpenCode

Type `/model` in the TUI to switch to a multimodal model. Free tier: `opencode/mimo-v2.5-free`. Subscription: `opencode-go/mimo-v2.5`. Text and code go to ds4f (cheap, high volume); image tasks switch to a multimodal model.

### Option B: Automated Vision-Agent Routing in OMP

In OMP, configure a **vision agent**: image-reading tasks route automatically to a multimodal model. No manual switching.

Best practice:

- **Main model**: `opencode-go/deepseek-v4-flash` (text/code, cheap and high-volume)
- **Vision agent**: prefer Zen's `opencode/mimo-v2.5-free` (free multimodal, endpoint `https://opencode.ai/zen/v1/chat/completions`), fall back to Go's `opencode-go/mimo-v2.5` (endpoint `https://opencode.ai/zen/go/v1/chat/completions`) when the free quota runs out or fails

Daily image reading barely touches the Go subscription this way. The subscription is only tapped when the free tier is exhausted or fails.

![Route by task: two terminals splitting traffic](illustration-1.png)

The core idea in both: **route by task**. Text and code go to ds4f; images go to a multimodal model. OpenCode does it manually, OMP does it automatically.

## Myth 5: Go Subscription = a Fixed Number of Requests Per Month

"How many requests per month does the Go subscription allow?" is the most common question, and the most wrongly framed one.

The quota is not a request count. It's dollars: $5 first month, $10/month after, buying a rolling quota of $12 per 5 hours, $30 per week, $60 per month [2]. Why $60? The official explanation: $10 buys you 6x equivalent usage, funded by bulk discounts and reserved GPUs. Models whose discounts couldn't be negotiated get a lower multiplier [2].

Which models have lower multipliers? The **$15 tier** (monthly quota cut from $60 to $15, a 1.5x multiplier instead of 6x): Grok 4.5, GPT 5.6 Luna, Kimi K3, MiMo-V2.5-Pro, DeepSeek V4 Pro, Qwen3.8 Max.

The reason: OpenCode couldn't get bulk discounts on these, or the public pricing is already so low there's no room to discount [2]. Calling them drains your monthly quota faster. For the same $10 allocation, ds4f can process approximately 158,000 requests, whereas GLM-5.2 yields only around 4,300.

`Requests = Dollar Quota / Model Price / Tokens per Request`. The official estimate table [2]:

| Model | Estimated requests/month |
|---|---|
| DeepSeek V4 Flash | ~158,150 |
| MiMo-V2.5 | ~150,400 |
| Qwen3.7 Plus | ~21,600 |
| Hy3 | ~21,500 |
| DeepSeek V4 Pro | ~17,150 |
| Qwen3.6 Plus | ~16,300 |
| MiniMax M3 | ~16,000 |
| GPT 5.6 Luna | ~10,250 |
| Kimi K2.7 Code | ~6,750 |
| GLM-5.2 | ~4,300 |
| Grok 4.5 | ~600 |
| Kimi K3 | ~490 |

> Excerpt of the official estimate table; the full list is at [opencode.ai/docs/go](https://opencode.ai/docs/go/) [2]. Estimates assume typical usage (ds4f: ~790 input + 68,000 cached + 280 output tok per request). My own Go ds4f usage in the same period: 2,151 calls, billed $2.57. My per-request volume runs higher than the typical assumption, and even so the monthly quota clearly isn't exhausted.

Over quota, two options. Default: **rate limiting** (requests get blocked with 429). Or enable **Use balance** in the console: over-quota traffic continues on your Zen balance automatically, no interruption [2].

## The Most Cost-Effective Setup: Combine All Three

Go's subscription value is **more requests for less money**.

> **Key premise**: all models share a single unified subscription quota ($60/month). ds4f, MiMo, and GLM all draw from the same pool. They don't each get their own quota.

Sorted by estimated monthly request volume, high to low:

| Model | Est. requests/month | Price (per 1M tok) | Where it fits |
|---|---|---|---|
| **ds4f (DeepSeek V4 Flash)** | ~158K | $0.14 / $0.28 | **Primary pick**: highest volume, use it for all daily coding |
| **MiMo-V2.5** | ~150K | $0.14 / $0.28 | **Same tier**: nearly as many requests, handles image tasks too |
| MiniMax M3/M2.7, Qwen3.6/3.7 Plus, Hy3, etc. | 16/21K | $0.30-0.50 | Fewer than ds4f; use for specific scenarios |
| Kimi K2.6/K2.7 Code, GPT 5.6 Luna, etc. | 5,750/6,750/10,250 | $0.95 | Medium volume; specific scenarios |
| **GLM-5.2/5.1** | ~4,300 | $1.40 / $4.40 | **Expensive per token**; noticeably fewer requests |
| Grok 4.5, Kimi K3, etc. | 600/490 | $2.00-3.00 | **Smallest tier** ($15/month quota); only when necessary |

> Estimates assume typical usage (ds4f: ~790 input + 68,000 cached + 280 output tok per request). Your actual count depends on your per-request token size. The $60 monthly quota is shared by all models.

### Best Practice: Three Tiers, Not a Choice of One

| Scenario | Recommended setup | Why |
|---|---|---|
| Daily coding, text generation | **Go subscription ds4f** | 1M context, ~158K requests/month, cheapest |
| Image understanding | **Zen free MiMo-V2.5 Free** → fallback to Go MiMo-V2.5 | Free multimodal first, no Go quota spent |
| Batch jobs | **Go subscription ds4f** | High volume; mind the ~250 req/hour rate limit |
| Production / compliance | **Official API** | Independent balance, zero retention, doesn't touch Go quota |
| Evaluating new needs | **Zen free tier first** → then Go | Zero-cost experimentation |

### The One-Sentence Strategy

**Deploy the Go subscription's ds4f as your primary workhorse, rely on the Zen free tier for image processing fallbacks, and route production workloads directly to official APIs.** The three tiers combine. You don't have to pick one.

Measured and verified 2026-08-09. The free model list, quotas, and model versions are moving fast. Check the official docs before you commit.

> Thinking about a Go subscription? Sign up through my referral link and you get an extra $5 of quota (I get $5 too — official program): <https://opencode.ai/go?ref=CGNQ69YARZ>

---

## References

1. Zen official docs: <https://opencode.ai/docs/zen/>
2. Go official docs: <https://opencode.ai/docs/go/>
3. WatermelonWater: OpenCode Zen free model deep review and CC Switch integration guide (2026-06-06): <https://watermelonwater.tech/insights/opencodezen免费模型评测/>
4. This site: OpenCode cold start: DeepSeek V4 Flash free in five minutes (2026-07-06): <https://blog.chuanxilu.net/en/posts/2026/07/ai-path-opencode-zen-setup/>; AY Automate: DeepSeek V4 Flash Free specs: <https://www.ayautomate.com/free-models/opencode-zen-deepseek-v4-flash-free>
5. Zhihu (Chinese): Sharing ways to use DeepSeek-V4-Flash for free ("about 200 requests a day"): <https://zhuanlan.zhihu.com/p/2066641347087069>
6. 51AllAI: DeepSeek-V4-Flash official release API goes live, natively integrated with Codex (2026-07-31): <https://51allai.com/posts/2026/07/deepseek-v4-flash-0731-codex/>
7. V2EX: Is the opencode go subscription's deepseek v4 flash limited? (2026-07-31): <https://www.v2ex.com/t/1231306>
