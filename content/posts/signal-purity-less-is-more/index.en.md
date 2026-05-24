---
title: "Strategy Genes: Pruning Review Prompts with Genetic Algorithm Thinking"
slug: "signal-purity-less-is-more"
date: 2026-05-24T08:00:00+08:00
draft: false
description: "A review prompt went from 317 lines to 135 lines, and review quality improved by 29%. What I removed was not useful procedure, but redundant content the model could infer on its own. What stayed were strategy genes: irreplaceable constraints, negative examples, and tone locks."
tags: ["AI", "Prompt Engineering", "Strategy Genes", "Genetic Algorithms", "Agent"]
categories: ["AI Practice", "Classic Theory Meets Agent Practice"]
series: ["Classic Theory Meets Agent Practice"]
toc: true
cover:
  image: "cover.png"
  alt: "A bloated prompt pruned into compact strategy genes, with redundant fragments removed and core constraints preserved"
---

> Series: Classic Theory Meets Agent Practice (Part 2)
> [Previous: Dual-Pass Review: Why Recall and Precision Cannot Both Win](/en/posts/dual-pass-review-recall-precision-tradeoff/)

> **TL;DR:** A review prompt went from 317 lines to 135 lines (-58%), and review quality improved by 29%. What I removed was not useful procedure, but redundant content the model could infer on its own. What stayed were strategy genes: irreplaceable constraints, negative examples, and tone locks.

The previous post covered dual-pass review: splitting one review agent into a "find everything" pass and a "filter hard" pass. Valid find rate went from 75% to 92%. But it left one problem open: what the "find everything" pass chooses to report or ignore is still affected by prompt wording.

This post is not about review architecture. It is about the prompt itself: what should go into a prompt, and what should not.

I used to think a more detailed prompt was safer. Spell out every step. Give a full example for every output format. Then the model would make fewer mistakes.

I was wrong.

A lot of prompt content is redundant because the model can infer it on its own. Keeping it in the prompt dilutes attention. What needs to be written down is the part the model cannot infer by itself.

After removing inferable redundancy, review quality improved by 29%. That changed how I think about prompt writing. The question is not "how much should I write?" The question is "what must be written?"

## Theoretical bridge

**First, the caveat: this is an interpretive lens, not an academic proof.**

![Holland building blocks, Wang strategy genes, and EvoMap Gene format converging into the basic unit of a prompt](theory-bridge.png)

Wang et al. proposed the concept of "strategy genes" in a 2026 arXiv paper: procedural skills can be compressed into smaller, more stable, reusable strategy units for experience accumulation and strategy optimization during test-time evolution.[1]

When I read the paper, it reminded me of Holland's "building blocks" from half a century ago. In genetic algorithms, better solutions are assembled by recombining short, composable, repeatedly useful fragments.[2] The structural echo is what mattered: Wang's "strategy genes" and Holland's "building blocks" both ask the same question — **what is the irreducible unit?**

This article uses Holland's building blocks as an interpretive lens for understanding how Wang et al.'s strategy genes map onto my prompt experiment. Two pieces of work separated by half a century share a structural shape. That gives a useful way to think about what a prompt should keep and what it should cut.

## Results first

The review system has one core review file. All review behavior is driven by it.

I refined it once: 317 lines down to 135 lines, -58%.

Quality did not drop. It improved. I compared three prompt versions on the same real code review task. Two groups scored them independently. The second group did not know which version was which:

| Version | Lines | Score | vs. Control |
|---------|-------|-------|-------------|
| Constraints + negative examples (refined, final) | 135 | 7.70 | +29% |
| Constraints only (intermediate, rejected) | 215 | 6.05 | +2% |
| Master v0.8.0 (control) | 317 | 5.95 | — |

![A bloated review prompt pruned into a shorter clearer version while quality rises](prompt-pruning-result.png)

Important caveat: this is a limited observation on one specific review task, not a broad statistical claim about all prompt engineering.

The refinement was not one step. It took two.

