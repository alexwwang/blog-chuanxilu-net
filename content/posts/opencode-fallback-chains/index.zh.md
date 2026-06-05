---
title: "omo vs oms：Fallback 链深度解析"
slug: "opencode-fallback-chains"
date: 2026-06-07T11:00:00+08:00
draft: false
description: "oh-my-openagent（omo）和 oh-my-opencode-slim（oms）的 fallback 机制完全不同：omo 是五层管线逐层降级，oms 是启动选模型 + 运行时 abort 重试。本文从源码出发，拆解两套系统的架构、配置模式、最佳实践，并给出一份脱敏的实战配置示例。"
tags: ["AI", "opencode", "agent", "fallback", "oh-my-openagent"]
categories: ["AI 实践"]
toc: true
series: ["opencode-triple-config"]
---

> 本文是[《当你的 AI 编程工具需要三套配置》](/posts/opencode-triple-config-switch/)的下篇。上篇介绍了三套配置的方案设计、文件结构和编排理念，本文聚焦 fallback 链的机制差异和配置实践。
>
> 文中 omo = oh-my-openagent，oms = oh-my-opencode-slim。模型和 provider 名称已脱敏为 `provider-a/model-x` 等泛化名称。

## 为什么要理解 Fallback

omo 和 oms 都支持 fallback——首选模型不可用时自动切到备选。但机制完全不同：omo 是多层管线逐层降级，oms 是启动选模型 + 运行时 abort 重试。理解这个差异，才能配出靠谱的链。

我自己的触发场景：主力 provider 有每 5 小时的配额限制，用完返回 429。不配 fallback 的话，配额耗尽直接报错，整个 session 中断。配了 fallback + runtime_fallback，配额用完自动切到备选 provider 继续干活，无感切换。

## omo 的 Fallback 架构

omo 的模型解析是一个 **五层管线**，按优先级从高到低：

1. **Override**：用户通过 UI 显式选择的模型，直接返回，跳过所有后续层
2. **Category Default**：agent category 配置的默认模型，带模糊匹配（`model-alpha` 能匹配到 `provider-e/model-alpha`）
3. **User Fallback Models**：用户在配置里写的 `fallback_models`，逐个尝试直到找到在线的
4. **Hardcoded Chain**：omo 内置的 per-agent 和 per-category 硬编码链（9 个 agent + 9 个 category，总共约 65 个条目），跨 provider 匹配
5. **System Default**：所有层都失败时的最终兜底（`opencode/gpt-5-nano`）

关键点：用户的 `fallback_models` 不是替代硬编码链，而是**覆盖**——用户链用完了，还有硬编码链兜底。

`fallback_models` 支持四种写法：

```jsonc
// 写法一：单个模型
"fallback_models": "provider-e/model-s"

// 写法二：有序列表
"fallback_models": ["provider-e/model-s", "provider-f/model-g"]

// 写法三：对象数组（可带参数）
"fallback_models": [
  { "model": "provider-f/model-g", "variant": "high", "temperature": 0.7 }
]

// 写法四：混合（字符串 + 对象）
"fallback_models": [
  "provider-e/model-s",
  { "model": "provider-f/model-g", "variant": "high", "thinking": { "type": "enabled", "budgetTokens": 5000 } }
]
```

对象格式支持的字段：`model`（必填）、`variant`、`reasoningEffort`（none/minimal/low/medium/high/xhigh/max）、`temperature`、`top_p`、`maxTokens`、`thinking`（type + budgetTokens）。这意味着 fallback 不仅是换个模型，还能换推理模式——主模型用高推理，备选切到中等推理省 token。

omo 还有运行时 fallback（`runtime_fallback`）：session 中途遇到 429、500、502、503、504 等 HTTP 错误，或者 rate-limit、quota-exceeded 等错误模式时，自动切换到链中下一个模型，不需要重启 session。默认参数：

```jsonc
"runtime_fallback": {
  "enabled": false,                    // 默认关闭，需要显式开启
  "retry_on_errors": [429, 500, 502, 503, 504],
  "max_fallback_attempts": 3,          // 每个 session 最多切换 3 次
  "cooldown_seconds": 60,              // 同一个模型失败后 60s 内不再重试
  "timeout_seconds": 30,               // provider 无响应的超时判定
  "notify_on_fallback": true           // 切换时弹出通知
}
```

omo 还有**模糊匹配**能力：模型名称会被规范化（小写、版本号分隔符统一），然后做子串匹配。`model-alpha` 能匹配到 `provider-e/model-alpha`，甚至不同 provider 之间的变体也能对应上。

