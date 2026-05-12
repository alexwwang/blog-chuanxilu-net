---
title: "AI Path L0→L1 Upgrade Guide (4): Building Your Personal System"
slug: "ai-path-l0-l1-week4"
date: 2026-05-11T08:00:00+08:00
draft: true
description: "Part 4 of the AI Path L0→L1 Upgrade Guide. Build a prompt library, pick the right tool for each job (with separate maps for international and Chinese users), and learn a tiered approach to knowledge management — because not every AI output is worth saving."
tags: ["AI", "toolchain", "evolution-path", "tutorial"]
categories: ["AI Practice"]
toc: true
series: ["AI Path L0→L1 Upgrade Guide"]
---

> 📖 This is Part 4 of 5 in the "AI Path L0→L1 Upgrade Guide" series.
>
> [Part 1: Understanding Your Tools](/en/posts/2026/05/ai-path-l0-l1-week1/) · [Part 2: From Vague Questions to Precise Instructions](/en/posts/2026/05/ai-path-l0-l1-week2/) · [Part 3: Turning AI Into Your Collaboration Partner](/en/posts/2026/05/ai-path-l0-l1-week3/) · Part 4: Building Your Personal System · [Part 5: Graduation & Next Steps](/en/posts/2026/05/ai-path-l0-l1-graduation/)

Over the first three weeks we covered the cognitive foundations, prompt techniques, and conversation management. In this final week we're going to cement those skills — building a prompt library, choosing the right tools, and setting up knowledge management. By the end, you'll have a personal AI workflow that's genuinely yours.

---

## Week 4: Building Your Personal System — From "Can Use" to "Uses Well"

### Day 22–23: Build a Prompt Library

**Why it matters:** Have you ever had this experience — you wrote a prompt that produced a brilliant result, but when you needed it again you couldn't find it? Or you *know* you crafted a great prompt once, but you can't quite recall the exact wording? A prompt library solves exactly this problem. It's your personal knowledge asset — your "ammunition depot" for efficient AI collaboration.

**How to think about it:** A prompt library doesn't need to be complicated. The core idea is simple: **write down the prompts you've verified as effective, organize them by category, and make them easy to reuse.**

**How to build one** — pick one of these two approaches:

- **Option A** (recommended if you already use a note-taking app): Create a categorized notebook in Notion or Obsidian. Each prompt is one note, tagged by category.
- **Option B** (simplest possible): Create a folder on your computer with Markdown files — one file per category.

Organize by use case: writing, analysis, programming, daily tasks — or whatever categories make sense for you. The only criterion that matters is **you can find what you need when you need it.**

For each prompt entry, record:

- **The original prompt**: The exact text you used
- **Effectiveness rating**: 1–5, or simply "great / decent / poor"
- **Iterated versions**: If you later refine the prompt, log the new version alongside the original

**Practice exercise:** Look back over your AI usage from the past three weeks and extract at least 5 battle-tested prompts. If you can't find your history, create 5 new prompts you know you'll need at work, test each one, confirm the results, and add them to your library.

**Target by month's end:** At least 10 verified prompts in your library — enough to cover 80% of your everyday scenarios.

### Day 24–25: The Right Tool for the Right Job

**Why it matters:** I've seen too many people try to do *everything* with a single AI tool, only to hit a wall in certain scenarios. Every AI tool has a "comfort zone" — inside it, the tool performs like an expert; outside it, the results are mediocre. Pick the right tool for the right job, and everything gets easier.

**How to think about it:** I'm providing **separate** scenario-to-tool maps for international users and Chinese users. The two ecosystems are very different — lumping them together would be misleading.

#### Option A: International Users

| Scenario | Recommended Tool | Why |
|----------|-----------------|-----|
| Deep research | Perplexity / Gemini Deep Research | Live web search, cross-referencing, cited sources |
| Long-form writing | Claude Projects | Upload reference materials for persistent context; excellent long-text quality |
| Everyday Q&A | Any of ChatGPT / Claude / Gemini | All-rounders — more than sufficient for daily use |
| Code assistance (autocomplete) | Copilot / Cursor | Deep IDE integration; great autocomplete and refactoring experience |
| Office documents | Copilot for Office / Notion AI | Seamless integration with your office environment |

#### Option B: Chinese Users

