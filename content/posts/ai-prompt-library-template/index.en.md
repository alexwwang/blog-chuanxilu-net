---
title: "What My Prompt Library Looks Like: A Real Template"
slug: "ai-prompt-library-template"
date: 2026-05-28T06:00:00+08:00
draft: false
description: "Not sure how to organize a Prompt library? Here's a complete directory structure and three real examples you can copy directly."
tags: ["AI", "toolchain", "evolution-path", "prompt-engineering"]
categories: ["ai-path"]
toc: false
series: ["AI Path L0→L1 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor style: a wooden desk with a partially open drawer revealing neatly organized pastel index cards in three rows, three sample cards fanned out on the desk surface"
---

The biggest obstacle to building a Prompt library isn't the tool — it's knowing how to organize it. Yesterday you picked 5 Prompts; today I'll show you a complete real template.

## Directory Structure

This structure uses the Markdown folder approach. You can copy it directly:

```text
prompt-library/
├── writing/
│   ├── email.md
│   ├── article-summary.md
│   └── ...
├── analysis/
│   ├── data-interpretation.md
│   ├── case-breakdown.md
│   └── ...
├── daily/
│   ├── meeting-notes.md
│   └── ...
└── README.md (global notes)
```

The record format for each Prompt:

```markdown
## Original Prompt
[Your Prompt text]

## Effectiveness
[1-5 rating, or a brief note]

## Iterations
### v2: [What changed]
- New Prompt
- Effect change
```

## Example 1: Writing — Email Prompt Evolution

**Original Prompt v1**:

```
Write an email to my boss about project progress.
```

**Effectiveness**: 2/5 — Too generic. No specific format, tone is stiff and impersonal.

**Iteration v2**:

```
You are a project manager reporting to a CTO. Write a concise email covering: 1. Features completed this week 2. Technical blockers encountered 3. Next week's plan. Professional but not stiff tone, no more than two sentences per section.
```

**Effect change**: 3/5 — Clear structure, appropriate tone, but missing email subject line and call to action.

**Iteration v3**:

```
You are a project manager reporting to a CTO. Write a concise email covering: 1. Features completed this week 2. Technical blockers encountered 3. Next week's plan. Professional but not stiff tone, no more than two sentences per section. Subject line: "Project Update - [Project Name] - [Date]". End with "If you need more details, I can set up a brief meeting to discuss."
```

**Final rating**: 5/5 — Fully meets the need, ready to send.

I've used this Prompt for six months. It went from one sentence to three paragraphs of constraints, each revision driven by a real pain point from actual use.

## Example 2: Analysis — Data Interpretation

**Original Prompt**:

```
Explain this sales data.
```

**Effectiveness**: 3/5 — Gave general trends but lacked specific insights and actionable recommendations.

**Iteration**:

```
You are a data analyst. I will provide an Excel sales dataset with three columns: date, product category, and sales amount. Please:
1. Identify months where sales grew more than 20% month-over-month
2. Find product categories with consecutive sales declines
3. Give 3 actionable sales strategy recommendations
Output as a numbered list, each recommendation no more than 30 words.
```

**RBGO Breakdown**:
- **Role**: Data analyst
- **Background**: Excel data with date, product category, and sales amount columns
- **Goal**: Find growth months, declining categories, and provide strategies
- **Output**: Numbered list, each item under 30 words

**Effect change**: 4/5 — Clear output structure, specific insights, but occasionally misses edge cases. After adjusting column name descriptions for different data formats, rating stabilized at 4.5/5.

## Example 3: Daily — Meeting Notes

**Original Prompt**:

```
Organize this meeting recording into notes.
```

**Effectiveness**: 3/5 — Clear scenario and input, but output tends to be lengthy and unfocused without structural constraints.

**Iteration**:

```
Organize meeting notes including: 1. Discussion points (no more than 3) 2. Decisions made 3. Action items (owner + deadline). Bold the decisions and action items.
```

**Effect change**: 5/5 — With field constraints added, output format is stable and ready to share with attendees.

This prompt looks simple, but when used daily, each use saves a small amount of time. High-frequency prompts are worth polishing.

## Summary

Three examples demonstrate the core value of a Prompt library:

1. Iteration records show your evolution path — no need to start from zero each time
2. Frameworks like RBGO help you think systematically and avoid missing elements
3. Even simple high-frequency Prompts are worth adding — their reuse value compounds

Your Prompt library is built. Tomorrow's graduation assessment is where you put your four weeks of learning to the test.

---

📖 **Series Navigation**

- Previous: [Today's Practice: Organize Your First 5 Prompts](/en/posts/2026/05/ai-practice-build-prompt-library/)
- Next: [AI Path L0→L1 Upgrade Guide (Part 5): Graduation Assessment & Next Steps](/en/posts/2026/05/ai-path-l0-l1-graduation/)
