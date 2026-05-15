---
title: "4 变量 A/B 实验——正面示例为什么有害"
slug: "ab-test-positive-examples-harm"
date: 2026-05-15T10:00:00+08:00
draft: false
description: '为什么给 AI 看正面示例反而降低输出质量？一次 4 变量 A/B 实验，测了 Why Articulation 的结构、语气、位置和示例类型，发现正面示例有害——和 Anthropic 的对齐研究结论一致。'
tags: ["AI", "prompt 工程", "A/B 测试", "TDD", "Why Articulation"]
categories: ["AI 实践", "为什么让 AI 动手之前先说 why"]
series: ["为什么让 AI 动手之前先说 why"]
toc: true
cover:
  image: "cover.png"
  alt: "左侧印章复制相同图案，右侧自由笔触独立思考，中间红色叉号表示模仿路径不可取"
---

> **TL;DR：** 四变量 A/B 实验测试 Why Articulation 的结构、语气、位置和示例。正面示例反而有害——模型倾向模仿而非独立思考。开放式 prompt 方向性提升质量，同时节省 33% token。
>

> 系列：为什么让 AI 动手之前先说 why（第二篇）<br>
> [上一篇：从 Anthropic 的对齐研究到一个 Prompt 设计思路](/posts/anthropic-alignment-to-prompt-design/)

## 上篇回顾

Anthropic 的对齐研究[1]提出了一个洞察：教模型"为什么"比教它"做什么"更有效。基于这个思路，我在 TDD Pipeline 里设计了 Why Articulation 机制——强制模型在动手之前先解释自己的理解。初步效果不错，但我对模板的最优设计完全没有把握。用三个问题分别引导 AI 回答"目标是什么、风险在哪、为什么这个方案有效"，这是最优结构吗？语气太硬了吗？正面例子有帮助吗？

这些问题光想没用。我做了 4 变量的 A/B 实验。本文是实验全过程和数据分析。

## TDD Pipeline 与 Why Articulation

我的 TDD Pipeline 是一个六阶段的严格工作流：产品设计 → 技术方案 → 测试方案 → 测试代码 → 业务代码 → 预发布测试。每个阶段都有 Ralph loop 代码审查。Pipeline 的原则很简单：写不出一个失败的测试，说明你还没理解到可以动手的程度。

Why Articulation 是这个 Pipeline 的"思考门"。每个阶段文件顶部都有一段要求，模型必须先回答才能开始工作。初版是三个显式问题：

```markdown
## ⛔ Prerequisite: Why Articulation (MUST complete before Phase N execution)

Before any work in this phase, you must explicitly answer the three questions below.
This is not optional commentary — without these answers, you MUST NOT proceed to execution.

**1. What is this phase's goal? What does it protect?**
**2. Where are the complexity and risk points in this task?**
**3. How do I plan to proceed, and why will this approach achieve the goal?**
```

设计意图来自 Anthropic "Teaching Claude Why"[1] 的启发：不是告诉模型"先写测试再写代码"（what），而是强迫它自己 explain why。

这个模板跑了一段时间，我攒下了四个设计疑问：

1. **结构**：显式三问会不会给模型思维上的惰性，改为开放式 "articulate your understanding" 会更好还是更差？
2. **语气**：⛔ 强制（MUST NOT proceed）太硬，改为 💡 建议（strongly encouraged）是否同样有效？
3. **位置**：放在文件顶部（模型看到的第一件事）vs 放在 Objective 之后（模型了解上下文后再思考）？
4. **示例**：只有反面例子 vs 加上正面例子？

四个问题，四个变量，需要数据说话。

## 实验设计

我采用控制变量法，每次只改一个变量，不是全因子设计（2⁴=16 组太多，跑不动）。一共 5 个 condition：

- **Control**：初版模板，显式三问 + 强制语气 + 文件顶部 + 无正面示例
- **V1**：显式三问 → 开放式 prompt（结构变量）
- **V2**：⛔ MUST NOT → 💡 strongly encouraged（语气变量）
- **V3**：文件顶部 → Objective 之后（位置变量）
- **V4**：加正面示例（示例变量）

三个 mock task，覆盖不同难度梯度：

- **Task 1**（简单）：URL validation，Phase 3 测试方案
- **Task 2**（中等复杂度）：分布式 rate limiter，Phase 3 测试方案
- **Task 3**（early-stop 场景）：Ralph loop，Phase 4

总计 14 次运行。为什么不是 5×3=15？V3 改的是 Why Articulation 块在文件中的位置（顶部 vs Objective 之后）。但 Task 3 测的是 Ralph loop 的 early-stop 触发——这部分内容在 ralph-review-loop.md 里，Why Articulation 块不在那个文件里，位置变量对它没有影响。所以 V3 的 Task 3 和 Control 的 Task 3 是同一次运行，省了一轮。

评分维度四个：Trigger rate（二值，有没有触发 Why Articulation）、Quality（1-4 ordinal scale）、Token overhead、Early-stop trigger。其中 Quality 是重点，rubric 如下：

| 分数 | 质量特征（达到的最高水平，高分隐含低分要求全部满足） |
|------|------|
| 1 | Template-filling：复述任务描述，只列步骤不给理由 |
| 2 | Surface-level：给出理由，但只停留在通用风险层面 |
| 3 | Substantive：指出具体风险，给出任务相关的分析和清晰理由 |
| 4 | Insightful：识别非显而易见的风险，比较多种方案，分析下游影响 |

**这次实验的局限**：每个 condition 每个 task 只跑了一次（n=1），这些是方向性信号，不是统计显著的结论。Task 1 用了 coder subagent，Task 2-3 用了 oracle subagent，agent 类型本身是个混淆变量。只测了单模型（GLM-5.1），不一定泛化到其他模型。评分非盲——orchestrator 知道每个输出属于哪个 condition，可能有评分偏差。ordinal scale（1-4）求平均值在统计上也有问题。

