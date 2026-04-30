---
title: "Looking Back: Seven Human-AI Collaboration Patterns in the Aristotle Project"
slug: "seven-human-ai-collaboration-patterns-in-aristotle"
date: 2026-04-16T21:00:00+08:00
draft: false
description: "Looking back at the Aristotle project—from initial design to the GEAR protocol—I identified seven distinct collaboration patterns between myself and AI. As AI gets more capable, human judgment doesn't become less important. It becomes more critical."
tags: ["AI", "agent", "reflection", "aristotle", "human-AI collaboration", "harness engineering"]
categories: ["AI Practice", "Teaching AI to Reflect"]
series: ["Teaching AI to Reflect"]
cover:
  image: "cover.png"
  alt: "Seven human-AI collaboration patterns from the Aristotle project"
toc: true
---

Five articles in. Time to step back and look at the path itself.

[Aristotle: Teaching AI to Reflect on Its Mistakes](/en/posts/2026/04/aristotle-ai-reflection/) covered the design philosophy and initial implementation. [claude-code-reflect: Same Metacognition, Different Soil](/en/posts/2026/04/claude-code-reflect-different-soil/) told the story of porting across platforms. [Trust Boundaries: One Idea, Two Systems](/en/posts/2026/04/a-trust-boundary-design-experiment/) proposed a trust tiering model. [From Scars to Armor: Harness Engineering in Practice](/en/posts/2026/04/from-scars-to-armor-harness-engineering-practice/) validated the theory through refactoring. [A Markdown's Three Lives: From Static Rules to a Git-Backed MCP Server](/en/posts/2026/04/from-markdown-to-mcp-server-gear-protocol/) evolved the rule storage from append-only to the GEAR protocol.

Five articles about design and technology. This one is about the human—the specific ways AI and I collaborated throughout the project. Looking back at the full development process from early April to mid-April, I've distilled seven collaboration patterns. They're not a parallel list. They form an evolutionary line—from high-trust launch to metacognitive closure, each pattern a correction and deepening of the one before.

---

## Pattern 1: Human Gives Philosophy, AI Fills in the Details

The design and implementation of the original Aristotle.

I gave AI three design principles—immediate trigger, session isolation, human in the loop—plus the 5-Why root cause analysis framework. AI delivered the complete SKILL.md (394 lines), test script, and README in three commits. Done.

This pattern runs on **high-trust launch**. The human defines "why" and "what." AI handles "how." When the problem space is clear enough and the platform infrastructure is solid, AI's execution is strong. OpenCode's skill system and the omo background task infrastructure had already solved the hardest parts. AI just needed to compose them.

But "done in one pass" carries hidden risk. The 37 static assertions verified that protocol steps executed in order. They **did not verify whether the side effects were acceptable**. Tests won't tell you that the main session got flooded with 371 lines of context. They won't tell you that users needed to open a separate terminal to review drafts. Passing tests created the illusion of "it works," and I skipped manual verification.

When tools are smooth enough, humans naturally treat review as optional. Smoothness itself becomes the trap.

---

## Pattern 2: Platform Reality Keeps Correcting AI's Assumptions

Same design philosophy, different platform. Claude Code. Completely different experience.

AI failed repeatedly to install the plugin—wrong `marketplace.json` format, wrong skill invocation path, config changes that didn't take effect. Once installed, it hit a permission pitfall: `bypassPermissions` had a confirmed bug that silently rejected writes outside the project root. Later, the main session and sub-session shared an API endpoint, and concurrent requests triggered ECONNRESET errors.

Every time, AI confidently proposed a solution based on lessons from the previous round. Every time, platform reality pushed back. V1 introduced `bypassPermissions` to suppress dialogs → writes got rejected. V2 moved writes to a resumed session → forgot about preparation-phase atomicity. V3 merged everything into a single Bash command → testing revealed `bypassPermissions` couldn't actually be removed.

AI has rich theoretical knowledge but zero awareness of platform-specific implicit rules. Experience accumulated on OpenCode doesn't transfer to Claude Code. Every ecosystem's "obvious" details need to be relearned from scratch. It's like a senior Java developer writing Rust for the first time: architectural skills transfer, but platform conventions don't.

Looking back, the differences between the three approaches seem obvious. Getting there took real effort.

---

## Pattern 3: The Human Makes Architectural Decisions at Critical Moments

After two weeks of using the original Aristotle, four problems surfaced: context pollution (371 lines injected wholesale), report leakage (full RCA pulled back into the main session), broken review flow (task sessions are non-interactive), and wasted attention (model selection popup). AI's analysis concluded that the four problems were independent and needed separate fixes.

I made a different call: **all four problems pointed to the same structural deficiency—no separation between the "coordinator" and "executor" roles**. Based on this judgment, the fix wasn't four independent patches. It was an architectural restructuring: splitting the monolithic 371-line file into four on-demand files (Progressive Disclosure), each with a clear responsibility.

AI couldn't make this decision. AI can analyze symptoms and propose fixes for each problem individually. But attributing scattered problems to a common root cause and making an architectural decision based on that attribution—that's a human cognitive advantage. AI's 5-Why analysis finds surface causes. Stringing four independent 5-Why chains into one systemic architectural insight requires cross-domain abstraction.

Another example. During GEAR protocol design, AI suggested "L should connect directly to S, O is an unnecessary middleman"—citing CQRS as analogy: commands go through the coordinator, queries go direct, standard practice.

I corrected this. L is the agent helping the user write code. O is Aristotle, an independent reflection skill. They run in different contexts. L's context should be reserved for the user's primary task—no reflection infrastructure details should enter it. AI's suggestion was later analyzed by Aristotle's own reflection mechanism via 5-Why. The root cause: "a default negative judgment about indirection layers."

In general software design, removing middlemen is usually reasonable. In agent systems, the isolation layer is the product.

---

## Pattern 4: Real Usage Exposes What Design Documents Can't

During the design phase, I confidently wrote "zero context pollution in the main session," "transparent to the user," "won't interrupt the workflow." All 37 tests passed. The logic was correct at the code level—Coordinator did launch Reflector, Reflector did generate a DRAFT.

Then I actually used it:

| What the Design Promised | What Actually Happened |
|---|---|
| Zero context pollution | SKILL.md's 371 lines fully injected + full RCA report pulled back |
| Transparent to the user | Model selection dialog popped up immediately, consuming a conversation turn |
| Won't interrupt workflow | Review flow was broken; user needed a separate terminal |

This wasn't AI's fault. AI faithfully implemented the protocol in SKILL.md. The problem was that the protocol itself didn't account for side effects. Tests verified "did the protocol execute correctly." They didn't verify "are the side effects acceptable."

Later, during claude-code-reflect development, I put this lesson into practice: let AI test the system. Testing revealed three blind spots in the design documents—`bypassPermissions` as a platform quirk, API concurrency as an environment constraint, heredoc variable non-expansion as a Bash implementation detail. None of these were foreseeable at design time. When AI tests a system, it's not just an executor. It's a design verification participant.

Automated tests verify correctness. Manual testing verifies experience. Neither replaces the other.

---

## Pattern 5: AI Does the Research, Human Makes the Call

The previous patterns are about design and implementation. But there's another collaboration mode running throughout the entire project, less visible but always present—AI doing research that improves the quality of my decisions and reduces the chance of mistakes.

When refactoring Aristotle, I needed to confirm a critical fact: are OpenCode's `task()` sessions actually non-interactive? Not a guess. AI examined OpenCode's source code and database, empirically verifying that all 47 task sessions contained exactly 1 user message (a system prompt), with zero follow-up interaction. It also found GitHub Issues #4422, #16303, and #11012, all pointing to the same conclusion. This wasn't AI's "opinion." It was empirical data. Based on this evidence, I made the architectural decision to move review into the main session instead of the sub-agent session. Without this research, I might have kept going down the wrong path of "let users switch into the sub-agent session for review."

When designing the MCP Server, AI produced a comparison of Git vs. SQLite. Git's advantages (transparent, lightweight, no runtime dependency) and SQLite's advantages (query power, complex indexing) were laid out objectively. I chose Git based on the judgment that "a frequently-debugged early system needs transparency." AI also researched the Dream subsystem's sandbox design from Claude Code's leaked source, Cursor Bugbot's multi-round parallel analysis strategy, and the latest practices in harness engineering. These research outputs went directly into the third and fifth blog posts, backing up the trust tiering model and GEAR protocol design.

Even model selection involved AI-supported research decisions. When I ran into technical issues during claude-code-reflect development, I specifically had a deep conversation with Sonnet 4.6 to analyze the causes. But for the project implementation itself, I judged that the current model was fully capable and used it to move forward. This too is research—judgment about model capability is itself "research data" accumulated through daily use.

The pattern: **AI provides information and options. The human chooses based on judgment.** AI's research capabilities—rapidly retrieving documentation, examining source code, comparing approaches, synthesizing evidence—dramatically reduced my decision-making cost. Tasks that used to take hours of flipping through docs, reading source code, and searching Issues now produce structured research results in minutes. The quality of my decisions didn't drop (because the final judgment was still mine), but the speed and confidence improved significantly.

And AI's research didn't just serve my decisions. It served the writing. The OpenClaw security incident analysis, CVE inventory, and industry discussions in the third article—all of that material was gathered with AI's help. AI didn't write my conclusions. It found and organized the evidence so my conclusions could stand.

---

## Pattern 6: AI Executes and Verifies, Human Sets Direction and Priorities

The rule management system went through five stages of iteration, each forced out by a concrete problem encountered in actual use:

- Rules couldn't be rolled back → introduced Git
- Read/write interference → introduced read-write separation and a state machine
- AI executing git commands was unreliable → introduced the MCP Server
- Rules had no structure → introduced YAML frontmatter and search dimensions
- Production and review goals conflicted → introduced role separation
- Design was reusable → abstracted into the GEAR protocol

Throughout this iteration, AI did the bulk of concrete execution: writing 8 MCP Server tools (75 pytest cases, all passing), designing two-phase streaming filtering, implementing atomic writes and cold-start migration. This work is voluminous, detail-heavy, and deterministic—exactly AI's strength zone.

But every **directional decision** was mine. Why Git instead of SQLite? Because "visible and tangible" transparency is critical for a frequently-debugged early system. Why not let AI execute git commands directly? Because the rule repository is the user's long-term knowledge accumulation—one wrong command can destroy the entire history. Why split O/R/C/L/S into five roles? Because R optimizes for coverage and C optimizes for precision—mixing them lets two goals interfere with each other.

AI can produce high-quality output on "how to implement." But "why this choice" requires human judgment. Especially when tradeoffs involve values—transparency vs. performance, security vs. flexibility, isolation vs. efficiency—these judgments aren't technical problems at their core.

---

## Pattern 7: The Reflection System Reflects on Its Own Designer's Mistakes

During GEAR protocol design, AI suggested that L should bypass O and connect directly to S. That error was later subjected to a 5-Why root cause analysis by Aristotle's own reflection mechanism, which produced this rule:

> A default negative judgment about indirection layers—assuming every additional coordination layer is unnecessary complexity. This judgment is usually valid in general software design, but wrong in Aristotle's context. Aristotle's indirection layer isn't overhead; it's the product itself. The entire point of the skill is to make the reflection infrastructure invisible to the primary agent. Removing the indirection layer removes the product value.

AI made an error while designing a reflection system. The reflection system reflected on that error and generated a preventive rule. A bit recursive, but exactly what the system was designed to do—learn from mistakes, even the designer's own.

This reveals a deeper collaboration pattern: **an AI system's metacognitive capability can feed back into the system's own design.** When AI can examine its own decision-making process, identify cognitive biases, and generate preventive rules, it has evolved from an "execution tool" into a "cognitive partner." This partnership isn't built on the assumption that AI is always right. It's built on joint reflection about errors.

---

## The Evolution of Seven Patterns

Arranged chronologically, the seven patterns form a clear evolutionary line:

| Phase | Dominant Pattern | Human Role | AI Role |
|---|---|---|---|
| Initial design | Human gives philosophy, AI fills details | Principle setter | Solution implementer |
| Cross-platform port | Platform reality corrects assumptions | Problem discoverer | Solution iterator |
| Architecture refactoring | Human makes critical architectural decisions | Root-cause synthesizer | Concrete executor |
| Usage validation | Real usage exposes design blind spots | Experience verifier | Test participant |
| Research support | AI does research, human makes the call | Decision maker | Research assistant |
| System iteration | AI executes and verifies, human sets direction | Direction setter | Executor and verifier |
| Metacognitive closure | The reflection system reflects on itself | Corrector + confirmer | Self-examiner + learner |

The trajectory: **humans gradually shift from "full involvement" to "intervention at key decision points," while AI gradually gains "limited autonomy + self-reflection" capability.** This direction and the trust tiering model in the GEAR protocol (Level 0 → Level 3) are two sides of the same coin—as trust accumulates, checkpoints move backward. But judging when it's time to move them remains a human responsibility.

This is not a picture of "AI gets stronger, humans become less important." The opposite—as AI capability grows, human judgment becomes more critical, because every decision's blast radius expands. One wrong reflection rule, auto-loaded, can skew decisions across dozens of subsequent sessions. Stronger AI demands more precise human steering.

The key to steering AI isn't prompt engineering, and it isn't letting AI run autonomously. It's intervening at the right moments—knowing when to let go, when to step in, when to reflect. The Aristotle project itself has been the training ground for that judgment.