## omo 的 Fallback 模式与场景

**模式一：零配置——纯靠硬编码链**

只设 primary model，不写 `fallback_models`，不开 `runtime_fallback`。硬编码链覆盖 9 个 agent 和 9 个 category，每个链 4-8 个条目，跨多个主流 provider。

适用场景：刚上手 omo，还不熟悉配置。或者用默认 provider，硬编码链本身就是为这些 provider 设计的。好处是零维护，provider 挂了 omo 自己会找到替代模型。代价是不够精准——硬编码链不知道你有哪些 provider 账号，可能在已过期的 provider 上浪费时间。

**模式二：最小覆盖——1-2 个备选**

在硬编码链之上加 1-2 个自己实际可用的备选模型：

```jsonc
"fallback_models": ["provider-a/model-x", "provider-c/model-x"]
```

适用场景：日常开发。硬编码链的主要 provider 偶尔抽风，加两个自有的 provider 作快速备选。用户链优先级高于硬编码链，所以会先尝试你配的模型，失败了再走硬编码。

**模式三：精细控制——mixed 格式 + runtime_fallback**

用对象格式给不同备选配不同参数，并开启运行时降级：

```jsonc
"fallback_models": [
  "provider-e/model-s",
  { "model": "provider-f/model-g", "variant": "medium", "reasoningEffort": "low" },
  { "model": "provider-a/model-x", "temperature": 0.3 }
],
"runtime_fallback": { "enabled": true, "max_fallback_attempts": 5 }
```

适用场景：长 session 编码（比如 omo 模式下的 Sisyphus 编排任务持续几十分钟）。runtime_fallback 保证 session 中途不会因为单次 API 故障中断。mixed 格式允许主模型用高推理，降级时自动切到低推理省 token——强模型挂了不意味着整个 session 报废，用弱一点的模型也能继续。

**模式四：单模型重试——runtime_fallback 的特殊用法**

只开 `runtime_fallback` 不写 `fallback_models`。效果是：同一个模型在 session 内被重试（跳过冷却期后的重试），不切换模型。

适用场景：provider 限频但不限额度。429 错误等几秒重试就能过，不需要换模型。

## oms 的 Fallback 架构

oms 的 fallback 是**两层架构**：

1. **启动时选择**：在 `config()` hook 里从链中取第一个模型作为首选。这一步不检测 provider 是否在线——直接取第一个，能用就用，不能用等运行时再切
2. **运行时故障切换**：`ForegroundFallbackManager` 监听 OpenCode 事件（`message.updated`、`session.error`、`session.status`），检测到 rate-limit 错误后 abort 当前 session 并用链中下一个模型重新 prompt

```jsonc
"fallback": {
  "enabled": true,
  "chains": {
    "orchestrator": ["provider-a/model-x", "provider-c/model-x", "provider-c/model-d"],
    "explorer": ["provider-a/model-z", "provider-c/model-z", "provider-b/model-y"]
  },
  "retryDelayMs": 500,       // abort 后等多久再 prompt（默认 500ms）
  "retry_on_empty": true,    // 空响应（0 token）也触发重试（默认 true）
  "timeoutMs": 15000         // 单次调用超时（默认 15s）
}
```

oms 没有硬编码链——用户必须自己配完整。链通常比 omo 长（3-5 个备选 vs omo 的 1-2 个），因为 omo 有硬编码兜底，oms 全靠用户链。

oms 有 omo 没有的几个特性：

**严格 Agent 隔离**：每个 agent 只用自己的链。explorer 没配链，就绝对不会拿到 orchestrator 的强模型。每个 session 维护一个 tried-set，记录已尝试过的模型，不会回环重试。链用完了，session 保持失败状态，不会偷偷降级。

**空响应重试**（`retry_on_empty`）：模型返回了 0 token 的空内容，oms 也当故障处理。这对 council 评审场景特别有用——弱模型偶尔生成空响应，自动重试比手动重发省心。

**内联优先链**（Model Array 语法）：除了 `fallback.chains`，oms 还支持在 agent 配置里直接写模型数组：

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

Model Array 和 `fallback.chains` 会合并（Array 在前，chains 追加，去重）。这意味着你可以在 agent 配置里写主要偏好（带 variant），在 chains 里写兜底列表。

**Preset 联动**：oms 有 preset 系统（`/preset` 命令运行时切换）。切换 preset 时 `config()` hook 重新执行，链会重建。`ForegroundFallbackManager` 保留 session 状态（tried-set 不丢），但链内容更新了。这在"白天用贵模型，晚上切便宜模型"的场景下很有用。

