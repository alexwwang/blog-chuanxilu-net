---
title: "The Last Line of Defense for Inquiry: Independent Confirmation and Protocol Reflexivity"
slug: "inquiry-protocol-design-3"
date: 2026-05-07T10:00:00+08:00
draft: false
description: "The inquiry protocol's last line of defense: an independent confirmer uses falsifiability testing to hunt for counterexamples, pushing back against AI's shallow anchoring. Plus the protocol's origin story — from 18 bugs of practice to the v0.4.1 upgrade, and plans for reflexivity."
tags: ["AI", "5-Why", "root cause analysis", "inquiry protocol", "falsifiability", "Popper"]
categories: ["AI Practice", "AI Root Cause Diagnosis", "Inquiry Protocol Design"]
series: ["Taming AI Coding Agents with TDD", "AI Root Cause Diagnosis"]
toc: true
cover:
  image: "cover.png"
  alt: "The last line of defense for inquiry: independent confirmation and protocol reflexivity"
---

> **TL;DR:** The inquiry protocol's last line of defense is independent confirmation — a perspective free of confirmation bias that runs falsifiability testing to hunt for counterexamples. This post also covers how the protocol came to be (from 18 bugs of practice to a gap found while writing these articles) and plans for future reflexivity.

In the [previous post](/posts/inquiry-protocol-design-2/), I laid out the inquiry protocol's seven conditions: three floor conditions (T1–T3) that force the AI to go deep enough, and four guardrails (HC1–HC4) that keep the inquiry process from spiraling out of control. This post covers the last line of defense — and how the protocol actually came to be.

## Independent Confirmation: Falsifiability Testing

Even with seven conditions as guardrails, the AI checking itself still has blind spots. Confirmation bias isn't unique to AI. But AI lacks the "something feels off" intuition that humans get when staring at their own wrong conclusions.

So we added a final safety net: independent confirmation.

In the current version, the independent confirmer is a human reviewer. The long-term goal is to have a separate AI agent fill this role. But that requires enough perspective divergence between agents to avoid sharing the same set of biases — an unsolved challenge.

The essence of independent confirmation isn't re-running the T2 test. It's using a perspective free of confirmation bias to apply falsifiability testing to the entire hypothesis system. This direction is inspired by Karl Popper's philosophy of science [1]. When investigators check their own hypotheses, confirmation bias is inevitable — they actively seek supporting evidence and ignore contradictory signals. The independent confirmer doesn't carry that baggage.

Independent confirmation does exactly one thing: hunt for counterexamples.

There are three possible outcomes:

1. **No counterexample found.** The hypothesis system is complete and correct. Confirmation passes. Move to the fix phase.
2. **Overturning counterexample found.** The hypothesis system has a fundamental error. The counterexample becomes new evidence. Return to the 5-Why process and reinvestigate.
3. **Boundary counterexample found.** The hypothesis system is incomplete. It needs boundary conditions added. Refine and re-confirm.

Independent confirmation is the protocol's backstop — an external perspective that catches what the seven conditions missed:

- For single-path tracking, a counterexample may reveal symptoms that were overlooked.
- For confirmation bias, a counterexample may expose evidence that was selectively ignored.
- For stopping too early, a counterexample may prove that the current conclusion can't hold under boundary conditions — meaning the inquiry didn't go deep enough.

The three problems have different natures: stopping too early is insufficient depth, single-path tracking is insufficient breadth, and confirmation bias is a reasoning bias. The latter two are amplified by anchoring. Counterexamples serve one function across all three: proving that a shallow explanation doesn't hold — regardless of which dimension the problem lives in.

This method wasn't designed in a vacuum. Falsification-driven troubleshooting has been explicitly adopted by practitioners in software debugging — it has real applications in SRE and security operations. More direct evidence comes from AI debugging research: recent multi-agent debugging systems (FVDebug, AgentForge, DoVer) all introduce independent critic or verifier agents, and ablation studies show that independent verification roles significantly improve diagnostic accuracy [3][4][5].

Two design decisions are worth explaining.

**First, why only one round of confirmation instead of a loop.** This is an engineering tradeoff. One round risks missing things. Two or more rounds have diminishing returns that don't justify the cost. If one round of confirmation plus counterexamples as new evidence plus continued 5-Why still can't reach a conclusion, the problem has exceeded the inquiry protocol's capacity. Escalating to the user is the more reasonable path.

**Second, why independent confirmation only hunts for counterexamples instead of doing a full re-check.** Finding counterexamples is divergent thinking. The AI has already converged a long way in one direction. What's needed is an external perspective pulling hard in the opposite direction. A full re-check would just repeat the convergent work — unnecessary.

## From Practice to Protocol: The Iteration

This article isn't theory applied to practice after the fact. It's a record of what I learned from months of painful trial and error:

