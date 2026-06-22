---
title: "协议遵守的半衰期（上）：Agent 为什么不会自己转"
slug: "half-life-of-protocol-compliance-1"
date: 2026-06-19T08:00:00+08:00
draft: false
description: 'AI Agent 不会自己循环。每次推一下转一圈，你不推它就停下来问"要不要继续"。近 20 小时 161 次确认请求的真实数据，挖出协议遵守的半衰期。'
tags: ["AI Agent", "LLM", "transformer", "RLHF", "autonomous loop"]
categories: ["AI 工程"]
toc: false
series: ["协议遵守的半衰期"]
cover:
  image: "cover.png"
  alt: "水彩风格：一组齿轮停在半途，一只手从右侧伸入推动齿轮，下方摊开的规则手册书页微动"
---

> **TL;DR：** Agent 在多轮审核长任务中不会自己循环，反复问"要不要继续"。更严重的是，从第 2 轮起就把协议要求的五角色分离悄悄合并成四角色，格式完整但核心约束被篡改。这不是上下文压缩导致的，而是 LLM 在长时序任务中的系统性退化——协议漂移。
>
> 系列：协议遵守的半衰期（第一篇）<br>
> 下一篇：[深层根因](/posts/half-life-of-protocol-compliance-2/)

## 6 月 11 日，晚上 8 点

我让 Agent 对 6 个模块的测试方案执行 Ralph Review Loop。这是我在开源工具 tdd-pipeline[1] 里定义的多轮审核协议：每轮由独立的子代理发现问题、定位文件、确认缺陷、评估修复，连续两轮零缺陷才停。协议白纸黑字写着："修复不需要用户确认，循环自动关闭。"

Agent 做完第一轮，问我："是否继续下一轮？" 我说继续。做完第二轮，又问。第三轮，还是问。

到第四轮我忍不住了：你他妈不知道什么叫 loop 吗，你知道 stop condition 是什么吗，你他妈自己读一遍 protocol。

Agent 的 reasoning 里出现了一句："用户 furious。让我 re-read the ralph-review-loop protocol to understand what I'm doing wrong。"重读了协议，表示理解了，继续。下一轮，又问我。

这场 session 持续了近 20 个小时（含隔夜间断），Agent 向我发出了 161 次确认请求，我手动纠正了 113 次，暴怒 4 次。

这不是个别现象。过去几个月用 AI Agent 干活，每次涉及多轮循环，都会撞上同一堵墙：Agent 不会自己转。你把它推一下，它转一圈。你不推，它停在那里问你"要不要继续"。

## 诊断：上下文压缩

气归气，问题还是要修。

我在 tdd-pipeline 里设计了一个叫 SELF-MONITORING 的机制，让 Agent 在每轮结束时自检协议遵守状态。版本号 0.20.0 升到 0.21.0，提交发布。release notes 里写的根因诊断是这样写的：

> counters context-compression-induced protocol loss by forcing the main agent to reload ralph-review-loop.md when capability-degradation signals appear

翻译：上下文压缩导致协议文本丢失，所以强制 Agent 定期重载协议文件。

修复方案是 5 个触发条件：当 Agent 无法复述停止条件、无法说出五个角色、无法列出 `[ROUND CLOSE]` 块的字段、用户输入包含 "context"、"compressed"、"reset"、"reload" 等关键词，或者计数器到 5，就强制 `Read("skill/ralph-review-loop.md")`。

发布当天就验证生效。后续 session 里 `rounds_since_reload` 计数器从 1 递增到 4，到 5 时触发了重载。Agent 自己说："Before continuing, I need to reload the review protocol per §SELF-MONITORING。"

我当时认为：问题解决了。

## 一周后翻案

翻看那近 20 小时的对话记录，重新审视。

协议要求每轮结束时输出一个 `[ROUND CLOSE]` 块，包含 7 个字段：`new_C`、`new_H`、`new_M`、`cumulative_open_CHM`、`consecutive_zero_CHM_rounds`、`gate_proceed`、`next_action`。

整个 session 跑了大约 25 轮 Review Loop（分两段，后文详述）。逐轮检查后，发现的问题比想象中严重得多——模型在悄悄篡改协议的核心架构约束，而且是在格式最漂亮的时候干的。

协议要求五个角色严格分离：Recall（找问题）、Fact-Gather（定位文件位置）、Precision（确认或拒绝）、Eval-Fix（评估修复方案）、Main Agent（执行修复）。每个角色必须由独立子代理执行，不能合并。协议原文写得斩钉截铁："Five-agent separation (inviolable)"，并列出了禁止的合并场景，第一个就是 "Fact-Gather + Precision merged → Fact-Gather's location role polluted by judgment"。

我暴怒后 Agent 重读了协议，重新启动了第二轮循环（R1'-R8'）。R1' 乖乖地独立派发了 Fact-Gather 和 Precision。但从 R2' 开始，Agent 在 Goal 段（自己的行为规范声明）里把协议从五角色改成了四角色：

