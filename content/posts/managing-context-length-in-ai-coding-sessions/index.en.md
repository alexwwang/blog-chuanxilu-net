---
title: "Context Rot: An Easily Overlooked Problem in AI Coding"
slug: "managing-context-length-in-ai-coding-sessions"
date: 2026-04-18T10:00:00+08:00
draft: false
description: "Someone in a group chat complained that GPT-5.4 performed worse than Doubao, ByteDance's chatbot—the model would give irrelevant answers without even reading the question. After asking some follow-up questions, I learned they had fed it many documents and the conversation had gone on for a long time. This probably wasn't the model's problem—it was context rot. The conversation had gotten so long that the model could no longer 'see' the current task clearly. This raises an overlooked problem: in the process of vibe coding or writing, how do you manage context effectively to avoid token and time wasted on model performance degradation?"
tags: ["AI", "agent", "context management", "context rot", "opencode", "claude-code"]
categories: ["AI Practice"]
cover:
  image: "cover.png"
  alt: "Context rot: an easily overlooked problem in AI coding"
toc: true
---

Yesterday someone in a group chat said GPT-5.4 performed worse than Doubao. When they asked questions, the model would often give irrelevant answers without even reading the question. I asked a few follow-up questions and found they had fed it a lot of documents, and the conversation had gone on for many turns. This probably wasn't the model's problem—it was context rot.

I've had similar experiences myself. After talking to a model for a long time, it starts "forgetting" what we discussed earlier, or repeats mistakes that were already corrected. The model hasn't gotten stupider. The conversation has just gotten too long.

This article systematically discusses how to manage context effectively during vibe coding or writing, to avoid token and time wasted on context rot.

## What Is Context Rot

The term "context rot" was first used in a Hacker News discussion in June 2025. In July, Chroma Research published the first systematic research report, testing 18 mainstream models (GPT-4.1, Claude 4, Gemini 2.5-Pro, etc.) and found that model accuracy dropped 20-50% as input tokens grew from 10K to 100K[1]. In September, Anthropic formally adopted this term in their official engineering blog "Effective context engineering for AI agents"[2], spreading it widely throughout the industry. It's not about running out of the context window—the model's performance degrades long before reaching that limit.

The root cause lies in the transformer's self-attention mechanism. Self-attention uses softmax normalization—the sum of weights must equal 1. This means attention is a zero-sum game: the longer the context, the more tokens participate in distribution, and the less attention weight each token receives. From 10K to 100K tokens, the average attention weight for a single token shrinks by about 10 times. The information hasn't disappeared. It's just been diluted to the point where it can no longer affect the output. A 2023 study by Xiao et al. called the discovery that "attention anchors must be retained at the beginning" in this phenomenon "Attention Sinks"[3], further explaining why model efficiency at using information from the middle of context drops sharply in long contexts.

More troublesome is the U-shaped position bias. Transformers naturally tend to pay more attention to tokens at the beginning (primacy effect) and end (recency effect), while information in the middle receives significantly less attention. A 2023 paper by Liu et al. named this phenomenon "Lost in the Middle"[4]—the model's ability to retrieve information from the middle of context is clearly weaker than from both ends. A 2026 study by Chowdhury further proved that this bias is not a side effect of training, but an inherent property of the causal decoder + residual connection architecture[5].

Autoregressive generation also compounds errors. Each token's generation depends on the output of all previous tokens, including small biases that may have occurred earlier. A single token's bias may be trivial, but after accumulating over thousands of steps, the model may unconsciously drift in the wrong direction.

In plain English: **the longer the conversation, the less clearly the model "sees" the current task; things said in the middle are most easily ignored.**

This isn't a problem with any particular model. It's an inherent characteristic of the transformer architecture. GPT-5.4, Claude, Doubao—as long as the foundation is transformer, they can't escape this constraint. The difference is only where degradation starts and how fast it progresses.

## How Common Is the Problem

I pulled compaction records from my own OpenCode session database. Compaction is automatic summary compression that tools do when context approaches full capacity—the frequency at which it occurs indirectly reflects the severity of context rot.

30 compactions, distributed across 7 sessions:

| Session | Total Messages | Compaction Count | Avg Tokens Before Compaction |
|---|---|---|---|
| Reflection Skill Dual-Platform Blog Series Planning | 992 | 9 | 80,273 |
| Git-Based Aristotle MCP Solution Design | 844 | 5 | 114,697 |
| Technical Blog Series Part 4 Topic Planning | 542 | 3 | 108,893 |
| Fix opencode config paths in docs | 306 | 3 | 82,235 |
| Aristotle Series "Smooth Implementation" Section Warning Setup | 115 | 5 | 19,225 |
| Hugo Personal Blog Overall Plan | 196 | 3 | 39,294 |
| Git Initialization and Project Assessment Report Generation | 182 | 2 | 86,209 |