Step 1: split one large file into 6 smaller files and load them on demand. 550 lines → 317 lines (-42%). This was pure extraction. No information was lost. The content stayed the same; only the organization changed.

Step 2: remove inferable content. Step descriptions ("read the file, then evaluate, then output"), output format templates (full JSON examples), and positive examples were removed. What stayed was non-inferable content: tables, negative examples, warnings, and tone locks. 317 lines → 135 lines (-58%).

Together: 550 lines → 135 lines, -75%. Review quality +29%. Token usage also dropped by 58%. The refined content is now split into 6 files and loaded on demand.

## Strategy genes: the basic unit inside a prompt

In *Adaptation in Natural and Artificial Systems*, Holland introduced the idea of "building blocks": complex solutions are not built from scratch. They are assembled by recombining short, composable, repeatedly useful fragments. These fragments are the basic units of the solution. Remove them, and the solution is no longer the same solution.

Wang et al. proposed strategy genes: compact, structured, reusable units distilled from procedural skills — the parts that actually control behavior. The point is not documentary completeness, but signal density, applicability boundaries, and failure awareness.

EvoMap's Gene format engineers this idea further: a Gene is a reusable strategy template with trigger signals, constraints, and validation.[3] It is not a full manual. It is an action template that can be reused and recombined.

The concepts are separated by half a century, but the structure rhymes. They all ask: "what is the irreducible basic unit?"

Applied to prompts, this gives one practical way to judge the basic unit of a prompt:

**A prompt strategy gene is control information the model cannot infer from context, but which changes output quality.** Examples: constraint rules, negative examples, tone locks.

The opposite is redundant content: content the model can already infer from the task and context. For example, "read the file, then evaluate, then output" is basic model behavior. It does not need to be taught. A full JSON template is similar. The model has seen enough JSON; field names are usually enough.

Remove redundant content = keep strategy genes = focus the model's attention on what actually needs guidance.

This is not a strict theorem. It is a working framework for deciding what to write and what to cut. Holland's building blocks, Wang et al.'s strategy genes, and EvoMap's Gene format give one way to think about the basic units inside a prompt.

### Teachers, students, and procedural instructions

![A teacher gives only key conditions and common mistake warnings while the student derives the steps](teacher-student-prompt.png)

A teacher does not need to write every step when teaching a student to solve a problem. "Given A and B, prove C. Watch out for this common mistake." That is enough. The student derives the steps.

Write too much, and the student starts copying mechanically instead of thinking.

Review prompts have the same failure mode. "Read the diff, analyze each file, assign severity, then output JSON." These instructions teach the model to do what it already knows how to do. They are not strategy genes. They are redundant content. The model does not "understand" better when it reads them. It just follows the rails. Attention goes to inferable procedure, while the real strategy genes get diluted.

### Why negative examples are strategy genes

One key finding from the experiment: removing positive examples did not hurt quality. Removing negative examples did.

Why?

![Negative examples act like boundary lines that block wrong directions without prescribing the full path](negative-examples-boundary.png)

A positive example tells the model: "this is what good output looks like." The model tends to imitate it. Imitation narrows reasoning. The model stops asking "what is right?" and starts asking "how do I match this example?" Positive examples were not strategy genes.

A negative example tells the model: "this path leads to failure." It defines a boundary, not a path. Once the model knows the boundary, it can find its own route. Negative examples are strategy genes because they define an irreplaceable constraint: do not go this way.

Positive examples only show one possible correct shape. But there are many correct shapes. Negative examples show where correctness breaks. They supply the boundary. The path is for the model to infer.

### Tone locks and AVOID warnings

Two more concrete examples of strategy genes.

Tone lock. A review rule might say:

> You must include a severity level in the review output

"Must" is much stronger than "should." The model cannot infer that strength by itself. It does not know which step is mandatory and which one is optional. A tone lock tells the model: this rule is not negotiable.

Another class is warnings. For example:

> Avoid revealing round counts in review output

