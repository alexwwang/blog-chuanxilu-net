---
title: "Day 11: How to Verify What AI Gives You"
slug: "ai-path-l1-l2-week3-day11"
date: 2026-07-28T11:00:00+08:00
draft: false
description: "AI Path L1→L2 Day 11: GCO works both ways: it functions as a spec on the way in and a checklist on the way back. Three no-code methods to check whether AI actually did what you asked."
tags: ["AI", "tutorial", "verification", "output quality", "GCO"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor: a beam of light passes through GCO (Goal, Constraints, Output) through a magnifying glass, landing on a verified report"
---

> This is Day 11 of the AI Path L1→L2 Upgrade Guide, a practice article. Do [Day 8]({{< relref "ai-path-l1-l2-week2-day8" >}}) and [Day 10]({{< relref "ai-path-l1-l2-week3-day10" >}}) first.

Day 10 ended with a note: description and verification are two sides of the same coin. If you can't describe what you want, you can't check whether you got it.

I default to trusting AI output, especially when it sounds confident. It's well structured, clear, and sounds right. Day 10 mentioned an example: I asked AI to "organize these files by category." It sorted them alphabetically by name. The result looked organized, but it wasn't the kind of organization I meant. At the time, I thought "I need to describe it better next time," rather than "let me check whether what it delivered is actually correct."

That pattern keeps repeating. AI produces something that looks reasonable at a glance; I skim it and move on. By the time a detail goes wrong enough to notice, I've already built on top of the mistake.

Today, I flip GCO around. It functions as a spec on the way in and a checklist on the way back. Same three fields, different direction.

None of these methods require writing code.

---

## GCO as a Checklist

The GCO you wrote to describe the task works as acceptance criteria. You just switch the direction.

Day 10 exercise 2 asked AI to analyze 2025 sales data: trends by product line, growth rates, and recommendations. Day 10 showed the difference between vague and clear descriptions. Today, I pick up where Day 10 left off: how to check the result.

Say AI finished the analysis and handed you a report. Verification starts by pulling out the original GCO and going line by line:

| GCO Field | As Description | As Verification |
|-----------|---------------|-----------------|
| Goal | Analyze sales trends by product line with growth rates. | Report covers trends and growth by product line → pass |
| Constraints | Use 2025 data only | No 2024 data mixed in → pass |
| Constraints | Quarterly aggregation | Consistent quarterly granularity → pass |
| Constraints | Independent analysis per product line | Lines `A` and `B` aren't conflated → pass |
| Constraints | Flag growth below 10% | Product `C` marked "slowing" → pass |
| Output | Table, line chart, three key findings (one sentence each) | Table and chart present; five findings returned, but two exceed one sentence → fail, ask AI to condense |

One pass through the checklist and you know exactly what's off. No more "something feels wrong about this." You point at "Output says three findings, you gave me five, please consolidate."

I keep the GCO in a note after sending the task. When results come back, I tick through the checklist; the process takes about three minutes.

---

## Invariant Checks

Some things shouldn't change simply because AI processed the data. Find the properties that must stay the same regardless of what analysis happens.

Let's go back to the sales example:

- **Row count**: 1,024 rows in, 1,024 rows out. AI won't delete data intentionally, but it might decide a row looks "anomalous" and filter it out.
- **Key identifier columns**: Order IDs, user IDs. These are anchors. If they change, you can't trace back to the source.
- **Raw values**: AI can compute aggregates, but it shouldn't round individual values to the point where the underlying data is distorted.
- **Source categories**: Raw data has `A`, `B`, and `C` categories. The result shouldn't invent category `D`.

The most straightforward approach is to have the AI verify its own output.

> Check your analysis: did the total row count change? Were any order IDs modified? Are there categories in the output that don't exist in the source data? Answer each one.

Not sure what's invariant? Have AI figure it out:

> You're about to process this dataset. First, list the properties that must never change no matter what analysis you perform. Then, explain how you will verify each one.

AI lists the properties. You review them, confirm the right ones, and add missing ones. Two minutes.

---

## Reverse Checking

GCO checklist checks completeness. Invariant checks check correctness. Reverse checking goes further: it assumes the result is wrong, then finds where it broke.

**Method 1: Likelihood list.**

> Pretend this analysis result is already wrong. List 10 potential failure points, ordered by probability.

AI will likely list issues such as an incorrect data source, a faulty aggregation formula, an improper time range, or unhandled null values. If any of these are directions you haven't checked, you now have a to-do list.

**Method 2: Sabotage testing.** Have AI play auditor against its own work.

> Now act as a reviewer. Find every issue in this report, the more detailed, the better. Tag each with a risk level and a fix recommendation.

AI will produce some false positives. You skim the reviewer's output, filter out the false positives, and find problems you might have missed even with a more thorough description.

---

## Human in the Loop

![Verification gradation: GCO checklist → Invariant checks → Reverse checks](illustration-verification.png)
The depth of these three methods depends on how critical the task is:

- 🟢 **GCO checklist**: Every task. 3 minutes. The GCO is already written. Just tick through it.
- 🟡 **Invariant checks**: Critical tasks. 5 minutes. It's worth it for anything involving data, configuration, or batch operations.
- 🔴 **Reverse checks**: High-risk tasks. 10 minutes. Anything involving money, permissions, or external delivery.

You are not the one doing the manual checking. AI handles the bulk of verification: scanning a thousand rows in under a minute, listing possible failure modes, and questioning its own output from different angles. Your job is judgment. Is this deviation acceptable? Does that risk need action?

GCO's value closes the loop here. You used it to say what you wanted. You used it to confirm that's what you got.

---

## Today's Practice

Pick a task you'd give AI today, preferably with data output or text generation. Run it through:

1. **GCO checklist**: Turn your original GCO into an acceptance checklist and check off each item.
2. **Invariant check**: Ask AI to list immutable properties and verify each one.
3. **Reverse check (optional)**: Have AI attack its own result.

### Today's Takeaways

- [ ] GCO works both ways: as a description tool and a verification tool.
- [ ] Can use GCO as a checklist to verify AI output line by line.
- [ ] Can identify invariants and have AI self-verify critical properties.
- [ ] Know two reverse-checking methods: likelihood lists and sabotage testing.
- [ ] Can choose verification depth based on task importance (3 / 5 / 10 minute tiers).

---

Description and verification covered. [Day 12]({{< relref "ai-path-l1-l2-week3-day12" >}}) is next: your AI toolbox, how to combine APIs with autonomous AI agents, and when to reach for which.
