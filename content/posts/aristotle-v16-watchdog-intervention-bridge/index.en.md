---
title: "From 'Post-Mortem Reflection' to 'Real-Time Interception': Aristotle v1.6.0's Watchdog-Intervention Bridge"
slug: "aristotle-v16-watchdog-intervention-bridge"
date: 2026-07-04T07:00:00+08:00
draft: false
description: 'The first five articles all answered one question: how to make AI remember its mistakes. But some mistakes cost too much to wait for "next time." Files are being corrupted, commits are being polluted right now. Reflection cannot undo damage already done. v1.6 introduces the Watchdog-Intervention Bridge: no more waiting for post-mortem, intercept violations the moment they occur.'
tags: ["AI", "TDD", "watchdog", "intervention", "AI-assisted development", "harness engineering"]
categories: ["AI Practice", "Teaching AI to Reflect"]
series: ["Teaching AI to Reflect"]
cover:
  image: "cover.png"
  alt: "Watchdog-Intervention Bridge three-layer architecture transitioning from post-mortem reflection (warm amber) to real-time interception (cool cyan)"
  relative: true
toc: true
---

> **TL;DR:** Aristotle v1.6.0 introduces the Watchdog-Intervention Bridge, shifting from "reflect after the fact" to "intercept in real time." A TypeScript watchdog detects 21 signal types around tool calls. A Python intervention layer handles 13 violation types, connected via a subprocess bridge. MCP tools expanded from 10 stubs to 25 full implementations. Two known bugs remain. Open source on GitHub, MIT license.

## A Hypothesis Overturned

From v1.0 to v1.5, Aristotle answered one question: when AI makes a mistake, how do you make it remember and not repeat it?

[Aristotle: Teaching AI to Learn from Its Mistakes](/en/posts/2026/04/aristotle-ai-reflection/) laid out the design philosophy. [From Four Scars to One Suit of Armor: Harness Engineering in Aristotle's Rewrite](/en/posts/2026/04/from-scars-to-armor-harness-engineering-practice/) walked through the refactoring. [Ralph Loop: AI Errors Aren't Random. They Converge.](/en/posts/2026/04/ralph-loop-ai-errors-converge/) explained the multi-round review process.

All of this work shares a premise: the error has already happened. Post-mortem root cause analysis, generate rules, prevent the next occurrence.

That chain depends on a hidden assumption: you will always get a "next time." Reflection can be slow because the damage is done, and the goal is to stop it from recurring.

But in real Agent scenarios, certain types of mistakes cost too much to wait for "next time."

Files are being written in the wrong phases, commits are missing corresponding records, and tests are being skipped as they happen. No amount of reflection can undo that. The problem is timing. Reflection happens after the fact, so it can only do cleanup.

In v1.6, I stopped asking "how do we make reflection deeper" and started asking "why wait until after the fact at all?"

## Four Violations That Need Instant Interception

The tdd-pipeline skill defines a strict flow: Phase 1 requirements, Phase 2 design, Phase 3 test plan, Phase 4 test code, Phase 5 business code. Each phase has clear entry criteria and exit standards.

When AI executes this flow, four types of violations do not wait for "next time." They need to be caught the moment they happen.

**Process violations:** Skipping the red phase and writing implementation directly. TDD requires writing a failing test first (RED), then writing code to make it pass (GREEN). But AI sometimes skips the RED step. Or the reverse: modifying tests during GREEN to make them pass instead of fixing the implementation.

**Behavior violations:** Writing implementation files with no test files in the corresponding directory. Or declaring completion before enough review rounds. The Ralph Loop requires two consecutive clean rounds to exit, but AI sometimes declares the review done after just one zero-bug round.

**Regression violations:** Tests that passed before now fail. AI modified code without running regression tests and broke existing functionality.

**Compliance violations:** Completing a phase without a commit. Or missing KI (Known Issues) documentation. AI wrote code but there is no corresponding commit in the Git repository. Or new bugs were found in the code but never recorded in the KI document.

These four types share one thing in common: if you only discover them after the fact, the damage is already done. Files get written to the wrong place, commits go in without records, and tests end up skipped. No amount of reflection changes history.

![Four violation types: Process, Behavior, Regression, Compliance. Intercepted the moment they occur.](violations.png "Four violation types intercepted in real time")

## Watchdog-Intervention Bridge: Architecture and Workflow

