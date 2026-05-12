---
title: "AI Path L0→L1 Upgrade Guide (1): Understanding Your Tools"
slug: "ai-path-l0-l1-week1"
date: 2026-05-11T08:00:00+08:00
draft: false
description: "First part of the AI Path L0→L1 Upgrade Guide series. LLMs aren't search engines—they generate answers rather than retrieve them. Understand the difference between working memory and long-term memory, learn the strengths of mainstream platforms, and build the cognitive foundation for the next 4 weeks of practice."
tags: ["AI", "toolchain", "evolution-path", "tutorial"]
categories: ["AI Practice"]
toc: true
cover:
  image: "cover.png"
  alt: "Watercolor illustration: a person at a cozy desk, holding a glowing translucent orb representing the essence of understanding LLMs"
series: ["AI Path L0→L1 Upgrade Guide"]
---

> 📖 This is Part 1 of 5 in the "AI Path L0→L1 Upgrade Guide" series. Series navigation will be updated once all parts are published.

## Introduction: Sound Familiar?

I've watched a lot of friends use AI tools, and I keep noticing the same pattern. They're not strangers to ChatGPT or Claude—they use them casually from time to time—but their experience is wildly inconsistent. Sometimes the AI delivers a jaw-dropping answer; other times it completely misses the point, producing something unusable.

**"Sometimes great, sometimes terrible—basically a coin toss."** That's the stage where most people get stuck. I call it L0.

The problem at L0 isn't that you don't understand AI. The problem is that your interaction with it is essentially *hope-driven*. You type whatever comes to mind, with no structure and no clear expectations—so naturally, you can't consistently get high-quality output.

L1 comes down to four words: **using AI with intention**. You know when to start a fresh conversation and when to follow up. You have a tested Prompt library. You can tell whether the AI's output is actually reliable. Getting from L0 to L1 doesn't require you to code or understand math. It just takes about 4 weeks of deliberate practice, 20–30 minutes a day.

That's exactly what this guide is for. The full series has 5 parts — read them in order, do the exercises after each part, then move on:

1. **Understanding Your Tools** (this article) — LLMs aren't search engines, two types of memory, mainstream platform strengths
2. **From Vague Questions to Precise Instructions** — the RBGO prompt framework, Chain-of-Thought reasoning, output format constraints
3. **Turning AI Into Your Collaboration Partner** — follow-up iteration, context management, role-playing and expert simulation
4. **Building Your Personal System** — prompt library, scenario-based tool mapping (international and Chinese options), knowledge management
5. **Graduation & Next Steps** — L1 checklist, L1→L2 dual-path preview (API / autonomous execution AI)

Parts 1–4 correspond to the 4 weeks of practice. Part 5 wraps things up. Each part ends with exercises — plan on 2–3 days per part before moving to the next.

Ready? Let's begin.

![Understanding your tools — from "hoping for a good answer" to "designing for one"](l0-l1-1m.png)

---

## Week 1: Understanding Your Tools

### Day 1–2: LLMs Are Not Search Engines

**Why it matters:** This is the foundational piece of the puzzle. If you treat an LLM like a search engine, your expectations will be misaligned—you'll expect "the correct answer" every time, and when the AI fabricates a fact, you'll conclude it's unreliable. But LLMs and search engines work in fundamentally different ways.

**How to think about it:** A search engine is **retrieval-based**—you type in keywords, it searches an index for matching pages, and returns results ranked by relevance. The results come from real web pages and are deterministic. An LLM, on the other hand, is **probabilistically generative**—it reads your input and predicts the most likely next token, one at a time.

**AI doesn't "know" answers—it "generates" them.** "Knowing" implies a factual basis; "generating" means sampling from a probability distribution. Ask the same question three times, and you might get three different answers. Most of the time the output is reasonable and useful, but occasionally the AI will "hallucinate"—producing content that sounds perfectly plausible yet is entirely wrong.

**Practice:** Try this today. Pick an open-ended question (for example, "How can I improve team collaboration?") and ask the exact same question three times in a row on the same AI platform. Pay close attention to the differences across the three responses. You'll notice that while the core ideas may be similar, the specific arguments, examples, and structure vary each time.

