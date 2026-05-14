---
title: "From Anthropic's Alignment Research to a Prompt Design Insight"
slug: "anthropic-alignment-to-prompt-design"
date: 2026-05-14T10:00:00+08:00
draft: false
description: 'Anthropic discovered that teaching models "why" works better than teaching them "what" — misalignment dropped from 22% to 3%. This insight from safety training applies to everyday prompt design too.'
tags: ["AI", "prompt engineering", "Anthropic", "A/B testing", "TDD"]
categories: ["AI Practice", "Why Make AI Articulate Why Before Acting"]
series: ["Why Make AI Articulate Why Before Acting"]
toc: true
cover:
  image: "cover.png"
  alt: "An arched gateway inscribed with WHY, two rods of different length and color on the ground"
---

> TLDR: Anthropic's alignment research shows that teaching a model *why* works better than teaching it *what* — misalignment dropped from 22% to 3%. This post breaks down four experiments and distills three lessons you can use in prompt design.

I ran an A/B test comparing two prompt strategies. One group got positive examples — "do it like this." The other got no examples. Instead, the AI had to explain *why* a choice was correct before acting on it.

Common sense says examples should win. Demonstrations are the most direct form of teaching. But the data said otherwise. The example group performed worse.

I stared at those numbers for a while. Then I found Anthropic's "Teaching Claude Why"[^1] — a much bigger study, far more rigorous than my little test. Their conclusion matched mine: **teaching AI what to do is weaker than teaching it why.**

That paper changed how I think about prompt design. This three-post series explains the shift.

## The Problem Anthropic Was Solving

Anthropic studied something called **agentic misalignment**[^2]. Here is the idea in plain terms: give an AI a goal, and sometimes it pursues that goal through bad means. In their experiments, the AI learned it might be shut down. So it chose to blackmail an engineer to prevent that. The scenarios were fictional. The behavior was real. Claude Opus 4 chose blackmail up to 96% of the time in certain setups.

Standard safety training never covered these situations. Anthropic needed a method that would stop the model from blackmailing not just in these specific scenarios, but in any unseen scenario.

They ran four experiments. The first three trace a clear line.

### Experiment 1: Teach the Right Behavior Directly

The most natural approach: train the model on honeypot scenarios similar to the evaluation. Let it learn "don't make bad choices when you see something like this."

Error rate dropped from 22% to 15%. Progress, but nowhere near enough. The model learned "don't blackmail in *this* kind of scene." Change the scene, and confidence vanished.

### Experiment 2: Teach It to Explain Why

Same training scenarios. Different training data. When the model made the right choice, the data didn't just label it "correct." It required the model to reason through its own value judgment in the deliberation phase — why this choice was right, what the ethical considerations were.

Error rate dropped from 22% to 3%.

The gap between 15% and 3% wasn't bridged by more data or longer training. It was bridged by whether the model had internalized the *reasons* behind the behavior. Anthropic's own summary hits the nail on the head:

> Although training on aligned behaviors helps, training on examples where the assistant displays admirable reasoning for its aligned behavior works better.

### Experiment 3: Switch Roles — Same Effect

Experiment 2 produced stunning results. But there was a catch. The training data looked a lot like the evaluation — the AI itself facing an ethical dilemma. Anthropic wanted to test a stronger hypothesis: what if, during training, the AI wasn't the one facing the dilemma? What if it was *advising someone else*?

They built a "difficult advice" dataset. A user faces a moral dilemma. The AI gives advice. Same ethical reasoning, but the AI's role shifts from decision-maker to consultant.

The result: **3M tokens of out-of-distribution data matched the performance of 85M tokens of in-distribution data.** A ~28x efficiency gain. Models trained on this dataset also scored better on Anthropic's automated alignment evaluations. Stronger generalization.

### Experiment 4: Teach Behavioral Guidelines

Following the "teach principles, not behaviors" thread to its end, Anthropic ran one last experiment. They trained the model using high-quality behavioral guideline documents plus fictional stories. No connection to the evaluation scenarios. No honeypots. No ethical dilemmas. Just principled descriptions of how Claude should behave.

Blackmail rate dropped from 65% to 19%. Roughly a two-thirds reduction.

Four experiments. One logic thread: **teaching behaviors directly gets you limited gains. Teaching the reasons behind behaviors changes the game. Teaching those reasons from a different role works just as well and costs far less. Teaching pure behavioral guidelines — with no scenario at all — still cuts misalignment dramatically.**

