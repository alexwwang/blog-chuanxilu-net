---
title: "AI Path L0→L1 Upgrade Guide (2): From Vague Questions to Precise Instructions"
slug: "ai-path-l0-l1-week2"
date: 2026-05-16T06:00:00+08:00
draft: false
description: "Part 2 of the AI Path L0→L1 Upgrade Guide. Master the RBGO prompt framework (Role–Background–Goal–Output), learn Chain-of-Thought reasoning to improve analytical answers, and use format constraints to make AI output ready to use."
tags: ["AI", "toolchain", "evolution-path", "tutorial"]
categories: ["AI Practice"]
toc: true
series: ["AI Path L0→L1 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor still life: rough unpolished stone beside a faceted gemstone, symbolizing the refinement from vague to precise prompts"
---

> 📖 This is Part 2 of 5 in the "AI Path L0→L1 Upgrade Guide" series.
>
> [Part 1: Understanding Your Tools](/en/posts/2026/05/ai-path-l0-l1-week1/) · Part 2: From Vague Questions to Precise Instructions · Part 3: Turning AI Into Your Collaboration Partner (coming soon) · Part 4: Building Your Personal System (coming soon) · Part 5: Graduation & Next Steps (coming soon)

 In the last part we covered how LLMs actually work, how their memory operates, and the key differences between major platforms. Starting this week, we move into practice — how to turn what you want to say into instructions that AI can understand precisely.

**📋 Week 1 Recap:**

- [Part 1: Understanding Your Tools](/en/posts/2026/05/ai-path-l0-l1-week1/) — LLMs aren't search engines; they "think it through" every time
- [Practice: Ask AI the Same Question 3 Times](/en/posts/2026/05/ai-practice-same-question-3-times/) — Experience probabilistic generation firsthand
- [3 Cognitive Shifts: Stop Using AI Like a Search Engine](/en/posts/2026/05/ai-3-cognitive-shifts/) — From searching to conversing, from trusting to verifying, from answers to thinking
- [Your AI Has a Desk and a Filing Cabinet](/en/posts/2026/05/ai-tip-working-vs-long-term-memory/) — Working memory vs. long-term memory
- [Pick Your AI by the Job, Not the Ranking](/en/posts/2026/05/ai-tip-which-ai-to-use/) — Scenario-based matching across 7 platforms

![From vague questions to precise instructions — the RBGO framework helps AI understand you](l0-l1-2m.png)

---

## Week 2: Prompt Fundamentals — From Vague to Precise

### Day 8–9: The Art of Asking

**Why it matters:** The prompt is your only interface for communicating with AI. Given the same capabilities, vague instructions produce garbage; precise instructions produce gold. This isn't about whether the AI is powerful enough — it's about whether you've *said what you mean*.

**How to think about it:** There's really only one core principle — **the more specific your input, the more useful the output.**

Consider this contrast:

Vague: "Help me write a proposal."

Precise: "I'm a product manager who needs a pricing strategy proposal for a B2B SaaS product. The target customers are SMBs with 50–200 employees and limited budgets. Please provide three pricing models and analyze the pros and cons of each."

Same underlying request — "write a proposal" — yet the second version delivers an answer that's orders of magnitude more useful. What makes the difference? The second version provides four critical elements. I call this the **RBGO framework**:

- **R**ole — What role you want the AI to play: "product manager," "senior technical advisor," "strict editor"
- **B**ackground — Your specific situation: target customers, budget, time constraints
- **G**oal — What you actually want: a pricing strategy, a code review report, an email draft
- **O**utput — What the result should look like: three models, table format, under 500 words

Before every prompt, run through these four elements quickly: Did I specify who I am, what my situation is, what I need, and what format I want the answer in?

**Practice**: Pick three questions you've recently asked (or would ask) an AI in your daily work, and rewrite them using the RBGO framework. For instance, "how do I improve my conversion rate" becomes: "You are an e-commerce operations expert (Role). My independent storefront gets 5,000 monthly visitors with a 1.2% conversion rate, and I mainly sell home goods (Background). Please give me five specific strategies to improve conversion (Goal), formatted as a numbered list where each item includes the strategy name, concrete steps, and expected impact (Output)."

Compare the quality of the answers before and after rewriting. The difference is immediately obvious.

### Day 10–11: Making AI "Think Step by Step"

**Why it matters:** There's a simple yet powerful technique that can dramatically improve the quality of AI's analytical responses. It's called **Chain-of-Thought (CoT)**. The core idea: ask the AI to show its reasoning process *before* giving a conclusion, rather than jumping straight to the answer.

**How to think about it:** Have you noticed that when you ask AI for a direct answer, it sometimes "skips steps" — the conclusion might be right but lacks supporting reasoning, or worse, it jumps to a wrong conclusion because an intermediate step was wrong? CoT addresses exactly this problem.

The technique itself is incredibly simple: add a sentence to the end of your prompt like "Please reason through this step by step" or "Analyze first, then give your conclusion."

**When to use it**: Analytical questions ("What are the risks of this business model?"), logical reasoning ("If A is true, does B necessarily follow?"), multi-step tasks ("Help me develop a go-to-market strategy").

**When not to use it**: Simple factual queries ("What's the capital of France?"), format conversions ("Translate this text into English"), straightforward single-step tasks. Adding CoT in these scenarios just wastes time and tokens.

**Practice**: Pick a question that requires analysis — say, "Should I buy a house or keep renting?" Ask it two ways: first, simply "Should I buy a house or keep renting?"; second, with CoT: "Please analyze this step by step — list the pros and cons of buying vs. renting, considering factors like finances, quality of life, and flexibility, then give your recommendation."

Compare the two responses carefully. You'll find the second one has a more complete argument structure, broader coverage of relevant factors, and — crucially — you can trace its reasoning chain and check whether each step holds up. That's far more valuable than a bare conclusion.

### Day 12–14: Format Constraints — Making Output Ready to Use

**Why it matters:** The format of AI's output directly determines whether you need to do additional processing. A cleanly structured Markdown table can be copied straight into a document; an unformatted blob of text might cost you ten minutes of reformatting. Spending 10 seconds specifying format in your prompt can save a lot of cleanup time later.

**How to think about it:** You can (and should) explicitly specify the output format when you ask a question. Common format constraints include:

- **Markdown tables**: "Please list this as a Markdown table with the following columns..."
- **JSON structured data**: "Please output in JSON format with the following fields..."
- **Numbered lists**: "Please use a numbered list, with each item under 50 words"
- **Sectioned structure**: "Please follow this structure: start with a conclusion (under 100 words), then three supporting arguments (200 words each), and finish with action items (3 items)"

An advanced move is to specify the **output structure**, not just the format. For example: "Start with the conclusion, then give three supporting arguments, then end with action items" — this constrains not only the presentation format but also the logical organization of the content.

**Practice**: Pick an information-dense topic (e.g., "10 AI trends worth watching in 2026") and have AI produce it in three different formats: plain prose paragraphs, a Markdown table, and a numbered list with a one-sentence summary per item. Notice how each format feels in actual use — which is better for quick scanning? Which fits better in a report? Which works best for archiving?

Build a habit: before every prompt, think "what format do I want the result in?" and write that into the prompt. It takes five seconds, but the long-term payoff is enormous.

---

*That wraps up Week 2. Next time we move into conversation management — how to use follow-up questions, context control, and role-playing to turn AI into a true collaboration partner. (Part 3 coming soon)*
