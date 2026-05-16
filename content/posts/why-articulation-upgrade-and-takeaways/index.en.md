---
title: "The Upgrade — New Template and Three Transferable Lessons"
slug: "why-articulation-upgrade-and-takeaways"
date: 2026-05-16T10:00:00+08:00
draft: false
description: "Upgrading the Why Articulation template based on A/B test data: replacing explicit questions with open-ended reasoning plus self-check, keeping mandatory tone and negative-only examples. Three transferable prompt engineering lessons."
tags: ["AI", "prompt engineering", "AB testing", "TDD", "Why Articulation"]
categories: ["AI Practice", "Why Make AI Articulate Why Before Acting"]
series: ["Why Make AI Articulate Why Before Acting"]
toc: true
cover:
  image: "cover.png"
  alt: "Three objects on warm cream: a compass, a crossed-out stamp, and a blank card with a hand-drawn arrow"
---

> **TL;DR:** Before-and-after comparison of the upgraded Why Articulation template, plus three transferable lessons: give principles not examples, lock critical steps with mandatory tone, and trust the model's self-organization. Experiment limitations included.

> Series: Why Make AI Articulate Why Before Acting (Article 3)<br>
> [Previous: A 4-Variable A/B Test — Why Positive Examples Harm Prompt Performance](/posts/ab-test-positive-examples-harm/)

## Recap

[Article 1](/posts/anthropic-alignment-to-prompt-design/) started from Anthropic's alignment research: teaching a model *why* rather than *what* cut misalignment from 22% to 3% (about 7×), and achieved equivalent results with 1/28 the data [1]. I adapted this into Why Articulation — a mechanism that forces AI to explain purpose, risks, and approach before writing any code.

[Article 2](/posts/ab-test-positive-examples-harm/) tested four template variables with A/B experiments. Removing explicit questions: quality nudged up, tokens dropped 33%. Adding positive examples: quality dropped 0.33 points, tokens rose 50%. Softening tone: quality dropped 0.33 points. The optimal configuration based on single-variable tests was no scaffolding + mandatory tone + negative-only examples.

This post lands the findings: the upgraded template, change-by-change explanations, and three transferable recommendations.

## Before vs. After

The new version makes one structural change: replacing the explicit three-question prompt with a two-stage design — open-ended reasoning first, self-check fallback second. Everything else stays — ⛔ mandatory tone, top-of-file position, negative-only examples, risk hints. Here are the specifics.

**Old version (V0) — the core section:**

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

**New version (V1) replaces it with:**

```markdown
Before any work in this phase, articulate your understanding of this task.
Do not proceed to execution until you have produced this reasoning.

After articulating, check: did you address what this phase protects,
where the key risks lie, and why your approach will work?
If not, supplement before proceeding.
```

What stays — risk hints and negative examples remain unchanged:

```markdown
> **Phase N risk hint**: <phase-specific hint>

### ❌ What superficial Why Articulation looks like
- <phase-specific negative example>
- Restating the task description ("Phase N's goal is to...")
- Listing steps without rationale ("I'll do A, then B")
- Dodging risk assessment ("Risks are low, just proceed normally")
```

The most visible change: the explicit three-question prompt (with guiding hints under each) becomes a two-stage design. The first stage is purely open-ended — the model thinks freely. The second stage is a self-check — ensuring key dimensions aren't missed. What doesn't change: ⛔ mandatory tone, top-of-file position, negative-only examples, risk hints. Every decision has data behind it.

## Change-by-Change

**Explicit questions → open-ended reasoning plus self-check.** The old version broke "goal, risk, approach" into three numbered questions, each with a guiding hint underneath. The V1 experiment removed this structure — a single sentence, "articulate your understanding of this task," purely open-ended, no dimensions specified. The model organized the same three dimensions on its own, quality nudged up (+0.17), tokens dropped 33%. The explicit questions weren't helping the model think. They were constraining it.

But purely open-ended has a risk: the model might miss a critical dimension. In the experiment it happened to cover goal, risk, and approach every time — but that's an n=3 sample. No guarantee it holds generally. So the final template adds a self-check after the open-ended stage: "Did you cover what this phase protects, where the risks lie, and why your approach works? If not, supplement." Let it reason freely first, then catch gaps with a lightweight backstop.

**⛔ Mandatory tone stays.** The V2 experiment replaced "MUST NOT proceed" with "strongly encouraged." Trigger rate didn't change (100% in both). But quality dropped 0.33. Mandatory tone affects depth, not compliance. The model executed Why Articulation under both conditions, but analyzed more thoroughly under the mandatory one. So the new version keeps ⛔ and "Do not proceed to execution until" exactly as they were.

**Top position stays.** V3 moved Why Articulation from the top of the file to after the Objective section. Quality dropped 0.17. Token overhead unchanged. Net effect: negative. Position stays.

