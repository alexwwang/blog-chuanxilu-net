---
title: "升级落地——新模板与三个可迁移建议"
slug: "upgrade-why-articulation-template-three-transferable-tips"
date: 2026-05-14T10:00:00+08:00
draft: true
description: '系列完结篇：基于 A/B 实验结果升级 Why Articulation 模板，逐条解读变化依据，提炼三条可迁移到任何 prompt 场景的建议，并诚实地交代实验局限。'
tags: ["AI", "Prompt 设计", "Why Articulation", "AB 测试", "对齐研究"]
categories: ["AI 实践", "为什么让 AI 动手之前先说 why"]
series: ["为什么让 AI 动手之前先说 why"]
toc: true
---

# 升级落地——新模板与三个可迁移建议

## 前两篇回顾

[第一篇](/posts/2026/05/anthropic-alignment-research-to-prompt-design/)从 Anthropic 的对齐研究出发：教模型"为什么"比教它"正确答案"效果好一个数量级。我把这个发现移植到 prompt 设计里，造出了 Why Articulation 模板——要求 AI 动手前先说清目的、风险和方案。

[第二篇](/posts/2026/05/ab-experiment-why-positive-examples-harm/)用四组 A/B 实验测了模板的四个维度：去掉编号三问，质量微升且 token 省 33%；加正面示例，质量跌 0.33 分且 token 涨 50%；软化语气，质量跌 0.33 分。结论是开放式 prompt + 强制语气 + 纯反面例子 = 最优组合。

本文把发现落地：升级模板，逐条解释变化，提炼三条可迁移建议。

## 升级前 vs 升级后

直接看 diff。左边是旧版，右边是新版。

### 旧版（V0）

```markdown
## ⛔ Prerequisite: Why Articulation (MUST complete before Phase N execution)

Before any work in this phase, you must explicitly answer the three questions below.
This is not optional commentary — without these answers, you MUST NOT proceed to execution.

**1. What is this phase's goal? What does it protect?**
> Do not restate the task description. Explain why this phase exists
> and what is lost by skipping it or executing it carelessly.

**2. Where are the complexity and risk points in this task?**
> Name the 1–2 biggest risk points and which dimension you will focus
> on most (logical correctness, boundary conditions, design consistency,
> interface contracts, etc.).

**3. How do I plan to proceed, and why will this approach achieve the goal?**
> Decision rationale, not a step list. If multiple approaches exist,
> explain why you chose this one.

> **Phase N risk hint**: <phase-specific hint>

### ❌ What superficial Why Articulation looks like
- <phase-specific negative example>
- Restating the task description ("Phase N's goal is to...")
- Listing steps without rationale ("I'll do A, then B")
- Dodging risk assessment ("Risks are low, just proceed normally")
```

### 新版（V1）

```markdown
## ⛔ Prerequisite: Why Articulation (MUST complete before Phase N execution)

Before any work in this phase, articulate your understanding of this task:
explain what this phase protects, where the key risks lie, and why your
chosen approach will achieve the goal. Do not proceed to execution until
you have produced this reasoning.

> **Phase N risk hint**: <phase-specific hint>

### ❌ What superficial Why Articulation looks like
- <phase-specific negative example>
- Restating the task description ("Phase N's goal is to...")
- Listing steps without rationale ("I'll do A, then B")
- Dodging risk assessment ("Risks are low, just proceed normally")
```

视觉上最明显的变化：三个编号问题变成了两行开放式描述。不变的部分：⛔ 强制语气、文件顶部位置、纯反面例子、risk hint。每个决策背后都有数据。

## 逐条解读

**编号三问 → 开放式描述。** 旧版把"目标、风险、方案"拆成三个带编号的问题，每个下面还有引导提示。去掉这个结构后，模型自己组织出了同样的三个维度，质量微升（+0.17），token 省 33%。编号三问不是在帮模型思考，是在限制它。原则描述已经告诉模型该想什么了，再加结构就是多余。

**⛔ 强制语气保留。** V2 实验把 "MUST NOT proceed" 换成 "strongly encouraged"，trigger rate 没变（都是 100%），但质量掉了 0.33。强制语气影响的是深度，不是服从性。模型在两种条件下都做了 Why Articulation，但在强制条件下分析得更认真。所以新版原样保留了 ⛔ 和 "Do not proceed to execution until"。

