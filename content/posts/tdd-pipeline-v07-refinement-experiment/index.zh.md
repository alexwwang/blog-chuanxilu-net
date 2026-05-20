---
title: "以尺度尺，用方法改进方法"
slug: "tdd-pipeline-v07-refinement-experiment"
date: 2026-05-20T10:00:00+08:00
draft: false
description: '你造了一把尺子，尺子量出"冗余有害"，然后你用这把尺子裁掉了尺子本身的冗余。把 AI 工具里的操作步骤删掉，只保留原则和反面例子，模型自己推导出了被删掉的步骤。'
tags: ["AI", "TDD", "skill 设计", "prompt 工程", "原则驱动"]
categories: ["AI 实践", "破而后立的 TDD 流程迭代"]
series: ["破而后立的 TDD 流程迭代"]
toc: true
cover:
  image: "cover.png"
  alt: "一把尺子量出自身刻度的冗余，然后用这把尺子裁掉多余刻度"
---

> 系列：破而后立的 TDD 流程迭代（第二篇）
> [上一篇：失之东隅，收之桑榆的实验](/posts/tdd-pipeline-v08-failed-experiment-discovery/)

> **TL;DR：** TDD Pipeline 自己教的是"给原则不给步骤"，但自己却长成了步骤驱动的工具。把阶段一到阶段五的操作步骤删掉，只保留原则、风险提示和反面例子。模型自己推导出了被删掉的步骤，输出质量不降。原因：阶段一到阶段五是创作阶段，需要发散空间，去掉固定轨道反而更好。同样的策略用在阶段六上失败了——下一篇讲为什么。

## 为什么倒叙回 V0.7

上一篇讲了 V0.8 实验——精炼阶段六没达到预期，但意外发现精炼版更擅长项目级全局视角[1]。

那个实验有一个前提：阶段一到阶段五的精炼已经成功了。V0.8 是在 V0.7 的成功之上做的延伸尝试。

要理解 V0.8 为什么失败、为什么失败得有价值，得先看 V0.7 为什么成功。

## 卡住的地方

TDD Pipeline 跑了一段时间，阶段一到阶段五的 skill 文件越来越长。每个文件里塞了操作步骤、模板格式、检查清单、反面示例。加起来几千行。

每一条规则都有用——都是从实战 bug 里提炼出来的。但"每一条都有用"和"整体最优"是两件事。

这让我想到一个早就在系列文章里反复出现的发现：**给模型的约束越具体，模型越倾向走捷径。** 在 Why Articulation 的 A/B 实验里[2]，正面示例让模型的分析同质化，去掉示例反而提升了独立推理质量。在 Anthropic 的对齐研究里[3]，教原则比教行为效果好了约 7 倍。

那问题就来了：skill 文件里那些具体的操作步骤、模板填充指引、checklist 提示——它们和正面示例是不是一回事？都是在给模型一个可以不思考的出口？

**TDD Pipeline 自己教的是"给原则不给步骤"，但 TDD Pipeline 自己却长成了步骤驱动的工具。**

这个矛盾本身就是实验动机。

## 实验设计

我的假设是：把阶段一到阶段五的 skill 文件从"步骤驱动"精炼为"原则驱动"，模型在原则框架下能自主推导出被删掉的操作步骤，输出质量不低于旧版。

精炼策略不复杂。留四删三：

**保留：**
- Why Articulation 强制自检机制[2]
- 每个阶段的风险提示
- 反面例子（"敷衍的 Why Articulation 长什么样"）
- 审核通过条件

**删掉：**
- 具体操作步骤（"Step 1 做 X，Step 2 做 Y"）
- 模板填充指引（"在下面这个模板里填入你的内容"）
- 重复说明（在多处出现的同一条规则）

精炼前后对比举个具体例子。旧版阶段一的开头：

```markdown
## Objective

Understand **what** to build and **why**, not **how**.
Surface all ambiguity before a single line of code is considered.

## Detailed Process

1. Use deep-interview skill to gather requirements
2. Classify user stories as core / secondary
3. For each core story, write acceptance criteria
4. Validate all ACs are testable (binary pass/fail)
...
```

精炼版只保留了原则、risk hint 和反面例子，去掉了 Detailed Process 部分。

