---
title: "Your AI Feels Like an Intern? Try the GCO Framework"
slug: "ai-path-l1-l2-week3-day10"
date: 2026-07-21T07:00:00+08:00
draft: false
description: "Three exercises that show how fuzzy vs clear task descriptions change AI output — and the GCO framework that fixes it."
tags: ["AI", "tutorial", "prompt-engineering", "task-description"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor illustration: fuzzy clouds condensing into a sharp beam of light, illuminating three cubes labeled G, C, O"
---

> This is Day 10 of the AI Path L1→L2 Upgrade Guide. You should complete [Day 8](../ai-path-l1-l2-week2-day8/) and [Day 9](../ai-path-l1-l2-week2-day9/) first.

I learned this the hard way. "I thought I was clear" is a lie I have told myself more often than I care to admit when prompting AI.

I once asked an AI to organize project documents:

> "Help me sort these files."

What I got back: all `.md` and `.py` files mixed together, sorted alphabetically by filename. It *did* sort them. Just not the way I meant.

Another time I said: "Show me the directory structure." I wanted a tree view. The AI gave me `ls -lh` output: file sizes, timestamps, permissions. Everything I didn't ask for.

Same request, two completely different results. The gap wasn't in the tool. It was in how I described what I wanted.

A fuzzy description and a clear one can mean the difference between three iterations and zero. Here are three exercises from everyday scenarios. Each starts with a vague version, breaks down what's missing, and builds up to a clear version.

If you read these and think "wait, I write prompts like the vague version too," that is exactly why this article exists.

<!--more-->

## Exercise 1: "Organize My Files"

The vague version most people write:

> Clean up my Downloads folder.

This sentence has three holes.

First, "clean up" is too broad. Sort by type? Archive by date? Delete duplicates? Rename for consistency? The AI guesses one interpretation. If it guesses wrong, you redo everything.

Second, no classification rule. By file type or by project topic? What naming convention? Whatever the AI defaults to probably doesn't match your workflow.

Third, no deliverable. What counts as done? Do you want a manifest to review?

The fix is straightforward: state the goal, set constraints, define the output.

**Clear version (macOS path; Windows users replace `~/Downloads` with `C:\Users\yourname\Downloads`):**

> The Downloads folder needs organizing. Please:
>
> Goal: Sort files by extension into subfolders.
>
> Constraints: Move only, no deletions or modifications. Images → images/, documents → documents/, archives → archives/, everything else → misc/. Create folders if missing. Ignore hidden files.
>
> Output: Print a migration manifest showing each file's origin and destination.

With this version, the AI gets it right on the first try nine times out of ten. Even if something is off, say SVGs end up in documents/ instead of images/, you correct one category, not the whole task.

A fuzzy description costs more than a few extra edits. The AI may end up doing something completely different from what you had in mind.

## Exercise 2: "Analyze This Data"

**Vague version:**

> Analyze this sales data.

"Analyze" is a black hole. Trend analysis, anomaly detection, YoY comparison, summary stats, distribution overview: they are all "analysis." Without specifying which, the AI picks one at random. You might care about growth rate gaps between product lines; the AI charts a heatmap of the entire dataset.

Then there's the data source problem: where's the file? What format are the columns? Without this, the AI needs a round of clarifying questions, or worse, guesses a path and errors out.

**Clear version:**

> I have 2024 sales data in `data/sales_2024.csv` (CSV). Fields: product_line, quarter, revenue, growth_rate.
>
> Goal: Identify sales trends and anomalies per product line.
>
> Constraints: 2024 data only. Quarterly aggregation. Each product line analyzed independently. Flag growth rates below 10% as "needs attention."
>
> Output: A table (product_line | annual_total | quarterly_detail | growth_rate), a line chart by quarter, and three findings (one sentence each).

I tested both versions on the same dataset. The vague one returned a heatmap of a year I did not ask for plus a generic summary. The clear one returned exactly what I specified: table, chart, and findings, ready to put in a report.

## Exercise 3: "Write a Monitoring Script"

**Vague version:**

> Write a script to monitor disk space.

Three missing pieces: What threshold triggers the alert? What's the notification channel? What environment and scheduler?

The AI might write a Python script that depends on `psutil`. But your server runs Ubuntu 22.04 with a minimal base image and no extra packages. Or it writes an email alert, but you don't have SMTP configured.

**Clear version (platform-agnostic):**

> Goal: Check disk usage daily and alert when above 85%.
>
> Constraints: System commands only, no third-party tools. Log alerts to syslog; no external notification channel.
>
> Output: A runnable script plus a scheduler config example.

This version drops platform assumptions. The AI can use Bash, PowerShell, or any language. For more precision, here are platform-specific versions you can use without edits:

**Linux (Bash), copy-paste ready:**
> Goal: Check /dev/sda daily, alert above 85%.
> Constraints: Ubuntu 22.04. Alert via logger. Schedule via crontab. No third-party dependencies.
> Output: monitor_disk.sh + crontab config.

**macOS (Bash), copy-paste ready:**
> Goal: Check Macintosh HD daily, alert above 85%.
> Constraints: Check /dev/disk1s1. Alert via logger. Schedule via launchd.
> Output: monitor_disk.sh + plist config.

**Windows (PowerShell), copy-paste ready:**
> Goal: Check C: drive daily, alert above 85%.
> Constraints: Use Get-PSDrive C for usage. Write alerts to Event Log. Schedule via Task Scheduler.
> Output: Monitor-Disk.ps1 + Task Scheduler import config.

Every constraint eliminates a risk of assuming the AI would guess correctly. The vague version outputs a Python script that emails you. Except you don't have SMTP set up. Dead on arrival.

## The Pattern: GCO

All three clear versions share the same structure. I call it **GCO**:

![GCO three elements: Goal → Constraints → Output](illustration-gco.png)

**G (Goal).** What to do, and only that. One sentence defining the finish line.

**C (Constraints).** What not to do. Draw the boundaries, exclude the unwanted options.

**O (Output).** What counts as done. Define the deliverable so validation is objective.

These three elements are sequential. Goal sets direction. Constraints narrow the path. Output defines the finish line. Without Goal, Constraints and Output have no anchor. Without Constraints, the AI can hit the target but cross your boundaries, deleting files you wanted kept or using a library your environment does not have. Without Output, the AI finishes but you have no way to tell whether it is done, and you accept whatever it gives you.

## Try It Yourself

Open your autonomous AI tool and pick a real task for today. Ask with a vague description first, then see what comes back. Then roll back, fill in GCO, and ask again. The gap between the two results will be larger than you expect.

Here's a GCO template you can copy:

```
Goal: I need you to [one specific thing]
Constraints: [environment/tools/boundaries/limits]
Output: Give me [format: table/code/list/summary]
```

---

This is Day 10 of the AI Path L1→L2 Upgrade Guide series. Day 8 introduced the three elements conceptually; today was about building the habit. Day 11 covers how to verify AI output quality. Describing clearly is only half the equation; knowing when it is right is the other half.

What type of task do you delegate to AI most often? I'm planning follow-up articles with scenario-specific templates.