All 7 sessions experienced compaction. The longest one—the blog series planning—had 992 messages and was compressed 9 times. Looking at it by conversation turns is more intuitive:

| Compaction # | Cumulative Messages | Tokens Before Compaction | Messages Since Last Compaction |
|---|---|---|---|
| 1 | 45 | 59,599 | — |
| 2 | 141 | 101,614 | 96 |
| 3 | 277 | 80,659 | 136 |
| 4 | 403 | 63,297 | 126 |
| 5 | 467 | 74,360 | 64 |
| 6 | 561 | 105,226 | 94 |
| 7 | 657 | 93,583 | 96 |
| 8 | 796 | 76,208 | 139 |
| 9 | 910 | 67,913 | 114 |

The number of conversation turns between compactions fluctuates between 64 and 139. This means context fills up every 60-140 turns (including tool calls, file reads, code output). And these data only reflect the frequency of context compression—before compression happens, context rot is already occurring.

Below are five response strategies I've summarized from practice, arranged in chronological order of when they're encountered in a task.

## Strategy 1: Start a New Session for New Tasks

This is the simplest and most easily overlooked one.

A session has been running for two hours. The context is already heavy. You say "let's switch to something else"—continue in the current session, or start a new one?

Continuing in the current session means the new task's context has to share space with the old task's history. File contents from the old task, decision reasoning, error corrections—they're all there. According to the context rot principle above, longer context means more severe attention dilution—when the model processes the new task, its attention gets scattered by information from the old task. Worse, the model might "extract" irrelevant patterns from the old task's context, interfering with its judgment on the current task.

Looking back at my data confirms this. That 992-message session on "reflection skill dual-platform blog series planning" contained three logical units: writing the first blog post, writing the second blog post, series planning discussion. By all rights it should have been split into three sessions. But it wasn't—three serialized posts needed coherence, and keeping them in one session let the model "remember" the style and conventions established earlier. This touches on the boundary between compacting and splitting sessions, which Strategy 5 will explore in detail.

**Core judgment: if the new task isn't in the same logical unit as the current task, start a new session.** If multiple tasks have strong dependencies—where later output quality directly depends on earlier context—keep them in the same session, but pair it with proactive compacting. Developing and testing the same feature can share a session, but developing feature A and designing feature B shouldn't. Otherwise, if you're just "doing it on the side," don't be lazy—start a new session.

One rule of thumb: when you find yourself repeatedly reminding the model "we're doing X now, not Y," you should have started a new session long ago.

## Strategy 2: Don't Load MCPs and Skills You Don't Need

After starting a new session, the next step is to control the context baseline at initialization.

Every loaded MCP server and skill occupies context space[6]. Even if your current task doesn't use them, their tool descriptions, parameter schemas, usage instructions are already in the context. According to the attention dilution principle, this irrelevant information will scatter the model's attention from the current task.

Actual impact: if you've installed 10 MCP servers, each registering 5-8 tools, 50-80 tool descriptions permanently reside in context. Every time the model responds, it has to "see" these tools, even if the current task only needs 3 of them. Anthropic's subsequent engineering blog specifically analyzed this problem and proposed using code execution to replace direct tool calls to compress token consumption[7].

Claude Code's skill system uses semantic matching for on-demand loading—only loading the description, not the full content[8]. But even so, descriptions from dozens of skills add up. MCP servers are heavier—every server registers the complete schema for all tools when it starts.

**Principle: only load tools necessary for the current task.** MCP servers can be configured per project (`.mcp.json`), no need for global loading. Keep only skills you actually use, clean up unused ones regularly.

OpenCode has similar layering: skills load on-demand (descriptions stay resident, full content enters context only when invoked), while MCP servers register complete schemas at startup—higher loading cost. The difference in context overhead between the two maps directly onto the principle of "don't load what you don't need."

## Strategy 3: Delegate Subtasks to Subagents, Isolate Context

Once in the execution phase, the most effective context management tool is isolation.

This is the most important lesson learned from Aristotle's development. The initial Aristotle injected the complete 371-line SKILL.md of the reflection protocol into the main session. Reflection is a subtask, but all its details—the 5-Why analysis template, error classification, rule generation protocol—were crammed into the main session's context. After the reflection subagent finished, `background_output(full_session=true)` pulled the complete RCA report back into the main session. Result: the main session's context got completely polluted by the reflection task, and the main task's space was squeezed out.

The redesigned solution uses Progressive Disclosure: 371 lines split into 4 files, loaded on demand. The Coordinator only does lightweight orchestration (84 lines), while Reflector runs in an isolated sub-session. The main session only receives a one-line notification.