This exercise builds an important intuition: AI output isn't *looked up*—it's *assembled*. Once that clicks, you'll stop treating it like a search engine.

Then ask yourself a key question: **When should you use AI, and when should you use a search engine?** A simple rule of thumb: verifying specific facts ("What is China's latest GDP?") → search engine; analysis, creation, synthesis, or reasoning ("Help me analyze the risks in this business model") → AI. For anything requiring accurate cited sources, always verify with a search engine first.

### Day 3–4: Two Kinds of Memory — Working Memory vs. Long-Term Memory

**Why it matters:** Understanding how AI "remembers" things is the key to avoiding two of the biggest frustrations: conversations that gradually go off the rails, and having to re-explain yourself from scratch every time. If you don't know what the AI can and can't remember, you can't manage context effectively in your conversations.

**How to think about it:** AI has two types of "memory," and they work very differently.

#### Working Memory (Context Window)

**Working memory** is everything the AI can "see" within the current conversation. Every message you send and every reply it gives lives inside this "window." The critical limitation: **when the conversation ends, working memory disappears.** Start a new chat, and it knows nothing about what you discussed before.

Working memory also has a **capacity** limit—the context window is typically measured in **Tokens** (roughly equivalent to words or word-pieces). Each message takes up space, and as the conversation grows long, earlier content can get "pushed out" of the window. The AI effectively "forgets" what you said before. That's why long conversations tend to drift.

There are three practical techniques to keep in mind:

1. **Know when to start a new conversation.** If you're switching to a task unrelated to the current chat, don't continue in the same thread—start fresh.
2. **Proactively summarize in long conversations.** Every 10–15 turns, pause and say something like, "So far we've established the following key points: 1... 2... 3..." This compresses critical information back into the AI's active context.
3. **Know when to stay in the current conversation.** When you need the AI to continue building on context you've already discussed, stay put.

#### Long-Term Memory (Cross-Conversation Memory)

**Long-term memory** refers to the cross-conversation memory features that AI platforms offer. By 2026, this has become a mainstream standard—but implementations vary significantly across platforms, and it's worth spending a few minutes understanding the differences.

> The information below is current as of **May 2026**. Platform features may have been updated since—check official docs for the latest.

| Platform | Memory Type | How It Works | Free Tier |
|----------|------------|--------------|-----------|
| **ChatGPT** | Dual system | **Saved Memories** (explicit—you tell it what to remember) + **Chat History Reference** (implicit—extracts preferences from past conversations). Limited availability for free users | Partial |
| **Claude** | Auto-summary | Updates a memory summary every 24 hours, automatically accumulating insights about your conversation habits and preferences. Available for free across all platforms | Yes |
| **Gemini** | Conversation memory + ecosystem integration | Remembers cross-conversation preferences and can connect to Google ecosystem data (email, calendar, etc.). Deep Personal Intelligence features require a subscription | Partial |
| **Doubao (豆包)** | Dual-track | Explicit memory + implicit chat history reference. Free to use, with a total cap (cycles out older memories) | Yes |
| **Qwen (千问)** | Explicit + implicit | Up to 50 explicit memories + implicit chat history reference. Free to use | Yes |
| **Kimi** | Passive memory | Automatically records user preferences and habits, accumulating passively over time. Free to use | Yes |
| **DeepSeek** | ⚠️ None | Fully stateless—no cross-conversation memory whatsoever | — |

**Key insight: long-term memory ≠ infinitely reliable.** It can remember things incorrectly (mixing up preferences you mentioned) or store things you'd rather it didn't (treating a one-off preference as permanent). So develop a habit: **periodically clean up AI memory, just like you'd tidy up browser bookmarks.**

**Practice:**

1. **Experience working memory:** Start a new conversation, chat with the AI for 5–6 turns (about anything), then open a brand-new conversation and ask, "What did we just talk about?" It won't know—that's working memory vanishing when a conversation ends.
2. **Manage long-term memory:** On whatever platform you use daily, find the memory management settings (usually under Settings), and review what the AI currently remembers about you. Delete anything outdated or incorrect. Make it a monthly habit.

