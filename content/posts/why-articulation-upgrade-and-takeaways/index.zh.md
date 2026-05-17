---
title: "升级落地——新模板与三个可迁移建议"
slug: "why-articulation-upgrade-and-takeaways"
date: 2026-05-17T09:00:00+08:00
draft: false
description: '基于 A/B 实验结果升级 Why Articulation 模板：去掉显式三问，改为先自由思考再自检补充，保留强制语气和纯反面例子。提炼出三条可迁移到其他 prompt 工程场景的建议。'
tags: ["AI", "prompt 工程", "AB 测试", "TDD", "Why Articulation"]
categories: ["AI 实践", "为什么让 AI 动手之前先说 why"]
series: ["为什么让 AI 动手之前先说 why"]
toc: true
cover:
  image: "cover.png"
  alt: "左侧散落的脚手架碎片标记为废弃，右侧干净的空框，三条金色虚线连接——从复杂到简洁的升级"
---

> **TL;DR：** 展示 Why Articulation 模板升级前后的对比，以及三条可迁移建议：给原则不给示例、关键步骤用强制语气、相信模型的自我组织能力。实验局限也已说明。
>

## 前两篇回顾

[第一篇](/posts/anthropic-alignment-to-prompt-design/)从 Anthropic 的对齐研究出发：教模型"为什么"比只教它"正确答案"，误对齐率从 22% 降到 3%（约 7 倍），而且用 1/28 的数据量就能达到同等效果[1]。我把这个发现移植到 prompt 设计里，造出了 Why Articulation 模板——要求 AI 动手前先说清目的、风险和方案。

[第二篇](/posts/ab-test-positive-examples-harm/)用四组 A/B 实验测了模板的四个维度：去掉显式三问，质量微升且 token 省 33%；加正面示例，质量跌 0.33 分且 token 涨 50%；软化语气，质量跌 0.33 分。结论是去脚手架 + 强制语气 + 纯反面例子，是基于单变量实验的最优配置。

本文把发现落地：升级模板，逐条解释变化，提炼三条可迁移建议。

## 升级前 vs 升级后

新版改了一个地方：把显式三问替换成两段式设计——先自由思考，再自检补充。其余全部保留——⛔ 强制语气、文件顶部位置、纯反面例子、risk hint。具体变化如下。

**旧版（V0）的核心部分：**

```markdown
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
```

**新版（V1）替换为：**

```markdown
Before any work in this phase, articulate your understanding of this task.
Do not proceed to execution until you have produced this reasoning.

After articulating, check: did you address what this phase protects,
where the key risks lie, and why your approach will work?
If not, supplement before proceeding.
```

不变的部分——risk hint 和反面例子保持原样：

```markdown
> **Phase N risk hint**: <phase-specific hint>

### ❌ What superficial Why Articulation looks like
- <phase-specific negative example>
- Restating the task description ("Phase N's goal is to...")
- Listing steps without rationale ("I'll do A, then B")
- Dodging risk assessment ("Risks are low, just proceed normally")
```

视觉上最明显的变化：显式三问（含引导提示）变成了两段式设计——第一段纯开放式，让模型自由思考；第二段自检，确保关键维度不被遗漏。不变的部分：⛔ 强制语气、文件顶部位置、纯反面例子、risk hint。每个决策背后都有数据。

## 逐条解读

**显式三问 → 先自由思考，再自检补充。** 旧版把"目标、风险、方案"拆成三个带编号的问题，每个下面还有引导提示。V1 实验去掉了这个结构，只给了一句话——"articulate your understanding of this task"，纯开放式，不指定任何维度。模型自己组织出了同样的三个维度，质量微升（+0.17），token 省 33%。显式三问不是在帮模型思考，是在限制它。

但纯开放式有个风险：模型可能遗漏关键维度。实验里它恰好每次都覆盖了目标、风险、方案，但这是 n=3 的小样本，不能保证普遍如此。所以最终模板在纯开放式后面加了一段自检——"你有没有覆盖这个阶段保护什么、风险在哪、为什么这个方法有效？没有就补充"。先放手让它自由推理，再用自检兜底。

**⛔ 强制语气保留。** V2 实验把 "MUST NOT proceed" 换成 "strongly encouraged"，trigger rate 没变（都是 100%），但质量掉了 0.33。强制语气影响的是深度，不是服从性。模型在两种条件下都做了 Why Articulation，但在强制条件下分析得更认真。所以新版原样保留了 ⛔ 和 "Do not proceed to execution until"。

**顶部位置保留。** V3 把 Why Articulation 从文件顶部挪到 Objective 之后。质量掉了 0.17，token 开销无变化。净效果为负，位置没动。

