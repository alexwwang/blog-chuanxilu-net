---
title: "Long Conversation Failures: Lessons from 3 Drift Disasters"
slug: "ai-3-long-conversation-fails"
date: 2026-05-23T06:00:00+08:00
draft: false
description: "AI conversations often start drifting around turns 10–15 — but not always in the same way. Three real failures: work directions cross-contaminating, data citations going wrong, and requirements bleeding across strategy documents — each broken down into what happened, why, and how to prevent it."
tags: ["AI", "toolchain", "evolution-path", "prompt engineering"]
categories: ["ai-path"]
toc: false
series: ["AI Path L0→L1 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor style: a winding paper trail across a desk, with three stations symbolizing mixed directions, data citation errors, and requirement bleed-through"
---

The previous exercise was to run a 15-turn conversation with AI, using progress summaries and new conversations as checkpoints. If you actually did it, you probably noticed something else too — drift doesn't always look the same.

The three cases below are all failures I've run into myself. Here's what happened, why it happened, and how to avoid it.

## Failure 1: Work Directions Got Mixed Together

**What Happened**

I was figuring out the approach for a project. I first discussed Approach A with AI — building a data dashboard. After 4 turns, it didn't feel deep enough, so I switched to Approach B — automated reports — for another 3 turns. Then I thought maybe we could combine Approach C's real-time push capability. Three directions kept jumping around in the same conversation for a dozen turns.

When I finally asked AI for a consolidated proposal, it paired Approach A's data source with Approach B's display logic, then added Approach C's push triggers. The three directions' individual logic got stirred together. It looked complete, but it was internally contradictory: the dashboard needed real-time querying, while the reports were generated offline at T+1. They had fundamentally different data source requirements.

**Why**

LLMs automatically look for connections inside one context window. For a single task, this is useful — it keeps the conversation coherent. But when multiple directions are mixed together, the model can combine arguments from different contexts and produce a "reasonable-looking" answer, even when those arguments only made sense in their original context.

The dangerous part is that the result often looks persuasive at first glance. Each piece is correct on its own, but the combination doesn't hold together.

**How to Prevent It**

Don't pile multiple directions into one conversation. Open a separate conversation for each direction, discuss it until you reach a conclusion, then compare the conclusions.

The rule is simple: **if two directions may affect each other's conclusion, clarify them separately first and compare later; if they don't affect each other, they shouldn't be in the same conversation at all.**

If you must compare multiple directions in one conversation — for example, when doing a side-by-side evaluation — ask AI to produce conclusions for each direction independently first, then compare those conclusions. Don't jump back and forth during the discussion.

## Failure 2: Data Citations Went Wrong

**What Happened**

I was doing a user behavior analysis. In the first 5 turns, AI and I clarified the analysis framework. In turns 6–10, I had it look at specific data and produce a few findings. By turn 11, I asked it to summarize the key findings, and one number made me pause: "Daily active users: 120K, up 8% from last month."

I scrolled back to turn 7. The original text was: "Daily active users: 112K, up 3.2% from last month." In turn 9, there was another metric called "active visiting accounts," close to 120K, measured over the last 7 days. In the summary, AI mixed together two similarly named metrics with different time windows. Worse, it also included a conversion-rate number I couldn't find anywhere. When I asked, "Which turn did this number come from?" it admitted there was no source — it had generated it. The analysis framework was still there, but the data filling that framework no longer came from the same source.

**Why**

There were two problems here.

The first was **source confusion**. LLMs processing long conversations have positional bias — information in the middle of the conversation is more likely to get lost. The original data and later supplemental data were scattered across different turns, and the metric names were similar. In the summary, AI failed to distinguish "daily active users" from "active visiting accounts," and it failed to preserve the difference between "last month" and "last 7 days."

The second was **hallucinated completion**. When it needed to produce a complete analysis but couldn't find a number in the context, it didn't necessarily stop and say "I don't know." More often, it kept generating a plausible, confident, source-less number. That number wasn't a bad calculation. It was filled in without evidence.

This kind of distortion is dangerous because it often looks "directionally right, numerically wrong, and very confident." A quick skim won't catch it. You only find it by asking for sources and verifying line by line.

**How to Prevent It**

Do two things together.

First, **save original data outside the conversation**. When AI gives you key numbers in turn 7, copy them into your notes. The conversation itself is not an archive. AI won't do version control for you.

Second, **ask AI to cite the source turn for key conclusions**. For example: "Summarize the key findings, and mark each conclusion with 'data from turn N.'" If it can cite the source, you can verify it quickly. If it can't cite the source, or if it can't explain the source when challenged, don't use that number.

## Failure 3: Requirements Bled Across Strategy Documents

**What Happened**

Once, I asked AI to write three strategy documents in the same conversation. The first was a user retention improvement strategy, focused on user segmentation and recall actions. The second was a churn prediction and identification strategy, focused on warning signals and risk levels. The first two went smoothly, so I asked it to write a third one: an analysis plan for recommendation ranking iteration opportunities.

The problem appeared in the third document. It should have analyzed where the current recommendation ranking still had room to improve, which user behaviors and business metrics could reveal opportunities, and which problems were worth checking first. But as AI wrote, it brought in material from the previous two documents. It used retention segmentation to explain recommendation ranking, then inserted churn-prediction risk logic into opportunity assessment. It still looked like a complete plan, but the core question had changed. It was no longer analyzing "what iteration opportunities exist for recommendation ranking"; it was forcing the methods from the first two documents onto the third one.

**Why**

I didn't have AI create a separate plan for the third document first. I stayed in the same conversation and simply said, "Write another recommendation ranking analysis plan." To AI, the first two documents were not finished historical tasks. They were still available context. Without a new plan to draw boundaries, it treated the retention and churn-prediction methods as reusable material for the third document.

This wasn't just "writing off topic." More precisely, the requirement boundary wasn't locked down. Retention improvement, churn prediction, and recommendation ranking analysis are adjacent but different problems. When they are generated consecutively in one long conversation, their methods start bleeding into one another.

**How to Prevent It**

Don't keep writing in the original conversation. Open a new one. The first two documents have already contaminated the context; asking AI in the same window to "not reuse them" is awkward by itself. If it can see those documents, it may still borrow from them.

The first message in the new conversation should include only the necessary background, not the full text of the previous two documents. For example: "I need to write an analysis plan for recommendation ranking iteration opportunities. The goal is to identify where the current ranking strategy can improve. First, create a plan: what problem this document should solve, which user behaviors and business metrics we need to inspect, and which analysis methods do not apply." Confirm the plan first, then write section by section.

In one sentence: **when writing adjacent topics back to back, start a new conversation from the third one onward.** Use the old conversation only to review background, not to generate the next draft.

## Summary

Three failures, three different mechanisms:

- **Failure 1 (directions got mixed)** — multiple directions cross-contaminate inside one context window, and AI assembles "reasonable-looking" combinations. One direction, one conversation
- **Failure 2 (data citations went wrong)** — similar metrics and different measurement windows get mixed together, and source-less hallucinated numbers can appear. Archive data outside the conversation + cite source turns
- **Failure 3 (requirements bled across documents)** — adjacent topics are written consecutively, and methods from the first two documents bleed into the third. Start a new conversation from the third one onward, then make a plan

The previous exercise let you experience long-conversation drift directly. This article categorizes common drift patterns by symptom and cause. Next time, we'll talk about advanced follow-up questions — moving from "asking" to "probing."

---

📖 **Series Navigation**

- Previous: [Today's Practice: A 15-Turn Conversation Experiment](/en/posts/2026/05/ai-practice-15-turn-conversation/)
- Next: Advanced Follow-ups — Using 3 Questions to Expose Hidden Assumptions in AI's Answers (coming soon)
