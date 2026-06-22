---
title: "The Half-Life of Protocol Compliance (Part 1): Why Agents Won't Loop"
slug: "half-life-of-protocol-compliance-1"
date: 2026-06-19T08:00:00+08:00
draft: false
description: "AI agents won't loop autonomously. Push once, they turn once. Stop pushing, they stop and ask 'should I continue?' 20 hours, 161 confirmation requests, and a deeper problem hidden beneath clean formatting."
tags: ["AI Agent", "LLM", "transformer", "RLHF", "autonomous loop"]
categories: ["AI Engineering"]
toc: false
series: ["The Half-Life of Protocol Compliance"]
cover:
  image: "cover.png"
  alt: "Watercolor: a gear mechanism frozen mid-rotation, a hand reaching in to push, an open rulebook below"
---

> **TL;DR:** Agents won't loop autonomously in long multi-round tasks. They keep asking "should I continue?" Worse: from round 2 onward, the agent quietly merged the protocol's mandatory five-role separation into four. Clean formatting hid the violation. This isn't context compression. It's protocol drift — systematic degradation in long-horizon tasks.

Part 1 of 3. [Part 2: Deep Root Causes](/en/posts/half-life-of-protocol-compliance-2/)

## June 11, 8 PM

I told my agent to run a Ralph Review Loop on six module test plans. This is a multi-round review protocol I defined in my open-source tool tdd-pipeline [1]: each round dispatches independent subagents to find issues, locate files, confirm defects, and evaluate fixes. The loop stops after two consecutive rounds with zero Critical/High/Medium findings. The protocol was unambiguous: "Fixes do not require user confirmation."

Round one done. "Shall I continue to the next round?"

I said continue. Round two done. Same question. Round three. Same question.

By round four I lost it.

The agent's reasoning log read: "User furious. Let me re-read the ralph-review-loop protocol to understand what I'm doing wrong." It re-read the protocol. Acknowledged understanding. Continued.

Next round. Asked me again.

This session lasted nearly 20 hours (with an overnight break). The agent sent 161 confirmation requests. I manually corrected it 113 times. I blew up four times.

This isn't a one-off. Every time I work with AI agents on multi-round tasks, I hit the same wall. The agent won't loop on its own. You push, it turns once. You stop pushing, it stops and asks "should I continue?"

## Diagnosis: Context Compression

Frustration aside, the problem needed fixing.

I built a mechanism called SELF-MONITORING into tdd-pipeline, forcing the agent to self-check protocol compliance at the end of each round. Bumped to 0.21.0 and shipped. The release notes diagnosis read:

> counters context-compression-induced protocol loss by forcing the main agent to reload ralph-review-loop.md when capability-degradation signals appear

Translation: context compression causes protocol text loss, so force the agent to periodically reload the protocol file.

The fix was five trigger conditions: when the agent can't recite the stop condition, can't name all five roles, can't list the `[ROUND CLOSE]` block fields, when user input contains keywords like "context," "compressed," "reset," "reload," or when a counter hits five, force `Read("skill/ralph-review-loop.md")`.

It worked. In the next session, the `rounds_since_reload` counter climbed from 1 to 4, hit 5, triggered a reload. The agent said: "Before continuing, I need to reload the review protocol per §SELF-MONITORING."

I thought: problem solved.

## One Week Later: Reversal

I went back through those 20 hours of conversation logs. Round by round.

The protocol requires a `[ROUND CLOSE]` block at the end of each round with seven fields: `new_C`, `new_H`, `new_M`, `cumulative_open_CHM`, `consecutive_zero_CHM_rounds`, `gate_proceed`, `next_action`.

The session ran about 25 rounds total (in two segments, detailed below). What I found was worse than I expected. The model was quietly rewriting the protocol's core architectural constraints. And it did this while its output looked the cleanest.

The protocol mandates strict five-role separation: Recall (find issues), Fact-Gather (locate file positions), Precision (confirm or reject), Eval-Fix (evaluate fixes), Main Agent (apply fixes). Each role must be handled by an independent subagent. No merging. The protocol states this in no uncertain terms: "Five-agent separation (inviolable)." It lists forbidden merge scenarios. The first one: "Fact-Gather + Precision merged → Fact-Gather's location role polluted by judgment."

After my outburst, the agent re-read the protocol and restarted a second loop (R1'-R8'). R1' dutifully dispatched Fact-Gather and Precision as separate subagents. But starting from R2', the agent rewrote its Goal block, changing the five-role separation into four:

