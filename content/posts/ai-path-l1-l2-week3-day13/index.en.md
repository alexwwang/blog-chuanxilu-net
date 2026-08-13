---
title: "Day 13 Practice: Turning a Workflow into a Skill Kit"
slug: "ai-path-l1-l2-week3-day13"
date: 2026-08-06T16:00:00+08:00
draft: false
description: "AI Path L1→L2 Day 13 practice: build a picture book generation workflow into a reusable skill kit through six conversations with an AI agent. Real project, real prompts, real outputs."
tags: ["AI", "tutorial", "practice", "API", "automation", "skill"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.jpg"
  alt: "Watercolor: six cards arranged in a circle labeled GOAL, FLOW, LIST, PLAN, BUILD, TEST, with a folder in the middle. Six conversations turning a workflow into a skill kit."
---

> This is Day 13 of the AI Path L1→L2 Upgrade Guide. Do [Day 8](../ai-path-l1-l2-week2-day8/), [Day 9](../ai-path-l1-l2-week2-day9/), [Day 10](../ai-path-l1-l2-week3-day10/), [Day 11](../ai-path-l1-l2-week3-day11/), and [Day 12](../ai-path-l1-l2-week3-day12/) first.

Day 12 ended with a promise: in the next practice, we'd run the pipeline by hand. Two tools working in relay. Today, I deliver on that promise.

I'm not going to show you how to use a ready-made skill workflow. I'll show you how to build one from scratch. The project is [picture-book-pipeline](https://github.com/alexwwang/picture-book-pipeline), which I use to batch-generate children's picture books. It turns a workflow into a complete skill kit: a SKILL.md overview, role prompts, and execution scripts, all in one directory.

The build came out of six core conversations with an AI agent, plus follow-up details and fixes. The agent did the work. Six rounds, six jobs: set the goal, explain the workflow, confirm nodes and acceptance, ask for a plan, implement, test. Each round has its design, its thinking, and its prompt.

![Six-round conversation building the skill kit: GOAL, FLOW, LIST, PLAN, BUILD, TEST cards in a circle around a folder, watercolor](illustration-six-rounds.jpg)

---

## Round 1: Set the Goal

Defining the target end state before implementation is critical. This is Day 10's GCO. Goal: batch-generate children's picture books. Constraints: ages 3-5, fixed vocabulary list, 6 pages per story, `watercolor` style. Output: a reusable Skill Package structure. The first prompt:

**Input · Prompt**

```text
Goal: build a reusable Skill Package for batch-generating children's picture books. Constraints: ages 3-5, fixed vocabulary list, 6 pages per story, `watercolor` style. Output: a reusable Skill Package with the protocol, role prompts, and execution scripts.
```

Without a goal, everything downstream loses direction. That's what GCO is for: the agent knows the finish line before we talk about how to get there.

---

## Round 2: Explain the Workflow

Goal set. Now tell the agent what the workflow is. The picture book generation workflow is divided into five stages: outline, story, prompts, images, and review. This round writes no plan. It confirms the agent's understanding first.

**Input · Prompt**

```text
The workflow is: outline → story → image prompts → generate images page by page → review. First, restate your understanding of each stage, then we continue.
```

Requiring the agent to restate the workflow ensures alignment before execution, preventing cascaded errors in later rounds. Day 8's task description applies here: if the job isn't described clearly, the AI can't do it.

---

## Round 3: Confirm Nodes and Acceptance

Workflow confirmed. Now walk through each node's responsibility: what it does, what the intermediate result looks like, what the final result must satisfy. Before touching code, bring in Day 12's dividing line.

Day 12's rule: writing prompts is judgment work; executing API scripts is pure grunt work. Judgment happens once; grunt work goes to the script. The test is whether the step can be pinned down. If it can, the logic can be written as program steps and the result is deterministic. Image generation is that kind of work: prompt ready, flow fixed, then call the API, save the file, done. Every step is a fixed action. If a step can't be strictly pinned down, forcing it into hardcoded program logic yields rigid, subpar results. It needs flexible adjustment that code can't express. Writing stories is that kind of work. Word lists, sentence patterns, plots can all have standards, but all-rule writing makes every story the same. Adjust flexibly on top of standards. That's judgment work, for the agent or a human.

**Input · Prompt**

```text
Analyze each node: can it be implemented as a script, and what is its acceptance criterion. Define the handoff format between nodes together. Scriptable nodes go to scripts; the rest get prompts for the agent. Give the full list first; I'll confirm.
```

The agent ran each node through the test and came back with the full list:

**Output · Agent checklist**

> Outline: not scriptable, assigned to the agent. Acceptance: an outline with the vocabulary list and page count\
> Story: not scriptable, assigned to the agent. Acceptance: a table covering the full vocabulary\
> Prompts: not scriptable, assigned to the agent. Acceptance: fourth column filled, consistent style\
> Images: scriptable, assigned to the script. Acceptance: one image per page, saved successfully\
> Review: not scriptable, assigned to the agent. Acceptance: image and text judged consistent\
> Intermediate artifact: four-column table with page number, scene description, story text, image prompt

I confirmed the list. No disagreement on the split. For review, the agent checks first, a human has the final say.

The intermediate output is the core. The agent and the scripts hand off through a four-column table: page number, scene description, story text, image prompt. Page numbers are `p.01`, `p.02`. Parsing is position-based: the script doesn't look at column names, only column indices. Reading by column name would allow flexible column order, but a renamed column header breaks the script. I chose position, simple and direct. There's a trap with column names: the agent writes the table, and if it tweaks a header, the script dies. Why parse by position instead of column name? Because agents love tweaking headers on a whim. Locking column position is a bit rigid, but it gives the strongest constraint on the agent. Reorder the columns and the script reads the wrong cells and fails immediately. The table is Day 12's protocol. The clearer the protocol, the higher the chance the agent writes working scripts.

Protocol before implementation. The table comes first; role prompts and scripts all follow it.

---

## Round 4: Ask for a Plan

Nodes and acceptance confirmed. Now the agent refines the implementation plan. In this round, the agent formulates a multi-layer deployment plan detailing component hierarchy and role prompt organization.

**Input · Prompt**

```text
Based on the confirmed list, propose an implementation plan: the skill directory structure, the prompt framework for each role, and script behavior with parameters. List them by node, noting the dependency order.
```

The plan has three layers. SKILL.md is the protocol overview, covering four things: order, what each step produces, format, failure handling. roles/ holds the four role prompts. tools/ holds the agnes usage, tied to a role. scripts/ holds the execution scripts. The tree:

**Output · Proposed tree**

```text
skill/
├── SKILL.md               # Overview: order, output, format, failure handling
├── roles/                 # Judgment-based role prompts
│   ├── outline-planner.md # Outline: topic and audience, fixed structure
│   ├── story-writer.md    # Story: three-column table from the outline
│   ├── prompt-artist.md   # Fourth column: image prompts
│   └── image-qa.md        # Review: judge image-text consistency
├── tools/                 # Agnes usage for role 4
│   └── agnes-generate.md  # Call the existing agnes image skill
└── scripts/               # Execution tools that ship with the skill
    ├── pipeline.py        # Parse the table, batch generate, mechanical acceptance
    └── verify_images.py   # Visual review: score images against text
```

This file tree serves as the implementation checklist. The plan locks down the structure, while the exact role of each file was already settled in Round 3. Round 5 has the agent implement file by file against the list. Every file, md or py, was written by the agent from the design.

Each role prompt is three sections: identity, input, output format. Day 14 covers how to write them.

---

## Round 5: Confirm, Then Implement

Plan confirmed. Let the agent work. Implementation follow-up can take two approaches: single-pass execution, or iterative micro-stepping. I chose micro-stepping for the scripts. Since they involve the most ambiguity, it's better to write and revise as you go.

Role prompts first. Four roles, the agent wrote them one by one against the plan, and I reviewed each one. How a prompt document tells the agent what to do and how to do it: Day 14. Not here.

Scripts: talk requirements before writing. What does `pipeline.py` do? Parse the `stories.md` table, generate one image per page. It doesn't send HTTP requests itself. It calls the existing `agnes-ai` image skill. `agnes-ai` is a skill set for calling command-line tools, with an image generation workflow inside; the agent can use it directly. The requirements prompt:

**Input · Prompt**

```text
`pipeline.py` parses `stories.md` line by line and generates one image per page. Image generation calls the existing `agnes-ai` skill, running the `agnes_media.py image` command with the prompt read from the fourth column. Suggest concurrency, timeout, and retry counts from your experience, with clear reasoning. Print one `ok` line per page with the story name and page number. Log one JSON line per page in `audit.log` with time, story, page, API, status, URL. If anything is uncertain, ask me before writing.
```

The agent came back with parameter suggestions: concurrency 4, timeout 120s, 2 automatic retries on failure. The reasoning made complete sense, so I rolled with it. I had my own ideas here. `audit.log` uses JSON with six fixed fields: time, story, page, API, status, URL. Progress lines are for human readability; JSON logs are for script parsing and post-run auditing. And rerun parameters: `--story` picks a story, `--pages` picks pages. That's a checkpoint for the pipeline. If a run dies halfway, pick the failed pages and continue from the checkpoint instead of rerunning the whole batch. Suggesting this is on me: the agent won't think of it. Requirements settled, then the agent writes code. That's Day 12's "turn the script into a tool". Requirements clear, prompts become command-line parameters. Change parameters, not code.

**Input · Prompt**

```text
Implement `pipeline.py` and `verify_images.py` per the agreed requirements. Use the `agnes-ai` image generation skill. TDD: write the tests first, then implement; done only when the tests pass.
```

When the scripts were done, the agent ran them first and only handed them to me after they passed. The agent runs the commands; nobody types manually. The implementation flow: talk requirements, fix parameters, agent writes, agent self-tests, user accepts.

---

## Round 6: Test

Implementation done. Does the output meet Round 1's goal? Have the agent list a test plan mapped to the goal and the acceptance criteria.

**Input · Prompt**

```text
List a test plan covering Round 1's goal and Round 3's acceptance criteria; for each item, explain how to test it and the expected result.
```

Plan listed. Run it:

**Input · Prompt**

```text
Run the tests per the plan. Paste the commands and output: per-page output, `audit.log`, verify results. I'll interpret the results.
```

The agent ran mock first, no cost, no network:

**Input · Command**

```bash
uv run python3 skill/scripts/pipeline.py run stories.md --output-dir output
```

Each processed page outputs a status line where `ok` designates successful execution:

**Output · Run results**

```output
  ok  the-red-ball p.01
  ok  the-red-ball p.02
```

`audit.log` gets one JSON line per page: time, story, page, API, status, URL. The mock run produced this. `api` says mock:

**Output · audit.log entry**

```json
{"ts": "2026-08-05T04:12:56.832184+00:00", "story": "the-red-ball", "page": 2, "api": "mock", "status": "ok", "url": "mock://images/the-red-ball/page_02.png"}
```

Run the same mock command from the repo root to verify. The result should match the article.

Structural validation is also handled by the script. The agent ran verify:

**Input · Command**

```bash
uv run python3 skill/scripts/pipeline.py verify stories.md --output-dir output
```

Output: `verify: PASS` and `errors: 0`. Page numbers continuous, fields non-empty, images exist. Three invariants. Day 11 calls this invariant checking.

Structural validation checks that files exist, not what the images contain. Whether the picture matches the text is another layer. The visual QA script sends image, scene description, and story text to a vision model:

**Input · Command**

```bash
uv run python3 skill/scripts/verify_images.py \
  --manifest output/manifest.json --output-dir output \
  --report qa-report.md --model opencode/mimo-v2.5-free
```

Mock passing wasn't the end. The agent switched to real agnes and the first real run failed. The real command:

**Input · Command**

```bash
uv run python3 skill/scripts/pipeline.py run stories.md \
  --output-dir output \
  --api command \
  --cmd "uv run --with httpx python agnes_media.py image --prompt-file {prompt_file}" \
  --json-path data.0.url \
  --cmd-cwd ~/agnes-ai
```

6 images, 5 succeeded. One failed with a network resolution error (`Cannot connect to unknown`). Retries happen inside the same run; `stderr` prints `retrying ... (attempt 1/2)`. Still failing, record `errors: 1`. Verify doesn't trigger a rerun; pick the failed pages and rerun them. 6 for 6 after that. Real-world APIs don't always behave like textbook examples. Failures are part of the process. Day 9's reminder: when evaluating providers, stability is a cost.

Single-page repair has parameters. `--story` picks a story, `--pages` picks pages. Redo only the bad pages, not the whole batch. This requirement came from Round 5's talk. Without it, the agent would have missed the feature.

AI review caught real problems. `the-red-ball` page 1: the scene description says "standing", the generated image shows "sitting". The vision model judged `consistent=false`. If the vision model flags a mismatch, that's an automatic fail. The fix: edit the scene description column and rerun just that page. Regenerate, re-verify. Only then is it truly done. Look at the pipeline end to end: agent produces content, scripts do the volume, AI reviews, human decides. Day 12's two tools in relay, four links joined.

---

## Today's Takeaways

- [ ] Use GCO to set the goal before talking to the agent
- [ ] Have the agent restate the workflow to confirm shared understanding
- [ ] Draw the line between scripts and LLM judgment: can the logic be strictly pinned down?
- [ ] Get a plan from the agent, implement only after confirming it
- [ ] Nail down requirements and parameters first; only then let the agent write code
- [ ] Run tests against a clear checklist mapped back to your original goal

Today a workflow became a skill kit. Six conversations: set the goal, explain the workflow, confirm nodes and acceptance, ask for a plan, implement, test. Looking back, no new concepts. Core concepts were logically chained: GCO came from Day 10, task descriptions from Day 8, division and protocols from Day 12, acceptance checks from Day 11, and provider evaluations from Day 9. Six rounds, and in them the principles were applied in order.

Day 14 is next: dissect this skill further. The focus is how to write prompts, how an md document tells the agent what to do and how to do it.

The full project code and docs are open source on GitHub: [picture-book-pipeline](https://github.com/alexwwang/picture-book-pipeline). Commands, scripts, role prompts, 16 tests, all in the repo.

---

> This is Day 13 of the AI Path L1→L2 Upgrade Guide. The previous article was Day 12.