1. **Practice phase.** In the Aristotle project, I tracked 18 bugs total. Every root cause was uncovered by me manually driving the AI through inquiry.
2. **Distillation phase.** I organized these scattered practical experiences into tdd-pipeline's Phase 6 inquiry protocol, versioned at v0.4.0.
3. **Reflection phase.** While outlining this article, I did a logic review of the protocol and found two design gaps: T2's framing didn't explicitly require a preventive dimension, and independent confirmation's scope was too narrow — previously it only re-checked T2.
4. **Upgrade phase.** I updated the design docs. The protocol went from "T2 re-check" to "falsifiability testing." Version bumped to v0.4.1. Not yet deployed.
5. **Pending validation phase.** Every mechanism in the protocol was extracted from those 18 bug battles. For example, I used the counterexample "why can the ROUTE segment be followed?" to overturn the AI's "the model isn't cooperating" attribution — that's counterexample hunting in action. v0.4.1 encodes all these practices into explicit protocol steps. The next step is running v0.4.1 in production.

The inquiry protocol's ultimate goal is to automate human inquiry experience so that agents can complete root cause investigations of equal quality without human intervention.

But honestly: the "practice → reflection → upgrade" cycle this time was human-driven. I found the protocol's gaps while writing this article and reviewing its logic. The protocol itself doesn't have self-improvement capability. T1–T3 are stopping rules for a single investigation. Independent confirmation is falsifiability testing for a single hypothesis. Neither addresses reflection on the protocol itself. Protocol self-improvement still depends on human intervention.

## Known Limitations and Next Steps

The current protocol has two known limitations.

First, it can't distinguish between "the fix failed because the protocol didn't catch an error" and "the fix failed because the bug exceeded the protocol's capacity."

Second, the inquiry protocol encodes human expert judgment about termination conditions into explicit rules, enabling the AI to use 5-Why correctly. But 5-Why itself has limited applicability — Card notes that its coverage of multi-factor interaction problems is low [2]. The inquiry protocol helps the AI use 5-Why well in scenarios where 5-Why works. It can't make 5-Why cover scenarios it was never designed to cover.

The plan going forward is to add reflexivity capability to the protocol. Aristotle's reflection system already has patterns ready to transfer: code error → reflect on error → distill preventive rule → commit to rule library. The adaptation to the inquiry protocol would be: fix fails → reinvestigate bug → simultaneously investigate where the protocol failed to catch it → produce protocol amendment → upgrade protocol.

There are three trigger conditions for the reflexivity process: the same bug fails to fix 2+ times with different root causes each time; the fix requires rolling back to a deeper layer than the protocol recommended; independent confirmation passes but the fix still fails. Any protocol amendment must itself pass T1–T3 verification before taking effect.

The v0.4.1 upgrade had a somewhat accidental trigger: the gaps weren't found in production but during the writing of this article, when I was reviewing the protocol's logic. The goal for future iterations is to build reflexivity mechanisms into the protocol so that this kind of upgrade can be automated. That work is currently in design, and needs to integrate with Aristotle's capabilities.

## References

1. Popper 1959, *The Logic of Scientific Discovery*, Hutchinson, https://www.routledge.com/The-Logic-of-Scientific-Discovery/Popper/p/book/9780415278430
2. Card 2017, "The problem with '5 whys'", *BMJ Quality & Safety*, vol. 26, no. 8, https://doi.org/10.1136/bmjqs-2016-005849
3. Bai et al. 2025, "FVDebug: An LLM-Driven Debugging Assistant for Automated Root Cause Analysis of Formal Verification Failures", arXiv:2510.15906, https://arxiv.org/abs/2510.15906
4. Kumar et al. 2026, "AgentForge: Execution-Grounded Multi-Agent LLM Framework for Autonomous Software Engineering", arXiv:2604.13120, https://arxiv.org/abs/2604.13120
5. Ma et al. 2025, "DoVer: Intervention-Driven Auto Debugging for LLM Multi-Agent Systems", arXiv:2512.06749, https://arxiv.org/abs/2512.06749

## Cross-References

- [Part 1: Why AI Can't Do 5-Why Right: Stopping Too Early, Single-Path Tracking, and Confirmation Bias](/posts/inquiry-protocol-design-1/)
- [Part 2: Seven Conditions to Keep AI's 5-Why from Going Off the Rails](/posts/inquiry-protocol-design-2/)
- The earlier post ["The Bug Loop You Can't Escape"](/posts/ai-bug-root-cause-diagnosis/) covers four root cause diagnosis lessons from practice; this article is the operational follow-up that turns those lessons into an executable process
- tdd-pipeline repository: [https://github.com/alexwwang/tdd-pipeline](https://github.com/alexwwang/tdd-pipeline)
