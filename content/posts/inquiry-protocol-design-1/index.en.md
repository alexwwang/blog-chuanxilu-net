---
title: "Why AI Can't Do 5-Why Right: Stopping Too Early, Single-Path Tracking, and Confirmation Bias"
slug: "inquiry-protocol-design-1"
date: 2026-05-05T10:00:00+08:00
draft: false
description: "5-Why handed to AI fails not because the method is outdated, but because AI thinks shallow—stopping early, chasing one thread, seeking only confirming evidence. A real case where all four rounds of attribution went wrong."
tags: ["AI", "5-Why", "root cause analysis", "inquiry protocol", "AI-assisted development"]
categories: ["AI Practice", "AI Root Cause Diagnosis", "Inquiry Protocol Design"]
series: ["Taming AI Coding Agents with TDD", "AI Root Cause Diagnosis"]
toc: true
aliases: ["/posts/inquiry-protocol-design-1-en/"]
# cover:
#   image: "cover.png"
#   alt: "Why AI Can't Do 5-Why Right: Stopping Too Early, Single-Path Tracking, and Confirmation Bias"
---

> **TL;DR:** AI fails at 5-Why in three ways: stopping too early (insufficient depth), single-path tracking (insufficient breadth), and confirmation bias (reasoning distortion). The three are independent but tend to show up together — a shallow conclusion becomes an anchor that compresses the exploration space and biases evidence selection. This post uses a real case where all four rounds of attribution went wrong to dissect each failure mode.

This post sits at the intersection of two series: "Taming AI Coding Agents with TDD" and "AI Root Cause Diagnosis."

I've been building a tool for AI-assisted root cause diagnosis, and I wanted to use the 5-Why method—a workhorse from industrial engineering. But when I guided AI through 5-Why questioning to locate bug root causes, I noticed it kept stopping too early, chasing only one line of inquiry, and hunting for evidence that confirmed its existing beliefs. Every session required heavy follow-up questions from me.

That's a problem for automation. If I want to remove the human from the loop, I need scaffolding that steers the AI through proper 5-Why analysis. And to design that scaffolding, I first need a clear picture of exactly where AI falls short.

## 5-Why Depends on Human Judgment. AI Doesn't Have Any.

5-Why originated with Taiichi Ohno's practice in the Toyota Production System [1]. His idea: when you hit a problem, keep asking "why" until you reach the root cause. It later got distilled into the rule of thumb "ask why five times."

One thing about this method: the stopping condition is never explicitly defined. When have you reached a root cause? That's entirely up to the experience and judgment of the person asking. A well-trained engineer knows when to stop, when to switch direction, and when they might be fooling themselves.

Academics have criticized 5-Why. Card argued in 2017 that the same incident, when mapped onto a cause tree, can yield 75 or more causes—while 5-Why typically finds only one or two, a coverage rate below 3% [2]. But his example comes from medical adverse-event investigations, where incidents usually involve a dozen or more interacting contributing factors. Software debugging is a completely different scenario.

Research shows that software bug root causes cluster into 3 to 9 categories, and over 70% are semantic-level logic errors [5]. Many bugs have a single dominant root cause. Roughly 80% of server-side bugs are deterministic—same input, same failure [6]. This is nothing like the multi-factor interactions in medical incidents.

Card says 5-Why coverage is below 3%, but in debugging scenarios there simply aren't that many root causes to begin with. The "75 causes, missed 73" problem doesn't exist here. 5-Why analysis is goal-directed. In practice, users naturally filter out uncontrollable influencing factors. When I debug, the actionable causes are usually very few. I need to find them fast—not get distracted by logically sound but completely impractical explanations.

Card attacked coverage. Paradies attacked a different problem: confirmation bias. In 2005 he pointed out that investigators actively seek evidence supporting their pre-set conclusions while ignoring contradictory information [3]. This criticism isn't about the method itself—it's a cognitive trap of the person using it. Experienced engineers know to actively seek counterexamples as a hedge. In their hands, 5-Why doesn't go off the rails.

The coverage criticism doesn't hold in debugging contexts. Confirmation bias is a real risk but can be hedged. Neither criticism is a reason to abandon 5-Why—provided the user has enough experience. AI has none of that experience, and it lacks the human instinct that something "feels off."

I've run multiple tests without external follow-up intervention. Left to itself, AI doing 5-Why stops after 2 or 3 layers by default. The answers look logically coherent, but they never reach an actionable root cause. For example, when debugging a command that wasn't executing, AI correctly identified the command itself as the issue—but never asked why another part of the same file was executing just fine. The direction was right, every step had supporting evidence, but it simply didn't go far enough.

## A Four-Round Attribution Case: How AI Fell Apart in Practice

I ran into a textbook case in the Aristotle project: instructions in `SKILL.md` were being ignored. The first three rounds of attribution all failed. Each one pointed at relevant clues but none went deep enough.

**Round 1:** AI diagnosed "opencode run doesn't support async notifications." Partially correct—the issue was indeed related to the runtime environment. But it stopped at the testing-method level and never reached the root cause. I noticed the same code behaved differently in other environments, challenged the conclusion, and we moved to the next round.