| Scenario | Recommended Tool | Why |
|----------|-----------------|-----|
| Deep research | Kimi / 秘塔搜索 (MetaSo) / 天工 AI (Tiangong) | More complete coverage of the Chinese web; no VPN needed; Kimi supports ultra-long context (256K tokens, ~500K characters) |
| Long-form writing | Kimi / 千问 (Qwen) | More natural Chinese prose; better formatting for government and business documents |
| Everyday Q&A | 豆包 (Doubao) / 千问 (Qwen) / Kimi / 智谱清言 (ChatGLM) — any one | Generous free quotas; strong Chinese comprehension; fast response times; ChatGLM also stands out for code and reasoning |
| Code assistance (autocomplete) | Trae (by ByteDance) / 通义灵码 Lingma (by Alibaba) | Domestic AI IDEs, free, low latency, accurate understanding of Chinese comments. Trae ships with multiple built-in models and a "SOLO" autonomous coding mode; Lingma has passed multiple authoritative security certifications for code |
| Office documents | WPS 灵犀 (Lingxi) / 飞书 AI (Lark AI) / 钉钉 AI (DingTalk AI) | Deeply integrated into domestic office ecosystems; more professional handling of Chinese-specific documents like government memos and contracts |
| AI-powered search | 豆包 (Doubao) / 夸克 (Quark) / 腾讯元宝 (Tencent Yuanbao) | Doubao excels at multimodal tasks; Quark handles long documents well; Yuanbao is natively integrated with the WeChat ecosystem |

**A few extra notes for Chinese users:**

- **Code assistance:** If you write code, Trae and Lingma are better fits for developers in China — they work directly on the domestic network, and their free tiers are far more generous than Copilot Free (which caps you at just **50 requests per month**). Pick whichever one matches your tech stack and ecosystem preference.
- **Office documents:** WPS Lingxi handles Chinese government memos and contracts far more natively than Copilot; Lark AI and DingTalk AI deliver a smoother experience in enterprise collaboration scenarios.
- **Don't ignore international tools:** Even in China, if you produce English content or work on international projects, Claude and ChatGPT remain the go-to choices for long-form writing and code review. Many advanced users run both tracks in parallel.

**Practice exercise:** List the 5 scenarios you use most often, and match each one with the best tool. Then ask yourself a deeper question: **Which of these 5 are your *core* scenarios?** Core scenarios deserve the time to learn the tool deeply; for non-core ones, "good enough" is fine.

**Guiding principle:** Don't try to master every tool. Get really good at the ones that cover your core scenarios, and keep one reliable fallback for everything else.

### Day 26–28: Knowledge Management — Not Every AI Output Is Worth Saving

**Why it matters:** This is a topic many people don't want to confront. We instinctively feel that "good stuff should be saved," so we hoard AI's best outputs, building elaborate knowledge bases — and then never open them again. Three months later you have an enormous bookmark collection, but your actual skills haven't improved one bit.

**First, ask yourself: do you actually *need* a "knowledge base"?**

It depends on how you learn. If your style is to internalize on the spot — see something great, understand it immediately, apply it, remember it — then treating AI outputs as disposable is perfectly fine. You don't need any archiving system at all. But if you often find yourself hunting for "that great answer AI gave me once," then yes, some kind of archive makes sense.

**Watch out for a trap:** The process of building a knowledge base can itself become a form of **"all process, no learning" performance art.** You organize 100 notes, add tags, pretty up the formatting, build a table of contents — but you haven't genuinely understood a single one. That's not knowledge management; that's *performing* knowledge management.

**How to think about it — a tiered approach:**

If you do need to save AI outputs, I recommend a **two-zone system** rather than one big dumping ground:

- **Core library** (for learning): Only material you genuinely intend to learn and internalize. For example, a conceptual framework AI helped you untangle, or a thinking model you reference repeatedly.
- **Reference material** (for lookup): Code snippets, data tables, templates, formatted content — utilitarian stuff. You don't need to "understand" these; you just need to find them when you need them.

And then there's the third tier:

- **Don't archive at all:** One-off Q&A, disposable tasks, things you already understand. Delete them. Don't fall into the "what if I need it someday" trap.

> **The Half-Year Principle: If you don't plan to learn it, don't have a clear use for it, and aren't genuinely curious enough to go deeper within the next six months, it does not belong in your core library.**

Six months is a rough window — the point is to force a decision. Don't let your core library become a "throw everything in" junk drawer.

**Practical tips** (only for people who genuinely need knowledge management):

1. Set up two zones in Obsidian or Notion: "Core" and "Reference"
2. For every item you archive, note the source (which platform, which prompt generated it)
3. **Review your core library regularly** — at least once a month, check whether you're actually learning from and using the material. If something has been sitting in your core library untouched for three months, be honest with yourself and demote it to reference material.

**Practice** (optional): From all your AI conversations this week, pick **no more than 3** items you believe you'll genuinely use in the next six months, and organize them into your core library. Notice I said "no more than 3" — that cap is deliberate. It forces you to think hard about what's truly worth saving.

---

*That wraps up Week 4. All four weeks of practice are now complete — ready for the final test? → [Part 5: Graduation & Next Steps →](/en/posts/2026/05/ai-path-l0-l1-graduation/)*
