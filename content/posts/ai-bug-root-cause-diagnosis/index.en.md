---
title: "The Bug Loop You Can't Escape: Root Cause Diagnosis with AI"
slug: "ai-bug-root-cause-diagnosis"
date: 2026-05-01T10:00:00+08:00
draft: false
description: 'Fix #13, and old bugs come back. This isn''t a "how I fixed a bug with AI" anecdote. It''s a full post-mortem of a 15+ bug battle — four rounds of attribution, regression traps, and how TDD was forced out by pain.'
tags: ["AI", "bug diagnosis", "root cause analysis", "regression testing", "Aristotle", "AI-Assisted Development"]
categories: ["AI Practice"]
series: ["Teaching AI to Reflect"]
toc: true
cover:
  image: "cover.png"
  relative: true
  alt: "The bug loop: four rounds of root cause diagnosis and regression tests breaking the spiral"
---

## 1. The Loop That Never Ends

A few days ago, the Aristotle project [1] — aimed at fully implementing the GEAR protocol — finally validated all its core technical pathways. The codebase had gone through its third refactoring, core features were working, and testing was complete. Right before merging the development branch into main for release, I ran a manual test and discovered that SKILL.md instructions weren't being executed correctly — the model received the action but didn't call `task()` to launch a background subagent. Instead, it loaded LEARN.md. From investigating this issue, more bugs kept surfacing:

Fix #1 (SKILL.md context injection), and #3 turned out to be worse — Shell syntax `$(date +%s)` was being injected directly into the main session, leaving a random timestamp command visible on the user's screen. Fix #3, and #5 turned out to be an architectural flaw: when the Reflector session disappeared, every DRAFT report vanished with it. I typed `/Aristotle review` and got an error. Fix #5, run the tests — #1 is back. The AI's fix for one bug had quietly reintroduced another.

Every bug fix moved the progress bar half a step forward and one step back. You think you've fixed 5? Test again. Now there are 8 left — 3 are old bugs that came back, 2 are new ones introduced by the fixes themselves. Shipping felt impossible.

I realized I was stuck in a dead loop.

Through all of this, every line of code, every test script, every fix — written by AI. My job was quality control: reviewing AI output against expectations, giving feedback, pointing out gaps or misinterpretations. But even with AI dramatically speeding up diagnosis and coding, the loop remained unbroken. Faster fixes meant faster regressions too.

This wasn't deadline anxiety. It was the despair of standing on quicksand — you never know if the next step lands on solid ground or another hole. Bug fixing was no longer a linear countdown. It was a spiral. Fix one, three appear. Fix those three, look back — the first one is broken again.

I needed to solve two problems:

1. How to pinpoint root causes? Not surface explanations — causes solid enough to nail the bug dead.
2. How to prevent fixes from reintroducing old bugs? How to break the loop?

This article is the full post-mortem of that battle. Not an "I used AI to fix a bug" anecdote, not a list of "AI debugging prompt tips." It's an honest record of a 15+ bug campaign — four rounds of attribution (three failed, one succeeded), AI-specific regression traps, and the full story of how TDD was forced into existence by sheer pain. I previously wrote about AI self-reflection architecture design [1]; this piece is its practical sequel.

---

## 2. Four Rounds of Attribution: Starting from a SKILL.md Instruction Failure

The story begins with a strange symptom: after receiving the `fire_o` action, the model didn't execute `task()` to launch a background subagent. Instead, it autonomously loaded LEARN.md.

Tracing this problem became the core narrative of the entire article. In every step of the four attribution rounds, AI was the primary driver.

Let me be honest: AI's technical conclusions are often too detailed for me to verify as true or false. So I developed a method to let AI dig out root causes on its own. I make it show the complete reasoning chain — all the information it relied on, every inferential step — and then I evaluate exactly two things: is the information complete and accurate? Does the reasoning hold up logically? If information is missing or reasoning has gaps, I push back. I steer AI toward the right direction rather than making technical judgments myself — I don't have the time and energy for that.

