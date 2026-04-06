---
title: "claude-code-reflect: Same Metacognition, Different Soil"
date: 2026-04-06T14:56:00+08:00
draft: false
description: "The same reflection mechanism lands on different platform foundations with very different landing postures and paths—from plugin installation to permission pitfalls to API concurrency, documenting the actual development process on Claude Code."
tags: ["AI", "agent", "claude-code", "reflection", "claude-code-reflect"]
categories: ["AI Practice"]
series: ["Teaching AI to Reflect"]
toc: true
---

Same metacognitive ability, different soil. The growing patterns look nothing alike.

My previous post on Aristotle (the reflection skill on OpenCode) had three core principles: immediate trigger, session isolation, human in the loop. These sound platform-agnostic. But when I moved the same philosophy to Claude Code, I discovered something: platform differences are much larger than expected.

## First Hurdle: Plugin System Differences

Claude Code's plugin and OpenCode's skill are completely different systems. Just getting the plugin installed and recognized took several rounds of struggle.

The marketplace.json format was wrong. Plugin installed but wasn't recognized. Skill call path was wrong, system couldn't find the entry point. Loading mechanism misunderstood, configuration changes wouldn't take effect. AI repeatedly failed installation. It took multiple rounds to figure out the correct format and location.

This raises a question: why does the same model-driven Vibe Coding, when designing tasks with the same goals in Claude Code, not even get the plugin system right? The answer: implicit rules of different platforms run deeper than surface differences. I used to think OpenCode's skill system and Claude Code followed the same protocol. Highly similar. In practice, I discovered Claude Code's plugin loading mechanism, configuration format, and path conventions all have detailed differences and extra restrictions. Experience the model accumulated on the first platform can't be directly migrated. Each ecosystem's "common sense" details need to be learned again. Checking documentation is still important. It just shifted from humans checking to teaching AI to check.

What looks like "same standard protocol + switch platform" is actually understanding another ecosystem's design details from scratch.

## Second Hurdle: Permission Model Pitfalls

The real problem was yet to come. The same reflection subagent design went smoothly on OpenCode. On Claude Code, it hit walls repeatedly. When the reflection task started, the main session conversation got constantly interrupted by user confirmation popups from subtasks. Users typed in the wrong place easily. This caused serious context pollution. Wrong responses led to AI misunderstandings.

The subagent often failed to start entirely. Reflection tasks that did start often executed in the main session instead. This blocked the user's workflow and seriously polluted the context. The experience completely deviated from the goal design. Unacceptable.

<details>
<summary><strong>Why does this happen?</strong> (Click to expand technical details)</summary>

The root cause is non-atomic preparation. Starting a reflection task involves multiple independent steps: generating a session UUID, creating a directory, writing state.json, writing the prompt file, launching a background subprocess. In Claude Code's default `ask` permission mode, each Bash or Write call triggers a user confirmation popup. Between each popup, control returns to the main session. The user's next message might slip in—at best the preparation flow is interrupted, at worst the reflection task starts directly in the main session and the context is completely polluted.

The V1 solution introduced `bypassPermissions`: skip all confirmation popups and let the preparation flow complete in one go. This did solve the interruption problem, but `bypassPermissions` does more than that—it changes the entire reflection flow's permission model. When background sub-sessions run in non-interactive mode, without it even basic file writes are rejected. In other words, `bypassPermissions` on one hand guarantees atomicity, on the other hand becomes the source of subsequent permission issues. I'll continue discussing this detail below.

</details>

<p></p>

After finally getting the subagent to start (V1 version refactoring introduced the bypassPermissions solution), file writes were rejected again. After some investigation, I discovered:

> Claude Code's background sub-sessions have a confirmed bug: `bypassPermissions` silently rejects writes outside the project root directory.

When the solution hit this bug, it manifested as: user-level rules (like skill updates under `~/.claude/skills/`) precisely needed to write outside the project root directory. But background sub-sessions were designed as non-interactive. The locations they needed to write happened to be on the permission boundary. So **saving files failed**.

## Exploring Around the Pitfall: Solution Iteration v2→v3

So I came up with a v2 solution to work around the write permission problem: move all final writes to the user-confirmed interactive session (resumed session). The background sub-session would only do analysis and generate drafts. This way the background sub-session only writes to `.reflect/reflections/{id}/` inside the project root, avoiding that bug.

But v2 still had problems: the atomicity of the preparation phase was forgotten. If the preparation process was interrupted, it would leave an inconsistent state. The problem that was solved in the V1 refactoring came back.

So I continued with a v3 solution, merging all preparation steps into a single Bash command to eliminate the interruption window. At the same time I decided to abandon the OMC dependency and only maintain the standalone branch.

### Why Abandon OMC Dependency

OMC brings two core capabilities:
1. `notepad_write_priority`, for cross-compaction notification—when the background subagent completes analysis, it injects a priority notification through notepad, ensuring the reminder is still visible after context compression. But in the v3 version's redesigned write path, users need to actively resume the subagent session to do review and writing, so the value of this notification mechanism has greatly decreased—users already know they triggered a reflection. `/reflect inspect` and `/reflect list` are enough.

2. `project_memory_add_note` / `project_memory_add_directive`, providing structured project memory management. Standalone uses the Write tool to directly write `.reflect/project-memory.json`, functionally equivalent, just without OMC's unified management layer. For this project's usage scenario, the difference is barely perceptible.

