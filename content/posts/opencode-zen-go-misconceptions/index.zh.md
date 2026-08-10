---
title: "同一个 key，两个世界：OpenCode 的 Zen 与 Go"
slug: "opencode-zen-go-misconceptions"
date: 2026-08-10T16:00:00+08:00
draft: false
description: "网上关于 OpenCode 免费模型与订阅的传言，逐条拿数据对账：同一把 key 如何区分 Zen 与 Go、免费版额度的实测边界、oc 的 ds4f 是否缩水、Go 订阅额度怎么算。"
tags: ["AI", "opencode", "zen", "go", "deepseek", "订阅"]
categories: ["opencode"]
toc: true
cover:
  image: cover.png
  alt: "水彩画：一把金钥匙与两扇拱门，代表 Zen 与 Go 两套服务"
---

正在用或想要用 OpenCode.ai（以下简称 oc）的推理服务做开发、跑 Agent 的朋友，估计不少人都有这样的焦虑：要么担心模型不如官方的质量好，要么担心免费版天天撞限额，要么搞不懂 Go 订阅的额度到底怎么算，看别人说5分钟用完半个月就觉得不靠谱。

但是在deepseek v4 flash（以下简称 ds4f）正式版发布后，我发现我没有 Token 焦虑了，也没有这样那样的担心了。这里我把过去三个月使用 opencode.ai 的经验，以及本地最近 3000 多条真实调用日志拉出来对了一下账，给大家详细说说 5 个关键误区的真相，相信你彻底弄明白之后，不仅工作流跑得更稳，也不用担心 Token 额度不够用了。

## 误解一：同一把 key，Zen 和 Go 是一回事

OpenCode 的模型服务有两套：Zen 和 Go。它们共享一个入口和后台管理界面，API key 的创建页面也没有做区分，事实上同一把 key 也能同时调 Zen 和 Go 两套服务 [1][2]。因此很多人把它们当成了一个东西，以为 Go 是 Zen 的订阅，以为 Zen 提供的免费模型就是 Go 的免费模型。

- Zen：`https://opencode.ai/zen/v1`
- Go：`https://opencode.ai/zen/go/v1`

两个地址只差一个 `/go`，计费体系完全不同。对照如下：

| | Zen | Go |
|---|---|---|
| base URL | `https://opencode.ai/zen/v1` | `https://opencode.ai/zen/go/v1` |
| 模型 ID | `opencode/<model>` | `opencode-go/<model>` |
| 计费方式 | 按量付费 + 限时免费档 | 订阅额度 |

Zen 是按量付费网关：充余额、按 token 扣费，带 Free 后缀的免费模型（`deepseek-v4-flash-free` 等）只在这里 [1]。Go 是订阅制：首月 $5、之后 $10/月，额度按美元算 [2]。

共用入口和后台界面，再加上同一把 key 两边都能调，误解就在这里。其实你填哪个 base URL，就走哪套计费。两个 URL 一列出来，区别就清楚了。

## 误解二：免费版够用且随便用，所以不用订阅 Go

免费版是真的免费，但它是「限时试用装」，不是「永久正装」。我用本机三个月的调用记录给你看边界。

**先说限时。** 官方明确写着免费模型「available for a limited time」，目的是收集反馈改进模型 [1]。免费名单本身也在变：6 月的免费榜是 Nemotron 3 Super、MiniMax M2.5、Qwen3.6 Plus 那一批，8 月的官方列表已经换成了另一批 [3][1]。

**再说能力。** 免费版有两条硬边界：上下文 200K [4]，没有视觉能力（code/text 模态）[4]。

**再说用量。** 网上有说法是「每天大约 200 次请求」[5]。我统计了最近一周多（2026-07-27 ~ 08-07）撞限额墙的实际调用量，来估计免费额度。共 3606 次 `deepseek-v4-flash-free` 调用，实测的限额边界是：

![免费版限额示意：量杯与沙漏](illustration-2.png)

- 限额按 **UTC 0 点重置**（= 北京 08:00）。三次撞限额的 retry-after 全部精确指向次日 UTC 0 点，恢复后的第一条成功调用都在重置之后
- 免费调用次数存在波动，和 token 消耗量、当日的推理资源富余量有关系，实测约 **450~766 次/日**（均值 605），对应 **49~72M tok/日**。每次请求的 token 结构约 94.5K 缓存命中输入 + 6.5K 未命中输入 + 0.8K 输出，整体 cache 命中率 93.6%，**单次请求命中率中位数 99.6%**；绝大多数请求几乎全命中缓存，少数新上下文请求把整体均值拉低
- 三次限额里有一次是速率触发的：深夜 3 小时内密集调用了 450 多次（最后 1 小时约 250 次），当日总量其实还没到累计上限就被拦了。说明除了每日总量，还有一个请求频率的边界在：跑批任务连续快速请求，可能比累计用量更早撞上这条。另外两次（7/28、8/5）都是累计到上限触发的
> 数据来源：本机 ~/.omp/stats.db，opencode-zen provider，2026-07-27 ~ 08-07。

