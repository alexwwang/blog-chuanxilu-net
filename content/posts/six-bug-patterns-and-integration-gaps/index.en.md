---
title: "Green Tests, Broken System: Six Bug Patterns AI Left at the Integration Layer"
slug: "six-bug-patterns-and-integration-gaps"
date: 2026-05-07T10:00:00+08:00
draft: false
description: "Before releasing Aristotle v1.1, I found 18 bugs. Unit tests caught four. The rest lived at the integration layer. After root cause analysis, six patterns emerged — not because the problems got harder, but because AI bypassed the defenses I'd built through years of experience."
tags: ["AI", "bug patterns", "integration testing", "Aristotle", "AI-assisted development", "TDD"]
categories: ["AI Practice"]
series: ["Teaching AI to Reflect", "Taming AI Coding Agents with TDD"]
toc: true
cover:
  image: "cover.png"
  alt: "Six bug patterns: components correct in isolation, broken after integration, diagnostic clarity emerging from chaos"
---

> **TL;DR:** Before releasing Aristotle v1.1, I found 18 bugs. Unit tests caught four (22%). The other 14 lived at the integration layer — component wiring, config propagation, process startup seams. Root cause analysis revealed six patterns: path/environment mismatch (5), registration omission (3), startup hang (2), silent failure (2), test-production path divergence (2), integration seam errors (4). The root cause isn't harder problems — it's AI bypassing the defenses that experience built. Implementation and review rhythms decouple, code appearance misleads quality judgment, and integration shifts from an explicit action to an implicit assumption. Includes an eight-dimension integration checklist and a 16-type bug roadmap at the end.

## 1. Tests Green, System Broken

I kept hitting the same scenario during the Aristotle release in the early stage. All automated tests green. Lint clean. Type checks passing. I'd breathe easy and prepare to ship.

Then I'd run the full workflow manually. The system didn't work. Not some edge case — the most basic path was broken. Tests covered each function's logic. Put them together, nothing fit.

Aristotle is a multi-process tool orchestration platform built on the MCP protocol. Registration mechanism, inter-process communication, lifecycle management. Not a toy project, not a massive system — a medium-complexity tool.

I found 18 bugs before release. Unit tests caught four. Twenty-two percent.

Unit tests covered the logical correctness of each function. That's fine. But 14 of the 18 bugs weren't at the function level. They lived at the seams — component wiring, config propagation, process startup intersections. Every component looked correct in isolation. Bolt them together, and things exploded.

## 2. I Wouldn't Have Made These Mistakes Before

Several of these 18 bugs, I wouldn't have made writing code by hand. Manual coding has review built in. When I write registration logic, I think as I go: this service needs an entry in the main file, that tool goes in the route table. Writing and checking wiring happen in the same breath.

With AI, I can generate a complete registration system in three minutes. The code looks polished — good comments, clean naming, better formatted than what I'd write myself. I'd glance at it and move on. Not because I'm lazy. Because my review speed can't keep up with its generation speed. That's layer one — the velocity gap.

Then comes trust. If an intern wrote the same logic, I'd check line by line. But AI-generated code looks so professional. Type annotations, error handling, reasonable abstractions. That polish lowers your guard. I'd see "logging is there" and feel satisfied — without checking whether the log level was actually correct.

The third layer is the most subtle. In traditional development, integration is an explicit act. You wire a new module into the existing system, and that act itself forces you to check connections, paths, configs. With AI, multiple components land almost simultaneously. The assembly step gets compressed. You think AI generated a complete system. What it actually generated is a pile of parts that each run fine on their own.

Traditional development has an implicit coupling: your skill and the complexity you produce grow in lockstep. The complexity of code you can write roughly matches your ability to debug it. AI breaks that coupling. It lets you generate above-your-threshold complexity with below-your-threshold experience. This isn't AI's fault. You just haven't built new defenses for this skill-complexity gap.

---

## 3. Six Patterns I Hit Repeatedly

After root cause analysis on all 18 bugs, they clustered into six patterns. I hit each one more than once.

### Right Path, Wrong Environment (5/18)