### Round 1: Correct but Incomplete

I fed the symptom to AI. It quickly concluded: "opencode run doesn't support async notifications."

This was a fact. The Layer 4 tests used `opencode run`, a single-command mode where async notifications genuinely couldn't be delivered. AI even pasted the relevant source code from opencode. Evidence was airtight. I almost accepted the conclusion — "this whole approach is infeasible on opencode" — and asked AI to prepare an architectural rewrite.

But I asked one more question: "Then why does it also fail in interactive sessions?"

AI stalled. The explanation only covered the Layer 4 test scenario. It didn't explain the failures reproduced in interactive sessions at all. The facts were correct, but the conclusion drawn from those facts was wrong. The check I used here eventually became a rule I codified: before accepting a conclusion, list every known anomaly and verify the conclusion explains all of them.

> **Insight 1: Correct facts ≠ correct conclusion.** AI offered a conclusion that explained some anomalies while ignoring the rest. My approach: lay out every known anomaly and demand an explanation that covers all of them simultaneously. In philosophy of science, this is called Inference to the Best Explanation — among competing hypotheses, the one with the greatest explanatory power and no conflicts with known evidence is more likely correct. Harman formalized this in 1965 [2], building on Whewell's earlier concept of "consilience of inductions" (1858) — the idea that a hypothesis explaining a wider range of phenomena than it was originally designed for is more likely true.

### Round 2: Plausible but Wrong

AI adjusted direction and quickly produced a second conclusion: "The model doesn't follow SKILL.md instructions."

Sounded perfectly reasonable. The model hadn't executed the `task()` call in ACTIONS, and had loaded LEARN.md on its own. Isn't that the definition of not following instructions? I even had AI start drafting a prompt optimization plan to improve instruction adherence.

But I asked: "Then why were the ROUTE instructions followed?"

The model had correctly called MCP `orchestrate_start`, proving it could read and act on SKILL.md content. If it "doesn't follow instructions," why follow some and ignore others? I had AI test the reflect flow too — same pattern. Partially followed, partially ignored. This meant claiming "learn isn't followed but reflect is" was itself wrong. Both flows had problems, and the root cause sat at a deeper level.

> **Insight 2: When claiming X behaves differently from Y, you must test Y.** Counter-verification revealed both flows had issues — the root cause was deeper. This maps to a fundamental principle in experimental methodology: when you claim two scenarios differ, you must observe both. Mill formalized this as the Method of Difference in *A System of Logic* (1843) [3] — a judgment of difference is only valid when both sides have been actually observed. Modern experimental design applies this directly through negative controls.

### Round 3: Surface Cause

AI ran a file visibility analysis and produced a third conclusion: "LEARN.md's existence causes the model to bypass the dispatcher."

Delete LEARN.md and test — the problem disappears. AI started writing a fix plan: "Remove LEARN.md, merge its content into SKILL.md." I told it to stop. Wait. "Delete the file" is a solution, not an analysis.

I pushed back: Why does LEARN.md get loaded? Understand why before telling me how.

It hit me. "Delete the file" is a solution, not a causal chain. I knew deleting the file made the symptom vanish, but I had no idea why the symptom appeared in the first place. Like a flickering lamp at home — you unplug a nearby appliance and the flickering stops, but you don't know why. Next time a different appliance might trigger it again. This time it was LEARN.md. Next time it could be REFLECT.md or REVIEW.md. The problem would never end.

> **Insight 3: Understand the problem before proposing a solution.** "Delete the file" is a fix, not a causal chain. Complete the causal analysis before proposing solutions. Aristotle distinguished two types of knowledge in *Posterior Analytics* I.13 [4]: knowing *that* something is the case (hoti), and knowing *why* it is the case (dioti). "Deleting the file makes the problem disappear" is hoti. "Why the file's existence causes the problem" is dioti. Without the latter, every fix spawns a new bug.

### Round 4: The Real Root Cause

