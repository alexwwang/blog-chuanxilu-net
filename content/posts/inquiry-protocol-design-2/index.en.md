---
title: "Seven Conditions to Keep AI's 5-Why from Going Off the Rails"
slug: "inquiry-protocol-design-2"
date: 2026-05-05T17:00:00+08:00
draft: false
description: "Designing termination conditions for an inquiry protocol: T1–T3 are floor conditions (ensure AI goes deep enough), HC1–HC4 are guardrails (prevent the inquiry from spiraling). T2's preventive counterfactual check is the most important insight."
tags: ["AI", "5-Why", "root cause analysis", "inquiry protocol", "TDD"]
categories: ["AI Practice", "AI Root Cause Diagnosis", "Inquiry Protocol Design"]
series: ["Taming AI Coding Agents with TDD", "AI Root Cause Diagnosis"]
toc: true
cover:
  image: "cover.png"
  alt: "Seven conditions to keep AI's 5-Why from going off the rails"
---

> **TL;DR:** The inquiry protocol sets seven conditions to keep AI's 5-Why on track: T1–T3 are floor conditions (can't stop until all three are met), HC1–HC4 are guardrails (prevent the process from spiraling). T2's preventive counterfactual check is the most important design — preventive framing forces the inquiry to go deep, while counterfactual questions deliberately construct negation scenarios to counter confirmation bias.

[← Previous post](/posts/inquiry-protocol-design-1/) The last post diagnosed three problems when AI runs 5-Why: stopping too early (depth insufficient), single-path tracking (breadth insufficient), and confirmation bias (reasoning bias). These three are independent but tend to show up together — a shallow conclusion becomes an anchor, which simultaneously compresses the exploration space and biases evidence selection. This post designs the inquiry protocol: encoding the tacit judgment of "when to stop, when to keep going" that human experts use, into explicit rules that bring AI's reasoning quality up to the standard 5-Why actually requires.

## Three Floor Conditions

The last post identified three problems: insufficient depth, insufficient breadth, and reasoning bias. They have different natures, so they need different control directions.

Insufficient depth is AI's default behavior — it just stops early. The fix is to push downward: set a minimum threshold, and don't let it stop until the threshold is met. I call these **floor conditions** (T1–T3) — all three must be satisfied before the inquiry can terminate.

Insufficient breadth and reasoning bias are risks that emerge during the process — the deeper the inquiry goes, the more likely AI is to chase a single thread or seek only confirming evidence. The fix is to pull inward: constrain the scope of inquiry and how evidence is used. I call these **guardrails** (HC1–HC4).

The two groups solve problems in opposite directions: floors push down, guardrails pull in. Let's start with the three floor conditions.

### T1: Actionability

The root cause must correspond to a concrete fix action.

This condition mainly constrains stopping too early. If the conclusion you reach doesn't map to a specific fix, you haven't gone deep enough. For example, if your conclusion is "the developer wasn't careful" — that doesn't correspond to any concrete fix action, so you can't stop there.

### T2: Preventive Counterfactual Check

T2 requires a counterfactual question to check whether the conclusion you've reached is deep enough — "if X didn't exist, would this bug still happen?" But the angle of the question determines whether the check actually does its job.

Suppose the root cause you've found is "missing a null check." You could ask:

> "If we'd added the null check, would this error still have occurred?"

The answer is obviously no. The check passes — but the root cause hasn't been reached. You've only patched this one instance. Next time, a similar null pointer bug will show up somewhere else.

Try a different angle:

> "If we had a systematic null-handling mechanism (say, a type system), would this class of null pointer bugs still occur?"

If the answer is no, you've reached a system-level root cause. If the answer is "yes, they still would, because null pointers aren't something validation can prevent" — then the root cause you've found isn't deep enough, or you're chasing the wrong direction.

The difference between these two angles: one asks from the patch perspective, looking only at this bug; the other asks from the prevention perspective, looking at this *class* of bugs. I call the former **patch framing** and the latter **preventive framing**. T2 requires preventive framing.

**How T2 counters confirmation bias.** The counterfactual approach comes from the formal framework for causal reasoning [1]. Confirmation bias makes people — and AI — seek only evidence that supports the current conclusion. Counterfactual questions deliberately construct a negation scenario, forcing the AI to look for information that could overturn what it currently believes. For instance, if the AI concludes "the model doesn't follow `SKILL.md` instructions," T2 requires it to think the other way: what if the instruction format is the problem? What if there are passages in the same file that do get followed? A human expert doing 5-Why would naturally ask these questions. AI won't, unless you make it.

