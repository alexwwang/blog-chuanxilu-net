---
title: "Aristotle: Teaching AI to Reflect on Its Mistakes"
slug: "aristotle-ai-reflection"
date: 2026-04-06T10:00:00+08:00
draft: false
description: "Installing reflection capability into AI coding assistants—when the model makes a mistake, immediately trigger root cause analysis and transform the correction into persistent rules."
tags: ["AI", "agent", "opencode", "reflection", "aristotle"]
categories: ["AI Practice"]
series: ["Teaching AI to Reflect"]
toc: true
---

"Knowing yourself is the beginning of all wisdom." — Aristotle

Every time I work with an AI coding assistant, I run into the same problem.

Mistakes that were corrected get repeated in the next session. The model isn't stupid. There's a structural gap in memory.

For example. Last week I corrected a mistake the model made. It apologized, I accepted, we kept working. Today I started a new session, and the same mistake appeared again.

The correction just... evaporated.

This isn't a one-off problem. It's the norm in every conversation. The model remembers the current context, but not the mistakes it made before and how they were corrected.

This made me realize something. The best time to reflect is right when the mistake happens. No delays. No switching tools. No interrupting the current workflow.

When cognitive balance breaks — the model makes a mistake, the user corrects it — the metacognitive rebalancing should start soon after the conflict appears. But it shouldn't interfere with the original task.

I learned this from cognitive science. But the Vibe Coding tools and plugins I use don't have this capability yet.

So I built one.

## Three Design Principles

When designing Aristotle, I set three principles for myself.

**First**, let the user trigger reflection, but remind them. When a signal of error correction is detected, remind the user to run `/aristotle`.

Don't make them actively think, "Oh, I should record this mistake." The user might be focused on correcting a complex error and forget to reflect.

But full automatic reflection carries a risk. If the user hasn't finished entering the full correction before reflection starts, the reflection will likely be incomplete.

**Second**, complete session isolation. The reflection process happens in a background sub-session with zero pollution to the main session context. It won't affect the current task.

Also, when the model makes a mistake, the user might already be impatient. If the main flow has to wait for a reflection task before continuing, the user experience would be terrible.

Another benefit of isolation is that the reflection session can access the complete conversation history without disrupting the current work rhythm. After all, reflection is the model's responsibility, not the user's obligation.

**Third**, "human in the loop". Generated rules don't get persisted without user approval.

AI might mistake a temporary correction for a general rule. Or treat a special case as a general pattern. The user's judgment is the last line of defense.

## How Aristotle Works

The core is 5-Why root cause analysis. Starting from the surface error, ask "why" layer by layer to find the true root cause.

For example. If the model outputs incorrect code, the first layer asks why — it might be misunderstanding the requirement. The second layer asks why the misunderstanding — maybe context information is insufficient. The third layer asks why insufficient — maybe the user didn't explicitly state a constraint.

Asking five times usually pinpoints the problem.

Errors are divided into 8 categories: MISUNDERSTOOD_REQUIREMENT, ASSUMED_CONTEXT, PATTERN_VIOLATION, HALLUCINATION, INCOMPLETE_ANALYSIS, WRONG_TOOL_CHOICE, OVERSIMPLIFICATION, SYNTAX_API_ERROR.

Classification isn't the goal. It's to make subsequent rule matching more precise.

Rules are divided into two levels: user-level and project-level. User-level rules follow the individual. Project-level rules are shared within the team.

The specific scope judgment mechanism is an engineering detail, so I won't go into it here. What matters is that the layered rules let the results of reflection be reused in the appropriate scope — neither over-generalized nor limited to one person's experience.

oh-my-opencode's background tasks naturally support isolated sub-sessions. The main session triggers a background task. The Reflector reads the conversation history in a completely isolated environment, does root cause analysis, and generates rule suggestions.

The entire process is transparent to the user and doesn't interrupt the workflow.

## Smooth Implementation

OpenCode's skill system plus the omo background task infrastructure made Aristotle's implementation surprisingly smooth. It only took 3 commits.

The first commit was the complete SKILL.md, 394 lines. I wrote the entire protocol in one go — including the Coordinator-Reflector dual-layer architecture, the 5-Why root cause analysis template, and the Stop Hook automatic detection logic.

Coordinator only does lightweight orchestration. It collects metadata like session ID, project directory, and language. Reflector does the reanalysis in a completely isolated background session.

This design was clear from the start. No back and forth adjustments.

The second commit was the test script. 37 static assertions plus E2E live tests. The tests covered the complete chain from trigger mechanism to rule generation.

When writing tests, I found several edge cases — like empty conversation history and multi-round correction scenarios. I added explanations for these in the SKILL.md.

The third commit was the README. Writing down the design philosophy and usage clearly, bringing this project to a close.

The whole process went smoothly without unexpected technical obstacles.

Not because the problem was simple. But because OpenCode's infrastructure already solved the hardest parts. The skill system makes implementing custom commands natural. The omo task() background task natively supports session isolation. The session read/write APIs are complete.

I just had to combine these capabilities and express Aristotle's design philosophy with a clear framework.

## Reflection Itself Is Worth Reflecting On

I thought about the name Aristotle for a long time. I finally chose it because of that sentence.

"Knowing yourself is the beginning of all wisdom."

Giving AI the ability to reflect is essentially letting AI recognize its own limitations. This isn't simple error recording. It's structured metacognition.

The model makes mistakes not because it's smart or stupid. It's because it has no awareness of its blind spots. Aristotle makes these blind spots explicit through root cause analysis and transforms them into learnable rules.

There's a concept in cognitive science called metacognition. It refers to "thinking about thinking," or "knowing what you know and knowing what you don't know."

Human learning largely depends on metacognitive ability. When we encounter difficulties, we stop and reflect. "Why did I make this mistake?" "How to avoid it next time?"

This reflection isn't accidental. It's a core link in the learning process.

What AI was missing is exactly this link. The model can learn and adjust in real-time during conversations, but this learning is temporary and situational. After the session ends, the experience is lost.

Aristotle structures this link. It lets the model "know what it doesn't know" and transforms this awareness into persistent knowledge.

This isn't magic. Rules generated by Aristotle still need human review. The application scenarios of rules might also have limitations.

But it fills the metacognitive link at the system level. It makes AI's learning go from temporary and isolated to persistent and accumulative.

## What's Next

Moving the same philosophy to Claude Code wasn't that simple.

OpenCode has a complete skill system and background task infrastructure. Implementing Aristotle was a natural fit. Claude Code's environment is different. Many capabilities need to be redesigned.

In the [next post](/en/posts/2026/04/claude-code-reflect-different-soil/), I'll talk about this process and the technical challenges encountered. The core philosophy stays the same, but the implementation path is completely different.

The key to mastering AI isn't prompts. It's giving AI the ability to learn from mistakes. This is the starting point of this series. And what I consider the most important point.