I asked AI to put ROUTE and ACTIONS side by side and compare them. The difference jumped out immediately:

- ROUTE used concrete verbs: "call MCP `orchestrate_start`" — the model interpreted this as an executable action.
- ACTIONS used bullet-list format: `fire_o → task(...)` — the model interpreted this as documentation.

The ACTIONS section was written in a documentary style, not an imperative style. The model wasn't "refusing to follow instructions" — ACTIONS simply didn't provide clear enough directives, and the model chose the most semantically reasonable alternative path.

I specifically asked AI: Are you sure this is the root cause? Could there be other factors? AI replied that it had compared public opencode skill implementations on GitHub. Every successfully executed instruction used numbered steps (`STEP N`) or conditional branches (`### If action is X:`). None used bullet lists for action mapping. Rewriting ACTIONS into conditional branch format would most likely solve the problem.

AI made the change. Tested. The model executed `task()` correctly, launched the subagent, and didn't load LEARN.md.

Root cause found. Fix passed on the first try. But verification wasn't done — the callback chain working doesn't mean async notifications were actually active. Two mechanisms can produce identical output: genuine async notification (`<system-reminder>` delivered to session) versus synchronous fallback (task tool degrading to synchronous execution in run mode). I had AI run a discriminating experiment:

1. Check response for `<system-reminder>` markers: present.
2. Compare execution timelines: task execution time far exceeded total response time, confirming background execution.
3. Trace opencode source code paths: confirm task tool behavior definition in run mode.

> **Insight 4: Observed behavior ≠ confirmed mechanism.** Seeing the callback chain work doesn't confirm async notifications are active — two mechanisms can produce the same output while being fundamentally different. The same phenomenon can have multiple explanations. In philosophy of science, this is called "underdetermination." How to determine which one is correct? Design a test where the two explanations predict different outcomes. Popper called this a "crucial experiment" [5]. Duhem, who originally articulated the underdetermination problem in 1906, was skeptical that such experiments could ever be truly decisive — he argued auxiliary hypotheses can always protect a theory from refutation. Popper took the opposite view: high-risk tests can genuinely distinguish between competing hypotheses.

### AI's Role: Reasoning Accelerator, Not Diagnostic Tool

Honesty requires acknowledging this: the wrong attributions in rounds 1–3 were AI-led. The correct attribution in round 4 was also AI-led.

This isn't a contradiction. It's a structural feature of how AI reasons. AI is good at jumping quickly from fact A to conclusion B, but it doesn't automatically ask "does this B cover every observed phenomenon?" Each attribution was based on correct facts — but each set of correct facts only covered part of the picture. The first three conclusions "looked reasonable" because they had evidential support. The evidence was just incomplete.

What did I do? I didn't judge whether each technical conclusion was right or wrong — often I couldn't. I checked the reliability of AI's reasoning process: Was the information it relied on complete? Did the reasoning chain have gaps? Were there known anomalies left unexplained? A wrong answer can be redone. A wrong reasoning direction sends you down the wrong road indefinitely.

This is the critical boundary of AI-assisted debugging: AI can massively accelerate reasoning and coding, but it won't proactively consider the global context. The human's job is to pull it back to the big picture when it locks onto a local optimum. My entire contribution was reviewing output, giving feedback, and pointing out blind spots — not writing a single line of code, but scrutinizing the reasoning behind every line.

Later I realized this maps directly to managing a complex organization. Beyond a certain scale, no manager can understand the technical details of every subordinate's work. What they can evaluate is whether results meet objectives, whether reports show thorough consideration, whether actions align with goals, and whether logic is internally consistent. The manager doesn't judge whether each technical decision is correct — they judge whether the process that led to the decision was sound. Evaluating AI's reasoning process is the same thing.

---

## 3. The Battlefield: 15 Bugs and Why They Won't Die

The SKILL.md problem was solved. The bigger battle had just begun. Functional testing exposed 8 issues. E2E testing found more. 15 bugs stacked up in front of me.

