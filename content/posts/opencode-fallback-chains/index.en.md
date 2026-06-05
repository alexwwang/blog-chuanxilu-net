---
title: "omo vs oms: Fallback Chains Deep Dive"
slug: "opencode-fallback-chains"
date: 2026-06-07T11:00:00+08:00
draft: false
description: "oh-my-openagent (omo) and oh-my-opencode-slim (oms) have different fallback mechanisms: omo uses a 5-layer pipeline, oms uses startup selection + runtime abort retry. Source-code deep dive."
tags: ["AI", "opencode", "agent", "fallback", "oh-my-openagent"]
categories: ["AI Practice"]
toc: true
series: ["opencode-triple-config"]
---

> This is Part 2 of [When Your AI Coding Tool Needs Three Configs](/posts/opencode-triple-config-switch/). Part 1 covered the config design, file structure, and orchestration philosophy. This article focuses on fallback mechanisms.
>
> omo = oh-my-openagent, oms = oh-my-opencode-slim. Model and provider names are anonymized as `provider-a/model-x` etc.

## Why Bother Understanding Fallback

omo and oms both support fallback—automatic switching to backup when the primary model is unavailable. But their mechanisms differ completely: omo is a multi-layer pipeline that degrades step by step; oms uses startup model selection + runtime abort retry. You need to understand this difference to configure a reliable chain.

My own trigger: my primary provider has a quota limit every 5 hours. When the quota runs out, it returns 429. Without fallback, I get an error as soon as quota is exhausted—the whole session gets interrupted. With fallback + runtime_fallback, the system automatically switches to a backup provider when the quota is exhausted and continues working. Seamless.

## omo's Fallback Architecture

omo's model resolution is a **5-layer pipeline**, in priority order from highest to lowest:

1. **Override**: Model explicitly selected by the user via UI, returned directly, skipping all subsequent layers
2. **Category Default**: Default model configured for agent category, with fuzzy matching (`model-alpha` can match `provider-e/model-alpha`)
3. **User Fallback Models**: `fallback_models` written by the user in config, tried one by one until an available model is found
4. **Hardcoded Chain**: omo's built-in per-agent and per-category hardcoded chain (9 agents + 9 categories, ~65 entries total), cross-provider matching
5. **System Default**: Final safety net when all layers fail (`opencode/gpt-5-nano`)

Key point: Your `fallback_models` doesn't replace the hardcoded chain—it **takes priority over** it. When your chain is exhausted, the hardcoded chain still provides a backup.

`fallback_models` supports four formats:

```jsonc
// Format 1: single model
"fallback_models": "provider-e/model-s"

// Format 2: ordered list
"fallback_models": ["provider-e/model-s", "provider-f/model-g"]

// Format 3: object array (with parameters)
"fallback_models": [
  { "model": "provider-f/model-g", "variant": "high", "temperature": 0.7 }
]

// Format 4: mixed (string + object)
"fallback_models": [
  "provider-e/model-s",
  { "model": "provider-f/model-g", "variant": "high", "thinking": { "type": "enabled", "budgetTokens": 5000 } }
]
```

Object format supports fields: `model` (required), `variant`, `reasoningEffort` (none/minimal/low/medium/high/xhigh/max), `temperature`, `top_p`, `maxTokens`, `thinking` (type + budgetTokens). This means fallback isn't just switching models—it can switch reasoning modes too. Use high reasoning on the primary, medium reasoning on the backup to save tokens.

omo also has runtime fallback (`runtime_fallback`): when HTTP errors like 429, 500, 502, 503, 504 occur mid-session, or rate-limit/quota-exceeded error patterns, it automatically switches to the next model in the chain without restarting the session. Default parameters:

```jsonc
"runtime_fallback": {
  "enabled": false,                    // Off by default, must explicitly enable
  "retry_on_errors": [429, 500, 502, 503, 504],
  "max_fallback_attempts": 3,          // Max 3 switches per session
  "cooldown_seconds": 60,              // Don't retry same model within 60s
  "timeout_seconds": 30,               // Timeout threshold for provider unresponsiveness
  "notify_on_fallback": true           // Pop up notification when switching
}
```

omo also has **fuzzy matching** capability: model names are normalized (lowercase, version separators unified), then substring matching is applied. `model-alpha` can match `provider-e/model-alpha`, even variants from different providers can map to each other.

## omo Fallback Patterns & Scenarios

**Pattern 1: Zero config—purely relying on hardcoded chain**

Set only primary model, don't write `fallback_models`, don't enable `runtime_fallback`. The hardcoded chain covers 9 agents and 9 categories, each chain has 4-8 entries, spanning multiple mainstream providers.