Imagine ordering something online while traveling. You type in your home address out of habit. The package arrives at your house — not lost, not misdelivered — just not where you actually are.

The root cause: AI lacks awareness of the deployment environment. Paths that work in development break in production. This was the largest category (5/18, 28%) and the most frustrating one.

After deployment, the MCP server failed to start. Logs showed `uv` couldn't find the project's Python environment and fell back to the system Python 3.8. System 3.8 lacked required modules. The service crashed.

I checked the config file. The path was written as `~/path/to/module`. On my dev machine, the shell auto-expands the tilde. Everything works. But the deployment startup script doesn't go through shell expansion. The tilde gets treated as a literal string. Module not found. Service won't start.

The full chain: `uv run --project ~/path` doesn't expand tilde → invalid path → uv falls back to system Python 3.8 → missing modules → MCP server fails to start. During development, I tested with the expanded absolute path. When committing the config, I wrote the tilde. AI-generated code "happened to work" in the current environment.

Before AI, I'd actively consider environment differences when writing paths. AI generates a reasonable-looking path. The code is so clean you never suspect the path might be wrong.

Later I had AI add two grep checks in CI:

```sh
# Find hardcoded absolute paths
grep -rn '/Users/\|/home/\|C:\\\|D:\\' --include='*.ts' --include='*.py' --include='*.json' .
# Find unexpanded tildes
grep -rn '~/' --include='*.json' --include='*.yaml' --include='*.toml' .
```

Hardcoded paths and unexpanded tildes get caught in CI.

### Written but Never Registered (3/18)

Imagine hiring someone but never setting up their system access. They sit at their desk, fully capable, but the company's systems don't know they exist. They can't do any work.

The mechanism: feature implementation and system registration are disconnected. The feature is written, tests pass, but when a real user tries to call it — the tool doesn't exist. More subtle than the path issue.

In Aristotle, tool functions were exported but never appeared in the MCP server's tool registration list. Unit tests passed because tests call functions directly — the test framework auto-discovers and registers exported functions. In production, nobody does this. The function is there. The system doesn't know it exists.

Before AI, wiring and implementation were two steps of the same action. Write the function, then register it in the entry file. When AI generates code, the wiring step lives in a different file, a different context. Registration drops out of its context window.

Later I had AI add this check: every PR with new features gets grepped for export-registration alignment:

```sh
# List all exported functions/classes
grep -rn 'export function\|export class\|def ' src/ | grep -v test
# List all registration points
grep -rn 'register\|\.tool(\|mcp\.tool(' src/init.ts
```

Cross-reference the two outputs. Exported but unregistered means invisible at runtime.

### Hung: No Error, No Timeout (2/18)

Imagine waiting for a friend who said "I'm on my way." You keep waiting. You don't know their car broke down. No call, no text. Just waiting. Waiting for Godot.

The root cause: initialization dependencies lack timeout protection. Component A starts slowly. Component B's `await` has no timeout, so it waits along with it. Path issues at least produce error messages. Registration problems can be found with diagnostic tools. A startup hang gives you nothing — the system is stuck. No error, no timeout. It just waits forever.

When AI generates initialization code, it writes the happy path for each component — assumes dependencies exist, networks are up, resources are available. When multiple components have initialization dependencies, AI doesn't proactively build timeout cascades. Reality violates the assumptions. The system doesn't error. It just waits.

Before AI, deployment environments were never as clean as dev environments, so these issues surfaced during deployment. But with AI-assisted development, local test environments are also too clean. All dependencies are local. The dev server never starts without network access.

Later I had AI do two things. First, assert in CI that startup completes within five seconds — fail if it doesn't. Second, grep for unprotected calls:

```sh
# Measure startup time
time <start-command>
# Find await/fetch/connect without timeout protection
grep -rn 'await\|fetch\|connect' src/init.ts | grep -v 'timeout'
```

### Worse Than Hanging: Nothing Happened (2/18)

Imagine a smoke alarm that, when there's a fire, just quietly mumbles "there's smoke." The fire is burning. You don't know.

