---
title: "The Experiment Design Was Fine. The LLM Still Failed."
slug: execution-context-design
date: 2026-05-31T10:00:00+08:00
draft: false
tags: ["AI Agent", "Experiment Methodology", "Context Construction", "Execution Protocol", "Sub-agent"]
categories: ["AI Practice", "AI Agent Experiment Methodology"]
series: ["AI Agent Experiment Methodology"]
toc: true
description: "A double-blind experiment with flawless design still produced unusable results. The culprit wasn't the protocol—it was the execution context. ANSI-polluted output fed into a scorer that diligently scored garbage, and a single sub-agent aggregated across scenarios it shouldn't have. I show how reconstructing the execution context flipped the conclusion from 'insufficient evidence' to 'adopt B'."
cover:
  image: "cover.png"
  alt: "A carefully designed experiment pipeline corrupted by context leaks at two nodes, contrasted with the clean rebuilt version"
---

> Series: AI Agent Experiment Methodology (Part 2)
> [Part 1: How to Use Double-Blind Experiments to Validate Skill Changes](/en/posts/2026/05/double-blind-experiment-ai-prompt-validation/)

> **TL;DR:** Round one of the double-blind experiment: B won 3/4 scenarios but failed the magnitude filter. Verdict: "insufficient evidence." Investigation revealed S1-A's output was polluted by terminal color codes, and the scorer diligently scored 8 dimensions on ANSI garbage. After reconstructing the execution context, B won 4/4. The failure wasn't in the experiment design—it was in how sub-agents' context boundaries were constructed.

---

## Round One: Perfect Protocol, Unusable Conclusion

The previous post covered the double-blind experiment design: two versions, four scenarios, blind mapping, independent scorer. The protocol itself was flawless.

Round one results:

| Scenario | Target Code | Variant A | Variant B | Winner | Gap |
|----------|------------|-----------|-----------|--------|-----|
| S1 | Python user service | **0.625** | **2.875** | **B** | +2.250 |
| S2 | React payment form | **2.625** | **2.750** | **B** | +0.125 |
| S3 | Java order processor | **2.625** | **2.625** | **Tie** | 0.000 |
| S4 | Node.js cache | **2.250** | **2.875** | **B** | +0.625 |

B won 3/4, with S3 a tie. But the magnitude filter failed—A was only 73% of B, below the 90% threshold.

8 evaluator runs, one scorer, a pile of tokens. The conclusion: "insufficient evidence, cannot adopt." Had to rerun.

That 0.625 for S1-A was an obvious outlier. Max score 3, and 5 out of 8 dimensions got 0 or 1. But data is data—you can't throw away a number just because it looks wrong. Not unless you find the reason.

## Investigation: Not the Experiment Design's Fault

First instinct was to question the experiment design: was one scenario too hard? Was the rubric biased toward B?

After checking each dimension, S1-A had 5 out of 8 dimensions at 0 or 1, a massive gap from other scenarios. The cause: **S1-A's output file was polluted by ANSI escape sequences**—terminal color codes mixed into the text, making it nearly unreadable.

This wasn't the experiment design's fault. Double-blind protocol, secret mapping, 8-dimension rubric—every step was correct. The problem was in the execution chain: **the evaluator's output had no integrity check, and the scorer's input had no readability check.**

The evaluator produced a polluted result. The scorer received garbled input and didn't flag an error—it scored 8 dimensions against ANSI escape sequences. The prompt didn't say "if the input is unreadable, refuse to score," so it defaulted to processing it.

This is the same pattern as "phantom delivery" from the previous post: **LLMs won't proactively tell you something went wrong. If you don't specify rejection conditions in the prompt, they'll "successfully" complete work on garbage input.**

Here's how absurd S1-A's scores were, dimension by dimension:

| Dimension | S1-A Score | Reason |
|-----------|-----------|--------|
| Prompt Contamination | 1 | ANSI pollution treated as a prompt issue |
| Dual-Pass Adherence | 1 | Output unreadable, can't judge process |
| Severity Accuracy | 0 | Can't identify any content |
| Defect Discovery | 1 | Barely detected some patterns |
| False Positive Control | 1 | Can't distinguish true from false |
| Suggestion Quality | 1 | Suggestions based on garbage |
| Critical Opinion | 1 | Opinion based on unreadable content |
| Format Compliance | 0 | Completely unreadable |