So the conclusion is that standalone is completely sufficient. The OMC dependency in the main branch isn't cost-effective:
* First, OMC itself needs separate installation, an extra installation step and cognitive burden for users, while the benefits it brings are already marginal.
* Second, standalone's file-based solution is more transparent—which file gets written, what gets written, users can see and control completely, fitting this project's human-in-the-loop design philosophy.
* Third, maintaining two branches itself has ongoing costs. Every time SKILL.md changes, it needs to be synchronized, and I already have the write path redesign big change to do.

So I had the v3 solution:

| Phase | Session Type | bypassPermissions | Write Scope |
|---|---|---|---|
| Preparation | Main session (1 atomic Bash call) | Yes—for atomicity | `.reflect/reflections/` |
| Background Analysis | Background sub-session | Yes—required for non-interactive writes | `.reflect/reflections/{id}/` |
| Review+Write | Interactive (resumed) session | No | `.reflect/` + `~/.claude/` |

## Bumpy Implementation Based on v3 Solution

I used a ralph loop to execute the v3 solution changes. Cross-platform path compatibility is a detail—Windows Git Bash and POSIX systems handle paths differently.

This step went relatively smoothly. The v3 solution drew a clear boundary between "preparation" and "analysis," concentrating on solving write permission issues. What came next was where I really stepped into pitfalls.

### Testing Found That Bypass Can't Be Removed

In theory, the background sub-session only writes to `.reflect/reflections/{id}/` inside the project root. So `bypassPermissions` shouldn't be needed.

In practice? Without it, I couldn't even write files. Theory and platform reality don't always agree.

The final solution added back `bypassPermissions`, and at the same time added path restrictions in the prompt as defense in depth: open in permissions, constrained in logic.

A table to review the V1→V3 iteration. Looking back it's simple, but figuring it out really took some effort:

| Dimension | V1 | V2 | V3 |
|---|---|---|---|
| Preparation Phase | Multi-step independent calls, can be interrupted | Multi-step independent calls (same as V1) | Single atomic Bash command |
| Background Write Location | Tried to write `~/.claude/` (rejected) | Only write to project root | Only write to project root |
| Final Write Location | Background sub-session writes directly | Moved to resumed session | Moved to resumed session |
| bypassPermissions | Introduced—suppress popups | Tried to remove—theoretically not needed | Added back—actually required |
| OMC Dependency | Yes | Yes | Abandoned, standalone only |

Iteration isn't linear progress, but constant trade-offs between atomicity, permission safety, and dependency complexity. Each solution solves the previous version's problems, then exposes new boundary conditions.

### Testing Found API Concurrency Errors

Another problem surfaced during testing. Main session and sub-session share the API endpoint. Concurrent requests triggered ECONNRESET errors.

Troubleshooting took a few detours. First I tried specifying a different model — suspected a model switching issue. Checked third-party API configuration — suspected a routing problem. Finally confirmed: the API I was using had a concurrency limit. Concurrent requests to the same endpoint get rejected. Switched to an API with looser limits, problem gone.

### Solution: Retry Mechanism

Since concurrency limits objectively exist, let's add a retry mechanism:

```bash
(
  MAX_RETRIES=3
  RETRY_DELAY=10
  attempt=0
  while [ $attempt -lt $MAX_RETRIES ]; do
    claude -p "$(cat prompt.txt)" --session-id $SESSION_ID --model ${REFLECT_SUBAGENT_MODEL:-sonnet} --permission-mode bypassPermissions --output-format json 2>>stderr.log
    [ $? -eq 0 ] && break
    attempt=$((attempt + 1))
    sleep $RETRY_DELAY
  done
) &
```

The background pulls up a sub-shell wrapping the `claude -p` call. After failure it waits 10 seconds and retries, up to 3 times. At the same time add a configurable model parameter `REFLECT_SUBAGENT_MODEL`, allowing users to choose the model according to their own API's concurrency limits.

Verification succeeded, matching expectations. But this is an uncontrollable risk from outside. The current design mechanism can only mitigate its impact, cannot completely eliminate it.

## Finally: 6 Known Issues Remain

Not every problem has an elegant solution. Let's honestly face the unresolved problems:

1. The preparation phase confuses users (looks like freezing, actually analyzing in the background)
2. No way to automatically notify the user when the sub-session completes
3. Session ID might conflict during retry
4. Read tool doesn't display accurately when rendering markdown
5. Insufficient error recovery options
6. Cross-compaction notification reliability

Solving these problems requires platform-level support, or making trade-offs under current constraints. Engineering is like this—not all problems have perfect solutions.

## One more thing: The Value of AI-Driven Testing

The entire testing process was completed by AI. This isn't the point. The point is that several problems discovered during testing were in the blind spot of the original solution documentation: `bypassPermissions` permission is a platform characteristic, not a design problem. API concurrency is an environment limitation, also not a design problem. `heredoc` variable not expanding is a Bash implementation detail, even less a design problem.

If designed in traditional ways, these problems might only be exposed after launch. Letting AI test the system, AI can discover unforeseen edge cases in human solutions. This point is worth emphasizing—if you're designing a system, let AI test it. AI isn't just an executor, it's also a participant in design verification.

## Next Post Preview

The next post will systematically compare the differences between the two systems—from skill systems to permission models to concurrency control to underlying design philosophy, seeing what the same metacognitive mechanism grows into on different soil, and what insights it gives us for future AI practice.