The mechanism: errors get swallowed by catch blocks, only producing low-level log output. A hang at least tells you something is wrong — the system is stuck. A silent failure is worse: the operation failed, but the user sees zero feedback. The log has one line: `debug: task completed with errors`. A background task failed. The user waited five minutes with nothing happening.

When AI generates catch blocks, it prioritizes keeping the flow uninterrupted. It uses `logger.debug` or `logger.info` for severe errors. It swallows exceptions with catch and `continue`. Not throw, not error — silent skip. AI isn't deliberately hiding problems. It just chose a "don't break the flow" strategy when generating the code.

Before AI, I'd add proper logging and notifications for silent failures. But AI-generated code "already has logging" — just at the wrong level. During review, seeing `logger.info(...)` doesn't trigger alarm. You don't realize it should be `logger.error(...)`. The defense never activates because you didn't realize you needed one.

Later I had AI add a grep to the review pipeline:

```sh
# Find potentially undergraded log levels
grep -rn 'logger\.\(debug\|info\)' src/ | grep -v test
```

Check each line: is this log level adequate? Background task failures, scheduled task exceptions — these should be `warn` or `error`, not `debug`.

### Tests Green, Production Broken (2/18)

Imagine practicing parallel parking in an empty lot until you're flawless. Then the actual test is driving on a highway. You practiced the wrong thing.

The root cause: test coverage paths don't match production paths. The tests aren't buggy. They just exercise different paths than real users do. All tests pass. Production breaks.

In Aristotle, some tests triggered graceful shutdown via `stdin`. Tests covered the full graceful shutdown flow — cleanup resources, save state, notify downstream. All passed. But in production, processes got killed by SIGKILL. The cleanup handler never ran. The graceful shutdown path covered by tests never actually happens in production.

When AI generates tests, it tends to follow its own calling path — direct function calls, test-specific APIs, simplified inputs. These tests effectively verify logical correctness. But they skip the full path real users take.

Before AI, I'd deliberately simulate real scenarios when writing tests. That deliberation came from understanding the system as a whole. When AI generates tests, its understanding is limited to the current component's interface definition. It doesn't know how users actually trigger the feature.

The check is intuitive — compare the test's activation mechanism with what real users do:

```sh
# Check what activation mechanism tests use
grep -rn 'send-keys\|stdin\|mock.*trigger' test/ | head -5
```

If real users trigger via CLI, tests should use CLI. If real users send HTTP requests, tests should use HTTP. Preventing test shortcuts is the only reliable way to catch these bugs.

### Individually Correct, Together Wrong (4/18)

Imagine two contractors building a bridge from opposite banks. Each half is structurally sound. But they don't meet in the middle — one team followed a different spec.

The root cause: AI implements component by component, without cross-component interface consistency checks. Each component looks fine in isolation. Put them together, things break. Second largest category (4/18, 22%).

AI generates two components separately. Each time, the code is "correct." Combined, it's not. Parameter format mismatches, IDs not properly passed, boundary conditions in inter-process communication — these live in the gaps between components.

In Aristotle, one place used `execFile` for inter-process communication. `execFile` doesn't support bidirectional IPC — you need `spawn` for that. AI chose `execFile` when writing the individual call — no interaction needed, seemed reasonable. But the overall architecture requires bidirectional communication. AI couldn't see that global requirement.

Before AI, integration was an explicit act. Two hand-written modules bolted together — interface mismatches surface immediately. With AI, multiple components land almost simultaneously. Each has tests, passes lint, has type definitions. "Should be fine" becomes the default assumption.

Later I had AI check with these commands:

```sh
# Check inter-process communication method
grep -rn 'execFile\|execSync' src/
# Check if ID fields are properly passed
grep -rn 'parentId\|sessionId\|ownerId' src/ | grep -v test
```

---

## 4. The Checklist I Built After

After the release, I had AI compile these lessons into a checklist. Not a theoretical framework — actual bugs I hit. Each row maps to a real failure.

Every time AI generates a new set of components, I run this checklist against them. Generation is fast. Review quality comes from structured checks.

For every pair of interacting components in the project, check row by row. Any "not sure" in any column is a blind spot.