**纯反面例子保留。** V4 在反面例子旁加了正面示例，质量跌 0.33，token 涨 50%。正面示例让模型走模仿捷径——用示例的模式套当前任务，而不是独立分析。反面例子已经足够：告诉模型什么不算合格，但不规定什么是合格。这个留白，正是模型发挥推理能力的空间。

## 三个可迁移建议

上面是具体到 Why Articulation 的决策。下面我把这些发现抽象成三条建议，适用于任何 prompt 设计场景。

![三条可迁移建议：从约束到自由的三层递进——底层原则种子、中层开放锁、顶层空框](illustration.png)

### 1. 给原则，不给示例

在 prompt 里描述你期望的思考维度（"解释保护什么、风险在哪、为什么这个方法有效"），而不是给出"好的输出长什么样"的示例。正面示例看似有用，但模型会走模仿捷径——用示例的模式去套当前任务，而不是做独立分析。

这不只是 V4 实验的结论。Anthropic "Teaching Claude Why"[1] 研究的发现是一样的：教原则（行为准则文档、伦理推理）比教行为（正确答案示例）效果好了约 7 倍。我们在 prompt 层面复现了同样的模式。

### 2. 关键步骤用强制语气锁定

把 ⛔ "MUST NOT proceed" 改成 💡 "strongly encouraged"，trigger rate 不变，但质量下降了。强制语气影响的是模型的认真程度，不是它是否触发行为。

如果你的 prompt 里有些步骤是"必须做"的——比如写测试前先写测试方案、提交代码前先 review——用强制语气。不是因为 AI 不听话，而是因为强制语气让它在执行时更深入。模型在"应该做"和"必须做"两种措辞下都会做，但"必须做"让它做得更扎实。

### 3. 相信模型的自我组织能力

我原本以为显式三问给了模型一个有用的结构。实验结果出乎意料：去掉显式结构后，模型自己组织出了同样的三个维度（目标、风险、方案），而且在复杂任务上分析得更深入。

这条建议和第一条是一体两面。给原则是"告诉它想什么"，给结构是"告诉它怎么想"。脚手架不是没用，但有成本——它限制了模型可能探索的方向。你描述清楚期望的维度，然后放手让它自己组织，效果往往比替它安排结构更好。从输入（给什么），到执行（怎么锁定），到结构（放手多少）——越少替模型做决定，它越需要自己思考，自己思考出来的东西质量往往更高。

## 这次实验的局限

上面的建议有方向性的实验支撑，但没有经过统计检验。必须把局限说明白。

**样本量极小。** 每个数据点只跑了一次（n=1 per task per condition）。LLM 输出有随机性，单次运行可能是噪音，V1 的"优势"（+0.17）完全来自一个 task 的半个分数点。

**Agent 类型不一致。** Task 1 用 coder subagent，Task 2-3 用 oracle subagent。不同 agent 的推理风格不同，可能引入混淆变量。

**单模型测试。** 只测了 GLM-5.1。不知道这些结论是否泛化到 Claude、GPT、Gemini 等其他模型。

**非盲评分。** 评分者知道每个输出属于哪个 condition，可能有隐性偏见——哪怕我努力保持客观。

**Ordinal scale 求平均。** 1-4 分的 ordinal 数据直接求平均，统计上有问题。严格说应该用非参数检验，但样本量太小，检验也没意义。

这些局限意味着：上面的发现是方向性信号，不是确证。它指向了明确的方向（去脚手架优于显式结构、正面示例有害、强制语气有深度效应），但如果你在自己的场景里用，建议跑一次小规模验证。

## 结语

三篇串起来就是一条线：Anthropic 的对齐研究发现了"教 why > 教 what"，我用实验验证了这个发现在 prompt 层面同样成立，然后基于数据升级了模板。出发点是别人的研究，落地点是你能直接用的东西。

值得提一句：这个方向不止 Anthropic 一家在说。Wang 等人[2]在经验表示的研究中独立得出了高度一致的结论——他们用 4,590 次受控实验证明，紧凑的控制导向表示（Gene，~230 tokens）比完整的文档包（Skill，~2,500 tokens）效果更好（+3.0pp vs -1.1pp），而且给紧凑表示加回文档材料（包括示例和 API 备注）反而削弱效果。这和我们的发现完全对应：少即是多，多加东西不一定更好。

---

**参考**

1. Anthropic, "Teaching Claude Why", 2026. [anthropic.com/research/teaching-claude-why](https://www.anthropic.com/research/teaching-claude-why)
2. Wang et al., "From Procedural Skills to Strategy Genes: Towards Experience-Driven Test-Time Evolution", arXiv:2604.15097, 2026. [arxiv.org/abs/2604.15097](https://arxiv.org/abs/2604.15097)
