---
title: "A 4-Variable A/B Test — Why Positive Examples Harm Prompt Performance"
slug: "ab-test-positive-examples-harm"
date: 2026-05-15T10:00:00+08:00
draft: false
description: "Why do positive examples make AI output worse? A 4-variable A/B test on Why Articulation structure, tone, position, and example type found that demonstrations hurt — echoing Anthropic's alignment research."
tags: ["AI", "prompt engineering", "A/B testing", "TDD", "Why Articulation"]
categories: ["AI Practice", "Why Make AI Articulate Why Before Acting"]
series: ["Why Make AI Articulate Why Before Acting"]
toc: true
cover:
  image: "cover.png"
  alt: "Left: a stamp copying identical patterns. Right: freeform marks for independent thinking. Red X marks the imitation path as wrong"
---

> **TL;DR:** A 4-variable A/B test on Why Articulation — structure, tone, position, and examples. Positive examples made output worse. The model imitated instead of reasoning. Open-ended prompts improved quality directionally and cut tokens by 33%.

> Series: Why Make AI Articulate Why Before Acting (Article 2)<br>
> [Previous: From Anthropic's Alignment Research to a Prompt Design Insight](/posts/anthropic-alignment-to-prompt-design/)

## Where We Left Off

Anthropic's alignment research [1] landed on a sharp insight: teaching a model *why* beats telling it *what*. I took that idea and built Why Articulation into my TDD Pipeline — a mechanism that forces the model to explain its understanding before it writes any code. Early results looked good.

But I had no confidence in the template design. Three explicit questions guiding the model through "goal, risk, approach" — was that the best structure? Was the tone too aggressive? Would positive examples help?

Guessing wouldn't settle it. I ran a 4-variable A/B test. This post walks through the full experiment and the data.

## The TDD Pipeline and Why Articulation

My TDD Pipeline runs through six strict phases: product design → technical design → test plan → test code → business code → pre-release testing. Each phase goes through a Ralph loop for code review. The pipeline has one principle: if you can't write a failing test, you don't understand the problem well enough to start coding.

Why Articulation is the "thinking gate" inside this pipeline. Every phase file has a block at the top. The model must answer it before doing any work. The original version used three explicit questions:

```markdown
## ⛔ Prerequisite: Why Articulation (MUST complete before Phase N execution)

Before any work in this phase, you must explicitly answer the three questions below.
This is not optional commentary — without these answers, you MUST NOT proceed to execution.

**1. What is this phase's goal? What does it protect?**
**2. Where are the complexity and risk points in this task?**
**3. How do I plan to proceed, and why will this approach achieve the goal?**
```

The design comes straight from Anthropic's "Teaching Claude Why". Instead of telling the model "write tests first, then code" (a what), I force it to explain *why* on its own.

This template ran for a while. Four design questions piled up:

1. **Structure**: Do explicit questions create lazy thinking? Would an open-ended "articulate your understanding" do better — or worse?
2. **Tone**: Is ⛔ "MUST NOT proceed" too harsh? Would 💡 "strongly encouraged" work just as well?
3. **Position**: Top of the file (first thing the model sees) vs. after the Objective (model gets context, then thinks)?
4. **Examples**: Negative examples only vs. adding positive examples?

Four questions. Four variables. Time for data.

## Experiment Design

I used the controlled variable method — change one variable at a time. A full factorial design (2⁴ = 16 groups) was too many runs. Five conditions total:

- **Control**: original template — structured three-question prompt + mandatory tone + top of file + no positive example
- **V1**: structured three-question prompt → open-ended prompt (structure variable)
- **V2**: ⛔ MUST NOT → 💡 strongly encouraged (tone variable)
- **V3**: top of file → after Objective (position variable)
- **V4**: add positive example (example variable)

Three mock tasks, spanning different difficulty levels:

- **Task 1** (simple): URL validation, Phase 3 test plan
- **Task 2** (medium complexity): distributed rate limiter, Phase 3 test plan
- **Task 3** (early-stop scenario): Ralph loop, Phase 4

Total: 14 runs. Why not 5 × 3 = 15? V3 changes where the Why Articulation block sits in the file (top vs. after Objective). But Task 3 tests the Ralph loop's early-stop trigger — that logic lives in ralph-review-loop.md, which has no Why Articulation block. The position variable doesn't apply to it. V3 Task 3 and Control Task 3 are the same run. Saved one round.

Four scoring dimensions: Trigger rate (binary — did it fire?), Quality (1–4 ordinal scale), Token overhead, and Early-stop trigger. Quality is the focus. Here's the rubric:

| Score | Quality Characteristics (highest level achieved; higher scores imply all lower requirements met) |
|-------|------|
| 1 | Template-filling: restates the task, lists steps without reasons |
| 2 | Surface-level: gives reasons, but stays at generic risk level |
| 3 | Substantive: identifies specific risks, provides task-relevant analysis with clear reasoning |
| 4 | Insightful: spots non-obvious risks, compares multiple approaches, analyzes downstream impact |

**Limitations of this experiment**: Each condition ran once per task (n=1). These are directional signals, not statistically significant conclusions. Task 1 used a coder subagent; Tasks 2–3 used an oracle subagent — agent type is a confounding variable. I tested a single model (GLM-5.1); results may not generalize. Scoring was non-blind — the orchestrator knew which condition produced each output, so rating bias is possible. Averaging ordinal scores (1–4) is also statistically questionable.

This isn't a "scientifically verified" finding. It's a directional exploration with limited resources. The conclusions are "signals worth further testing," not final answers.

## Four Results

Summary data first:

| Condition | Task 1 | Task 2 | Task 3 | Avg Quality | Token Change |
|-----------|--------|--------|--------|-------------|--------------|
| Control   | 3      | 4      | 3      | 3.33        | —            |
| V1        | 3      | 4      | 3.5    | 3.50        | -33%         |
| V2        | 3      | 3      | 3      | 3.00        | -8%          |
| V3        | 3.5    | 3      | 3*     | 3.17        | 0%           |
| V4        | 3      | 3      | 3      | 3.00        | +50%         |

\*V3 Task 3 = Control (position change has no effect on that file)

Trigger rate hit 100% across every condition. The model always executed Why Articulation. The difference was all in quality.

### V1: Open-Ended Won — Barely

V1 replaced the three explicit questions with an open-ended prompt:

```markdown
Before any work in this phase, articulate your understanding of this task:
explain what this phase protects, where the key risks lie, and why your
chosen approach will achieve the goal. Do not proceed to execution until
you have produced this reasoning.
```

Result: +0.17 in quality, and 33% fewer tokens. On Task 2 (distributed rate limiter), it produced the deepest analysis of alternatives — hazard-driven vs. component-driven test structure, contract-first vs. coverage-first strategy trade-offs. On Task 3 (early-stop), it spotted non-obvious risks: false-red tests, timing attacks, wrong-interface imports.

One finding stuck out. The model organized its response around goal, risk, and approach on its own — the same three dimensions the mandatory three-question prompt was designed to elicit. The scaffolding wasn't necessary.

But let's be honest about that +0.17. It comes entirely from Task 3's 0.5-point bump (3.5 vs. 3). A different evaluator might score it differently. The honest takeaway: the open-ended prompt is at least as good as the structured three-question prompt, and it costs fewer tokens.

### V2: Mandatory Tone Cannot Be Softened

⛔ "MUST NOT proceed" became 💡 "strongly encouraged." Trigger rate didn't budge — still 100%. But quality dropped.

Task 2 showed it clearly: Control scored 4, V2 scored 3. Softer language likely made the requirement feel less important. The model took it less seriously.

This result matters. It shows that tone affects quality, not trigger rate. If you only measure "did the model do Why Articulation?" — soft and hard tone look identical. Doing it and doing it well are two different things.

### V3: Position Barely Matters

Moved from top of file to after the Objective. Task 1 improved slightly (3.5 vs. 3). Task 2 dropped noticeably (3 vs. 4). Net effect: not worth changing.

Position effects varied by task with no consistent directional signal. Keep the original design.

### V4: Positive Examples Harm Output

This is the most important finding.

Before the negative examples, I added a positive example:

```markdown
### ✅ What high-quality Why Articulation looks like
- "Phase 3 protects test-requirement alignment. For this URL validation task,
  the key risk is testing only happy-path URLs and missing edge cases like
  unicode domains, scheme-relative URLs, and IPv6 literals..."
```

Result: all three tasks scored 3. Most consistent condition — but quality dropped by 0.33. Token overhead went up 50%. More tokens. Worse output.

## Why Positive Examples Harm: Digging Into V4

V4 puzzled me for a while. How does showing the model a good example make it worse?

Once I thought it through, the answer lined up perfectly with Anthropic's findings.

Anthropic's "Teaching Claude Why" makes one observation over and over: demonstrations fall short of principles. When you give a model a positive example, it takes an imitation shortcut. It copies surface patterns instead of reasoning independently.

V4 reproduced exactly this. The positive example covered URL validation and test planning. After seeing it, the model's output drifted toward the example in structure and phrasing — homogeneous, safe, error-free, but lacking genuine depth for the task at hand.

Put another way: the positive example wasn't "teaching" the model how to think. It was giving the model an escape hatch from thinking. The model no longer needed to analyze the current task's risks and approach from scratch. It just dressed the example's framework in new clothes.

This contrasts sharply with V1. V1 removed scaffolding (the mandatory three-question prompt), and the model organized deeper analysis on its own. V4 added a positive example, and the model's analysis became homogeneous. Both variables point the same direction: the less concrete the guidance — the more abstract the constraint — the more the model leans into independent reasoning. The more the guidance looks like an "answer template," the more the model takes shortcuts.

This doesn't mean all examples are harmful. The experiment tested one specific scenario: adding examples to a prompt that demands independent reasoning. In classification, formatting, and code generation, few-shot examples are clearly effective. But the **"think before you act"** scenario is different. **The goal is to make the model produce original reasoning — not to copy patterns.**

A caveat worth emphasizing: this is a directional signal from a qualitative experiment with three samples, not a statistically significant conclusion. But it cross-validates Anthropic's findings from different tasks and different models. That makes it more credible than an isolated data point.

## What's Next

The experiment produced several directional signals: open-ended prompts are at least as good as structured three-question prompts, mandatory tone affects quality, position doesn't matter, and positive examples are harmful. Based on these results, I upgraded the Why Articulation template. The next post covers what the new template looks like, the data behind each change, and recommendations you can transfer to other prompt engineering scenarios.

---

**References**

1. Anthropic, "Teaching Claude Why", 2026. [anthropic.com/research/teaching-claude-why](https://www.anthropic.com/research/teaching-claude-why)
