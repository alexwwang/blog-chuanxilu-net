---
title: "Automating Skill Documents: Four Core Blocks for Tailored AI Workflows"
slug: "ai-path-l1-l2-week3-day14"
date: 2026-08-12T16:00:00+08:00
draft: false
description: 'Day 14 practice: automate your skill documents. Four core blocks (identity, input, output requirements, quality requirements) are all it takes for the AI to build your skill.'
categories: ["ai-path"]
tags: ["AI", "ai-path", "l1-l2", "skill", "prompt", "deepseek v4 flash"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: cover.png
  alt: "Four watercolor cards forming a role document: IDENTITY, INPUT, OUTPUT, QUALITY"
---

> This is Day 14 of the "AI Path: Advanced Upgrade Guide" Week 3 series. Previous post: [Day 13 Practice]({{< relref "ai-path-l1-l2-week3-day13" >}}). Project repo: [picture-book-pipeline](https://github.com/alexwwang/picture-book-pipeline).

## Introduction

In Day 13, I built a skill through six rounds of conversation. A skill is made of role documents, one per role. The agent works from those documents. How you write them directly dictates the quality of the output.

A role document has four blocks: identity, input, output requirements, quality requirements. This post goes through each one. What to write, and why.

## Don't Grab Someone Else's Skill

I don't want to write them by hand. Can't I just use a skill someone else built?

It saves effort. But there are two kinds of risk.

One is technical. A skill grows out of someone else's environment. The driver model, CLI settings, API keys, and script paths are often hardcoded to the author's personal environment. If you copy it as-is, it may fail to run, and that is the minor issue. If it fails to align with your personal workflow, you waste both time and tokens.

Their acceptance criteria suit the original author's workflow, not yours. The quality requirements encode what the original author calls correct. Your project might check different things. If you adopt the skill as-is, defects can easily slip through, or the output may fall far short of your expectations.

The intermediate artifact protocol is worse. It comes with a fixed format, like Day 13's stories.md, a three-column table read by position. That format belongs to someone else, and your workflow has to consume it. If it doesn't fit, you have to add a converter or change your interface.

The other risk is security. A skill could harbor malicious prompt injections, potentially wiping your root directory, exfiltrating API keys or credentials, or planting a trojan. If you skip sandboxing to save effort, the consequences could be disastrous. 🙈

So don't simply grab one skill and run it without checking. By understanding the four parts of a skill first, you'll see whether a skill fits you and what to change to fit your needs. Or just ask the AI to build one from scratch, using the following rules of thumb.

## The Skeleton of a Role Document

Take story-writer.md, one of the skill's role documents. It's Role 2 in the picture-book pipeline. Its job is to write each page's story text from the outline.

**Block 1: Identity.** The heading says "Role 2: story-writer (story content)". The driver model is `opencode-zen/deepseek-v4-flash-free` (free tier). Two lines. They tell the agent who it is and which model to use.

**Block 2: Input.** A single line specifying "outline.md (output of Role 1)", with the prompt body dynamically embedding `{full text of outline.md}`. The previous role's output is passed directly into the prompt in its entirety.

**Block 3: Output requirements.** Inside the prompt body, the heading says "Output Requirements (Strict)". Read them one by one:

```text
- One Markdown table per story, placed after the '## Story N title' heading
- Fixed header: | page | scene description | story text |, second row is the separator |:--|:--|:--|
- Page numbers run continuously from 1
- Scene description: the page's scene (in Chinese, for later prompt conversion), what's in the picture + action + emotion
- Story text: one sentence, using only that story's vocabulary words + high-frequency words, simple sentence structure
- One table per story; separate tables with a # heading
- Output only tables, no explanation
```

**Block 4: Quality requirements.** A separate section at the end of the file:

- Story text uses only vocabulary words + high-frequency words (out-of-range words must be struck and rewritten)
- One sentence per page, ≤ 10 words
- Scene description and story text must match strictly (anything in the scene description must be supported by the story text, and vice versa)
- Page numbers run 1..N continuously (a broken table stalls Role 4's verify)

Four blocks answer four core questions: who the agent is, what inputs to use, what the output should look like, and what defines success.

## Technique 1: Write "How to Do It" as a Checklist

The output requirements have no adjectives. No "write carefully", no "write well". Every item is a verifiable short sentence: header fixed as X, page numbers start at 1, tables only.

AI agents ignore vague adjectives but thrive on explicit checklists. Saying "write carefully" leaves the model guessing. Specify "Header fixed as | page | scene description | story text |", and it knows exactly what each column requires.

Day 13's Round 6 test checklist runs on the same logic. Acceptance conditions listed item by item. The agent follows them. You check them.

Consider prompt-artist.md as another example. It explicitly mandates: "keep the first 3 columns as-is, add the prompt in column 4" and "page numbers, scene description, and story text must match the input exactly." Every item is fully verifiable. Use concrete checklists instead of descriptive adjectives.

## Technique 2: Quality Requirements = Acceptance Criteria Up Front

Defining acceptance criteria up front eliminates the need for manual post-checks. Day 11 covered three kinds of verification. They line up: format, content, consistency. story-writer.md's quality requirements cover all three.

Day 12 introduced the judgment work vs. labor test: can it be standardized into rules? Judgment work can't be scripted, but it can become a checklist inside a prompt. story-writer.md is the example. The checklist gets nailed down. The content stays open, for the agent to write on the spot.

outline-planner.md works the same way. Vocabulary must stay in the word list. Style stays unique across the whole piece. Role 1 guards the vocabulary when planning the outline.

## Technique 3: Input = Protocol Artifact

The previous role's output becomes the next role's input. The prompt body embeds `{full text of outline.md}`. That's pipeline-style passing.

![Pipeline passing: previous role's output embedded in next role's prompt](illustration-1.png)

The prompt serves as the primary consumer of the protocol. The clearer the protocol structure, the less boilerplate the prompt needs. Day 12 said intermediate artifacts are the protocol. outline.md's format is fixed in SKILL.md. story-writer.md doesn't re-explain the format. It just embeds the file.

prompt-artist.md is the same. Input is stories.md. The prompt body embeds `{full text of stories.md}`. Role 2's table, Role 3 adds column 4. The prompt enforces the protocol. First 3 columns stay untouched.

## Where Judgment Work vs. Labor Land in the Skill

The five roles are divided into two distinct types, each landing differently in the skill files.

Roles 1, 2, and 3 belong to judgment work and are directly driven by prompts. The execution order has a priority: the current agent runs it directly (recommended), delegates to a subagent, or installs pi or opencode for the CLI. The prompt says "what to do" and "how to do it".

Roles 4 and 5 handle pure execution (labor), executing via scripts with fixed parameters. Role 4's doc, `tools/agnes-generate.md`, specifies a command call:

```bash
uv run python3 skill/scripts/pipeline.py run stories.md \
  --output-dir output \
  --api command \
  --cmd "uv run --with httpx python agnes_media.py image --prompt-file {prompt_file}" \
  --json-path data.0.url \
  --cmd-cwd ~/agnes-ai \
  --concurrency 2 \
  --timeout 300 \
  --retries 2
```

Role 4 doesn't write a prompt. It writes invocation parameters. The dividing line is Day 12's criterion: judgment work runs on prompts, labor runs on scripts.

Role 5 (image-qa) occupies a hybrid middle ground. It runs as a script, `verify_images.py`. The judgment criteria live in the script's JSON protocol: `{"consistent": bool, "quality": 1-5, "issues": [...]}`. consistent=false or quality<3, that page fails. This is the half where criteria can be nailed down, handed to the script. The visual evaluation step is still performed by the model.

SKILL.md's five-role table draws the line:

| # | Role | Invocation |
|---|------|------------|
| 1 | outline-planner | Direct Agent / Subagent / CLI (by priority) |
| 2 | story-writer | Direct Agent / Subagent / CLI (by priority) |
| 3 | prompt-artist | Direct Agent / Subagent / CLI (by priority) |
| 4 | image-generator | skill/scripts/pipeline.py run |
| 5 | image-qa | skill/scripts/verify_images.py |

## Writing a Role Document Is Judgment Work, Too

Write the four blocks as structured requirements, then pass them to a skill-building tool like skill-creator. The agent generates the skill document according to the protocol. Put the acceptance criteria in the requirement prompt. The generated document won't drift from your goal.

## Today's Takeaway

- [ ] Can state the four-block skeleton: identity, input, output requirements, quality requirements
- [ ] Can write "how to do it" as a checklist, no adjectives
- [ ] Can put acceptance criteria up front in quality requirements
- [ ] Can use pipeline-style input: previous role's output embedded in next role's prompt
- [ ] Can tell judgment work (prompts) from labor (scripts)

Next post is the L2 graduation assessment. Finish it and L2 is done. Where L3 heads, that post will say.