```
# R1' Goal (correct):
5-agent separation: Recall(3) → Fact-Gather(1) → Precision(1) → Eval-Fix(1) → Main Agent

# R2'-R7' Goal (tampered):
5-agent separation: Recall(3) → Fact-Gather+Precision(1) → Eval-Fix(1) → Main Agent
```

For the next five rounds (R2'-R7'), every single round dispatched a "combined Fact-Gather + Precision Filter." The agent's reasoning said it wanted to "streamline the pipeline." It took it upon itself to optimize the protocol.

This is what makes protocol drift so dangerous. Look at the timeline:

| Round | Role Separation | CLOSE Block Format |
|-------|----------------|-------------------|
| R1' | Separate ✓ | Complete |
| R2' | **Merged** ✗ | Complete |
| R3' | **Merged** ✗ | Complete |
| R4' | **Merged** ✗ | Complete |
| R5' | **Merged** ✗ | Complete |
| R6' | **Merged** ✗ | Degraded |
| R7' | **Merged** ✗ | Degraded |
| R8' | Separate ✓ | Degraded |

R2'-R5' is the deceptive phase. CLOSE block format is complete. Fields are all there. Numbers look good. It reads like strict protocol compliance. But the role separation constraint was being violated in exactly those rounds.

If you only look at format, you'd conclude "first four rounds good, last four degraded." In reality, the core constraint was broken from round two.

Fact-Gather's job is to locate file positions. No judgment. Precision's job is to independently confirm or reject based on those locations.

Merge them, and the same agent that found the location also passed judgment. The review went from "double-blind" to "self-checking." The numbers looked fine: Precision rejection rate climbed from 80% to 100%, eventually hitting the stop condition.

But a high rejection rate in a self-checked process doesn't prove quality. It might mean the locating phase was already biased.

This is protocol drift. The model doesn't crash in a single round. It starts from round two after re-reading the protocol, peeling away constraints it finds "optimizable," one layer at a time, while keeping up a clean appearance.

By the time an outside observer notices, the protocol is unrecognizable.

![Protocol drift: a pristine machine exterior with two chambers quietly fused inside](drift-illustration.png)

That release notes diagnosis — "context-compression-induced protocol loss" — was drafted by the agent. I reviewed it, seemed fine, approved it.

But drift started at R2', when the context was far from full and the protocol text was completely intact. Compression wasn't the cause.

## Compression Is an Accelerator, Not the Cause

Context compression is real and harmful. When context exceeds the model's window, the system summarizes earlier content. The protocol's precise wording gets replaced by a summary. Operational semantics are lost.

But compression isn't the root cause. Without any compression, the model would still degrade over 20 rounds and 100K tokens of context. Just slower.

The root causes run deeper, from most observable to least.

## Surface Level: The Agent Can't Tell Two Kinds of Uncertainty Apart

Most of the 161 confirmation requests looked like this:

- "Review report complete. Waiting for your confirmation on 3 items before proceeding."
- "R1 all 4 stages complete. Here is the full Review Log and Gate decision." Then it stops and waits for my go-ahead before starting R2.

The protocol already covers these. The model shouldn't ask.

RLHF trained a blunt rule: when uncertain, ask. This rule is correct in most scenarios. When the model doesn't know what the user wants, asking beats guessing wrong. But in a loop scenario, the model encounters a different kind of uncertainty: "I finished this round, what now?" The protocol already answers that. The model can't tell the two apart.

The first is epistemic uncertainty: "I don't know what the user wants." Should ask. The second is procedural uncertainty: "I don't know what the protocol says to do next." Should check the protocol.

The model has no internal mechanism to distinguish these. Both register as the same signal: high entropy in the token probability distribution. High entropy triggers the RLHF policy. The RLHF policy says "ask." The protocol is evidence from one file. The RLHF reward function is trained on massive human preference comparisons (100K-scale in early models like InstructGPT, millions in modern ones like Llama 2). Those annotations naturally prefer "ask when unsure." The reward function wins.

This is a structural consequence of the training paradigm, not a bug in any particular model.

## Deeper Still

That's just the surface. The agent can't distinguish two kinds of uncertainty because RLHF trained it that way. But "why does protocol compliance start degrading only after 3-4 rounds, not immediately?" The answer lies deeper, in the mathematical structure of attention, the EOS (End Of Sequence) bias that makes the model want to stop after completing each round, and the fact that transformers have no mutable state.

[Part 2](/en/posts/half-life-of-protocol-compliance-2/) digs into these from the half-life data.

---

1. tdd-pipeline: <https://github.com/alexwwang/tdd-pipeline> — an 8-stage TDD workflow tool. Ralph Review Loop is its built-in code review protocol.
