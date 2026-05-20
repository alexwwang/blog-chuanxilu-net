---
title: "Using the Method to Improve the Method"
slug: "tdd-pipeline-v07-refinement-experiment"
date: 2026-05-22T10:00:00+08:00
draft: false
description: "I built a ruler. The ruler measured 'redundancy is harmful.' Then I used that ruler to trim the ruler's own redundancy. I deleted the operational steps from my AI skill files, keeping only principles and counterexamples. The model reconstructed the deleted steps on its own — output quality didn't drop."
tags: ["AI", "TDD", "skill design", "prompt engineering", "principle-driven"]
categories: ["AI Practice", "Breaking to Build: TDD Process Iterations"]
series: ["Breaking to Build: TDD Process Iterations"]
toc: true
cover:
  image: "cover.png"
  alt: "A ruler measuring its own scale marks for redundancy, then trimming the excess marks away"
---

> Series: Breaking to Build: TDD Process Iterations (second post)
> Previous: [What a Failed Experiment Got Right](/en/posts/tdd-pipeline-v08-failed-experiment-discovery/)

> **TL;DR:** The TDD Pipeline taught "give principles, not steps" — but it had grown into a step-driven tool itself. I stripped the operational steps from Phases 1 through 5, keeping only principles, risk hints, and counterexamples. The model independently derived the steps I had deleted. Output quality held. The reason: Phases 1 through 5 are creative phases that need room to diverge. Removing the fixed track actually helped. The same strategy failed on Phase 6 — next post explains why.

## Why I Went Back to V0.7

The previous post covered the V0.8 experiment. Refining Phase 6 didn't meet expectations, but it unexpectedly revealed that the refined version had better project-level awareness [1].

That experiment had a prerequisite. Refining Phases 1 through 5 had already succeeded. V0.8 was an extension attempt built on top of V0.7's success.

To understand why V0.8 failed — and why that failure was valuable — you first need to see why V0.7 succeeded.

## Where I Got Stuck

The TDD Pipeline ran for a while. The skill files for Phases 1 through 5 kept getting longer. Each file packed in operational steps, template formats, checklists, and counterexamples. Thousands of lines total.

Every single rule was useful — distilled from real bugs. But "every rule is useful" and "the whole set is optimal" are two different things.

This echoed a finding that had already shown up repeatedly in this series: **the more specific the constraint, the more the model tends to take shortcuts.** In the Why Articulation A/B experiments [2], positive examples made the model's analysis converge. Removing those examples improved independent reasoning quality. In Anthropic's alignment research [3], teaching principles outperformed teaching behaviors by roughly seven times.

That raised a question. Were the step-by-step instructions, template filling guides, and checklist prompts in the skill files just another form of positive examples? Were they all giving the model an exit ramp from thinking?

**The TDD Pipeline taught "give principles, not steps." But it had grown into a step-driven tool.**

That contradiction was the motive for the experiment.

## Experiment Design

My hypothesis: refine the skill files for Phases 1 through 5 from step-driven to principle-driven. Under a principle framework, the model would autonomously derive the steps I removed. Output quality would not drop below the original version.

The refinement strategy was straightforward. Keep four things, cut three things.

**Keep:**
- Why Articulation mandatory self-check mechanism [2]
- Risk hints for each phase
- Counterexamples ("what a lazy Why Articulation looks like")
- Gate pass conditions

**Cut:**
- Operational steps ("Step 1 do X, Step 2 do Y")
- Template filling guides ("fill your content into the template below")
- Redundant rules (the same rule stated in multiple places)

A concrete before-and-after. The original version of Phase 1 opened like this:

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

The refined version kept only the principles, risk hints, and counterexamples. The entire Detailed Process section was gone.

Comparison method: same tasks, run with both the original skill and the refined skill. An independent evaluation agent did blind A/B comparison. Six dimensions — deliverable completeness, review quality, boundary coverage, counter logic, triggers, and phase transitions.

## Results: The Refined Version Held Its Own