The model does not know this constraint. It cannot infer by itself that review prompts should not leak meta-information. This is implicit knowledge that must be written explicitly.

Tone locks and warnings are both strategy genes. They are constraints the model cannot infer on its own. Remove them, and the model's behavior degrades immediately.

## How I got here

After finishing the dual-pass review work in the previous post, the prompt got longer. At the time I thought: more information should be safer. More detail should mean fewer mistakes.

The data showed a tension: more review dimensions should find more issues, but a longer prompt may dilute attention. Which force wins?

I revisited the core review file. It had 317 lines. Reading through it, I found a lot of descriptive content.

Step instructions: "read the file, evaluate, then output." Does the model need this? No. Reading, evaluating, and outputting are basic model abilities.

Output format template: a full JSON structure example. Does the model need this? No. A few field names are enough.

Positive example: "a good review output looks like this." Does the model need this? No. The model has seen enough good examples.

All of these are inferable. They are redundant content, not strategy genes.

### First experiment: keep only strategy genes

I made the first experimental version: keep only constraints, remove all descriptions, format templates, positive examples, and negative examples. 215 lines.

Score: 6.05. Slightly better than the control group (5.95), +2%. I did not ship it.

What went wrong? I cut too much. Constraints are strategy genes, but they are not the only strategy genes. Negative examples are strategy genes too. This version removed them, so the model lost boundary information. That boundary information was irreplaceable.

### Second experiment: constraints + negative examples

I made the second experimental version: keep constraints, add negative examples back. But this was not just adding content to the 215-line version. I also rewrote the constraints themselves — merging redundant rules and shortening wording. Final result: 135 lines.

So 135 lines did not become shorter "because adding negative examples magically made it shorter." It was the result of two changes at once: negative examples came back, and constraint wording was compressed hard.

Score: 7.70. +29% over the control group. Much better than constraints-only (+27%).

The key finding: positive examples were redundant content; negative examples were strategy genes.

Positive examples make the model imitate, which limits reasoning. Removing them gave the model more room to think about what is right. Negative examples tell the model where the boundary is without constraining the path. Remove them, and the model does not know where the trap is — so it falls in. Negative examples define an irreplaceable boundary constraint.

### Method takeaway

This is not "less is more" as a slogan.

"Less is more" is not operational. Less what? Less to what degree?

The operational version is: **remove inferable redundant content; keep irreplaceable strategy genes.**

How do you tell whether a piece of content is a strategy gene or redundant content? Remove it and observe the output. Remove a strategy gene, and output gets worse. Remove redundant content, and output stays the same or improves.

This is an ablation test. The definition of a strategy gene is not the content itself, but its effect on output. Remove it, and the solution is no longer the same solution.

## One more dimension problem

Strategy genes answer the question: "what should go into the prompt?" Removing redundant content and keeping only strategy genes improved review quality by 29%.

But one question remains: are the review dimensions complete enough?

What the "find everything" pass chooses to report or ignore is influenced not only by prompt wording, but also by dimension coverage. If the review dimensions only cover correctness and style, then security issues, performance issues, and maintainability issues get systematically missed. Strategy genes do not solve that. Even if the signal is clean, if the dimension is missing, the model may still not know where to look.

The next post tests how dimension coverage affects find rate.

## References

1. Wang, Y., et al. (2026). "From Procedural Skills to Strategy Genes: Towards Experience-Driven Test-Time Evolution." arXiv:2604.15097. [https://arxiv.org/abs/2604.15097](https://arxiv.org/abs/2604.15097)
2. Holland, J. H. (1975). *Adaptation in Natural and Artificial Systems*. University of Michigan Press. [https://mitpress.mit.edu/9780262581116/adaptation-in-natural-and-artificial-systems/](https://mitpress.mit.edu/9780262581116/adaptation-in-natural-and-artificial-systems/)
3. EvoMap. "GEP Protocol." [https://evomap.ai/wiki/16-gep-protocol](https://evomap.ai/wiki/16-gep-protocol)
