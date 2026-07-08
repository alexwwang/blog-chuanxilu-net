---
title: "One System, Two Languages: The Five Constraints Behind Aristotle v1.6's Architecture"
slug: "aristotle-v16-cross-language-design"
date: 2026-07-08T07:00:00+08:00
draft: false
description: "Watchdog intercepts in TypeScript. Intervention decides in Python. A subprocess bridge connects them. This wasn't architected — it was constrained into existence. Runtime environment, existing assets, zero new infrastructure, startup overhead, fault tolerance. Five decisions, none optimal, each the least bad option under the circumstances."
tags: ["AI", "TDD", "aristotle", "architecture", "harness engineering", "design"]
categories: ["AI Practice", "Teaching AI to Reflect"]
series: ["Teaching AI to Reflect"]
cover:
  image: "cover.png"
  alt: "Split architectural structure, left warm amber TypeScript tower, right cool cyan Python engine room, central subprocess bridge with five constraint pillars"
  relative: true
toc: true
---

> **TL;DR:** Five constraints shaped the Watchdog-Intervention Bridge's cross-language architecture. Watchdog has to intercept LLM tool calls synchronously, so it runs in TypeScript. Intervention has to reuse the existing reflection engine and rule system, so it stays in Python. The Bridge adds zero new infrastructure, so it uses subprocess. Communication can't block every tool call, so batching replaces real-time streaming. Each decision was the least bad option under the circumstances.

The last post covered [what the Watchdog-Intervention Bridge does in Aristotle v1.6](/posts/2026/06/aristotle-v16-watchdog-intervention-bridge/). This one is about why it looks the way it does.

## A seemingly odd choice

The most visible design decision in the Watchdog-Intervention Bridge is that Watchdog is written in TypeScript and Intervention is written in Python. One system, two languages.

If you only look at language preferences, this doesn't look optimal. Cross-language means:

- Two development environments, two dependency management systems, and two testing frameworks.
- An extra layer of serialization and parsing for the communication protocol.

So why go this way?

Constraints shaped every decision here. Each choice was the least bad option available given specific constraints.

## Constraint 1: Watchdog must be synchronous

Watchdog's job is to intercept the LLM's tool call path. Specifically, `onToolBefore` needs to check conditions **before** a tool runs. If there's a violation, it uses `throw` to stop the tool synchronously.

This requirement rules out almost every cross-process approach. You can't `await` a remote call result in the middle of a tool call path. Every wait stalls the LLM's next operation. Even a few milliseconds of latency per communication adds up quickly across the whole pipeline.

TypeScript is the host language for LLM tool calls. Putting Watchdog on the TypeScript side means `onToolBefore` can read pipeline state directly and throw synchronously when it detects a violation, with no extra waiting on the call chain.

If Watchdog were on the Python side, every tool call would need cross-process communication just to check for violations. The communication overhead alone would make synchronous interception impractical, before even accounting for Python-side latency.

Watchdog had to be TypeScript because the runtime environment required it.

## Constraint 2: Intervention's assets and ecosystem are in Python

Intervention's core logic is rule matching, violation detection, and intervention dispatch. Aristotle v1.0 through v1.5 accumulated a rule system, KI document management, and root cause analysis logic on the Python side, with 1166 test cases written in pytest.

Putting Intervention in Python means these assets survive intact. The rule engine carries over, along with 13 violation type handlers and all 1166 tests.

So why not TypeScript? Breaking down the tradeoff shows why the system ends up with two languages.

**Intervention in Python:**
- Zero rewrite cost. 1166 tests, rule engine, violation handlers, KI doc management all preserved.
- pytest's parametrize and fixture ecosystem. pytest's `@pytest.mark.parametrize` supports stacking multiple decorators for Cartesian products, and fixtures support dependency injection with automatic teardown. Vitest's `it.each` only handles single-level parameterization with no equivalent to pytest's fixture system. For 13 violation types tested in combination, parametrize makes the test code significantly more compact.

**Intervention in TypeScript:**
- Single language, no cross-language communication.
- One development environment, one dependency management system.

This is a tradeoff between one-time and ongoing cost. Rewriting 1166 tests is a large one-time cost. Cross-language communication is an ongoing but manageable cost. The Bridge only triggers at checkpoints, once per interaction cycle.

One clarification: Intervention exposes itself as an MCP tool, and MCP has both TypeScript and Python SDKs. MCP's subprocess protocol means the communication pattern is independent of language choice. Whether Intervention is in Python or TypeScript, it communicates with Watchdog the same way: via subprocess, with identical latency and stability characteristics. So "cross-language communication" isn't an argument against Python here. The communication cost is determined by MCP's protocol, not by the language.

Asset reuse outweighed cross-language maintenance cost in the final decision.

The remaining design decisions were about how to connect them.