Four rounds of independent blind testing across four different task types:

| Round | Task | Type | Result |
|---|---|---|---|
| A | Token Bucket | Design-heavy | Pass: deliverables 7.5/8, review equivalent, boundaries 13/13, counters 4/4 |
| B | CSV Import | Code-heavy | Pass: deliverables 6/6, review equivalent, boundaries 10/13 acceptable |
| C | Notification Service | Blind test | Defect found — refined version lost the Ralph trigger and phase transition pointer |
| D | Policy Engine | Fix verification | Pass: all six dimensions passed, review verified by oracle 7/7 |

Round C's finding deserves attention. The refined version had removed the "trigger review when done" and "proceed to next phase" instructions at the end of each phase file. Running independently, the model didn't know whether to trigger a review or which phase to enter next.

This wasn't an output quality problem. It was a flow continuity problem. Some removed steps weren't things the model could derive. They were things it needed to be told.

The fix wasn't to restore all the steps. I added two lines to the end of each refined file — the review trigger instruction and the next phase's filename. Round D verified the fix with Policy Engine. All dimensions passed.

A more interesting detail came from Round A. Running with the skill file that had its operational steps removed, the model derived those steps on its own. The original version said "Step 1: use deep-interview to gather requirements. Step 2: classify user stories." The refined version only said "understand what to build and why, eliminate ambiguity."

The model's analysis spontaneously produced a reasoning chain: gather requirements → user stories → acceptance criteria → priority classification. Same steps as the original version. But the model organized them itself.

This maps directly onto a finding from the Why Articulation experiments: removing scaffolding led the model to self-organize the same dimensions [2]. Two experiments, different scenarios, same signal.

![Fixed track vs free reasoning: two paths through the same nodes](illustration-1.png)

One side benefit. Total lines dropped from 1,617 to 1,360 after refinement — a 16% reduction. Over time, that means less context injected per run and lower cost.

## Why It Worked

Looking back, the success of refining Phases 1 through 5 connects directly to the nature of these phases.

Phases 1 through 5 are **creative phases**. They produce requirements documents, design proposals, test plans, test code, and business code. Creative work needs room to diverge.

Step-by-step guidance gave the model a fixed track. The model followed the track without errors — but never went beyond it. Removing the track let the model reason freely within the boundaries set by principles. It found paths that fit the current task better.

This is the same logic as "give principles, not examples." Principles tell the model what the goal is and where the boundaries are. Examples tell the model "just do it this way."

The former forces the model to think about how to reach the goal. The latter gives it a ready-made path to copy.

## Recursion

Using your own methodology to improve your own tool is the strongest validation of that methodology.

V0.7 succeeded. That showed "principle-driven" doesn't just apply to prompt design — it applies to skill architecture as a whole. This success motivated V0.8: apply the same strategy to Phase 6.

Then V0.8 failed. But the failure pointed to a problem V0.7 never encountered. Next post covers that problem.

---

> Next in the series: [The Invisible Blank Layer](/en/posts/tdd-pipeline-phase7-invisible-gap/)

---

## References

1. What a Failed Experiment Got Right: [tdd-pipeline-v08-failed-experiment-discovery](/en/posts/tdd-pipeline-v08-failed-experiment-discovery/)
2. A 4-Variable A/B Test — Why Positive Examples Harm Prompt Performance: [ab-test-positive-examples-harm](/en/posts/ab-test-positive-examples-harm/)
3. From Anthropic's Alignment Research to a Prompt Design Insight: [anthropic-alignment-to-prompt-design](/en/posts/anthropic-alignment-to-prompt-design/)
4. The Upgrade — New Template and Three Transferable Lessons: [why-articulation-upgrade-and-takeaways](/en/posts/why-articulation-upgrade-and-takeaways/)
5. The Full Pipeline: Five Stages from Requirements to Code: [ai-tdd-full-pipeline-from-requirements-to-code](/en/posts/ai-tdd-full-pipeline-from-requirements-to-code/)