对照方式：同一组任务，分别用旧版 skill 和精炼版 skill 跑，独立评估 agent 做盲测比较。六个验证维度——交付物完整性、审核质量、边界覆盖、计数器逻辑、触发器、阶段切换。

## 结果：精炼版不比旧版差

四轮独立盲测，四个不同类型的任务：

| 轮次 | 任务 | 类型 | 结果 |
|---|---|---|---|
| A | Token Bucket | 设计密集 | 通过：交付物 7.5/8，审核等效，边界 13/13，计数器 4/4 |
| B | CSV Import | 代码密集 | 通过：交付物 6/6，审核等效，边界 10/13 可接受 |
| C | Notification Service | 盲测 | 发现缺陷——精炼版的阶段文件丢了 Ralph 触发器和阶段切换指针 |
| D | Policy Engine | 复验修复 | 通过：六个维度全部通过，审核经 oracle 独立验证 7/7 |

Round C 的发现值得说。精炼版删掉了每个阶段文件末尾的"完成后触发审核"和"进入下一阶段"指引，模型在独立跑的时候不知道该不该触发审核、该进哪个阶段。这不是输出质量问题，是流程衔接问题——去掉的步骤里有些不是"模型能推导的"，是"需要显式告诉模型的"。

修复方式不是加回所有步骤，而是在每个精炼版文件末尾加了两行——触发审核的指令和下一阶段的文件名。Round D 用 Policy Engine 复验，全部通过。

更有意思的是 Round A 里的一个细节：模型在被删掉操作步骤的 skill 里，自己推导出了那些步骤。旧版写着"Step 1 用 deep-interview 收集需求，Step 2 分类用户故事"，精炼版只有"理解要建什么、为什么，消除歧义"。模型的分析里自动出现了需求收集 → 用户故事 → 验收标准 → 优先级分类这条推导链——和旧版的步骤一致，但它自己组织的。

这和 Why Articulation 实验里开放式 prompt 的发现完全对应：去掉脚手架后，模型自己组织出了同样的维度[2]。两次实验，不同场景，同一个信号。

![固定轨道 vs 自由推理：两条路径经过相同节点](illustration-1.png)

还有一个附带收益：精炼后总行数从 1617 降到 1360，减少了 16%。在长期使用中，这意味着每次注入上下文的 token 量下降，成本降低。

## 为什么能成功

事后分析，阶段一到阶段五的精炼能成功，和这些阶段的本质特征有关。

阶段一到阶段五都是**创作阶段**——产出需求文档、设计方案、测试计划、测试代码、业务代码。创作需要发散空间。步骤指引给了模型一条固定轨道，模型沿着轨道走，不会出错，但也不会超越轨道。去掉轨道后，模型在原则框定的边界内自由推理，反而能找到更贴合当前任务的路径。

这和"给原则不给示例"是同一个道理。原则告诉模型"目标是什么、边界在哪"，示例告诉模型"这样做就对了"。前者让模型自己思考怎么到达目标，后者让模型复制一条现成的路。

## 递归

用自己发现的方法论改进自己的工具，这是对方法论最好的验证。

V0.7 成功了，说明"原则驱动"不只适用于 prompt 设计，也适用于 skill 整体架构。这个成功是迭代 V0.8 的动力——把同样的策略用在阶段六上。

然后 V0.8 失败了。但失败本身指向一个 V0.7 没有遇到的问题。下一篇讲那个问题。

---

> 系列下一篇：[看不见的空白层——Phase 7 诞生](/posts/tdd-pipeline-phase7-invisible-gap/)

---

## 参考

1. 失之东隅，收之桑榆的实验：[tdd-pipeline-v08-failed-experiment-discovery](/posts/tdd-pipeline-v08-failed-experiment-discovery/)
2. 4 变量 A/B 实验——正面示例为什么有害：[ab-test-positive-examples-harm](/posts/ab-test-positive-examples-harm/)
3. 从 Anthropic 的对齐研究到一个 Prompt 设计思路：[anthropic-alignment-to-prompt-design](/posts/anthropic-alignment-to-prompt-design/)
4. 升级落地——新模板与三个可迁移建议：[why-articulation-upgrade-and-takeaways](/posts/why-articulation-upgrade-and-takeaways/)
5. AI 辅助 TDD 全流程：从需求到代码的完整防线：[ai-tdd-full-pipeline-from-requirements-to-code](/posts/ai-tdd-full-pipeline-from-requirements-to-code/)