On April 21, I started testing. Within an hour, 4 bugs:

- **Bug #3:** The main session displayed `$(date +%s)` as a literal command. Root cause: `rule_id` generation was assigned to the Reflector instead of being handled by MCP. Dug into the code and found AI had written Shell commands directly into the prompt.
- **Bug #2:** The model output "According to protocol, executing REFLECT operation." Root cause: SKILL.md lacked a constraint against outputting protocol reasoning.
- **Bug #5:** Clicking "review" during testing threw "Reflector session no longer exists." Root cause: DRAFT content lived only in the volatile session. When the session closed, everything disappeared. This one took AI two full days — a complete refactoring of persistence logic, writing DRAFTs to disk at `~/.config/opencode/aristotle-drafts/`.
- **Bug #8:** Testing a fresh install scenario, the first `write_rule` call immediately reported "repo not initialized." Root cause: `install.sh` forgot to call `init_repo_tool()`. Checking commit history, AI had simply missed this step when writing the install script — the script wasn't covered by any test flow.

By April 25, AI had fixed all 8 functional test issues. I breathed a sigh of relief and asked it to run E2E tests, preparing for release. More problems surfaced.

**Bug #14** was a classic "clear symptom, hidden root cause." The review flow sporadically threw null pointer errors. The surface problem was that some object was null in the code. But why null? Tracing deeper: the model's output was too short — DRAFT reports were being truncated mid-write. First instinct: model limitation. Further investigation revealed the API provider's config file example had set a 4K max output for all models. Changed it to the model's actual maximum output value. Problem solved. From error to truncation, from truncation to config — three layers deep, each one requiring the diagnostic methods described in Section 2 to systematically close in on the root cause.

**Bug #13** was a concurrency issue. With multiple instances running concurrently, reconciliation would hang on stale sessions and block startup. An audit also found that `saveToDisk` risked overwriting data from other instances. AI added instance ID isolation and timeout mechanisms. Tested #13 three times. All passed. But there was no regression test suite — testing #13 meant testing only #13, without running through everything else to confirm existing fixes still held. So I moved forward with high hopes.

Then the notification mechanism broke again. I asked AI to analyze the cause. It went off on tangents — various possible explanations, none matching the actual symptom. It suddenly hit me: this might be an old bug coming back. I had AI write regression tests for every previously fixed bug. Ran them. Sure enough — old bug regression confirmed. Checking commit history, AI had modified session isolation logic while fixing #13, and that change had touched notification-related code. The modification had nothing to do with #13's fix objective.

Worse: this wasn't the first time. One or two minor regressions had happened before, caught by manual testing. At the time, they felt like flukes. The third time, I realized this wasn't luck — every time something went wrong, I had to first spend time figuring out "new bug or regression?" Wasting both energy and tokens. Three strikes. The process had to be systematized.

This is the regression trap: fixing one bug reintroduces a previously fixed one, and the existing test and review process has zero mechanism to catch it.

### The Regression Suite and the Birth of TDD

I was backed into a corner. I had AI write `regression_b1_checks.sh`, converting all 39 previously fixed bugs into regression checkpoints [6]. Before fixing a new bug, run the full regression to confirm the baseline. After fixing, run it again to confirm no regressions.

That's how TDD was born here — forced out by necessity. At first I just "ran tests after fixing." After regressions kept appearing, it evolved to "have AI write regression tests first, confirm baseline, then fix." Eventually it became a full workflow: write test (watch it fail) → write fix (watch it pass) → run full regression (confirm nothing else broke). I didn't pull TDD from a textbook. The pain of regressions forced it into existence.

Once this process was in place, bug fix velocity jumped immediately. No more time wasted on "is this a regression again?" Fix → regression all green → next bug. A stable rhythm emerged. The remaining fixes went smoothly:

- **Bug #14b:** Notification parent session logic fix, 4 new tests added, regression all green.
- Logger default level misconfiguration, fixed, regression all green.
- Config module audited by Oracle, revealing 2 high + 4 medium + 2 low severity issues. All fixed, regression all green.
- Final full regression: 39 regression checkpoints all green + E2E all green.

---

## 4. Victory and Lessons

The day v1.1.0 merged into main, every test was green: 325 pytest + 162 vitest + others = 654 tests [7]. Every former bug had a corresponding test case guarding it. No more worrying about fixes pulling old bugs back to life.

The biggest lesson from this campaign: your job isn't to judge whether AI's conclusions are right or wrong. It's to audit the reliability of AI's reasoning process. AI has three structural blind spots that require human intervention:

| What AI can't do | Consequence | Human role |
|---|---|---|
| Doesn't ask "does this hypothesis cover every observed phenomenon?" | Correct facts → wrong conclusion | Check whether reasoning relies on complete information |
| Doesn't distinguish observed behavior from confirmed mechanism | Same output masks different mechanisms | Check whether the reasoning chain has unverified leaps |
| Doesn't automatically check whether fixes introduce regressions | Fixes reintroduce old bugs | Establish rules making AI maintain regression tests automatically |

### Epilogue

The project shipped. Not because all 15 known bugs were fixed and business flows passed — bugs are never truly finished. It shipped because a systematic diagnosis and regression mechanism was in place. Within the agreed scope of requirements, bugs were no longer an infinite loop.

The despair wasn't about having many bugs. It was about fixing one and spawning three, then looking back to find the first one broken again. What broke the loop wasn't trying harder to fix bugs — it was nailing every fixed bug in place with a test. I later packaged this approach into a standalone tdd-pipeline tool [8], but its roots are in this painful campaign.

AI is not a silver bullet. It's an efficiency amplifier. Your correct decisions get amplified tenfold. Your wrong ones do too. The key to using AI well has never been writing more clever prompts. It's understanding its reasoning blind spots and knowing where to check its reasoning process.

---

## References

1. "Aristotle: Making AI Learn to Reflect on Its Mistakes" — the first article in the AI self-reflection series: [English](/en/posts/aristotle-ai-reflection/) | [Chinese](/posts/aristotle-ai-reflection/)
2. Harman, G. "The Inference to the Best Explanation." *Philosophical Review*, 1965. Whewell's consilience of inductions (1858) is the historical precursor — the core argument being that a hypothesis explaining more types of phenomena than it was originally designed to cover is more likely correct. Overview: <https://plato.stanford.edu/entries/whewell/>
3. Mill, J.S. *A System of Logic*, 1843, Book III, Ch. 8. The Method of Difference: to judge whether a difference between two scenarios constitutes a causal relationship, both sides must be actually observed. Modern negative controls in experimental design are a direct application of this principle.
4. Aristotle, *Posterior Analytics* I.13 (78a22). Aristotle distinguished hoti (knowing *that*) from dioti (knowing *why*): knowing a fact holds is not the same as knowing why it holds. Genuine scientific knowledge must be established through causes. Overview: <https://plato.stanford.edu/entries/aristotle-causality/>
5. Duhem, P. *The Aim and Structure of Physical Theory*, 1906. The underdetermination thesis: the same body of empirical evidence can support multiple mutually incompatible theories. Duhem himself was skeptical of "crucial experiments," arguing auxiliary hypotheses can always protect a refuted theory. Popper took the opposing view, arguing that high-risk tests can genuinely distinguish competing hypotheses — what he called "crucial experiments." Overview: <https://plato.stanford.edu/entries/scientific-underdetermination/>
6. Regression test script: <https://github.com/alexwwang/aristotle/blob/main/test/regression_b1_checks.sh> (39 checkpoints)
7. Final test counts: 325 pytest + 162 vitest + others = 654, test-coverage merge commit: `bf777fe`, later count update in commit `cd0a364`
8. tdd-pipeline project: <https://github.com/alexwwang/tdd-pipeline>