This lesson can be generalized: **any subtask with a complex intermediate process should be executed in an isolated environment, bringing only the final conclusion back to the main session.**

Applicable to:
- **Code exploration**—let the subagent search the codebase, return only a conclusion summary
- **Solution design**—let the subagent do multi-solution comparison, return only the recommended solution and rationale
- **Test execution**—let the subagent run tests, return only pass/fail and key error information
- **Documentation generation**—let the subagent write the first draft, the main session only reviews and revises

The subagent's intermediate process—search paths, trial-and-error records, intermediate versions—takes up a lot of context but doesn't help subsequent work at all. Isolated execution means these intermediate products only exist in the subagent's own context and won't pollute the main session.

## Strategy 4: Roll Back on Wrong Responses Immediately, Don't Repeatedly Correct

During execution, how you handle errors directly affects context quality.

The AI gives wrong code. You point out the error. It apologizes and gives a modified version—still wrong. You correct it again. It modifies again. After three rounds, six more messages are in the conversation, and the context is stuffed with wrong code, corrections, wrong again, corrections again. These intermediate processes don't help subsequent work at all, but they very much occupy context space. According to the attention dilution principle, they're weakening the model's attention to key information about the current task.

Worse, repeated corrections can establish wrong "inertia" in the conversation. In subsequent responses, the model might reference previous wrong versions and bring back already-corrected problems.

**Correct approach: upon discovering a wrong response, roll back directly to the state before the error, then give the correct instruction again.** Don't patch on top of errors, don't let the error process pollute the context.

Specific operations:

- **Claude Code**: `/rewind` command (alias `/undo`), or press Esc+Esc. Supports three rollback modes: roll back code only, roll back conversation only, roll back both. Rollback is based on automatically created checkpoints, created before every file edit[9].
- **OpenCode**: `session.revert()` API, with a rollback button in the UI. Two modes: roll back conversation only (keep file modifications), roll back conversation and code.

⚠️ Two points to note. First, neither rollback tracks side effects from Bash commands—if you executed `npm install` or `rm` in Bash, rollback won't undo these operations. Second, the habit of rollback is very counter-intuitive. Human instinct is to patch on top of errors, not pretend they never happened. Building this habit requires deliberate practice.

Honestly, I rarely use rollback myself. One reason is the scenario changed—switching from purely conversational ChatGPT to agentic tools like Claude Code and OpenCode, the model directly operates files and runs commands, so continuous errors happen significantly less often. Another reason is... I really don't have that awareness. I discovered the `/rewind` feature when reading tool documentation, and learned it could be done this way. Knowing is one thing, but when I encounter errors, I still subconsciously correct them instead of rolling back. I'm still in the process of building this habit.

Extreme case: if a session is already full of correction noise, don't hesitate—start a new session and bring clean context into it. Context purity is more important than continuity.

Rollback has a side effect: after an error is rolled back, there's no trace in the conversation. The context is clean, but the lesson from the error is lost too. This got me thinking—can we save the error's context before rolling back?

This is a new feature I'm considering adding to Aristotle: intercept rollback operations, capture the error scene before executing (the wrong instruction, the model's response, the user's correction intent), and trigger a reflection process. The goal isn't just to clean context, but to transform "why rollback was needed" into reusable experience—recording error patterns, trigger conditions, avoidance methods, reducing the likelihood of similar errors happening in the future.

Rollback cleans the context. It shouldn't erase the lesson. Discarded errors, if properly reflected and recorded, are the cheapest lessons.

## Strategy 5: Compact Proactively, Don't Wait for Auto-Trigger

A subtask is done, ready to switch to the next subtask. At this point there's a key action: proactive compact.

**Never wait for automatic compaction.** Automatic compaction is triggered by a token counter, with uncontrollable timing. It might happen while you're debugging a complex bug—you just finished reading three files in the previous round, the model just located the root cause, hasn't had time to give a fix solution yet, and context fills up. Compressed. All file contents, reasoning process compressed into a summary. The model then works based on the summary, losing key details.

Looking at my data, that MCP solution design session had 45-277 messages between compactions. This means you can't predict which round will trigger automatic compaction—it could interrupt your workflow at any moment.

**Correct approach: during gaps between subtasks in the same background, compact proactively.** For example, a feature is written, ready to start the next feature—compact first. A deep debugging session ends, ready to switch to documentation work—compact first.

Key principle: before compacting, ensure the current subtask's key conclusions have already landed—code written to files (not in conversation), decisions recorded to external storage. If your conclusions still only exist in the conversation context, after compacting they become summaries, details may be lost.