**Watchdog (TypeScript):** Intercepts around LLM tool calls. The Interceptor checks conditions before each call. The Observer inspects results after each call. Twenty-one signal types covering everything from phase state to test results.

**Intervention (Python):** Receives violation signals and executes intervention. Thirteen violation types, each handled by a dedicated handler that decides the strategy: quarantine, rollback, suspend, or instruct with guidance. Eight use the new handler path; the rest go through a legacy path.

**Bridge:** Connects the two layers. TypeScript detects a violation, caches it in the audit log, batch-sends at checkpoint, then Python returns an intervention decision and TypeScript applies it.

**onToolBefore:** Before a tool call, the Interceptor checks if the operation is legal. For example, AI writing code in Phase 5 when Phase 4 tests are not yet complete. Or modifying test files during GREEN to make tests pass instead of fixing implementation.

**onToolAfter:** After a tool call, the Observer checks if the result introduced a regression. For example, a test result changing from pass to fail. Or a phase ending with git status showing untracked files but no commit.

**tdd_checkpoint:** The violation gate checks for pending violation signals and batch sends them to Python intervention. Python returns an `InterventionResult` with four actions:

| Action | Meaning | Trigger |
|--------|---------|---------|
| quarantine | Move file to isolated directory | Writing to disallowed phase |
| rollback | Git rollback to last clean state | Test regression or missing commit |
| suspend | Pause pipeline, wait for human | Multiple consecutive severe violations |
| instruct | Return specific fix guidance, AI continues | Minor violation, fixable on the spot |

Python process startup takes about 400ms, so real-time communication would add perceptible latency to every tool call. Batching solves this, but it relies on a technical prerequisite: `onToolBefore` is synchronous. It reads cached state and throws to block tool calls without awaiting any async operation. Only `tdd_checkpoint`'s `handle()` is async and can wait for a subprocess. The checkpoint batches and sends violation signals from the audit log. No violations means no overhead and no subprocess.

```
┌─────────────────────────────────────────────────┐
│  LLM Tool Call                                   │
│     ↓                                           │
│  onToolBefore: Interceptor checks 21 signals     │
│     ↓ violation → audit log                      │
│  Tool Execution                                  │
│     ↓                                           │
│  onToolAfter: Observer inspects results           │
│     ↓ violation → audit log                      │
│  tdd_checkpoint: violation gate batch sends      │
│     ↓ subprocess (~400ms)                       │
│  Python: 13 violation types → handler dispatch   │
│     ↓                                           │
│  InterventionResult: quarantine / rollback /     │
│                     suspend / instruct            │
└─────────────────────────────────────────────────┘
```

![Watchdog-Intervention Bridge three-layer architecture: TypeScript Watchdog (top), Subprocess Bridge (middle), Python Intervention (bottom)](architecture.png "Watchdog-Intervention Bridge three-layer cross-section")

When Python is unavailable, the watchdog keeps working. If the bridge call fails, it returns an empty envelope and the pipeline continues. The watchdog does not crash just because Python goes down. The TypeScript-side violation gate still runs independently. Block-level violations are still intercepted, just without Python-side intervention suggestions. The design prioritizes availability over intervention completeness.

## Cross-Language Bridge: Why Subprocess and Not IPC or HTTP

I considered three options.

**HTTP:** Requires a persistent server on the Python side (FastAPI/Flask), managing port allocation, lifecycle, and crash recovery. The server runs even when there are zero violations, wasting resources. It introduces a full network stack. Even for localhost communication, you still deal with port conflicts, process daemonization, and graceful shutdown. The irony: the pipeline's watchdog monitors AI behavior, but an HTTP-based bridge would require another watchdog to monitor whether the communication layer is healthy.

**IPC (Unix Domain Socket / named pipe):** Also requires a persistent process. Lighter than HTTP but still involves connection management, heartbeat detection, and crash recovery. Debugging is limited. You cannot test with curl, and issues require low-level tracing tools (strace, dtrace, lldb, etc.). That infrastructure cost is too heavy for a communication path that is non critical (degradation does not affect the main flow) and triggers only once per checkpoint.

**Subprocess (chosen):** Spawns on demand, zero cost when there are no violations. No persistent process, ports, or connection management to maintain. Each call is a fresh process with natural isolation. A Python crash does not affect other components. Startup latency is ~400ms, but checkpoint frequency is low (once per interaction cycle).

