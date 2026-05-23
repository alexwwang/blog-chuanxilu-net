---
title: "Advanced Follow-Up: 3 Questions That Expose AI's Hidden Assumptions"
slug: "ai-follow-up-hidden-assumptions"
date: 2026-05-24T06:00:00+08:00
draft: true
description: "Follow-up questions are not just for getting AI to say more. They can expose the default assumptions behind an answer. Use three questions to check hidden premises, find unanswered questions, and identify conditions that would invalidate the conclusion before accepting a suggestion."
tags: ["AI", "toolchain", "evolution-path", "prompt engineering"]
categories: ["ai-path"]
toc: false
series: ["AI Path L0→L1 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor style: a translucent stack of papers on a desk with three follow-up checkpoints, symbolizing hidden assumptions behind AI answers"
---

The previous post was about how long conversations drift. After writing it, I noticed something else: drift does not only happen after a conversation gets long. It can also happen inside any answer that looks complete.

AI answers quickly, and its conclusions often sound smooth. But it rarely says upfront: what assumptions does this conclusion depend on? If those assumptions are not checked, I end up accepting them by default. Accept enough unchecked assumptions, and the later analysis may be built on the wrong foundation.

So when I get a suggestion now, I don't rush to decide whether it is right or wrong. I ask three questions first, to pull out the assumptions hiding behind the answer.

## Which Assumptions Are the Most Fragile?

> What assumptions does your analysis depend on? Which assumptions are most likely to fail?

A hidden constraint like "assuming your readers are developers" usually won't be stated by AI on its own. You have to force it out. Once you know which assumptions may not hold, you know where the suggestion's boundary is.

## What Questions Were Left Out?

> What questions does this analysis not answer? What are you unable to judge?

Sometimes AI looks like it knows everything, but it is only answering selectively. Getting it to admit "I don't know" or "I can't judge that" gives you a clearer picture of what the suggestion actually covers. Unknown questions are more dangerous than known ones.

## Under What Conditions Would This Conclusion Be Wrong?

> Under what conditions would this conclusion be completely wrong?

This is not about finding edge cases. It is about finding the conditions that would overturn the whole conclusion. If AI suggests shortening an article, I ask: under what conditions should the article be longer instead? If it cannot name the conditions that would invalidate its conclusion, it probably hasn't thought it through.

Recently, I was deciding whether to cut an article down to 800 words. AI said, "Shorter is more attractive to readers." I asked the three questions, and it admitted that the suggestion assumed "readers only have 30 seconds of attention," but had not considered that "deep content needs detailed examples." If the article's core value is a complete narrative, shortening it can damage the piece. Now I know when the suggestion holds, and when it is wrong.

These three questions are a safety check. They are not about distrusting AI. They are about knowing what you are agreeing to.

The next post covers how to turn follow-up habits into a system, so deeper questioning becomes automatic.

---

📖 **Series Navigation**

- Previous: [Long Conversation Failures: Lessons from 3 Drift Disasters](/en/posts/2026/05/ai-3-long-conversation-fails/)
- Next: [AI Path L0→L1 Upgrade Guide (Part 4): Building a Personal System](/en/posts/2026/05/ai-path-l0-l1-week4/)