Use case: Just getting started with omo, not familiar with config yet. Or using default providers—the hardcoded chain is designed for them. The benefit is zero maintenance: when a provider goes down, omo finds a replacement model on its own. The cost is lack of precision—the hardcoded chain doesn't know which provider accounts you have, so it might waste time on expired providers.

**Pattern 2: Minimal coverage—1-2 backups**

Add 1-2 backup models you actually have available on top of the hardcoded chain:

```jsonc
"fallback_models": ["provider-a/model-x", "provider-c/model-x"]
```

Use case: Daily development. The hardcoded chain's primary providers occasionally flake, so add two of your own providers as quick backups. Your chain has higher priority than the hardcoded chain, so it tries the models you configured first, only falls back to the hardcoded chain after failure.

**Pattern 3: Fine-grained control—mixed format + runtime_fallback**

Use object format to configure different parameters for different backups, and enable runtime degradation:

```jsonc
"fallback_models": [
  "provider-e/model-s",
  { "model": "provider-f/model-g", "variant": "medium", "reasoningEffort": "low" },
  { "model": "provider-a/model-x", "temperature": 0.3 }
],
"runtime_fallback": { "enabled": true, "max_fallback_attempts": 5 }
```

Use case: Long coding sessions (e.g., Sisyphus orchestration tasks in omo mode lasting tens of minutes). runtime_fallback guarantees the session won't be interrupted by a single API failure mid-session. Mixed format allows high reasoning on primary, auto-switch to low reasoning on degradation to save tokens—when the strong model goes down, the whole session isn't scrapped; a weaker model can still continue.

**Pattern 4: Single model retry—special usage of runtime_fallback**

Enable `runtime_fallback` without writing `fallback_models`. Effect: the same model is retried within the session (retry after the cooldown period), no model switching.

Use case: Provider rate-limits but doesn't limit quota. 429 errors, wait a few seconds and retry, no need to switch models.

## oms Fallback Architecture

oms's fallback is a **2-layer architecture**:

1. **Startup selection**: In the `config()` hook, the system takes the first model from the chain as primary. This step doesn't check if the provider is online—it just takes the first one, uses it if it works, otherwise waits for runtime to switch
2. **Runtime failure switching**: `ForegroundFallbackManager` listens to OpenCode events (`message.updated`, `session.error`, `session.status`), detects rate-limit errors then aborts the current session and re-prompts with the next model in the chain

```jsonc
"fallback": {
  "enabled": true,
  "chains": {
    "orchestrator": ["provider-a/model-x", "provider-c/model-x", "provider-c/model-d"],
    "explorer": ["provider-a/model-z", "provider-c/model-z", "provider-b/model-y"]
  },
  "retryDelayMs": 500,       // How long to wait after abort before re-prompting (default 500ms)
  "retry_on_empty": true,    // Empty response (0 tokens) also triggers retry (default true)
  "timeoutMs": 15000         // Single call timeout (default 15s)
}
```

oms has no hardcoded chain—users must configure everything themselves. Chains are usually longer than omo's (3-5 backups vs omo's 1-2), because omo has hardcoded fallback, oms relies entirely on user chains.

oms has several features omo doesn't have:

**Strict agent isolation**: Each agent only uses its own chain. If explorer isn't configured with a chain, it absolutely won't get the orchestrator's strong model. Each session maintains a tried-set, recording models already tried, so it won't retry the same model in a loop. When the chain is exhausted, the session stays in a failed state and won't secretly degrade.

**Empty response retry** (`retry_on_empty`): When a model returns empty content with 0 tokens, oms treats it as failure. This is particularly useful for council review scenarios—weak models occasionally generate empty responses, auto-retry is less hassle than manual resend.

**Inline priority chain** (Model Array syntax): Besides `fallback.chains`, oms supports writing model arrays directly in agent config:

```jsonc
"agents": {
  "orchestrator": {
    "model": [
      { "id": "provider-a/model-x", "variant": "high" },
      { "id": "provider-c/model-x" },
      { "id": "provider-c/model-d" }
    ]
  }
}
```

Model Array and `fallback.chains` are merged (Array first, chains appended, deduplicated). This means you can put your main preferences in agent config (with variant), and put the safety net list in chains.

