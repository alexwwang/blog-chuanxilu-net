---
title: "AI-Designed Experiments Need Human Review"
slug: experiment-design-review
date: 2026-06-01T10:00:00+08:00
draft: false
tags: ["AI Agent", "experiment methodology", "experiment design review", "ground truth bias", "single-scenario fallacy"]
categories: ["AI Practice", "AI Agent Experiment Methodology"]
series: ["AI Agent Experiment Methodology"]
toc: true
description: "A double-blind experiment succeeded, but design review revealed a rubric biased toward the tested variable and insufficient scenario coverage. Both design flaws were caught by review, not by running the experiment."
cover:
  image: "cover.png"
  alt: "A seemingly perfect experiment report under a magnifying glass revealing two design flaws: rubric bias toward the tested variable and insufficient scenario coverage"
---

> Series: AI Agent Experiment Methodology (Part 3)
> [Previous: The Experiment Design Was Fine, So Why Did the LLM Still Fail?](/en/posts/2026/05/execution-context-design/)

> **TL;DR:** In a double-blind experiment, Variant B won 4/4 scenarios with clean data. But design review revealed the rubric had 3/8 dimensions directly testing the target variable, exceeding the 1/3 ceiling and nearly becoming a self-fulfilling prophecy. In a separate validation, one scenario scored perfectly while another exposed a defect—if we had run only the first, the defect would have shipped. Both traps were caught by reviewing the design, not by running the experiment.

---

## The Experiment Succeeded—Now What?

In the previous article, after fixing the execution context and re-running the experiment, the streamlined variant (B) won 4/4 scenarios and passed the magnitude screen. Ready to adopt B.

My practice is to review the design materials after running experiments—the rubric, ground truth, and scenario definitions. Data is only as good as the design behind it.

This review caught two traps that almost slipped through.

## Trap 1: The Rubric Was Biased Toward What It Was Testing

The double-blind experiment's rubric had 8 scoring dimensions:

| # | Dimension | What It Tests |
|---|-----------|---------------|
| 1 | Prompt Contamination | Output contains stop conditions/counts |
| 2 | Dual-Pass Adherence | Strictly follows three-stage workflow |
| 3 | Severity Accuracy | Severity classification accuracy |
| 4 | Defect Discovery | Discovers all real defects |
| 5 | False Positive Control | No false positives |
| 6 | Suggestion Quality | Specific, actionable suggestions |
| 7 | Critical Opinion | Deep strategic insight |
| 8 | Format Compliance | Follows format requirements |

The variable being tested was **Signal Purity**—removing content from the review skill that the model could infer on its own, to see if the streamlined version performed better.

The rubric had a note at the bottom:

> Items 1–3 test the Signal Purity variable directly (≤ 1/3 of total).

Three dimensions directly tested the Signal Purity variable. The protocol requires variable-related dimensions to not exceed 1/3 of the total. But 3/8 = 37.5%, exceeding the 33.3% ceiling—the rubric violated its own stated rule.

The ground truth file annotation was worse: it declared "Variable-Specific (test Signal Purity impact) — 2 of 8," marking only 2 variable-related dimensions. The actual count was 3. One was missing.

Here's the problem: B was designed following the Signal Purity principle, so it had a natural advantage on dimensions 1–3—because these dimensions ask "did you correctly implement Signal Purity?" Prompt Contamination (did streamlined content remove what should have been deleted?), Dual-Pass Adherence (does the streamlined version still follow the workflow?), Severity Accuracy (are classifications still accurate after streamlining?)—all three dimensions ask the same thing.

![Biased scale: 3 of 8 rubric dimensions weighted toward one side, exceeding the 1/3 red line](biased-rubric-scale.png)

If I hadn't reviewed the rubric and just looked at the total scores: B won 4/4, data looks great, adopt B. But B's victory came almost entirely from its advantage on dimensions 1–3; dimensions 4–8 (general quality) were essentially tied between both variants.

The experiment nearly became a self-fulfilling prophecy: changed Signal Purity, designed a rubric that mainly tests Signal Purity implementation quality, then concluded "the Signal Purity streamlined version is better." Circular reasoning produces a tidy conclusion, but tidy isn't the same as true.

Post-review judgment: B didn't lose to A on general quality dimensions and had clear advantages on variable-related dimensions, so adopting B still holds. But this conclusion was manually verified by checking dimensions 4–8 scores—it wasn't automatically given by the experiment.

## Trap 2: One Scenario Missed It, Two Exposed It

This is a story from a separate validation task.

The Signal Purity change streamlined not just the review skill, but also the main TDD pipeline skill. To verify the streamlined version had no functional regressions, I designed a validation plan: two different coding tasks, run with both streamlined and original versions, comparing output quality.