「每天 200 次」低估了免费额度：我 544 次、665 次的日子都没触发限额；但「随便用」也是假的：跑批任务一小时 250 次就会撞墙。

所以免费版替代不了订阅：尝鲜和轻量任务，免费版够用；agent 跑批、长上下文、要稳定，该订阅 Go。差距就在这些边界上：Go 版 ds4f 是 1M 上下文（与官方原生规格一致 [6]），免费版只有它的五分之一。

## 误解三：oc 的 ds4f 相比官网是缩水版

传言说 oc 的 ds4f 是官网缩水版：上下文砍了、版本旧了、质量差一截。对账结果：同一个模型，同一个版本。

DeepSeek V4 Flash 官方 API 于 2026-07-31 更新到 0731 版本：重新后训练、结构不变（284B 总参数 / 13B 激活的 MoE），原生 1M 上下文、单次最大输出 38.4 万 token [6]。oc 的 ds4f 直连 DeepSeek 官方（社区佐证 [7]），内部计价 $0.14 / $0.28 per 1M token [2]，与官方人民币价约 ¥1 / ¥2 基本一致 [6]。

有一个看起来像「缩水」的真实细节：0731 版本只部署在中国，需要在 Go 控制台显式「启用部署在中国的模型」，否则报 403 RegionError [7]。这是部署位置的选择，不是模型缩水。

真正缩水的是免费档：200K 上下文、每日限额、无视觉。但那是 Zen 免费版（误解一、二已经讲清楚），不是 Go 订阅里的 ds4f。

## 误解四：ds4f 不能看图，所以 oc 处理不了图片

ds4f 确实不能看图：官方 Responses API 明确不接受图片和文件输入 [6]，免费档的模态就是 code/text [4]。这是**模型的能力边界**。

但处理图片不需要换工具，只需要换模型。不同应用有不同的路由方式：

### OpenCode：手动切换

在 TUI 里输入 `/model`，随时切到多模态模型。免费档选 `opencode/mimo-v2.5-free`，订阅档选 `opencode-go/mimo-v2.5`。文本和代码走 ds4f（便宜、量足），看图切多模态模型。

### OMP：vision agent 自动路由

如果你在用 OMP，可以配置 **vision agent**：把读图任务自动路由到对应的多模态模型，不用每次手动切换。

最佳实践：
- **主模型**：`opencode-go/deepseek-v4-flash`（文本/代码，便宜量足）
- **Vision agent**：优先走 **Zen 的 `opencode/mimo-v2.5-free`**（免费多模态，endpoint `https://opencode.ai/zen/v1/chat/completions`），额度不够或失败时再 **fallback 到 Go 的 `opencode-go/mimo-v2.5`**（endpoint `https://opencode.ai/zen/go/v1/chat/completions`）

这样日常看图几乎不消耗 Go 订阅额度，只有 free 档额度耗尽或失败时才动用订阅。

![按任务路由：双终端分流示意](illustration-1.png)

核心思路一致：按任务路由，文本和代码走 ds4f，看图走多模态模型。OpenCode 靠手动切换，OMP 靠 vision agent 自动分派。

## 误解五：Go 订阅 = 每月固定 N 次请求

「Go 订阅每月能调多少万次」是最常见的问题，也是问法最不对的问题。

Go 的额度不是次数，是**美元**：$5 首月、$10/月，买到的是 5 小时 $12、每周 $30、每月 $60 的三档滚动额度 [2]。为什么是 $60？官方说法是：$10 想给你 6 倍等值用量，靠批量折扣和预留 GPU 实现；折扣谈不下来的新模型，倍率就低 [2]。

哪些模型倍率更低？**$15 档**（月额度从 $60 降到 $15，相当于 1.5 倍而不是 6 倍）：
- Grok 4.5、GPT 5.6 Luna、Kimi K3、MiMo-V2.5-Pro、DeepSeek V4 Pro、Qwen3.8 Max

原因：官方没拿到这些模型的批量折扣，或对方公开定价已经压得很低，没空间再让利 [2]。调用这些模型会更快消耗你的月额度。同样花 $10，ds4f 能跑 15.8 万次，而 GLM-5.2 只能跑 4300 次。选模型时注意区分。

次数 = 美元额度 ÷ 模型单价 ÷ 单次请求 token 量。所以官方给的估算表长这样 [2]：
| 模型 | 估算次数/月 |
|---|---|
| DeepSeek V4 Flash | ~158,150 |
| MiMo-V2.5 | ~150,400 |
| Qwen3.7 Plus | ~21,600 |
| Hy3 | ~21,500 |
| MiniMax M3 | ~16,000 |
| Qwen3.6 Plus | ~16,300 |
| DeepSeek V4 Pro | ~17,150 |
| Kimi K2.7 Code | ~6,750 |
| GLM-5.2 | ~4,300 |
| GPT 5.6 Luna | ~10,250 |
| Kimi K3 | ~490 |
| Grok 4.5 | ~600 |