这不是一篇声称"科学验证"的文章，只是我在有限资源下做的方向性探索，结论是"值得进一步验证的信号"，不是定论。

## 四个结果

先看汇总数据：

| Condition | Task 1 | Task 2 | Task 3 | Avg Quality | Token 变化 |
|-----------|--------|--------|--------|-------------|------------|
| Control   | 3      | 4      | 3      | 3.33        | —          |
| V1        | 3      | 4      | 3.5    | 3.50        | -33%       |
| V2        | 3      | 3      | 3      | 3.00        | -8%        |
| V3        | 3.5    | 3      | 3*     | 3.17        | 0%         |
| V4        | 3      | 3      | 3      | 3.00        | +50%       |

*V3 Task 3 = Control（位置变化对该文件无影响）

Trigger rate 所有 condition 都是 100%。模型在每种设计下都执行了 Why Articulation，区别全在质量。

### V1：开放式赢了——但赢得不多

V1 把显式三问替换成了一段开放式 prompt：

```markdown
Before any work in this phase, articulate your understanding of this task:
explain what this phase protects, where the key risks lie, and why your
chosen approach will achieve the goal. Do not proceed to execution until
you have produced this reasoning.
```

结果 +0.17，token 还省了 33%。在 Task 2（分布式 rate limiter）产生了最深的替代方案分析——hazard-driven vs component-driven 的测试结构选择，contract-first vs coverage-first 的策略权衡。Task 3（early-stop）识别了具体的非显而易见风险：false-red tests、timing attacks、wrong-interface imports。

一个有意思的发现：模型自己组织了回应结构，围绕的恰好就是目标、风险、方案三个维度，和强制回答的三问引导方向一致——说明不需要脚手架也能达到目的。

不过，+0.17 这个数字并不显著：它完全来自 Task 3 的 0.5 点提升（3.5 vs 3）。换一个评委可能结果会不同，所以 V1 在大方向上说明"开放式至少不比显式三问差，而且更省 token"——这是更诚实的表述。

### V2：强制语气不可削弱

⛔ "MUST NOT proceed" 改为 💡 "strongly encouraged"。Trigger rate 没变，100%。但质量掉了。

Task 2 最明显：Control 拿到 4 分，V2 只有 3 分。软化的语言可能降低了感知重要性，模型不那么认真对待了。

这个结果有价值。它说明语气变量影响的是质量，不是触发率。如果你只看"模型有没有执行 Why Articulation"这个指标，软硬语气没差别。但执行了和执行好了是两件事。

### V3：位置影响微弱

从文件顶部移到 Objective 之后。Task 1 略有提升（3.5 vs 3），Task 2 明显下降（3 vs 4）。净效果不值得改位置。

位置变量的效果因任务而异，没有一致的方向性信号。维持原设计就好。

### V4：正面例子有害

这是最重要的发现。

在反面例子之前，我加了一段正面示例：

```markdown
### ✅ What high-quality Why Articulation looks like
- "Phase 3 protects test-requirement alignment. For this URL validation task,
  the key risk is testing only happy-path URLs and missing edge cases like
  unicode domains, scheme-relative URLs, and IPv6 literals..."
```

结果：三个 Task 全是 3，一致性最高，但质量 -0.33。token 开销涨了 50%。花了更多 token，质量反而更低。

## V4 深挖：正面示例为什么有害

V4 的结果让我困惑了一阵。给模型看好例子，怎么反而变差了？

想明白之后，它和 Anthropic 的发现高度一致。

Anthropic 在 "Teaching Claude Why"[1] 中有一个反复出现的观察：demonstrations（示例）不如 principles（原则）有效。当你给模型一个正面示例，模型倾向于走模仿捷径——复制示例的表面模式，而不是独立推理。

V4 恰恰重现了这个现象。正面示例讲的是 URL validation、test planning 的具体场景。模型看到了这个示例之后，产出的分析在结构和措辞上明显向示例靠拢——同质化、安全、不出错，但也缺乏对当前任务的真正深入思考。

换个说法：正面示例不是在"教"模型怎么思考，而是在给它一个可以不思考的出口。模型不再需要从零开始分析当前任务的风险和方案，它只需要把示例的框架套上去。

这和 V1 的结果形成了对照。V1 去掉了脚手架（强制回答的三问），模型反而自己组织了更深入的分析。V4 加了正面示例，模型的分析反而变得同质化。两个变量的数据指向同一个方向：给模型的约束越少、越抽象，模型越倾向独立推理；给的约束越具体、越像"答案模板"，模型越倾向走捷径。

这不是说所有示例都有害。实验测的是一个特定场景——在要求模型做独立推理的 prompt 里加示例。在分类、格式化、代码生成等场景下，few-shot examples 是明确有效的。但「**先思考再行动**」这个场景不一样——**它的目标是让模型生成原创推理，不是复制模式**。

值得强调：这是只有 3 个样本的定性实验给出的方向，不是具有统计显著性的结论。但它和 Anthropic 在不同任务、不同模型上的发现形成了交叉验证，这让它的可信度比孤立的一组数据要高一些。

## 下一步

实验给出了几个方向性信号：开放式 prompt 至少不差于显式三问，强制语气影响质量，位置不重要，正面示例有害。基于这些结果，我升级了 Why Articulation 的模板设计——新版模板长什么样，每条改动背后的数据，以及可以迁移到其他 prompt 工程场景的建议，会继续在下一篇讨论。

---

**参考**

1. Anthropic, "Teaching Claude Why", 2026. [anthropic.com/research/teaching-claude-why](https://www.anthropic.com/research/teaching-claude-why)
