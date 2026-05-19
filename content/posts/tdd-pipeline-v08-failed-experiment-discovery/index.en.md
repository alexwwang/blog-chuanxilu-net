---
title: "What a Failed Experiment Got Right"
slug: "tdd-pipeline-v08-failed-experiment-discovery"
date: 2026-05-19T18:00:00+08:00
draft: false
description: "I tried refining the pre-release testing phase of my TDD Pipeline by replacing step-by-step instructions with principles. The refined version failed at its core job. But comparing where it failed against where it unexpectedly succeeded revealed that individual defect diagnosis alone wasn't enough — it needed a systematic scanning layer on top."
tags: ["AI", "TDD", "skill design", "experiment methodology", "pre-release testing"]
categories: ["AI Practice", "Breaking to Build: TDD Process Iterations"]
series: ["Breaking to Build: TDD Process Iterations"]
toc: true
cover:
  image: "cover.png"
  alt: "An experiment dashboard where every expected metric shows red — except one gauge in the corner, glowing green"
---

> Series: Breaking to Build: TDD Process Iterations (first post)

> **TL;DR:** I refined Phase 6 (pre-release testing) of the TDD Pipeline from step-driven to principle-driven. The goal was better output. I didn't get it — the refined version was worse at drilling into individual bugs and building evidence chains. But comparing the two outputs revealed dimensional differences. The refined version was better at component gap checking and cross-bug pattern scanning. Those differences pointed to a judgment call: Phase 6 doesn't need refining. It needs a layer on top of it. That layer later became Phase 7.

## Background

I built a skill called TDD Pipeline. It came out of pain — real pain from debugging over a dozen bugs. The skill defines every stage of development, from requirements to delivery, with an independent review gate at the end of each stage.

When I added Why Articulation to the TDD skill, I ran a set of A/B experiments [2]. One finding surprised me: giving the AI positive examples actually reduced output quality. The model took a shortcut — it mimicked the examples instead of reasoning independently. A better approach was to give it principles. Tell it what to protect, where the risks are, and why the method works. Let it figure out the how on its own.

That finding only applied to one stage of the Pipeline. But it raised a bigger question. If "principles, not steps" works at the prompt level, does it work at the level of an entire rules file?

I tried it. Refining Phases 1 through 5 (requirements → solution → test plan → test code → business code) worked. The AI independently reconstructed the steps I had removed.

What about Phase 6?

## Result: The Refined Version Fell Short

Same diagnostic tasks, same comparison between the original version and the refined version. The refinement strategy was consistent: keep principles and counterexamples, remove operational details. The refined version showed no clear improvement. In some scenarios, it regressed.

It missed known bugs. It got severity calls wrong. Its fix proposals contained technical errors. The original version beat it across every core task.

## But It Was Different in Other Ways

The refined version led significantly in one dimension: component gap checking.

Pre-release testing isn't just about finding bugs in individual components. It's about catching mismatches where components meet. Can the downstream component handle the data format coming in? If this component crashes, does the next one know? Are they reading the same configuration?

The original version checked 3 component interaction pairs. The refined version checked 6 — double.

The original version only looked at direct calls between adjacent components. The refined version also caught indirect data flows — Component A writes data, Component B reads it from shared storage, no direct call between them but an implicit dependency. One of those implicit data flows exposed a real architectural issue.

There was another difference. Same bug, different framing. The original version flagged "this file has risk." The refined version flagged "this pattern appears in multiple places across the project."

The original version saw a single bug. The refined version saw a bug pattern.

And execution order analysis: same bug in a check routine. The original version found it and said "this check is too blunt — it clears data it shouldn't." The refined version also found it, but pushed one step further: the blunt check caused an early exit, so a more precise check downstream never ran at all.

The issue wasn't that the precise check made a bad judgment. The issue was that it got skipped entirely.

## What Those Differences Point to

What the original version does well — drilling deep on a single bug, running a five-layer drill-down to root cause, pairing every finding with concrete fix code — those are the core tasks of Phase 6. The refined version regressed on exactly those tasks.

What the refined version did differently — more component gap checks, cross-bug pattern scanning, execution order analysis — all point to the same tendency. Stepping back from individual bugs and looking at the project as a whole.

This isn't the refined version being better at Phase 6's job. This is the refined version doing something Phase 6 was never designed to do. The original version's attention was fully consumed by "drill into the next bug." It had no bandwidth left for anything else. The refined version lost its step-by-step guidance, so it wasn't locked into "what's next" — but it didn't do the core job better. It started doing a different job, and the cost was regression on what actually mattered.

Comparing the two dimensional profiles, a shape emerged. Phase 6 is good at drilling into bugs one at a time. But nobody stands above it, scanning for systemic issues across the whole project.

![Two columns of dimensional bars with a shape emerging from the negative space between them](illustration-1.png)

## The Missing Layer

Once I recognized that shape, Phase 7 had a definition: systematic scanning. Check the gaps between components. Analyze execution order. Scan for bug patterns that appear in multiple places. Phase 7 wasn't refined out of Phase 6. It was identified from the direction the refined version drifted toward.

Once Phase 7 was defined, the question became: how do I add it without losing Phase 6's drilling precision?

The answer isn't "refine Phase 6." The refined version was genuinely worse at its core job. The answer is: roll Phase 6 back to the original version, and add Phase 7 as an independent stage on top. Two layers, each doing its own thing. Phase 6 drills deep. Phase 7 scans wide.

The refined version failed at its stated goal — improving Phase 6. But the shape of that failure, where it was worse and where it was different, exposed a gap I couldn't see before.

The next post covers the refinement experiment for the first five stages. Comparing that success against this failure makes it clearer why Phase 6 couldn't be refined — and how Phase 7 grew out of the shape of the failure.

---

> Next in the series: [Using the Method to Improve the Method](/en/posts/tdd-pipeline-v07-refinement-experiment/)

---

## References

1. Endless Bugs and an Inescapable Loop: AI-Assisted Root Cause Diagnosis in Practice: [ai-bug-root-cause-diagnosis](/en/posts/ai-bug-root-cause-diagnosis/)
2. All Tests Green, System Broken: 18 Bugs and Six Ways They Kill: [six-bug-patterns-and-integration-gaps](/en/posts/six-bug-patterns-and-integration-gaps/)