### Day 5–7: Know the Mainstream AI Platforms and Their Strengths

**Why it matters:** Many people use only one platform and conclude "AI isn't that great." The reality is that different platforms have different strengths and sweet spots. Understanding these differences helps you pick the right tool for the right task.

**How to think about it:** I'll organize this by global platforms and Chinese platforms.

**Global platforms:**

- **ChatGPT**: The most complete ecosystem, with a rich plugin and app marketplace. The GPT-5.5 series delivers well-rounded capabilities. Best for all-purpose daily use and scenarios that benefit from the plugin ecosystem.
- **Claude**: Exceptional at long-form content, with high-quality writing and analysis. The Projects feature lets you upload reference materials and maintain context. Best for in-depth writing, long-document analysis, and code review.
- **Gemini**: Deep integration with the Google ecosystem (email, docs, calendar), strong multimodal capabilities, and Deep Research for thorough investigations. Best for heavy Google ecosystem users.

**Chinese platforms:**

- **Kimi**: Excellent at handling ultra-long contexts, with natural Chinese comprehension. Great for reading and summarizing very long documents.
- **Doubao (豆包)**: Built by ByteDance, integrates with the Douyin/Feishu ecosystem, offers fast response times, and generous free quotas. Ideal for everyday Chinese-language tasks and ByteDance ecosystem users.
- **Qwen (千问)**: Built by Alibaba, integrates with Taobao/DingTalk, and the Tongyi model family ranks among the strongest domestic options. Good for Alibaba ecosystem users and general Chinese-language tasks.
- **DeepSeek**: Outstanding reasoning ability (especially in math and programming), open-source models that can be self-hosted, and extremely competitive API pricing. Best for coding and mathematical reasoning, and for users with self-hosting needs.
- **Zhipu Qingyan (智谱清言 / ChatGLM)**: Built by a Tsinghua-origin team, with strong code generation and reasoning capabilities. Supports AI video calls and phone agents (AutoGLM). Active open-source ecosystem (GLM series has 150K+ GitHub stars). Great for coding assistance and users who enjoy trying cutting-edge features.

**A note for international readers:** Chinese platforms offer unique advantages for Chinese-language workflows—more formal business writing, better-localized research, and easier integration with domestic API ecosystems. If you regularly work with Chinese content, don't overlook these platforms.

Beyond conversational platforms, there are also **specialized tools** worth knowing about (no need to try them all now—just be aware they exist):

- **Perplexity**: An AI-powered search engine that can search the web, cross-reference sources, and cite its references. Ideal for deep research that requires factual verification.
- **Copilot / Cursor**: Programming assistants that provide AI-powered code completion and refactoring suggestions directly inside your editor. If you don't write code, skip these.
- **Notion AI**: AI features built into the Notion knowledge management tool. Handy for using AI directly within your note-taking environment.
- **Claude Code / OpenAI Codex (cloud) / OpenCode and similar autonomous AI tools**: These are often labeled "AI coding" tools, but their real nature is *autonomous task-execution AI*—they can read files, edit files, and run commands. Coding just happens to be the most obvious use case. For example, you could ask one to batch-convert a folder of Markdown files, reorganize a project directory structure, or analyze a spreadsheet. Most run locally (Claude Code, OpenCode), while some execute in cloud sandboxes (OpenAI Codex). They require basic command-line skills and fall into L2+ territory, but they're worth keeping on your radar—autonomous AI tools may well become the next mainstream tool category.

**Practice:** Pick a real, complex task you've recently encountered (e.g., "Analyze the viability of this business plan" or "Write a technical blog post"), and try it on 2–3 different platforms. Compare the quality, style, and depth of the results. This will give you an intuitive feel for the differences between platforms.

Then do something even more important: **based on your primary use cases, pick 1–2 main platforms and go deep.** You don't need to use them all. Being proficient with one or two is far better than barely scratching the surface across five. Write a lot? Go with Claude. General-purpose daily use? ChatGPT. Working primarily in Chinese? Doubao or Kimi. Let your needs drive the choice.

---

*That wraps up Week 1. Next week, we dive into Prompt fundamentals—from vague questions to precise instructions. (Part 2 coming soon)*