**Negative-only examples stay.** V4 added positive examples alongside the negatives. Quality dropped 0.33. Tokens rose 50%. Positive examples create an imitation shortcut — the model maps the example's pattern onto the current task instead of analyzing independently. Negative examples are sufficient: they tell the model what doesn't count as adequate, without prescribing what does. That blank space is exactly where the model's reasoning ability operates.

## Three Transferable Lessons

The decisions above are specific to Why Articulation. Below, I abstract the findings into three recommendations that apply to any prompt engineering scenario.

### 1. Give Principles, Not Examples

In your prompt, describe the thinking dimensions you expect ("explain what this protects, where the risks lie, and why your approach works") rather than showing "what good output looks like." Positive examples seem helpful, but the model takes an imitation shortcut — it maps the example's pattern onto the current task instead of doing independent analysis.

This isn't just the V4 finding. Anthropic's "Teaching Claude Why" [1] research reached the same conclusion: teaching principles (constitution documents, ethical reasoning) outperformed teaching behaviors (correct-answer examples) by roughly 7×. We replicated the same pattern at the prompt level.

### 2. Lock Critical Steps with Mandatory Tone

Changing ⛔ "MUST NOT proceed" to 💡 "strongly encouraged" didn't affect trigger rate, but quality dropped. Mandatory tone affects how seriously the model takes the task, not whether it complies.

If your prompt has steps that *must* happen — writing a test plan before coding, reviewing before committing — use mandatory tone. Not because AI disobeys soft language, but because mandatory phrasing makes it dig deeper. The model does the thing under both "should" and "must." But "must" makes it do the thing more thoroughly.

### 3. Trust the Model's Self-Organization

I assumed the explicit three-question prompt gave the model a useful structure. The experiment surprised me: removing the explicit structure let the model organize the same three dimensions (goal, risk, approach) on its own, and it analyzed more deeply on complex tasks.

This recommendation is the flip side of the first. Giving principles is "tell it what to think about." Giving structure is "tell it how to think." Scaffolding isn't useless — but it has a cost. It constrains the directions the model might explore. Describe the dimensions you want, then let go. The model often produces better results when you stop arranging its thinking for it. Input (what you provide), execution (how you lock it), structure (how much you let go) — the fewer decisions you make for the model, the more it has to think on its own, and self-generated thinking tends to be higher quality.

## Limitations of This Experiment

The recommendations above have directional experimental support, but no statistical testing. The limitations must be stated clearly.

**Tiny sample size.** Each data point ran once (n=1 per task per condition). LLM outputs are stochastic. A single run could be noise. V1's "advantage" (+0.17) comes entirely from a half-point difference on one task.

**Inconsistent agent types.** Task 1 used a coder subagent; Tasks 2–3 used an oracle subagent. Different agents have different reasoning styles, introducing a potential confound.

**Single-model test.** Only GLM-5.1 was tested. Whether these conclusions generalize to Claude, GPT, Gemini, or other models is unknown.

**Non-blind scoring.** The evaluator knew which condition produced each output. Implicit bias is possible — even with conscious effort to stay objective.

**Ordinal scale averaging.** Averaging 1–4 ordinal data is statistically questionable. Strictly speaking, non-parametric tests should be used — but with sample sizes this small, testing is meaningless anyway.

These limitations mean the findings are directional signals, not confirmations. They point in clear directions (de-scaffolding beats explicit structure, positive examples harm, mandatory tone has a depth effect), but if you apply them in your own context, run a small-scale validation first.

## Closing

Three posts, one thread: Anthropic's alignment research discovered that teaching *why* beats teaching *what*. I tested that insight at the prompt level and confirmed it holds. Then I upgraded the template based on data. The starting point was someone else's research. The landing point is something you can use directly.

One more thing worth mentioning: Anthropic isn't the only group reaching this conclusion. Wang et al. [2] independently arrived at highly consistent findings in their work on experience representation — they showed through 4,590 controlled experiments that a compact control-oriented representation (Gene, ~230 tokens) outperformed a full documentation package (Skill, ~2,500 tokens) by +3.0pp vs. -1.1pp. Adding documentation materials back to the compact representation (including examples and API notes) actually weakened results. This maps precisely onto our findings: less is more. Adding more material doesn't always make things better.

---

**References**

1. Anthropic, "Teaching Claude Why", 2026. [anthropic.com/research/teaching-claude-why](https://www.anthropic.com/research/teaching-claude-why)
2. Wang et al., "From Procedural Skills to Strategy Genes: Towards Experience-Driven Test-Time Evolution", arXiv:2604.15097, 2026. [arxiv.org/abs/2604.15097](https://arxiv.org/abs/2604.15097)