The scorer wasn't deliberately giving low marks—it was trying its best on an impossible task. Five dimensions at 0 or 1 wasn't because Variant A's review skill was bad. It was because the scorer was evaluating something that wasn't a normal review output at all.

## The Second Error: A Scorer Did What It Shouldn't

S1-A's ANSI pollution was the first execution problem. There was a second in v1—aggregation logic errors. The previous post explained the 0.03 gap from the conclusion angle; here's the execution perspective.

v1's scorer was a single sub-agent scoring all scenarios. Given four scenarios' inputs, it saw X and Y labels without knowing the mapping. So it did a "reasonable" thing: averaged all four X's and all four Y's.

The problem: four X's contained two A scores and two B scores. Same for Y. A and B scores were mixed in the average, and the difference was flattened.

X average 2.44, Y average 2.41, a 0.03 gap. Looks like "no difference."

This isn't some rare scorer error. Give it all the data, and it'll naturally aggregate—that's default LLM behavior. **The mistake was in my execution architecture: each scenario should have used an independent scorer sub-agent, given only that scenario's scoring input, so it had no opportunity to aggregate across scenarios.**

Same sub-agent, given 1 scenario's data vs. 4 scenarios' data, produces completely different conclusions. This isn't a prompt wording issue—it's a **context construction issue**.

## Fix the Context, Rerun

The fix wasn't to change the experiment design. It was to **reconstruct the execution context for each step**:

- Fix the evaluator's output capture (terminal color codes no longer leak in)
- **Launch an independent scorer sub-agent for each scenario**, given only that scenario's scoring input
- Aggregation done by whoever knows the secret mapping, not by the scorer

Two fixes, both with data changes. S1-A recovered from 0.625 to 2.500. Aggregation logic changed from "one scorer for all scenarios" to "independent scorer per scenario." v2 results:

| Scenario | Variant A | Variant B | Winner | Gap |
|----------|-----------|-----------|--------|-----|
| S1 | **2.500** | **2.750** | **B** | +0.250 |
| S2 | **2.375** | **2.500** | **B** | +0.125 |
| S3 | **2.250** | **2.375** | **B** | +0.125 |
| S4 | **2.125** | **2.500** | **B** | +0.375 |

| Metric | v1 (no execution constraints) | v2 (reconstructed context) |
|--------|------|------|
| B wins | 3/4 (S3 tie) | 4/4 |
| Magnitude filter | 0.73 ❌ | 0.91 ✅ |
| A average | 2.031 | 2.313 |
| B average | 2.781 | 2.531 |
| Conclusion | Insufficient evidence, cannot adopt | **Adopt B** |

One detail worth noting: B's average dropped from 2.781 to 2.531 in v2. B didn't get weaker—v1's S1-A score of 0.625 dragged down A's average severely, making B look like it won by a lot. After the fix, the gap narrowed, but the data became more reliable.

**Reconstructed the execution context for two steps, and the conclusion flipped from "insufficient evidence" to "adopt B."**

## If the Design Was Right, Why Did It Fail?

The experiment design was flawless—double-blind protocol, secret mapping, 8-dimension rubric. Yet v1 still failed, because getting the design right only solves half the problem:

- The evaluator wasn't asked to verify output integrity, so it didn't report the ANSI pollution
- The scorer was given 4 scenarios' data, so it naturally aggregated across them—flattening the difference

v2's fix didn't touch the experiment design. It did two things: added output integrity checks to the evaluator, and changed the scorer from "one agent scores all scenarios" to "one independent agent per scenario."

Working on tdd-pipeline, similar lessons kept appearing. Designing a workflow is one thing—what to do, in what order. Constructing context is another—what each sub-agent sees, what it doesn't see, under what conditions it should refuse to execute.

This experiment's iteration reminded me: successful engineering implementation requires both sound workflow design and careful context construction for each sub-agent handling a task. Both are critical to achieving the goal.

---

## References

1. [Double-blind experiment skill source (includes three-tier protocol and five failure modes)](https://github.com/alexwwang/tdd-pipeline/blob/main/experiment/SKILL.md)
2. [TDD Pipeline repository](https://github.com/alexwwang/tdd-pipeline)
3. [Part 1: How to Use Double-Blind Experiments to Validate Skill Changes](/en/posts/2026/05/double-blind-experiment-ai-prompt-validation/)
