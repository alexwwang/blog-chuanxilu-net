---
title: "Day 10: Your AI Feels Like an Intern? Try the GCO Framework"
slug: "ai-path-l1-l2-week3-day10"
date: 2026-07-21T07:00:00+08:00
draft: false
description: 'Here are three exercises that show how vague versus clear task descriptions change AI output, along with the GCO framework that resolves the problem.'
tags: ["AI", "tutorial", "prompt-engineering", "task-description"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor illustration: fuzzy clouds condensing into a sharp beam of light, illuminating three cubes labeled G, C, O"
---

> This is Day 10 of the AI Path L1→L2 Upgrade Guide. You should complete [Day 8](../ai-path-l1-l2-week2-day8/) and [Day 9](../ai-path-l1-l2-week2-day9/) first.

I learned this the hard way. "I thought I was being clear" is a lie I've told myself too many times while writing AI prompts.

I once asked an AI to organize project documents:

> "Help me sort these files."

What I got back: all `.md` and `.py` files mixed together, sorted alphabetically by filename. It *did* sort them, just not the way I meant.

Another time I said: "Show me the directory structure." I wanted a tree view. The AI gave me `ls -lh` output: file sizes, timestamps, permissions, everything I didn't ask for.

The root cause wasn't model capability. It was prompt specification.

Refining your task description can mean the difference between three back-and-forth prompt iterations and getting it right on the first turn. Here are three exercises from everyday scenarios. Each starts with a vague version, breaks down what's missing, and builds up to a clear version.

If you read these and think "wait, I write prompts like the vague version too," that is exactly why this article exists.

<!--more-->

## Exercise 1: "Organize My Files"

Most people start with a vague request: "Clean up my Downloads folder."

This prompt has three critical flaws.

First, "clean up" is too broad. Sort by type? Archive by date? Delete duplicates? Rename for consistency? The AI guesses one interpretation. If it guesses wrong, you redo everything.

Second, it lacks explicit classification rules. By file type or by project topic? What naming convention? Whatever the AI defaults to probably doesn't match your workflow.

Third, it defines no expected deliverable or output format. What counts as done? Do you need a migration manifest to verify the changes before moving any files?

The fix is straightforward: state the goal, set constraints, define the output.

**Clear version (macOS path; Windows users replace `~/Downloads` with `C:\Users\yourname\Downloads`):**

> The Downloads folder needs organizing. Please:
>
> Goal: Sort files by extension into subfolders.
>
> Constraints: Move only, no deletions or modifications. Images → `images/`, documents → `documents/`, archives → `archives/`, everything else → `misc/`. Create folders if missing. Ignore hidden files.
>
> Output: Print a migration manifest showing each file's origin and destination.

With these explicit guidelines, the AI gets the file structure right on the first try nine times out of ten. Even if a file is miscategorized (for example, if `SVG` files end up in `documents/` instead of `images/`), you only need to adjust that specific file-type mapping rule rather than restructuring the entire prompt.

A vague description costs far more than a few wasted minutes because it forces you to re-engineer the entire task from scratch.

## Exercise 2: "Analyze This Data"

A typical vague request starts with a simple prompt: "Analyze this sales data."

"Analyze" is a black hole. Trend analysis, anomaly detection, year-over-year (YoY) comparisons, summary statistics and distribution overviews are all distinct analytical tasks. Without specifying which, the AI picks one at random. You might care about growth rate gaps between product lines; the AI charts a heatmap of the entire dataset.

Then there's the data source problem: where's the file? What format are the columns? Without these details, the AI must either ask for clarification or, worse, guess a file path and fail.

**Clear version:**

> I have 2024 sales data in `data/sales_2024.csv` (CSV). Fields: `product_line`, `quarter`, `revenue`, `growth_rate`.
>
> Goal: Identify sales trends and anomalies per product line.
>
> Constraints: 2024 data only. Quarterly aggregation. Each product line analyzed independently. Flag growth rates below 10% as "needs attention."
>
> Output: A table (`product_line` | `annual_total` | `quarterly_detail` | `growth_rate` | `needs_attention_flag`), a line chart by quarter, and three findings (one sentence each).

I tested both versions on the same dataset. The vague prompt generated a heatmap covering an unrequested timeframe alongside a generic summary, whereas the clear prompt returned exactly what I specified: table, chart, and findings, ready for a report.

## Exercise 3: "Write a Monitoring Script"

Automation tasks often suffer from the same issue, starting with a prompt like: "Write a script to monitor disk space."

This prompt leaves out three critical pieces of information: the alert threshold, the notification channel, and the target execution environment along with its scheduler.

The AI might write a Python script that requires `psutil` on a minimal Ubuntu 22.04 image, or generate an email alert when no SMTP server exists.

**Clear version (platform-agnostic):**

> Goal: Check disk usage daily and alert when above 85%.
>
> Constraints: System commands only, no third-party tools. Log alerts to the system log; no external notification channel.
>
> Output: A runnable script plus a scheduler config example.

This version drops platform assumptions. The AI can use Bash, PowerShell, or any language. For more precision, here are platform-specific versions you can use without edits:

**Linux (Bash), copy-paste ready:**
> Goal: Check `/dev/sda` daily, alert above 85%.
> Constraints: Ubuntu 22.04. Alert via `logger`. Schedule via `crontab`. No third-party dependencies.
> Output: `monitor_disk.sh` + `crontab` config.

**macOS (Bash), copy-paste ready:**
> Goal: Check Macintosh HD daily, alert above 85%.
> Constraints: Check `/dev/disk1s1`. Alert via `logger`. Schedule via `launchd`.
> Output: `monitor_disk.sh` + `plist` config.

**Windows (PowerShell), copy-paste ready:**
> Goal: Check `C:` drive daily, alert above 85%.
> Constraints: Use `Get-PSDrive C` for usage. Write alerts to Event Log. Schedule via Task Scheduler.
> Output: `Monitor-Disk.ps1` + Task Scheduler import config.

Each constraint prevents a specific failure mode caused by the AI's implicit assumptions. Omitting these technical boundaries frequently causes scripts to fail on their very first run.

## The Pattern: GCO

All three clear versions share the same structure. I call it **GCO**:

![GCO three elements: Goal → Constraints → Output](illustration-gco.png)

**G (Goal):** What to do, and only that. One sentence defining the finish line.

**C (Constraints):** What not to do. Establish strict guardrails to prevent unapproved tools, unintended side effects or destructive file operations.

**O (Output):** What counts as done. Define the deliverable so validation is objective.

These three elements are sequential. Goal sets direction. Constraints narrow the path. Output defines the finish line. Without a Goal, Constraints and Output have no anchor. Without Constraints, the AI may achieve the goal while violating system safety, such as permanently removing critical files or introducing unapproved third-party dependencies. Without a defined output format, you lack an objective baseline for structural validation and must manually parse unstructured responses.

## Try It Yourself

Open your autonomous AI tool and pick a real task for today. Try it with a vague prompt first, then reset the session, apply the GCO framework and run it again. The gap between the two results will be larger than you expect.

Here's a GCO template you can copy:

```
Goal: I need you to [one specific thing]
Constraints: [environment/tools/boundaries/limits]
Output: Give me [format: table/code/list/summary]
```

---

This is Day 10 of the AI Path L1→L2 Upgrade Guide series. Day 8 introduced the three elements conceptually, while today focuses on building the habit. Day 11 covers how to verify AI output quality. Writing a clear prompt is only half the equation; knowing how to verify the output completes it.

What type of task do you delegate to AI most often? I'm planning follow-up articles with scenario-specific templates.