**顶部位置保留。** V3 把 Why Articulation 从文件顶部挪到 Phase 正文之前（位置靠后）。质量掉了 0.17，token 省 15%。省的 token 来自模型引用上下文少了——因为它离 task description 更近，少写了"如前所述"类的冗余。但质量下降不值得换这点 token 节省，位置没动。

**纯反面例子保留。** V4 在反面例子旁加了正面示例，质量跌 0.33，token 涨 50%。正面示例让模型走模仿捷径——用示例的模式套当前任务，而不是独立分析。反面例子已经足够：告诉模型什么不算合格，但不规定什么是合格。这个留白，正是模型发挥推理能力的空间。

## 三个可迁移建议

上面是具体到 Why Articulation 的决策。下面我把这些发现抽象成三条建议，适用于任何 prompt 设计场景。

### 1. 给原则，不给示例

在 prompt 里描述你期望的思考维度（"解释保护什么、风险在哪、为什么这个方法有效"），而不是给出"好的输出长什么样"的示例。正面示例看似有用，但模型会走模仿捷径——用示例的模式去套当前任务，而不是做独立分析。

这不只是 V4 实验的结论。Anthropic "Teaching Claude Why" 研究的核心发现是一样的：教原则（宪法文档、伦理推理）比教行为（正确答案示例）效果好一个数量级。我们在 prompt 层面复现了同样的模式。

### 2. 关键步骤用强制语气锁定

把 ⛔ "MUST NOT proceed" 改成 💡 "strongly encouraged"，trigger rate 不变，但质量下降了。强制语气影响的是模型的认真程度，不是它是否触发行为。

如果你的 prompt 里有些步骤是"必须做"的——比如写测试前先写测试方案、提交代码前先 review——用强制语气。不是因为 AI 不听话，而是因为强制语气让它在执行时更深入。模型在"应该做"和"必须做"两种措辞下都会做，但"必须做"让它做得更扎实。

### 3. 相信模型的自我组织能力

我们原本以为编号三问给了模型一个有用的结构。实验结果出乎意料：去掉编号后，模型自己组织出了同样的三个维度（目标、风险、方案），而且在复杂任务上分析得更深入。

这条建议和第一条是一体两面。给原则是"告诉它想什么"，给结构是"告诉它怎么想"。脚手架不是没用，但有成本——它限制了模型可能探索的方向。你描述清楚期望的维度，然后放手让它自己组织，效果往往比替它安排结构更好。

三条建议是递进的：先控制输入（给原则不给示例），再控制执行（关键步骤用强制语气），最后控制结构（让模型自己组织）。越少替模型做决定，它越需要自己思考——自己思考出来的东西，质量往往更高。

## 诚实的边界

上面的建议有方向性的实验支撑，但没有经过统计检验。必须把局限说明白。

**样本量极小。** 每个数据点只跑了一次（n=1 per task per condition）。LLM 输出有随机性，单次运行可能是噪音，V1 的"优势"（+0.17）完全来自一个 task 的半个分数点。

**Agent 类型不一致。** Task 1 用 coder subagent，Task 2-3 用 oracle subagent。不同 agent 的推理风格不同，可能引入混淆变量。

**单模型测试。** 只测了 GLM-5.1。不知道这些结论是否泛化到 Claude、GPT、Gemini 等其他模型。

**非盲评分。** 评分者知道每个输出属于哪个 condition，可能有隐性偏见——哪怕我努力保持客观。

**Ordinal scale 求平均。** 1-4 分的 ordinal 数据直接求平均，统计上有问题。严格说应该用非参数检验，但样本量太小，检验也没意义。

这些局限意味着：上面的发现是方向性信号，不是确证。它指向了明确的方向（开放式优于结构化、正面示例有害、强制语气有深度效应），但如果你在自己的场景里用，建议跑一次小规模验证。

## 结语

三篇串起来就是一条线：Anthropic 的对齐研究发现了"教 why > 教 what"，我们用实验验证了这个发现在 prompt 层面同样成立，然后基于数据升级了模板。出发点是别人的研究，落地点是你能直接用的东西。