Aristotle's GEAR protocol writes reflection rules to the Git repository rather than keeping them in conversation, partly for this reason. The file system is a persistence layer that compaction cannot touch. Important things go in files, not in conversation.

The first strategy above says "new tasks start new sessions," here it says "compact proactively during subtask gaps." Where's the boundary?

Key is distinguishing **between tasks** and **between subtasks**. Between-task switching—done with feature A, starting feature B—should start a new session. Between-subtask switching—code written, starting tests—compacting in the same session is enough.

But there are fuzzy times too. New session or compact, the boundary isn't always clear. As time invested on the task increases and understanding of the problem deepens, what was initially thought of as "one big task" might be re-decomposed into several independent tasks; what was initially thought of as "independent tasks" might reveal hidden dependencies. Subtask division changes, so the choice between compacting and splitting must adjust too.

That blog series planning session is a textbook gray area. 992 messages, three logical units—writing the first post, writing the second, series planning—should have been three sessions. But the three posts needed coherence, so they stayed together. The 9 compactions weren't a cost. They were an investment in active context management. Without proactive compacting, context rot erodes model performance before you notice. Later posts went to independent sessions—the fourth had only 542 messages and 3 compactions, less than half the first three combined. Enough conventions had accumulated to work outside the main session, while avoiding the weight of a single oversized session.

**The basis for judgment isn't the number of tasks, but the strength of information dependency between tasks.** Strong dependency, keep together, pair with proactive compact; weak dependency, split apart, each manages its own context.

## The Relationship Between the Five Strategies

These five are arranged in task chronological order, but they all revolve around the same core: **fighting context rot, keeping the model's effective attention on the current task.**

1. New tasks new sessions—different tasks don't share context, cutting rot off at the source
2. Lean loading—reduce attention competition from irrelevant information
3. Subagent isolation—subtask intermediates don't pollute the main session
4. Error rollback—don't let error processes squeeze out effective space
5. Proactive compact—periodically clean completed subtasks, leave context space for current work

The transformer's attention mechanism isn't perfect. In an era of increasingly long contexts, active context management isn't just optimization—it's necessary. If you don't manage it, the model's attention gets diluted by irrelevant information until it can't "see" what you want.

---

**References:**

1. Chroma Research, "Context Rot: How Increasing Input Tokens Impacts LLM Performance" (2025-07): [research.trychroma.com/context-rot](https://research.trychroma.com/context-rot)
2. Anthropic Applied AI Team, "Effective context engineering for AI agents" (2025-09-29): [anthropic.com/engineering/effective-context-engineering-for-ai-agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
3. Xiao et al., "Efficient Streaming Language Models with Attention Sinks" (2023): [arxiv.org/abs/2309.17453](https://arxiv.org/abs/2309.17453)
4. Liu et al., "Lost in the Middle: How Language Models Use Long Contexts" (2023): [arxiv.org/abs/2307.03172](https://arxiv.org/abs/2307.03172)
5. Chowdhury, "Lost in the Middle at Birth: An Exact Theory of Transformer Position Bias" (2026): [arxiv.org/abs/2603.10123](https://arxiv.org/abs/2603.10123)
6. Anthropic, "Introducing the Model Context Protocol" (2024-11-25): [anthropic.com/news/model-context-protocol](https://www.anthropic.com/news/model-context-protocol)
7. Anthropic, "Code execution with MCP: Building more efficient agents" (2025-11-04): [anthropic.com/engineering/code-execution-with-mcp](https://www.anthropic.com/engineering/code-execution-with-mcp)
8. Anthropic, "Equipping agents for the real world with Agent Skills" (2025-10-16): [anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
9. Anthropic, "Enabling Claude Code to work more autonomously" (2025-09-29): [anthropic.com/news/enabling-claude-code-to-work-more-autonomously](https://www.anthropic.com/news/enabling-claude-code-to-work-more-autonomously)

---

Series Articles:

- [Aristotle: Teaching AI to Reflect on Its Mistakes](/en/posts/2026/04/aristotle-ai-reflection/)
- [claude-code-reflect: Same Metacognition, Different Soil](/en/posts/2026/04/claude-code-reflect-different-soil/)
- [Trust Boundaries: One Idea, Two Systems](/en/posts/2026/04/a-trust-boundary-design-experiment/)
- [From Scars to Armor: Harness Engineering in Practice](/en/posts/2026/04/from-scars-to-armor-harness-engineering-practice/)
- [A Markdown's Three Lives: From Static Rules to a Git-Backed MCP Server](/en/posts/2026/04/from-markdown-to-mcp-server-gear-protocol/)
- [Looking Back: Seven Human-AI Collaboration Patterns in the Aristotle Project](/en/posts/2026/04/seven-human-ai-collaboration-patterns-in-aristotle/)
