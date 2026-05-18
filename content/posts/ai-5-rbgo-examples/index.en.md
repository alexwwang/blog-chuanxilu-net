---
title: "RBGO Rewrites in 5 Real Scenarios: Vague Prompt vs. Precise Prompt"
slug: "ai-5-rbgo-examples"
date: 2026-05-18T06:00:00+08:00
draft: false
description: "The RBGO framework sounds straightforward, but when you actually sit down to write a prompt, it's easy to get stuck. Here are 5 everyday scenarios—each with a full side-by-side comparison of the vague version and the rewritten version. Emails, analysis, learning, planning, code review. Copy them, use them directly."
tags: ["AI", "toolchain", "evolution-path"]
categories: ["ai-path"]
toc: false
series: ["AI Path L0→L1 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor style: a workbench with five woodworking sketches progressing from rough to refined, symbolizing how the same request gets rewritten from vague to precise"
---

We covered the RBGO (Role-Background-Goal-Output) framework in the previous post. But there's a gap between knowing the framework and actually using it: **how do you translate "I want…" into those four elements?**

Below are 5 common everyday scenarios. Each one starts with the vague version (what most people actually write), followed by the RBGO rewrite, and finally a breakdown of what changed and why.

---

## Scenario 1: Writing a Work Email

**Vague version:**

> Help me write an email to follow up on a project's progress

The AI will give you a generic follow-up email — tone, relationship with the recipient, and urgency level are all left to guesswork.

**RBGO rewrite:**

> You are a project manager (R). I'm running the "User Profile 2.0" project. The design deliverables were due this Wednesday, but the design team said yesterday they need to push to next Monday (B). I need to email the design lead, Li, to politely but clearly confirm the new deadline and understand the reason for the delay (G). Keep the email under 200 words, professional but not overly formal, and end by asking for a confirmation reply (O).

**What changed:**
- **R** helps the AI adopt a project manager's tone — assertive without being aggressive
- **B** provides the specific project name and timeline so the AI doesn't invent details
- **O** constrains length and tone, preventing a thousand-word essay or excessive pleasantries

---

## Scenario 2: Decision Analysis

**Vague version:**

> I'm thinking about changing jobs. Help me analyze it

The AI will give you a pile of generic advice — "consider salary, growth potential, commute" — things you already know.

**RBGO rewrite:**

> You are a career planning consultant (R). I'm currently a frontend developer at a mid-size tech company, earning 350K/year. The team is stable but the tech stack is outdated. I've received an offer from a startup at 450K/year, but I'd need to lead a 3-person team, and the tech stack is one I've been wanting to learn (B). Analyze the pros and cons from two dimensions: short-term gains and long-term growth (G). Present it as a table, listing 3 advantages and 3 risks under each dimension (O).

**What changed:**
- **B** turns the vague "should I change jobs" into two concrete options, so the AI can make a real comparison
- **O** "table + 3 items per dimension" forces a structured output instead of circular rambling
- **G** defines the analysis dimensions explicitly, keeping the AI from drifting into irrelevant advice like "you should talk to your boss first"

---

## Scenario 3: Learning a New Concept

**Vague version:**

> What are microservices

The AI will give you an encyclopedia entry — definition, characteristics, pros and cons. After reading it, you still might not know "should I use this or not?"

**RBGO rewrite:**

> You are a technical mentor for junior-to-mid developers (R). I do full-stack development, have used Express and Next.js, and my projects are within the scale of monolithic architecture (B). Explain what microservice architecture is, focusing on: compared to my current monolithic approach, what problems do microservices solve, and what new problems do they introduce (G). Start with an analogy to build intuition, then give a concrete code scenario comparison, and finally summarize in one paragraph what project scale justifies adopting microservices (O).

**What changed:**
- **R** "mentor for junior-to-mid developers" — the AI controls terminology density and won't jump straight into Kubernetes and service meshes
- **B** stating your current stack and project scale lets the AI anchor the explanation to your actual level
- **O** the three-part structure "analogy → code comparison → one-paragraph conclusion" is far more practical than an encyclopedia entry

---

## Scenario 4: Making a Plan

**Vague version:**

> Help me make a fitness plan

The AI will give you a generic plan — how many days per week, push/pull/legs split. But it knows nothing about your physical condition, schedule, or available equipment.

**RBGO rewrite:**

> You are a personal fitness coach (R). I'm 30 years old, sedentary office worker, 75kg, 172cm tall, with a history of mild knee discomfort (fully recovered). I can spare 3 days a week, 45 minutes per session, working out at home with only dumbbells and a yoga mat (B). Give me a 4-week beginner training plan focused on fat loss and core stability, knee-friendly (G). Format as a table organized by week/day, with sets, reps, and rest time noted for each exercise. Append a one-week nutrition guideline at the end (O).

**What changed:**
- **B** physical condition + time constraints + equipment constraints — three layers of constraints make the plan actually executable
- **G** "fat loss + core stability + knee-friendly" prevents the AI from assigning squat jumps and burpees
- **O** table format + detailed parameters per exercise means the plan is ready to follow immediately

---

## Scenario 5: Review and Optimization

**Vague version:**

> Help me check if there's anything wrong with this code

```
function getUser(id) {
  return fetch('/api/users/' + id)
    .then(res => res.json())
}
```

The AI will say "the code is basically fine, consider adding error handling" — correct, but adds no useful information.

**RBGO rewrite:**

> You are a senior frontend engineer conducting a code review (R). This is an API call function in a Node.js project that's already running in production with roughly 100K users (B). Review the following code for security and robustness. List all potential issues and provide fix suggestions (G). Order by severity from high to low. For each issue, include: problem description, trigger scenario, fix approach, and the corrected code snippet (O).

**What changed:**
- **R** "senior engineer doing a code review" — the AI applies engineering-grade standards, not tutorial-level feedback
- **B** "production project + 100K users" — security issues jump in priority; the AI won't just say "consider adding try-catch"
- **O** ordered by severity + four elements per issue gives the review structure and makes it trackable

---

## Summary

Common patterns across all 5 scenario rewrites:

1. **R (Role) sets the AI's perspective level** — mentor, consultant, reviewer: different roles produce advice at completely different levels of depth
2. **B (Background) eliminates the AI's guesswork** — the more specific your situation, the more tailored the response
3. **G (Goal) draws the boundary** — "analyze pros and cons" is far more precise than "help me analyze"
4. **O (Output) controls the shape of the result** — tables, numbered lists, word limits: these make the output immediately usable instead of needing a second round of cleanup

Next time we'll talk about Chain-of-Thought — when you should ask the AI to "think step by step," and when doing so is actually unnecessary.