> 以上为官方估算表的部分模型，完整列表见 [opencode.ai/docs/go](https://opencode.ai/docs/go/) [2]。估算基于典型用量假设（如 ds4f 按每次 ~790 input + 68,000 cached + 280 output tok 算）。我本机 Go 版 ds4f 同期 2151 次调用、计费 $2.57，单次请求量是比典型用量要高的，但就这样目测也用不完。

超额后的两种选择：默认是**限流**（请求直接被 429 拦下）；也可以在控制台开启 **Use balance**，超额后自动用 Zen 余额继续跑，不会断 [2]。

## 最实惠的搭配方案：不是三选一，是组合用

Go 订阅的核心价值是**用更少的钱跑更多的请求**。在 $10/月的前提下，不同模型的 tok 量差距巨大：

### Go 订阅内的模型性价比排序

> **重要前提**：所有模型**共享同一个订阅额度**（月 $60）。你调 ds4f、MiMo、GLM 都从同一个池子里扣，不是每个模型各算各的。

以下按**估算月最大调用次数从高到低**排序：

| 模型 | 估算月调用次数 | 单价（per 1M tok） | 性价比定位 |
|---|---|---|---|
| **ds4f（DeepSeek V4 Flash）** | ~15.8 万次 | $0.14 / $0.28 | **主力首选**：量最大，日常 coding 全用它 |
| **MiMo-V2.5** | ~15 万次 | $0.14 / $0.28 | **同量级**：和 ds4f 几乎一样多，看图任务也能用 |
| MiniMax M3/M2.7、Qwen3.6/3.7 Plus、Hy3 等 | 1.6/2.1 万次 | $0.30-0.50 | 量少于 ds4f，特定场景选用 |
| Kimi K2.6/K2.7 Code、GPT 5.6 Luna 等 | 5,750/6,750/10,250 次 | $0.95 | 量中等，特定场景选用 |
| **GLM-5.2/5.1** | ~4,300 次 | $1.40 / $4.40 | **单价高**，能跑的次数明显少于同档位 |
| Grok 4.5、Kimi K3 等 | 600/490 次 | $2.00-3.00 | **量最少档**（月额度 $15），仅在必要时调用 |

> 注：估算基于官方典型用量假设（如 ds4f 按每次 ~790 input + 68,000 cached + 280 output tok 算），实际次数因你的单次请求 token 量而异。月额度 $60 是所有模型共享的上限。

### 最佳实践：三档组合，不是三选一

| 场景 | 推荐方案 | 原因 |
|---|---|---|
| 日常 coding、文本生成 | **Go 订阅的 ds4f** | 1M 上下文、月 ~15.8 万次、最便宜 |
| 看图理解 | **Zen 免费档 MiMo-V2.5 Free** → fallback 到 Go MiMo-V2.5 | 免费多模态先顶上，不消耗 Go 额度 |
| 跑批任务 | **Go 订阅的 ds4f** | 量大、速率注意别撞 1h ~250 次限制 |
| 生产环境 / 合规要求 | **官方 API** | 独立余额、零保留协议、不占用 Go 额度 |
| 验证新需求 | **先 Zen 免费档** → 再切 Go | 试错成本为零 |

### 一句话策略

**Go 订阅的 ds4f 当主力，Zen 免费档看图当 fallback，官方 API 兜底生产。** 三档可以搭配用，不是只能选一个。

实测与取证于 2026-08-09。免费名单、额度、模型版本都在快速变化，下单前以官网为准。

---

## 参考

1. Zen 官方文档：<https://opencode.ai/docs/zen/>
2. Go 官方文档：<https://opencode.ai/docs/go/>
3. WatermelonWater：OpenCode Zen 免费模型深度评测与 CC Switch 接入教程（2026-06-06）：<https://watermelonwater.tech/insights/opencodezen免费模型评测/>
4. 本站：OpenCode 冷启动：五分钟用上免费的 DeepSeek V4 Flash（2026-07-06）：<https://blog.chuanxilu.net/posts/2026/07/ai-path-opencode-zen-setup/>；AY Automate：DeepSeek V4 Flash Free 规格：<https://www.ayautomate.com/free-models/opencode-zen-deepseek-v4-flash-free>
5. 知乎：分享 DeepSeek-V4-Flash 免费使用的途径（「每天大约 200 次请求」）：<https://zhuanlan.zhihu.com/p/2066646501347087069>
6. 51AllAI：DeepSeek-V4-Flash 正式版 API 上线公测，原生接入 Codex（2026-07-31）：<https://51allai.com/posts/2026/07/deepseek-v4-flash-0731-codex/>
7. V2EX：opencode go 订阅使用 deepseek v4 flash 受限了？（2026-07-31）：<https://www.v2ex.com/t/1231306>
