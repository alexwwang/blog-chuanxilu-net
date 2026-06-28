---
title: "Day 8: Autonomous AI, Automation Without Writing Code"
slug: "ai-path-l1-l2-week2-day8"
date: "2026-06-28T07:00:00+08:00"
draft: false
description: "L1 to L2 Week 2 Day 8: understand autonomous execution AI (Claude Code, OpenCode, Codex), learn to describe tasks and let AI handle the coding, with a hands-on file organization exercise."
tags: ["AI", "toolchain", "tutorial", "autonomous-execution", "automation"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor: person sitting at computer with AI auto-organizing folders, scattered file icons nearby"
---

> This is Day 8 of Week 2 in the "AI Path L1→L2 Upgrade Guide." You should have completed [Day 7](../ai-path-l1-l2-week2-day7/) first.

[Day 7](../ai-path-l1-l2-week2-day7/) you added error handling to your script. It now runs reliably in real network conditions. But there's a more fundamental limitation: **you still have to write code.**

Writing code to call APIs is one kind of automation. There's a lighter one: **describe the task, and let AI write the code, run it, and fix the bugs itself.** That's autonomous execution AI.

---

## What Is Autonomous Execution AI?

In API mode, you're the programmer. You write Python scripts, call OpenAI-compatible endpoints, handle timeouts, rate limits, file I/O. It's powerful, but you need to code.

In autonomous execution AI mode, you're the project manager. You tell AI what you want, and it writes the code, debugs it, and hands you the result. You don't need Python. You just need to understand your own problem.

**A direct comparison:**

| | API Mode | Autonomous Execution AI |
|---|---------|----------------------|
| What you do | Write code | Describe tasks |
| Who writes code | You | AI |
| Programming knowledge needed | Yes | No |
| Best for | Repetitive, predictable tasks | Exploratory, judgment-heavy tasks |
| Control granularity | Precise | Rough direction |

The two modes don't conflict. When AI completes a task autonomously, you can save its generated code and call it via API later. That's the combo approach Part 4 will cover.

---

## Mainstream Tools

Three tools are common in this space right now:

**Claude Code** (Anthropic). Built on Claude, tightly integrated with terminal operations. It's good at understanding complex context, handling large files, and running multi-step tasks. Pro plan: $20/month. Max starts at $100/month, tiered by usage multiplier.

**OpenCode** (OpenCLI). Open-source autonomous execution framework with multi-model switching, a skill system, and parallel agent scheduling. Go plan: $10/month ($5 first month). The framework itself is free and open source; you only pay for the backend model APIs. Best for technical users who want to customize their workflow.

**Codex** (OpenAI). Built into ChatGPT, handles file read/write, code execution, and web browsing to complete complex tasks. Plus plan: $20/month. Pro has two tiers: 5x at $100/month, 20x at $200/month.

They share one core capability: **you describe a task, it writes the code, runs it, debugs, and delivers.** The differences are the model backing, integration depth, and pricing.

---

## Task Description: Making AI Understand You

The core skill of autonomous execution AI is communicating intent. AI can't read minds, so the clearer you are, the better the result.

An effective task description has three elements: **goal, constraints, expected output.**

**Goal** is one sentence saying what you want. Skip the backstory and the justification. State the result.

**Constraints** are boundaries. What shouldn't change, what size limits exist, what formats must be preserved. The more specific you are, the less AI drifts.

**Expected output** is what the deliverable looks like. A file? Code? A report? Tell AI the final shape.

{{< figure src="illustration.png" alt="Three-element triptych: Goal, Constraints, Expected Output" class="img-medium" caption="An effective task description has three elements: state your goal, set clear constraints, and define the expected output so AI executes precisely" >}}

**A bad example:**

> Help me organize my downloads folder.

What does "organize" mean? Delete? Categorize? Rename? By what standard? How big can files be? AI has to guess. If it guesses wrong, you redo it.

**A good example:**

> Organize files in ~/Downloads by type. Put images in images/, videos in videos/, documents in documents/, installers in installers/. Sort within each category by date. Do not delete anything. Output a report showing where each file went.

All three elements show up: goal is categorize files, constraint is no deletion, expected output is an organized folder structure plus a report.

---

## Hands-On: Organize Your Downloads Folder

Pick a scenario you deal with regularly. The downloads folder is the classic case.

### Step 1: Describe the Task

Open your autonomous execution AI tool (Claude Code, OpenCode, or Codex; pick one). Enter a task like this:

```
My ~/Downloads folder is a mess. It has PDFs, images, videos, installers, and archives.

Please organize them:
1. Create four subfolders: images/, documents/, videos/, installers/
2. Move files by extension:
   - Images: .jpg .jpeg .png .gif .svg .webp
   - Documents: .pdf .doc .docx .txt .md
   - Videos: .mp4 .mov .avi .mkv .webm
   - Installers: .dmg .pkg .exe .deb .rpm .zip .tar.gz
3. Files that don't match any category go to misc/
4. Do not delete any files
5. Print a summary showing where each file was moved
```

### Step 2: Watch AI Execute

AI usually won't get it perfect on the first try. It typically does four things:

Lists the current files to confirm what it sees, creates the folder structure, moves files one by one (categorized by extension), and prints the summary report.

If AI hits a problem, like a file extension not in your preset list, it stops and asks you. The more specific your reply, the faster it adjusts.

### Step 3: Verify the Result

After organizing, check:

- [ ] Did files actually move to the correct folders?
- [ ] Were any files misclassified?
- [ ] Is any file missing?
- [ ] Is the summary report complete?

If something's wrong, tell AI directly:

> 3 .svg files ended up in documents/. Move them to images/.

AI will fix it.

---

## Common Concerns

**"Will AI delete my files?"**

Good autonomous execution tools ask before destructive operations. If it deleted files directly, your task description probably lacked constraints. Build the habit: always add "do not delete any files" to your task description.

**"Which tool should I use?"**

- Technical user, likes customization → OpenCode (free, open source)
- Want plug-and-play, don't care about internals → Claude Code or Codex
- Use both APIs and autonomous AI → Try all three, pick one you like

**"Wouldn't a Python script be faster for organizing files?"**

Yes, if you already have one. But the real question is: **when would you ever spend the time to write that script?** The value of autonomous execution AI is that you don't have to. Describe the task, and AI writes the code, runs it, and fixes the bugs itself. That saves more time than writing the script ever would.

---

## Today's Takeaway

- [ ] Understood the core difference between API mode and autonomous execution AI
- [ ] Learned the "goal-constraints-output" framework for task descriptions
- [ ] Completed a real file organization task
- [ ] Know how to verify and correct AI output

---

Have you tried letting AI organize files or handle daily tasks? Share your experience and the pitfalls you hit.

---

> This is Day 8 of Week 2 in the "AI Path L1→L2 Upgrade Guide." Previous: [Day 7 Error Handling](../ai-path-l1-l2-week2-day7/). [Read original](https://blog.chuanxilu.net/en/ai-path-l1-l2-week2-day8/) for the full task description template.

---

> Writing code with AI takes practice. Task description, result verification, and iterative fixes are real skills. A future series will cover methods for learning and improving them in depth.