**Task A:** Token Bucket Rate Limiter—a task where you must think about who to limit, how much, and where the boundaries are.

|  | Design Phase Score |
|--|-------------------|
| Original | 7.5/8 |
| Streamlined | 7/8 |

The streamlined version lost 0.5 points on the system_boundaries dimension—it didn't explicitly define system boundaries during design. The streamlined version happened to remove the part that guided the model to think about system boundaries.

**Task B:** CSV Import Pipeline—a file reading, parsing, and importing task where system boundaries are naturally clear.

Both versions scored perfectly on Task B, no difference. Not because the streamlined version is perfect on Task B—because Task B's scenario doesn't require system boundary thinking at all, so that dimension was never tested.

If the validation plan had only chosen Task B-type scenarios, the system_boundaries gap would never have been exposed. The gap still exists—it would appear in real usage when encountering tasks that require boundary thinking.

Two tasks, two results. You don't know which task will expose the problem, so you need to run multiple different task types. This isn't abstract methodology, it's engineering reality.

![Hidden gap: left path looks flat and perfect, right path forks into a pit—looking only at the left path misses the problem](hidden-gap-single-scenario.png)

## Why Both Traps Can Only Be Caught by Design Review

Both traps share a common pattern: the experiment finished, the data looked normal, but the design itself was flawed.

Ground truth bias triggers no errors. The scorer runs normally against the biased rubric, scores all 8 dimensions, the scores look reasonable, B really is higher than A. But the score difference comes from the rubric being biased toward B's design principles, not because B is better in all aspects. Double-blind protocols, secret mapping, independent scorers—these solve execution contamination, they don't guarantee the rubric itself is fair.

Single-scenario claims work the same way. Run one scenario, data looks perfect, scorer gives full marks. You don't know another scenario would expose the problem, because you didn't run it. The protocol requires ≥3 scenarios, but if your 3 happen to be the same type, the problem still slips through.

Among the five failure modes documented in the double-blind experiment skill (phantom delivery, self-scoring, single-scenario claims, ground truth favoritism, and context contamination), ground truth favoritism and single-scenario claims are both design-phase problems. The first two articles covered ANSI contamination, scorer aggregation errors, and phantom delivery—these are execution pipeline problems that protocols can constrain. But rubric dimension distribution, GT variable annotations, and scenario diversity—these happen where the protocol doesn't check.

## The Protocol Has Rules, But No Teeth

Both traps share a deeper root cause: **the protocol has rules, but no enforcement.**

Rubric bias: the protocol explicitly states the `≤ 1/3` rule, but has no checking mechanism. The rubric violated the rule, and the protocol didn't catch it. Single-scenario claims: the protocol requires `≥3` scenarios, but only constrains quantity, not diversity. Three scenarios of the same type all pass the check.

Rules without enforcement are no rules at all.

## Three Checks That Should Be Protocol Gates

Post-hoc review saved this experiment, but "remember to review" isn't reliable engineering practice. The better answer is to harden these checks into the protocol as pre-experiment gates—before the experiment runs, these checks must pass or error out, and the experiment cannot proceed.

**1. Rubric bias gate:** Automatically count variable-specific dimensions; reject the rubric if it exceeds 1/3. When testing "is the streamlined version better?", the rubric cannot have more than 1/3 of dimensions asking "did you correctly implement streamlining?"

**2. Ground truth annotation verification:** The declared variable-specific count must match the actual count. The protocol must explicitly verify this; if the annotation is wrong, send it back for correction—don't wait until reviewing results to discover the mismatch.

**3. Scenario diversity gate:** Not just `≥3`, but require coverage of at least 2 different requirement types. Three scenarios of the same type are worse than two of different types; diversity matters more than quantity.

These three checks aren't for designers to "remember to review"—they should work like type checks: fail the check, error out, the experiment doesn't run. Humans are unreliable; checklists are reliable. Turning review into gates is safer than turning review into habit.

Working on tdd-pipeline, this lesson keeps recurring: protocols prevent most execution errors, but design-level gaps must be plugged by stricter protocols—not by relying on people, but by having the protocol enforce itself.

---

## References

1. [Double-Blind Experiment Skill Source (includes three-tier protocol and five failure modes)](https://github.com/alexwwang/tdd-pipeline/blob/main/experiment/SKILL.md)
2. [TDD Pipeline Project Repository](https://github.com/alexwwang/tdd-pipeline)
3. [Previous: The Experiment Design Was Fine, So Why Did the LLM Still Fail?](/en/posts/2026/05/execution-context-design/)
4. [Part 1: How to Validate Skill Changes with Double-Blind Experiments](/posts/double-blind-experiment-ai-prompt-validation/)