## oms 的 Fallback 模式与场景

**模式一：基础链——每 agent 配 3 个备选**

```jsonc
"chains": {
  "orchestrator": ["provider-a/model-x", "provider-c/model-x", "provider-c/model-d"],
  "explorer": ["provider-a/model-z", "provider-c/model-z", "provider-b/model-y"],
  "oracle": ["provider-a/model-x", "provider-c/model-x", "provider-b/model-y"]
}
```

适用场景：标准使用。每个 agent 3 个备选，交叉 provider（provider-a 是主力，provider-c 是备选，provider-b/provider-c 的不同模型是兜底）。链里的模型按顺序尝试，第一个可用就停。

**模式二：内联优先链——agent 级别精细控制**

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

适用场景：某些 agent 需要特殊参数。oracle 用高推理模式（variant: high），降级时不需要 variant。内联链和 fallback.chains 合并后 oracle 的有效链是 `[model-x/high, provider-c/model-x, model-d]`。

**模式三：部分 agent 不配链——严格隔离**

只给 orchestrator 和 oracle 配链，explorer、librarian 等高频 agent 不配。这些 agent 首选模型挂了就直接报错，不会降级。

适用场景：控制成本。explorer 和 librarian 调用频率高（一次 session 几十次），用弱模型（model-z）就够。如果弱模型挂了，报错比偷偷切到贵模型（model-x）更好——后者一次 session 能多吃掉几十倍 token。strict isolation 保证了不会发生这种泄漏。

**模式四：retry_on_empty + timeout 调优**

```jsonc
"fallback": {
  "enabled": true,
  "retry_on_empty": true,
  "timeoutMs": 30000,
  "chains": { ... }
}
```

适用场景：使用不太稳定的 provider（比如国内 provider 的高峰期）。`retry_on_empty` 处理模型偶尔返回空内容的情况；`timeoutMs` 调高到 30s 给慢 provider 留余地。代价是每次超时要多等 30s 才切到下一个模型——如果链里 5 个模型都超时，最坏情况等 150s。

## 对比

| 特性 | omo | oms |
|------|-----|-----|
| 解析层级 | 5 层管线（override → category → user → hardcoded → system） | 2 层（启动选 + 运行时切换） |
| 内置硬编码链 | 有（9 agent + 9 category，~65 条目） | 无 |
| 用户链长度 | 通常 1-2 个（硬编码兜底） | 通常 3-5 个（全部自配） |
| 配置格式 | string / string[] / object[] / mixed[]（可带 variant、thinking） | string[]（chains）+ object[]（内联） |
| 运行时切换 | `runtime_fallback`（可配冷却时间、最大次数、超时） | `ForegroundFallbackManager`（事件驱动） |
| 空响应重试 | 不支持 | 支持（`retry_on_empty`） |
| Agent 隔离 | 无严格隔离（可能跨 agent 降级） | 严格隔离（无链 = 不降级） |
| 模糊匹配 | 有（名称规范化 + 子串匹配） | 无（精确匹配） |
| 兜底模型 | `opencode/gpt-5-nano` | 无（链用完就停） |
| Preset 联动 | 无 | 有（链随 preset 重建） |

## 配置最佳实践

**omo 的原则：少配多兜底**

omo 有硬编码链和 system default 两层兜底，用户配置是锦上添花，不是雪中送炭。

1. **链别超过 3 个**。用户链之后还有硬编码链，配太多只是增加无意义的尝试。主备各一个够了，最多加第三个做极端情况兜底。
2. **`runtime_fallback` 一定要开**。omo 的 session 通常持续几十分钟（Sisyphus 编排），不开的话一次 429 就中断整个任务。`max_fallback_attempts` 建议调到 5，`cooldown_seconds` 保持 60。
3. **交叉 provider，别堆同一家**。三个同 provider 模型堆一起，这家一挂全完。至少跨两个 provider。
4. **别在 fallback 链里放专用模型**。比如深度分析模型走 `oracle-ds4f`/`oracle-ds4p` 独立重试逻辑，放 fallback 链里会干扰自动降级。
5. **用 mixed 格式降级省 token**。主模型 `variant: "high"`，备选 `variant: "medium"` 或 `reasoningEffort: "low"`。强模型挂了不意味着 session 报废，弱推理也比没推理强。

**omo 实战配置示例**