**Round 2:** AI diagnosed "the model doesn't follow `SKILL.md` instructions." Broad direction was right—it was definitely related to `SKILL.md`. But it only chased the "model isn't cooperating" thread. It never explored the parallel branch: "is there something wrong with the instruction format itself?" It stopped at "model non-compliance" without asking why the ROUTE section of the same `SKILL.md` was being followed correctly while only the ACTIONS section was ignored. I raised that question, and we continued.

**Round 3:** AI diagnosed "the existence of `LEARN.md` causes the model to bypass the dispatcher." Direction was right again—it pointed at the file-loading mechanism. But it stopped at "the file exists" and proposed deleting `LEARN.md` as the fix. That couldn't survive any follow-up questioning. I asked "why is the solution to delete a file?" and we entered round four.

**Round 4:** Finally found the root cause: the ACTIONS section in `SKILL.md` used a documentation-style bullet list instead of an execution style with concrete verbs. The model treated it as regular documentation and ignored it.

## Three Problems Distilled from the Case

The first three rounds weren't hallucinations. Each step had supporting evidence—they were just one layer short of the root cause. Without my follow-up questions, AI would have stopped at round two or three, convinced it had found the answer.

Looking back at those three rounds, I see three distinct problems.

**Stopping too early—every round quit before reaching the root.** Round 1 stopped at the testing-method level, round 2 at "model non-compliance," round 3 at "file exists." Every direction was correct, but every round was one layer short—stuck at the operational level rather than reaching the semantic level. The root cause lived in the semantics of instruction formatting, and AI missed it three rounds in a row. AI defaults to 2-3 layers and decides that's enough. It doesn't push further on its own.

**Single-path tracking—chasing one thread, ignoring branches.** Round 2 is the clearest example. AI had already narrowed the direction to `SKILL.md`, but only pursued "model isn't cooperating." It never touched the "is the instruction format wrong?" branch.

**Confirmation bias—seeking only supporting evidence, never counterexamples.** All three rounds show this. AI gathered evidence supporting its own conclusion in each round and never actively looked for information that might overturn it. Wan et al. (2025) found that in chain-of-thought reasoning, a model's initial belief biases the entire reasoning chain—reasoning drifts toward supporting that initial belief [4].

## Three Problems, Three Natures

These three problems are independent categories.

Stopping too early is insufficient depth—AI defaults to 2-3 layers and stops. That's just how it works. No additional mechanism needed to explain it.

Single-path tracking is insufficient breadth—chasing one path without exploring alternatives.

Confirmation bias is a reasoning bias—seeking only supporting evidence while ignoring counterexamples, leading to wrong attributions.

Why do the latter two so often accompany stopping too early? Because of anchoring. Once a shallow conclusion forms, it becomes an anchor that constrains subsequent reasoning. It compresses the exploration space—branches that could have been pursued get dropped (insufficient breadth → single-path tracking). It also biases evidence selection—reasoning drifts toward supporting the initial conclusion (reasoning bias → confirmation bias). Anchoring doesn't explain why depth is insufficient. It explains how, once a shallow conclusion forms, breadth and reasoning get dragged off course.

So here's the question: can we design a verifiable set of rules and procedures that draw out the depth and reasoning quality that AI should be capable of?

> **Next post**: Knowing the problems isn't the same as knowing how to fix them. What mechanisms can intercept these three failure modes? [Next →](/posts/inquiry-protocol-design-2/)

## References

1. Ohno 1988, *Toyota Production System: Beyond Large-Scale Production*, Productivity Press, https://www.routledge.com/Toyota-Production-System-Beyond-Large-Scale-Production/Ohno/p/book/9780915299140
2. Card 2017, "The problem with '5 whys'", *BMJ Quality & Safety*, vol. 26, no. 8, https://doi.org/10.1136/bmjqs-2016-005849
3. Paradies 2005, "What's Wrong with 5-Whys???", TapRooT®, https://taproot.com/whats-wrong-with-5-whys-complete-article/
4. Wan et al. 2025, "Unveiling Confirmation Bias in Chain-of-Thought Reasoning", *Findings of the Association for Computational Linguistics: ACL 2025*, https://aclanthology.org/2025.findings-acl.195/
5. Tan et al. 2014, "Bug characteristics in open source software", *Empirical Software Engineering*, https://doi.org/10.1007/s10664-013-9258-8
6. Sahoo, Criswell & Adve 2010, "An Empirical Study of Reported Bugs in Server Software with Implications for Automated Bug Diagnosis", *ICSE*, https://doi.org/10.1145/1806799.1806870

## Cross-References

- The earlier post [The Bug Loop You Can't Escape](/posts/ai-bug-root-cause-diagnosis/) laid out four lessons from root cause diagnosis. This post systematically diagnoses the failure modes when AI uses 5-Why.
- tdd-pipeline project: [https://github.com/alexwwang/tdd-pipeline](https://github.com/alexwwang/tdd-pipeline)