Three factors decided it:

1. **Low call frequency:** The checkpoint triggers once per interaction cycle. Subprocess startup cost is not a bottleneck.
2. **Simple communication pattern:** Input is an audit log snapshot, output is an intervention decision. One-way, stateless, single round-trip. No streaming, duplex, or persistent connection needed.
3. **Fault tolerance over latency:** When the Python process fails, the bridge returns an empty envelope and the pipeline continues. HTTP and IPC require their own fault tolerance for their persistent processes. Who restarts the crashed server? Spawning a subprocess avoids this problem entirely.

## 25 MCP Tools: From Stubs to Full Implementation

v1.6 expands MCP tools from 10 stubs to 25 full implementations. The original 10 tools (3 orchestration, 3 reflection state, 2 sync, 2 undo/feedback) were already implemented in v1.5. v1.6 adds 15 new ones: 10 rule lifecycle tools (including `init_repo`), 2 KI doc tools, and 3 rollback tools.

| Category | Tools | Function |
|----------|-------|----------|
| KI Docs | `write_ki_doc`, `read_ki_docs` | Write and read Known Issues documents |
| Rollback | `create_rollback_point`, `rollback_to_checkpoint`, `cleanup_rollback_stashes` | Git stash-based checkpoint management |
| Rule Lifecycle | `init_repo`, `write_rule`, `read_rules`, `stage_rule`, `commit_rule`, `reject_rule`, `restore_rule`, `list_rules`, `detect_conflicts`, `get_audit_decision` | Full implementation from stubs (10 tools) |

These implementations fill the reserved stubs so AI can reliably use them in workflows for development state tracking and model violation correction.

## tdd-pipeline Skill Integration

install.sh adds Step 5: detect whether the user has the tdd-pipeline skill installed. Without tdd-pipeline, Aristotle has no phase rules to check. tdd-pipeline defines each phase's requirements. Aristotle checks whether they are actually met. The two together form automated process constraints.

## Remaining Bugs

Two known bugs still need fixing:

- **`_should_return_result` test branch:** Production code decides whether to throw or return a result based on the `PYTEST_CURRENT_TEST` environment variable. Tests exhibit different behavior from production, creating a gap in bridge and audit log coverage. This mismatch already caused one bug.
- **String sort priority values:** Priority sorting uses string comparison instead of numeric comparison. Sorting will produce incorrect results for multi-digit numbers.

## From "Post-Mortem Reflection" to "Real-Time Interception"

I originally designed Aristotle as an error reflection tool. AI makes a mistake, analyze it after the fact, generate rules, prevent recurrence. This logic worked well from v1.0 to v1.5.

But I realized the damage had already happened by the time reflection kicked in. All it could do was clean up.

v1.6's Watchdog-Intervention Bridge intercepts violations the moment they occur instead of waiting for post-mortem reflection. The Interceptor blocks illegal operations before tool calls. After tool calls, the Observer catches regressions. At checkpoints, the violation gate applies batch interventions. Reflection still handles systemic patterns, but interception comes first.

Aristotle started as a tool for making AI remember its mistakes. Now it also stops AI from making those mistakes in the first place. Reflection builds long-term habits; the watchdog constrains current behavior. v1.6 puts both in one system.

This series started with "teaching AI to reflect." It is now at "real-time error interception." I will use it for a while and see where it goes.

## References

1. Aristotle project: [github.com/alexwwang/aristotle](https://github.com/alexwwang/aristotle) v1.6.0 release and docs
2. tdd-pipeline project: [github.com/alexwwang/tdd-pipeline](https://github.com/alexwwang/tdd-pipeline). See `ralph-review-loop.md`
3. [Aristotle: Teaching AI to Learn from Its Mistakes](/en/posts/2026/04/aristotle-ai-reflection/)
4. [Ralph Loop: AI Errors Aren't Random. They Converge.](/en/posts/2026/04/ralph-loop-ai-errors-converge/)
5. [From Four Scars to One Suit of Armor: Harness Engineering in Aristotle's Rewrite](/en/posts/2026/04/from-scars-to-armor-harness-engineering-practice/)

> *Aristotle is open source on [GitHub](https://github.com/alexwwang/aristotle) under the MIT license. Issues and PRs welcome.*