以我自己的 omo 配置为例。主力 provider 有配额限制（每 5 小时重置），用完会返回 429。Fallback 链的设计思路：

```jsonc
{
  // runtime_fallback 是关键——不开的话 429 直接报错，开了才能自动切到备选 provider
  "runtime_fallback": {
    "enabled": true,
    "retry_on_errors": [429, 500, 502, 503, 504],
    "max_fallback_attempts": 5,    // 配额限制可能持续几小时，多给几次机会
    "cooldown_seconds": 60,        // 60s 内不重试同一个模型
    "timeout_seconds": 30,
    "notify_on_fallback": true     // 切换时弹通知，知道什么时候在用备选
  },
  "agents": {
    "sisyphus": {
      "model": "provider-a/model-x",
      "variant": "high",
      "fallback_models": ["provider-b/model-y"]  // 主力配额用完 → 切到无配额限制的备选
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
      "model": "provider-a/model-z",  // 弱模型够用
      "fallback_models": ["provider-b/model-y"]
    },
    "librarian": {
      "model": "provider-a/model-z",
      "fallback_models": ["provider-b/model-y"]
    },
    // 专用 agent：fallback 链是自重试，不切模型
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
      "fallback_models": ["provider-a/model-x"]  // 弱模型挂了用强模型顶
    },
    "writing": {
      "model": "provider-a/model-z",
      "fallback_models": ["provider-b/model-y"]
    }
  }
}
```

几个设计决策：

- **主力用 provider-a，备选用 provider-b**。provider-a 有配额但模型强、延迟低；provider-b 无配额限制但响应稍慢。正常情况走 provider-a 拿最好的体验，配额用完自动降级到 provider-b 继续干活。
- **Sisyphus 和 Hephaestus 主力模型相同，variant 不同**。Sisyphus（编排）用 high 推理，Hephaestus（执行）用 medium 就够。降级时都切到 provider-b 的同一个模型——备选 provider 不需要区分 variant。
- **explore/librarian 用弱模型（model-z）**。这两个 agent 调用频率高，用弱模型省配额。fallback 还是切到 provider-b 的 model-y，不切到 model-x（强模型），避免几十次 explore 调用瞬间吃掉 provider-b 的额度。
- **oracle-ds4f 自重试 4 次**。同一个模型重复 4 次，实现 5 次尝试。不走正常 fallback 逻辑，是专用 agent 的特殊配置。
- **`max_fallback_attempts: 5`**。配额限制最长持续几小时，5 次机会覆盖大部分场景。如果 5 次都失败，说明两个 provider 都挂了，手动处理也合理。
- **quick category 的 fallback 是 model-z → model-x**。弱模型挂了升级到强模型，而不是降级。这个方向反直觉但合理——quick 任务模型小，挂了说明 provider 出问题，切到同 provider 的强模型可能恢复（不同模型走不同服务集群）。

**oms 的原则：配全、配准、别偷懒**

oms 没有硬编码兜底，链配多少就是多少。漏配 = 没有降级。

1. **每个 agent 至少 3 个备选**。oms 不像 omo 有硬编码链兜底，你只配 1 个备选，那个也挂了就直接报错。3 个是起步价。
2. **交叉 provider 是硬性要求**。omo 还能靠硬编码链兜底，oms 链用完就没了。如果链里 3 个模型全是同一家 provider，这家一挂全完。
3. **高频 agent（explore/librarian）用弱模型，别配链**。这两个 agent 调用频率极高，配链意味着降级到贵模型后几十次调用都走贵模型。用 strict isolation（不配链）控制成本，挂了就报错，比偷偷烧钱好。
4. **`timeoutMs` 根据实际延迟调**。默认 15s 对部分 provider 偏紧，高峰期偶尔超时。建议调到 20-30s。但别超过 60s——一次 fallback 尝试等 60s，链里 5 个模型全超时就是 5 分钟白等。
5. **`retry_on_empty` 保持 true**。空响应在 council 评审场景下偶发，开了自动重试省心。关了的话，一次空响应就要手动重新 prompt。
6. **用 preset 管理"白天/晚上"两套链**。白天用贵模型保证质量，晚上切便宜模型省成本。preset 切换时 tried-set 不重置，不会重复尝试白天已经失败的模型。

## 专用分析 Agent 的特殊处理

两套系统都可以配置专用分析 agent（如 `oracle-ds4f` 和 `oracle-ds4p`）。它们不参与自动 fallback——只在显式请求时使用。fallback 链是自重试：同一个模型重复 4 次，实现 5 次尝试。