| Dimension | What to Ask | How to Check | Example |
|-----------|-------------|--------------|---------|
| Schema | Are data formats consistent across components? | Compare input/output schemas at each boundary | A outputs `id`, B expects `userId` |
| State | Is cross-process state management correct? | Check: who creates, who reads, who cleans up temp files | Temp files never cleaned, next startup reads stale data |
| Timing | Are there race conditions? | Check: startup order, idle detection, polling intervals | A hasn't finished starting, B already calls A's interface |
| Error propagation | Can A's errors surface in B? | Inject errors in A, verify B detects and handles them | A's process crashes, B waits forever without error |
| Config propagation | Does the same config reach all components? | Compare each component's resolved config (not the config file) | Config file is correct, but env var overrides one component's value |
| Registration chain | Can every consumer find its provider? | Enumerate registered tools/services, compare with expected list | Tool function written but unregistered, invisible at runtime |
| Lifecycle | Are startup resources cleaned up at shutdown? | Kill the process, check for residual files/processes | PID file not deleted, next startup thinks "already running" |
| Freshness | Does it run in a clean environment? In a dirty one? | Test separately in clean and dirty environments | Works on dev machine (cached from last run), fails in CI |

One dimension isn't on this checklist: test-production divergence. Integration checks can't catch it. You need to address it at test design time — ensuring tests use the same activation paths as real users.

---

## 5. Bugs I Haven't Hit Yet

Eighteen bugs covered six patterns. But in multi-component systems, I've encountered other bug types in other projects. Listing the common ones alongside Aristotle v1.1's status shows what to defend against next.

| Common Bug Type in Traditional Development | Appeared in Aristotle v1.1? | Next Step |
|---|---|---|
| Path/config inconsistency <sup>1,2</sup> | ✅ 5 | CI grep checks in place |
| Registration/wiring omission <sup>1</sup> | ✅ 3 | Added to review checklist |
| Startup hang <sup>1</sup> | ✅ 2 | Startup time assertion added |
| Silent failure <sup>3</sup> | ✅ 2 | Log level grep added |
| Test-production path divergence <sup>2,4</sup> | ✅ 2 | E2E uses real activation paths |
| Integration seam errors <sup>1,5</sup> | ✅ 4 | Eight-dimension checklist per item |
| Resource leaks (memory, file descriptors, connection pools) <sup>6</sup> | ❌ | Add long-running soak test next version |
| Race conditions (concurrent access to shared state) <sup>1,6</sup> | ❌ | Checklist has Timing, but never actually tested |
| Data serialization boundaries (encoding, precision, special characters) <sup>1,5</sup> | ❌ | Need schema validation across language boundaries |
| Version skew (component A upgraded, B still uses old interface) <sup>1,2</sup> | ❌ | Add contract tests, lock interface contracts between components |
| Graceful degradation (non-critical dependency goes down, what then?) <sup>7</sup> | ❌ | Need fallback strategy design, not just timeouts |
| Auth/permission boundaries (inconsistent access control between components) <sup>4,8</sup> | ❌ | Only appears in multi-tenant scenarios, not yet in scope |
| Error handling defects (the error handling code itself has bugs) <sup>9</sup> | ❌ | Distinct from silent failure: silent failure means no handling; this means handling done wrong — errors amplified, fallback logic flawed, exception type mismatch |
| Performance logic defects (sharp degradation in specific scenarios) <sup>6,10</sup> | ❌ | Distinct from resource leaks: not a leak, but logic-driven — N+1 queries, unoptimized slow paths, batch ops going single-item |
| Cascading failures (single-point failure spreads through dependency chain) <sup>2,11</sup> | ❌ | Distinct from graceful degradation: degradation is desired behavior, cascading failure is actual disaster — one component dies, retry storm takes down downstream too |
| Implicit contract violations (undocumented semantic assumptions broken) <sup>5</sup> | ❌ | Distinct from integration seam errors: seam errors are explicit interface mismatches, these are implicit assumptions — call order, thread safety, sync/async semantics |