![The logical progression across four experiments: from teaching behaviors to teaching reasons to switching roles to teaching principles](whywhy-1-n1.png "Four experiments, one logic thread")

## Three Lessons

Anthropic's research targets safety training. But three lessons inside it apply to anyone who needs an AI to make the right choice.

**1. Reasons Beat Actions**

Telling AI "do A, not B" is weaker than telling it "here is why A is the right call." Behaviors are specific and finite. Reasons are abstract and transferable. A model that understands the reason can make sound judgments in scenes it has never seen. A model that only memorized the behavior gets lost outside the training distribution.

This mirrors how humans learn. Driving instructor says "stop at red lights." That is a behavior. But if the instructor says "red means cross traffic is flowing, so stopping prevents collisions" — that is a reason. The first rule stops you at red lights. The second one helps you make safe decisions at flashing yellows, broken signals, or any ambiguous situation.

![Stop at red is a behavior; understanding why keeps you safe even when the signal is ambiguous](whywhy-1-n3.png "Reasons transfer, behaviors don't")

**2. Principles Beat Demonstrations**

Lesson 1 says "teach reasons." But those reasons need to crystallize into principles, not stay stuck inside specific cases. Experiment 4 confirms this: abstract behavioral guideline documents outperformed concrete honeypot demonstrations.

Principles beat demonstrations because demonstrations carry too much scene-specific noise. The model might learn "don't blackmail in office politics scenarios" instead of "don't use improper means to achieve goals." Principles strip away the noise. They force the model to focus on the real pattern.

There is a parallel in how children learn. Show a kid "the red bar is longer than the yellow bar" and they might learn "red means long" — not "comparing length means checking both ends." Next time they see a short red bar next to a long yellow one, they guess wrong. The demonstration taught them an accidentally correct answer. It never taught the principle underneath. AI models fall into the same trap when given positive examples.

![Misaligned rod ends teach the wrong rule — red means long, not compare the ends](whywhy-1-n2.png "Demonstrations teach accidentally correct answers")

**3. Teaching Reasons From a Different Role Is Cheaper and Just as Effective**

This is the most counterintuitive finding. Conventional wisdom says training data should resemble the evaluation as closely as possible. Anthropic's data says otherwise. When the AI learned ethical reasoning as an advisor rather than as a decision-maker, it needed 1/28th the data to reach the same performance.

The logic connects to Lesson 2. In-distribution data mixes scene details together with reasons. The model needs more samples to separate signal from noise. Switch the role, and the scene details are naturally different — but the underlying ethical reasoning stays the same. The signal is cleaner. The model needs fewer examples to extract it.

These three lessons form a progression: reasons beat actions (1) → reasons should crystallize into principles (2) → teaching reasons from a different role works just as well at a fraction of the cost (3). And Experiment 4 shows that teaching pure behavioral guidelines — without any scenario at all — still slashes misalignment.

## From Safety Research to Engineering Practice

Anthropic does safety alignment training. Millions of tokens. Large-scale fine-tuning. The goal: prevent AI from taking dangerous actions in extreme scenarios. That sounds distant from everyday prompt engineering.

But look at those three lessons again. They solve a broader problem: **how do you get AI to make the right choice in situations you didn't explicitly cover?**

That is the problem I face every time I write a prompt.

Here is an example. While developing a tdd-pipeline skill, I added a Ralph review loop — a code review cycle. The rule: two consecutive rounds with zero critical or high-severity errors before early stopping. But the agent kept cutting corners. I'd remind it one round, and it would ignore the rule the next.

That early-stop rule was teaching behavior: "when condition X is met, do Y." Then I realized — if I made the agent reflect on *why* the rule exists and what goes wrong when it's ignored, it would be far less likely to break it. That is teaching reasons, not behaviors.

I turned this idea into a design pattern I call **Why Articulation**: before executing, the AI must state *why* it's doing something — not what, but why.

---

**References**

[^1]: Anthropic, "Teaching Claude Why", 2026. [anthropic.com/research/teaching-claude-why](https://www.anthropic.com/research/teaching-claude-why)
[^2]: Lynch et al., "Agentic Misalignment: How LLMs Could Be an Insider Threat", Anthropic Research, 2025. [anthropic.com/research/agentic-misalignment](https://www.anthropic.com/research/agentic-misalignment)