**Preset linkage**: oms has a preset system (switch at runtime via `/preset` command). When switching preset, the `config()` hook re-executes, chains rebuild. `ForegroundFallbackManager` retains session state (tried-set isn't lost), but chain content updates. This is useful in "use expensive models by day, switch to cheap models by night" scenarios.

## oms Fallback Patterns & Scenarios

**Pattern 1: Basic chain—3 backups per agent**

```jsonc
"chains": {
  "orchestrator": ["provider-a/model-x", "provider-c/model-x", "provider-c/model-d"],
  "explorer": ["provider-a/model-z", "provider-c/model-z", "provider-b/model-y"],
  "oracle": ["provider-a/model-x", "provider-c/model-x", "provider-b/model-y"]
}
```

Use case: Standard usage. Each agent has 3 backups, cross-provider (provider-a is primary, provider-c is backup, different models from provider-b/provider-c are the safety net). Models in the chain are tried in order, stopping when the first available model is found.

**Pattern 2: Inline priority chain—agent-level fine-grained control**

```jsonc
"agents": {
  "oracle": {
    "model": [
      { "id": "provider-a/model-x", "variant": "high" },
      { "id": "provider-c/model-x" }
    ]
  }
},
"fallback": {
  "chains": {
    "oracle": ["provider-c/model-d"]
  }
}
```

Use case: Some agents need special parameters. oracle uses high reasoning mode (variant: high), doesn't need variant when degrading. After merging inline chain and fallback.chains, oracle's effective chain is `[model-x/high, provider-c/model-x, model-d]`.

**Pattern 3: Partial agents without chain—strict isolation**

Only configure chains for orchestrator and oracle, don't configure for high-frequency agents like explorer/librarian. When these agents' primary models go down, they error directly, won't degrade.

Use case: Control costs. Explorer and librarian have high call frequency (tens of times per session), weak model (model-z) is enough. If weak model goes down, erroring is better than secretly switching to an expensive model (model-x)—the latter can consume tens of times more tokens in a single session. Strict isolation guarantees this leakage won't happen.

**Pattern 4: retry_on_empty + timeout tuning**

```jsonc
"fallback": {
  "enabled": true,
  "retry_on_empty": true,
  "timeoutMs": 30000,
  "chains": { ... }
}
```

Use case: Using unstable providers (e.g., domestic providers during peak hours). `retry_on_empty` handles occasional empty content from models; `timeoutMs` tuned to 30s gives slow providers some room. The trade-off is waiting 30s extra per timeout before switching—if 5 models in the chain all timeout, the worst case is 150s of waiting.

## Comparison

| Feature | omo | oms |
|---------|-----|-----|
| Resolution layers | 5-layer pipeline (override → category → user → hardcoded → system) | 2 layers (startup select + runtime switch) |
| Built-in hardcoded chain | Yes (9 agents + 9 categories, ~65 entries) | No |
| User chain length | Usually 1-2 (hardcoded fallback) | Usually 3-5 (fully self-configured) |
| Config format | string / string[] / object[] / mixed[] (with variant, thinking) | string[] (chains) + object[] (inline) |
| Runtime switching | `runtime_fallback` (configurable cooldown, max attempts, timeout) | `ForegroundFallbackManager` (event-driven) |
| Empty response retry | Not supported | Supported (`retry_on_empty`) |
| Agent isolation | No strict isolation (may degrade across agents) | Strict isolation (no chain = no degradation) |
| Fuzzy matching | Yes (name normalization + substring matching) | No (exact matching) |
| Safety net model | `opencode/gpt-5-nano` | None (stop when chain exhausted) |
| Preset linkage | No | Yes (chains rebuild with preset) |

## Configuration Best Practices

**omo's principle: configure less, rely on the safety net**

omo has two layers of safety net—hardcoded chain and system default. Your config is optional, not required.

1. **Don't exceed 3 models in chain**. After your chain, there's still the hardcoded chain. Configuring too many just adds meaningless attempts. One primary and one backup is enough, at most add a third as an extreme-case fallback.
2. **Must enable `runtime_fallback`**. omo sessions usually last tens of minutes (Sisyphus orchestration). If not enabled, a single 429 interrupts the whole task. I suggest setting `max_fallback_attempts` to 5, and keeping `cooldown_seconds` at 60.
3. **Cross providers, don't stack same provider**. Three models from the same provider stacked together—when that provider goes down, all are down. At least cross two providers.
4. **Don't put specialized models in fallback chain**. Like deep analysis models that go through `oracle-ds4f`/`oracle-ds4p` independent retry logic—putting them in fallback chain interferes with automatic degradation.
5. **Use mixed format to degrade and save tokens**. Primary model `variant: "high"`, backup `variant: "medium"` or `reasoningEffort: "low"`. When strong model goes down, session isn't scrapped—weaker reasoning is better than no reasoning.

**omo real-world config example**

Using my own omo config as an example. My primary provider has quota limits (resets every 5 hours), returns 429 when exhausted. Fallback chain design philosophy:

```jsonc
{
  // runtime_fallback is key—if disabled, 429 errors directly; if enabled, auto-switch to backup provider
  "runtime_fallback": {
    "enabled": true,
    "retry_on_errors": [429, 500, 502, 503, 504],
    "max_fallback_attempts": 5,    // Quota limits may last hours, give more chances
    "cooldown_seconds": 60,        // Don't retry same model within 60s
    "timeout_seconds": 30,
    "notify_on_fallback": true     // Popup notification when switching, know when using backup
  },
  "agents": {
    "sisyphus": {
      "model": "provider-a/model-x",
      "variant": "high",
      "fallback_models": ["provider-b/model-y"]  // Primary quota exhausted → switch to unlimited backup
    },
    "hephaestus": {
      "model": "provider-a/model-x",
      "variant": "medium",
      "fallback_models": ["provider-b/model-y"]
    },
    "oracle": {
      "model": "provider-a/model-x",
      "variant": "high",
      "fallback_models": ["provider-b/model-y"]
    },
    "explore": {
      "model": "provider-a/model-z",  // Weak model is enough
      "fallback_models": ["provider-b/model-y"]
    },
    "librarian": {
      "model": "provider-a/model-z",
      "fallback_models": ["provider-b/model-y"]
    },
    // Specialized agent: fallback chain is self-retry, doesn't switch models
    "oracle-ds4f": {
      "fallback_models": [
        "provider-c/deep-model", "provider-c/deep-model",
        "provider-c/deep-model", "provider-c/deep-model"
      ]
    }
  },
  "categories": {
    "ultrabrain": {
      "model": "provider-a/model-x",
      "variant": "high",
      "fallback_models": ["provider-b/model-y"]
    },
    "quick": {
      "model": "provider-a/model-z",
      "fallback_models": ["provider-a/model-x"]  // Weak model down → upgrade to strong model
    },
    "writing": {
      "model": "provider-a/model-z",
      "fallback_models": ["provider-b/model-y"]
    }
  }
}
```

Several design decisions:

- **Primary uses provider-a, backup uses provider-b**. provider-a has quota but strong model, low latency; provider-b has no quota limit but slightly slower response. Normal case goes through provider-a for the best experience; requests auto-degrade to provider-b when the quota is exhausted.
- **Sisyphus and Hephaestus share the same primary model, different variants**. Sisyphus (orchestration) uses high reasoning, Hephaestus (execution) medium is enough. Both degrade to the same model on provider-b—backup provider doesn't need to distinguish variant.
- **explore/librarian use weak model (model-z)**. These two agents have high call frequency, use weak model to save quota. Fallback still switches to provider-b's model-y, not model-x (the strong model), to avoid tens of explore calls instantly consuming provider-b's quota.
- **oracle-ds4f self-retry 4 times**. Same model repeated 4 times, achieving 5 attempts. This bypasses the normal fallback logic—it's a specialized configuration for a dedicated agent.
- **`max_fallback_attempts: 5`**. Quota limits may last hours, 5 chances cover most scenarios. If all 5 fail, it means both providers are down, and manual handling is reasonable.
- **quick category's fallback is model-z → model-x**. Weak model down → upgrade to strong model, not degrade. This direction is counter-intuitive but reasonable—quick tasks use small model, down means provider has issues, switching to same provider's strong model might recover (different models use different service clusters).

**oms's principle: configure completely, precisely, no shortcuts**

oms has no hardcoded fallback, you get exactly what you configure in the chain. Missed config = no degradation.

1. **At least 3 backups per agent**. oms doesn't have hardcoded chain fallback like omo. Configure only 1 backup—if that also goes down, you error directly. 3 is the minimum.
2. **Cross providers is a hard requirement**. omo can still rely on hardcoded chain fallback, oms chain is all you have. If 3 models in the chain are all from the same provider, when that provider goes down, all go down.
3. **High-frequency agents (explore/librarian) use weak models, don't configure chains**. These two agents have extremely high call frequency, configuring a chain means after degrading to expensive models, tens of calls all go through expensive model. Use strict isolation (no chain) to control costs, if down just error, better than secretly burning money.
4. **Tune `timeoutMs` based on actual latency**. Default 15s is tight for some providers, occasional timeout during peak hours. I suggest tuning to 20-30s. But don't exceed 60s—one fallback attempt waits 60s, and 5 models in the chain all timing out is 5 minutes wasted.
5. **Keep `retry_on_empty` true**. Empty responses occasionally happen in council review scenarios, auto-retry is less hassle. If disabled, one empty response requires manual re-prompt.
6. **Use preset to manage "day/night" two sets of chains**. Use expensive models by day for quality, switch to cheap models by night to save costs. When switching presets, the tried-set doesn't reset, so it won't retry models already failed during the day.

## Special Handling for Dedicated Analysis Agents

Both systems can configure dedicated analysis agents (like `oracle-ds4f` and `oracle-ds4p`). They don't participate in automatic fallback—only used when explicitly requested. The fallback chain is self-retry: same model repeated 4 times, achieving 5 attempts.