The first six rows are bugs I hit. The next ten are ones I haven't hit yet but will eventually. Resource leaks and race conditions, for instance — nearly inevitable in long-running and concurrent scenarios. Aristotle v1.1 just hasn't reached that complexity yet.

---

## What's Your Bug Story?

These six patterns came from 18 real bugs in a medium-complexity project. Your project might differ in complexity and tech stack, but the skill-complexity gap from AI-assisted development is the same.

If you're also coding with AI, I'd love to hear from you in the comments:

- Which bug patterns have you hit? Any that aren't on this list?
- The eight-dimension checklist at the end — what's missing?
- Do you have your own review or checking process? How's it working?

---

## References

1. Chillarege et al., "Orthogonal Defect Classification" (ODC), IBM Research, 1992. ODC v5.11 classifies defects into 8 types and 10+ triggers. Path/config → Trigger: Configuration; registration omission → Type: Interface/Missing; startup hang → Trigger: Startup/Restart; race conditions → Type: Timing/Serialization; data serialization → Type: Checking; version skew → Trigger: Backward/Lateral Compatibility; integration seams → Type: Interface/Relationship. [DOI](https://doi.org/10.1109/32.177364)
2. Google SRE Workbook, Appendix C. Root cause statistics from thousands of postmortems: config changes account for 31% of incident triggers, binary releases 37%, performance degradation 5%. [sre.google](https://sre.google/workbook/chapters/postmortem-analysis/)
3. Google SRE Book, Chapter 14: "Emergency Response". Omission faults in distributed systems (system fails to perform expected action) is the formal name for silent failure in fault classification. [sre.google](https://sre.google/sre-book/emergency-response/)
4. Catolino et al., "Not all bugs are the same: Quantifying bug types in open-source software", *Journal of Systems and Software*, 2019. Empirical analysis of 1,280 bug reports from Mozilla/Apache/Eclipse. [DOI](https://doi.org/10.1016/j.jss.2019.03.002)
5. Tang et al., "Cross-System Interaction Failures in Cloud Computing", UIUC, 2023. Studied 11 major incidents and 120 cases across Google/Azure/AWS. Found 69% of control-plane failures rooted in implicit semantic assumption violations between systems. [DOI](https://doi.org/10.1145/3552326.3587448)
6. Leesatapornwongsa et al., "TaxDC: A Taxonomy of Non-Deterministic Concurrency Bugs in Distributed Systems", *ASPLOS*, 2016. Follow-up to TaxPerf listing performance logic defects as one of six root causes of distributed performance bugs, and resource leaks as the top pattern in the Resource category. [DOI](https://doi.org/10.1145/2872362.2872374)
7. Nygard, *Release It!*, 2nd ed., Pragmatic Bookshelf, 2018. Industry-standard reference for system resilience patterns (Circuit Breaker, Bulkhead, Timeout, Fallback). [pragprog.com](https://pragprog.com/titles/mnee2/release-it-second-edition/)
8. MITRE CWE (Common Weakness Enumeration). CWE-862: Missing Authorization; CWE-863: Incorrect Authorization. Standardized weakness classification for auth/permission boundaries. [CWE-862](https://cwe.mitre.org/data/definitions/862.html) · [CWE-863](https://cwe.mitre.org/data/definitions/863.html)
9. Gunawi et al., "What Bugs Live in the Cloud? A Study of Bugs in Distributed Systems", *ACM Computing Surveys*, 2016. Error handling accounts for 18% of distributed system software bugs. The Linux kernel's `eBugs` dataset records 210 error handling defect cases. [DOI](https://doi.org/10.1145/2670979.2670986)
10. Jin et al., "Understanding and Solving Real-World Performance Bugs in Software", *ASPLOS*, 2012. Root cause classification of 109 performance bugs across five major open-source projects (Apache, Mozilla, GCC, MySQL, PostgreSQL). [DOI](https://doi.org/10.1145/2254064.2254075)
11. Google SRE Book, Chapter 22: "Addressing Cascading Failures". Defense strategies for cascading failures: rate limiting, degradation, request cancellation — preventing single-point failures from spreading through dependency chains. [sre.google](https://sre.google/sre-book/addressing-cascading-failures/)
