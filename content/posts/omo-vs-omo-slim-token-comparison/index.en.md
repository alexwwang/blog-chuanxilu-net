---
title: "OMO vs SLIM: I Switched Plugins to Save Tokens. Here's What Actually Happened."
slug: "omo-vs-omo-slim-token-comparison"
date: 2026-05-06T10:00:00+08:00
draft: false
description: "I switched from OMO to SLIM expecting lower token bills. The total average barely moved. But when I broke it down by task type, the picture got far more interesting."
tags: ["opencode", "token", "benchmark", "AI-assisted development"]
categories: ["AI Practice"]
toc: true
cover:
  image: "cover.png"
  alt: "OMO vs SLIM: I Switched Plugins to Save Tokens. Here's What Actually Happened."
---

> **TL;DR:** I switched from OMO to SLIM and ran it for 13 days. Average Tokens per message dropped 3.7% — practically flat. Broken down by task type: coding flat, writing +61%, review -53%, debug +121% (unreliable, tiny sample). Aristotle dropped 68%, but the main cause was an architecture rewrite, not the plugin. "Saving tokens" is not a global fact. It's local. The real differences are in experience and architecture choices, not in token counts.

oh-my-openagent ([GitHub](https://github.com/code-yeongyu/oh-my-openagent), npm package `oh-my-opencode`) and oh-my-opencode-slim ([GitHub](https://github.com/alvinunreal/oh-my-opencode-slim)) are two OpenCode plugins. The first is the original. The second is a fork. I'll call them OMO and SLIM from here on.

OMO goes all-in: 11 agents, prompts up to 1,100 lines, batteries-included. SLIM bets on minimal viable complexity: seven agents, trimmed prompts. SLIM has Council (multi-model voting) and Interview features that OMO lacks. OMO counters with LSP deep integration, hashline edit, ultrawork mode, and model-prompt hard binding.

After surveying both, one question mattered to me above all: SLIM claims lower token consumption. How much lower?

On April 22, 2026, I switched. Disabled OMO, installed SLIM. Ten minutes, done. Ran it for 13 days, pulled the data, and found a story far more complicated than "saves tokens" or "doesn't."

## Evaluation Method

Where does the data come from? OpenCode's session database, sitting at `~/.local/share/opencode/opencode.db` — a SQLite file. I wrote a Python script called opencode-daily-stats (with AI assistance, naturally) to extract token consumption records from it.

The core metric is **average Tokens per message** (`∑tokens / messages`). Why not just look at totals? Because the two periods had different usage intensity. Total token counts get distorted by message volume. Average Tokens per message is what actually reflects how efficiently a plugin builds context.

Time windows:

- OMO period: 2026-04-15 ~ 2026-04-21 (7 days)
- SLIM period: 2026-04-23 ~ 2026-05-05 (13 days)

Why start from April 15 and not earlier? Usage intensity stabilized after that date. Daily message counts between the two periods are close — OMO averaged 1,108 messages/day, SLIM averaged 1,339/day, a 1.21x ratio. Small enough to avoid intensity differences biasing the conclusions.

I labeled every session by task type and excluded automated test sessions. Labeling methodology is in [Appendix B](#appendix-b-labeling-methodology). Below I present three dimensions: total messages, total Tokens, and average Tokens per message.

## Layer 1: Total Average Is Flat

Overall numbers first:

| Metric | OMO (7 days) | SLIM (13 days) |
|--------|--------------|----------------|
| Total Messages | 7,758 | 17,411 |
| Total Tokens (M) | 736.9 | 1,592.3 |
| Avg per Message (K) | 95.0 | 91.5 |
| Daily Messages | 1,108/day | 1,339/day |
| Daily Tokens (M/day) | 105.3 | 122.5 |

Average Tokens per message dropped 3.7%. Practically flat. Daily Tokens went up 16%, but daily messages also went up 21% — SLIM period saw slightly heavier use.

"Looks like no difference." If I stopped here, the conclusion would be: saving tokens is a myth. But this average hides a lot.

## Layer 2: Task-Level Breakdown

### Basic Stats: Task Composition and Daily Spend

The two periods couldn't be more different in what I was doing.

| Category | OMO Daily Msgs | OMO Share | SLIM Daily Msgs | SLIM Share | Share Change |
|----------|----------------|-----------|-----------------|------------|-------------|
| **coding** | **160.4** | **14.5%** | **590.1** | **44.1%** | **+29.6pp** |
| writing | 302.6 | 27.3% | 263.4 | 19.7% | -7.6pp |
| **design** | **314.3** | **28.4%** | **147.6** | **11.0%** | **-17.4pp** |
| review | 33.1 | 3.0% | 128.5 | 9.6% | +6.6pp |
| debug | 2.3 | 0.2% | 80.1 | 6.0% | +5.8pp |
| exploration | 112.1 | 10.1% | 67.6 | 5.0% | -5.1pp |
| **Aristotle** | **169.4** | **15.3%** | **35.3** | **2.6%** | **-12.7pp** |

| Category | OMO Daily (M/day) | OMO Share | SLIM Daily (M/day) | SLIM Share | Share Change |
|----------|-------------------|-----------|---------------------|------------|-------------|
| **coding** | **17.8** | **17.0%** | **61.1** | **51.4%** | **+34.3pp** |
| writing | 19.4 | 18.6% | 27.2 | 22.8% | +4.2pp |
| **design** | **37.9** | **36.3%** | **14.4** | **12.1%** | **-24.2pp** |
| review | 2.2 | 2.1% | 4.1 | 3.4% | +1.3pp |
| debug | 0.1 | 0.1% | 8.4 | 7.0% | +6.9pp |
| exploration | 5.6 | 5.3% | 2.4 | 2.0% | -3.3pp |
| **Aristotle** | **21.4** | **20.5%** | **1.4** | **1.2%** | **-19.3pp** |
| **Total** | **104.4** | **100%** | **118.9** | **100%** | |

During the OMO period, I was mostly writing blog posts, designing solutions, and running Aristotle reflections. The SLIM period shifted heavily toward TDD coding and review, with debug volume climbing too. The two periods couldn't be more different in what I was doing.

A few cross-cutting facts stand out.

Coding accounts for 51.4% of SLIM's daily token spend — over half. Daily tokens for coding rose from 17.8 M to 61.1 M. The main driver isn't the plugin being more expensive. It's that coding messages surged 6.8x.

Writing messages increased 1.6x. Daily tokens climbed in step.

Review messages jumped 7.2x. Daily tokens still went up.

Aristotle messages fell to 39% of the OMO level. Daily tokens collapsed from 21.4 M to 1.4 M.

### Per-Message Cost Comparison

Control for task type, and the differences surface:

| Category | OMO Avg (K/msg) | SLIM Avg (K/msg) | Change | Direction |
|----------|-----------------|-------------------|--------|-----------|
| coding | 110.8 | 103.5 | -6.6% | ≈ flat |
| **writing** | **64.1** | **103.1** | **+60.8%** | **↑ more expensive** |
| design | 120.6 | 97.8 | -18.9% | ↓ cheaper |
| *review* | *67.2* | *31.6* | *-53.0%* | *↓ cheaper* |
| **debug** | **47.3** | **104.7** | **+121.4%** | **↑ more expensive** |
| *exploration* | *49.6* | *35.4* | *-28.6%* | *↓ cheaper* |
| *Aristotle* | *126.5* | *40.7* | *-67.8%* | *↓ cheaper* |

Three categories cheaper. Two more expensive. One flat. Aristotle's 68% drop came from an architecture rewrite (LLM calls migrated to MCP), not from a plugin mechanism difference. Excluding Aristotle, the plugin itself made three categories cheaper (review, exploration, design), two more expensive (writing, debug), and one flat (coding). "Saving tokens" is not a global fact. It's local.

## Attribution

The data is on the table. Let me break each one down.

**Coding flat (-6.6%)** is no surprise. SLIM's coding subagent builds context much the same way OMO does — pull code, run tests, read output. Token costs land in the same ballpark. Coding ate 51.4% of SLIM's daily token budget. This category didn't get more expensive, which means SLIM didn't make the biggest cost item worse.

But not every category stayed flat.

**Writing +61%** is worth watching. During the SLIM period, writing sessions involving @zh-writer, @en-writer, and @observer subagents may have heavier context construction — more background material pulled in per writing task, or higher overhead from multi-agent collaboration. The exact cause needs more data.

**Review -53%** is cheaper per round, not cheaper overall. In the OMO period, review was done by @oracle/@Momus performing deep audits, each round carrying heavy context — full files, history, project rules. One review round was very expensive. In the SLIM period, most review happened inside ralph loops as quick confirmations: "anything wrong this round?" Much lighter. But subjectively, I ran more review rounds with SLIM. Cheaper per round, more rounds to compensate. Daily tokens still went up.

**Debug +121%** — don't take this number seriously. The OMO period had only 16 debug messages. Too small a sample for any reliable conclusion. The SLIM period's 1,041 messages are the real data. In debug scenarios, the model reads code, runs commands, and analyzes output repeatedly. Context accumulates fast. High token consumption is expected.

The most interesting finding comes last.

**Aristotle -68%**, but the main cause isn't the plugin. SLIM doesn't support async subagent execution. The Aristotle project therefore rewrote its bridge plugin, migrating a lot of work that previously depended on LLM calls into MCP — file reads and writes, rule queries, state management all shifted from LLM invocations to local tool calls. This rewrite accidentally slashed token consumption — a live example of constraint driving innovation.

## User Experience Differences

Some differences don't show up in quantitative data.

Under OMO, subagents process tasks in parallel. The main session stays unblocked. I can run multiple directions at once — one agent writes code, another researches docs, and I keep chatting about next steps in the main session. Under SLIM, the main session blocks when a subagent starts. I wait, or I switch to something else. The interrupted workflow is noticeable.

But SLIM brought an unexpected gain too.

The Aristotle case was covered in the attribution section. From an experience perspective, the impact went beyond the token number. The constraint changed how I think about architecture choices. The boundary between LLM calls and local tool calls is worth reexamining.

Also, under SLIM's task prompt environment, I noticed the model's thinking depth thinned out during certain periods. AI using 5-Why would stop at the surface, chase a single line, and fall into confirmation bias more often. This pushed me to develop a fallback inquiry protocol. I wrote about this in a three-part series: [When AI Misuses 5-Why: Shallow Tracing, Single-Line Follows, and Confirmation Bias](/en/posts/inquiry-protocol-design-1/), [Putting a Quality Harness on AI: Seven Conditions for an Inquiry Protocol](/en/posts/inquiry-protocol-design-2/), [The Last Line of Defense: Independent Confirmation and Protocol Reflexivity](/en/posts/inquiry-protocol-design-3/).

## Reflection: The Right Way to Evaluate "Lightweight"

Grouping by task type is more complete, nuanced, and objective than looking at the total average. But it still has limitations.

The ideal approach would be concurrent A/B testing — same time period, same tasks, two plugins. In practice, once you switch, you don't switch back to run a control. This experimental design is hard to implement given current constraints.

A more ideal approach would also include: stratified comparison by task type, controlling for task type before comparing costs within each category; factoring in task completion rate and rework rate (saving tokens but reworking more means no real savings); quantifying the parallel vs. blocking capability as an experience dimension.

What this article achieves is a grouped comparison after aligning time windows. Still a distance from the ideal. I hope readers with the means to run more rigorous controlled experiments will share their results.

## Closing

The switching cost is low. Trying it out won't hurt. But don't set high expectations for "saving tokens." The real differences are in experience and architecture choices, not in token counts.

---

## Appendix A: Research Details

Before switching, I did a comparison survey. Here are the core differences:

| Dimension | OMO | SLIM |
|-----------|-----|------|
| Design Philosophy | batteries-included, full-featured | minimal viable complexity, trimmed to sufficiency |
| Agent Count | 11 | 7 |
| Prompt Scale | up to 1,100 lines | trimmed |
| Unique Features | LSP deep integration, hashline edit, ultrawork mode, model-prompt hard binding | Council multi-model voting, Interview feature |
| Subagent Execution | async parallel | sync blocking |

The core motivation was straightforward: shorter prompts mean less context, which should mean fewer tokens. The actual test showed this reasoning chain is too simple.

## Appendix B: Labeling Methodology

Data credibility requires an auditable labeling method. Here are the classification rules:

| Dimension | Rule | Example |
|-----------|------|---------|
| main session | classify by title keywords | contains "blog", "post", "writing" → writing; contains "debug", "fix", "repair" → debug |
| subagent session | identify subagent type first, then classify by the task it serves | observer analyzing a debug screenshot → debug; observer analyzing a cover image → writing; council doing code review → review; council reviewing a design proposal → design |
| coding subcategories | split into review, coding, debug, ops, setup | contains "implement", "refactor" → coding; contains "review", "check" → review; contains "deploy", "setup" → ops |
| Aristotle | reflection session + checker session + workflow session grouped together | — |
| Exclusion rule | automated test sessions excluded from statistics | — |