**Design note: you must use preventive framing.** If you use patch framing ("would adding a null check fix it?"), T2 passes at a shallow level and fails to do its job as a check. That's why the protocol explicitly requires preventive framing.

**Edge case.** The point of preventive framing isn't to require that every root cause be a system-level overhaul. Sometimes the answer to a preventive framing question reveals that the root cause isn't on the path you've been tracking. For example: you've traced down to "missing a concurrency lock" as the root cause. Preventive framing asks, "If we had a proper locking mechanism, would this class of bugs still occur?" The answer might be, "Locks prevent races, but this bug's real cause is event-handling order, which has nothing to do with locks." That tells you the root cause lies in another dimension — chasing the current path deeper won't help. Time to switch direction.

### T3: Explanatory Power

The root cause must account for all observed symptoms, not just a subset.

This condition mainly constrains single-path tracking. If there are symptoms the root cause can't explain, you've missed a branch — you need to keep asking.

But there's a caveat: T3 can only check whether the root cause explains the symptoms already observed. If the symptom list itself is incomplete, T3 can give a false pass. The next post will address how to close that gap.

All three conditions must be satisfied simultaneously before the AI is allowed to stop asking. That's the floor — ensuring the inquiry goes deep enough.

## Four Guardrails

But the process itself can go off track: chasing too deep without stopping, branching endlessly, continuing without evidence, or jumping to irrelevant layers. The four guardrails are there to catch these.

### HC1: Depth Ceiling of 5 Levels

5 levels is a ceiling, not a target. If you've gone 5 levels deep and still haven't satisfied T1–T3, the current path is wrong. Switch direction and start over.

### HC2: Branch Limit of 3

Prevents the inquiry from diverging endlessly and keeps the search space bounded. At any given level, you're allowed to chase at most 3 cause branches. This number comes from empirical research — studies have found that humans naturally enumerate an average of about 3 causal factors [2]. Three branches covers the common branching needs without exceeding what an investigator can effectively track.

### HC3: Evidence Anchoring

If 2 consecutive Whys have no new evidence to back them up, the inquiry must stop.

Note that HC3 only guarantees each step has evidence — it doesn't guarantee the evidence is deep. Evidence depth is still enforced by the T1–T3 thresholds. For example, "a reproduction experiment confirmed the race condition exists" is specific evidence that satisfies HC3. But that alone won't pass T1–T3 — you haven't traced down to why the race condition occurred in the first place.

### HC4: Layer Restriction

The root cause must land in one of four layers: code, architecture, configuration, or process. Causes at levels like "cognition" or "culture" are not allowed — they can't be acted on.

This rule excludes unactionable layers. It prevents AI from claiming it found a root cause at a level that sounds profound but can't be operationalized. For example, concluding "the model lacks capability" doesn't fall within the four allowed layers, so the inquiry must continue.

In short, here's what each condition constrains:

| Condition | What it constrains |
|-----------|-------------------|
| T1 Actionability | Stopping too early (depth insufficient) |
| T2 Preventive counterfactual | Confirmation bias (reasoning bias) |
| T3 Explanatory power | Single-path tracking (breadth insufficient) |
| HC1 Depth ceiling | Prevents going too deep |
| HC2 Branch limit | Prevents divergence |
| HC3 Evidence anchoring | Prevents unsupported speculation |
| HC4 Layer restriction | Prevents stopping too early (at unactionable layers) |

> **Next post preview**: Seven conditions can keep the inquiry process under control. But does AI auditing itself have blind spots? And how did this protocol emerge from practice? [Next post →](/posts/inquiry-protocol-design-3/)

## References

1. Pearl 1999, "Probabilities of Causation: Three Counterfactual Interpretations and Their Identification", *Synthese*, vol. 121, https://doi.org/10.1023/A:1005233831499
2. Kováč 2009, "Causal reasoning: the 'magical number' three", *EMBO Reports*, vol. 10, no. 5, https://doi.org/10.1038/embor.2009.75

## Cross-References

- [Part 1: Why AI Can't Do 5-Why Right](/posts/inquiry-protocol-design-1/)
- [Part 3: The Last Line of Defense](/posts/inquiry-protocol-design-3/)
- The earlier post [The Bug Loop You Can't Escape](/posts/ai-bug-root-cause-diagnosis/) covers four root cause diagnosis lessons from practice
- tdd-pipeline repository: [https://github.com/alexwwang/tdd-pipeline](https://github.com/alexwwang/tdd-pipeline)