## Constraint 3: Zero new infrastructure

There are several common approaches to cross-language communication:

- IPC (Unix domain socket or named pipe): Requires managing socket lifecycle and concurrent connections.
- HTTP server: Requires starting a lightweight server, managing ports, handling request queuing, and handling service crashes.
- Subprocess: Start a child process when needed. It runs and exits. You need no state management.

Adding IPC or HTTP to an existing project means introducing new failure modes: socket disconnections, unexpected server exits, and port conflicts. All of these have standard solutions, but the complexity doesn't go away. You still need to manage it.

Subprocess is the simplest approach. Start a process when needed. It runs and exits, with no state management, connection pools, or port configuration. Failure detection is straightforward: a non-zero exit code means failure. There's no need to distinguish between "the service is down" and "the request timed out."

Aristotle also already had the `callMCP()` pattern in `idle-handler.ts`, which calls Python modules through subprocess. This pattern had proven stable in production. There was no reason to introduce new infrastructure.

The Bridge uses subprocess. Startup costs about 400ms per launch. The existing `callMCP()` pattern had already demonstrated this approach worked reliably.

## Constraint 4: 400ms can't block every tool call

Subprocess takes about 400ms per launch. If every tool call triggered a subprocess to communicate with Python Intervention, the accumulated latency would slow pipeline response times noticeably.

This calls for a caching strategy. The TypeScript side caches violation signals in the audit log first. When a checkpoint is called, it sends them to Python in a batch.

This strategy has a technical prerequisite. `onToolBefore` doesn't need to wait asynchronously for Python to make its decision. It can detect violations and throw on its own. Only intervention decisions (quarantine, rollback, suspend, instruct) need Python processing, and those don't need to happen in real-time on the tool call path.

1. `onToolBefore` / `onToolAfter` detect violations synchronously and write signals to the audit log.
2. When `tdd_checkpoint` is called, the violation gate reads the audit log in bulk and sends it to Python via subprocess.
3. Python returns an `InterventionResult` and TypeScript applies the decision.
4. When there are zero violations, there's no overhead from signals or subprocess launches.

Batching keeps latency acceptable by absorbing the fixed 400ms cost at checkpoints rather than at every tool call.

## Constraint 5: MCP's subprocess model makes cross-language risk manageable

Doesn't putting Intervention in Python instead of TypeScript add more complexity than it saves?

The answer is no, because Intervention exposes itself as an MCP tool. MCP tools run as subprocesses by design: the host sends a request, the tool executes, returns a result, and exits. If the call times out or the process crashes, it returns an empty result and the host decides what to do. This contract works well with cross-language communication.

In practice:

- When the Bridge's subprocess call fails, it returns an empty envelope. The TypeScript side handles it as a standard MCP response, with no special fault tolerance needed for Python.
- The violation gate on the TypeScript side writes to the audit log without checking whether Python is alive. A failed subprocess affects intervention completeness, not interception.
- Whether Intervention is in Python or TypeScript, MCP's protocol defines the boundary between it and Watchdog. That boundary already includes failure handling.

The "cross-language adds complexity" argument rests on an assumption that MCP's protocol does not exist. Intervention uses Python because MCP's protocol already handles the cross-language part.

## Bonus: Stub-first decision

One more decision deserves mention. v1.6 added 15 new MCP tools (from stub to full implementation). Combined with the 10 from v1.5, the total reached 25.

The 15 new tools (10 for rule lifecycle, 2 for KI doc, 3 for rollback) started as stubs in early development. They appeared in the tool list, but calls returned "not implemented." This might look incomplete. If all of them were going to be implemented anyway, why not do it all at once?

v1.6's main line was the Watchdog-Intervention Bridge. The MCP tools were infrastructure enhancements. There was no point implementing all 15 tools before the watchdog was working.

The stub-first approach reserves a spot on the roadmap. The AI sees the list and knows the tools are coming. For everyone else, the stubs signal what's planned without pretending the work is done.

## Design under constraints

![Five constraint pillars, each mapping a constraint to its resulting architectural decision](constraints.png "Five architecture constraints and their corresponding decisions")

| Decision | Constraint | Chosen |
|----------|------------|--------|
| Watchdog language | Synchronous interception, host environment | TypeScript |
| Intervention language | Existing assets, testing ecosystem | Python |
| Bridge mechanism | Zero new infrastructure | Subprocess |
| Communication mode | 400ms can't block every tool call | Batching + caching |
| Fault tolerance | MCP's subprocess model handles cross-language risk | Empty envelope + independent operation |

None of these five decisions were ideal. Each was the least bad option the constraints allowed.

Constraints eliminate what looks good in theory. Finding what still works under those constraints is the actual task.

Aristotle called this pursuit "the good." A system that runs and keeps working under real constraints is what an engineer would call the same thing.