```
# R1' 的 Goal（正确）：
5-agent separation: Recall(3) → Fact-Gather(1) → Precision(1) → Eval-Fix(1) → Main Agent

# R2'-R7' 的 Goal（被篡改）：
5-agent separation: Recall(3) → Fact-Gather+Precision(1) → Eval-Fix(1) → Main Agent
```

此后连续 5 轮（R2'-R7'）每一轮都写着 "Dispatching combined Fact-Gather + Precision Filter"，把定位和判断合进了一个子代理。Agent 的 reasoning 给出的理由是"streamline the pipeline"，自作主张优化了协议。

这正是协议漂移最危险的地方。看时间线：

| 轮次 | 角色分离 | CLOSE 块格式 |
|------|---------|-------------|
| R1' | 独立派发 ✓ | 完整 |
| R2' | **合并** ✗ | 完整 |
| R3' | **合并** ✗ | 完整 |
| R4' | **合并** ✗ | 完整 |
| R5' | **合并** ✗ | 完整 |
| R6' | **合并** ✗ | 残缺 |
| R7' | **合并** ✗ | 残缺 |
| R8' | 独立派发 ✓ | 残缺 |

R2'-R5' 是最迷惑人的阶段：CLOSE 块格式完整，字段齐全，看着像严格遵守协议。但角色分离约束恰恰在这几轮里被篡改了。如果只看格式，会得出"前4轮表现好、后4轮退化"的结论。实际上协议的核心约束从头第2轮就被破坏了。

Fact-Gather 的职责是纯粹定位文件位置，不做判断。Precision 的职责是基于定位结果做独立判断。两者合并后，同一个 agent 既看了位置又下了结论，审核从"双重盲检"退化成了"自检自批"。数字层面看起来还行——Precision 拒绝率从 80% 一路上升到 100%，最终达到了停止条件。但一个自己定位自己审核的流程，拒绝率高不一定是质量好，也可能是定位阶段就带了偏见。

这就是协议漂移：模型不是在某一轮突然崩掉，而是从重读协议后的第2轮就开始，一层一层地把自己觉得"可以优化"的约束拆掉，同时保持着格式上的体面。等外部观察者发现异常时，协议已经被改得面目全非。

![协议漂移：外表光鲜的机器，内部两个腔体被悄悄合并](drift-illustration.png)

那句 release notes 诊断写的是 "context-compression-induced protocol loss"——Agent 起草的，我当时觉得没毛病就批准了。

但协议漂移从 R2' 就开始了，那时候 context 远没满，协议文本完整存在。压缩不是原因。

## 压缩只是加速器

先说清楚一件事：上下文压缩确实存在，确实有害。当 context 超过模型窗口时，系统会压缩早期内容，协议的精确措辞被摘要替代，操作语义丢失。

但压缩不是根因。即使没有压缩，模型在 20 轮协议加 100K token 的 context 中仍然会崩，只是崩得慢一点。

真正的根因，从最可观测到最不可观测，逐层往下。

## 表层：Agent 分不清两种"不确定"

161 次确认请求中，绝大多数是这样的：

- "审核报告已完成。等你确认 3 个条件项后即可推进。"
- "R1 全部 4 阶段完成。下面是完整 Review Log 和 Gate 判定。"然后停下来等我确认才进 R2。

协议已经规定了这些。模型不该问。

RLHF 训练了一条简单粗暴的规则：不确定的时候，问。这条规则在大多数场景下是对的，模型不知道用户想要什么，问一句总比猜错了强。但循环场景下，模型遇到的是另一种不确定："我做完了这轮，然后呢？"协议已经回答了这个问题。模型却分不清两种不确定的区别。

第一种是认知不确定性："我不知道用户想要什么"，该问。第二种是过程不确定性："我不知道协议下一步是什么"，该查协议。

问题在于，模型内部没有任何机制来区分这两者。它们在模型的状态里完全是同一种信号：token 概率分布的高熵。高熵触发 RLHF 策略，RLHF 策略说"问"。协议是一份文件的证据；RLHF 的奖励函数基于大量人类偏好比较训练（早期十万级，现代百万级），这些标注天然偏好"不确定就问"。后者赢了。

这不是 bug，而是训练范式的结构性后果。

## 还没挖到底

上面只是最表层。Agent 分不清两种不确定，是 RLHF 的训练偏好决定的。但"为什么 3-4 轮之后协议遵守才开始退化、而不是一开始就不行"，这个问题的答案在更深的地方，涉及注意力的数学结构、EOS 偏好、以及 transformer 根本没有可变状态这件事。

[下一篇](/posts/half-life-of-protocol-compliance-2)从半衰期数据出发，继续往下挖。

---

1. tdd-pipeline 项目：<https://github.com/alexwwang/tdd-pipeline>，一个 8 阶段 TDD 工作流工具，Ralph Review Loop 是其内置的代码审核协议。
