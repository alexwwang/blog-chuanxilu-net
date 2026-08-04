---
title: "Your AI Toolbox — How Scripts and AI Agent Work Together"
slug: "ai-path-l1-l2-week3-day12"
date: 2026-08-04T10:00:00+08:00
draft: false
description: "AI Path L1→L2 Day 12: how scripts and AI Agent split a batch job. A 71-page Dolch picture book project shows the full pipeline: constraints, structured tables, scripts, and verification."
tags: ["AI", "tutorial", "toolchain", "API", "batch processing", "automation"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor: a toolbox holding a code script and an AI agent, beside pages of a children's picture book being batch-generated"
---

> This is Day 12 of the AI Path L1→L2 Upgrade Guide. Do [Day 8](../ai-path-l1-l2-week2-day8/), [Day 10](../ai-path-l1-l2-week3-day10/) and [Day 11](../ai-path-l1-l2-week3-day11/) first.

Day 11 ended with a question: how do I automate these steps?

Here's my answer. Pairing stateless API calls with an AI agent is the same kind of work as breaking down workflows, designing systems, and building software. I've been doing that kind of work for years. The AI picture book project I'm building right now is a clean example. I'll walk through how I designed its pipeline and tasks.

Let me settle the terms first. Autonomous execution AI and AI Agent are the same thing: an AI with context and state awareness, one that remembers earlier conversation and adjusts course as it works. Under the hood it runs on stateless LLM API calls: one request at a time, no memory between calls. The agent keeps its own state on top of that. I'll use both terms interchangeably from here on; they point to the same concept.

Now the project. My kid was learning Dolch sight words and I wanted picture books that practiced them. Everything on the market was flashcards and worksheets. No storybooks at all.

So I decided to make our own. I can't draw, so AI had to paint. The full Dolch list: 220 words, 5 levels. That's a lot of books.

I started with level PP (Pre-Primer, the first reading level): 40 words, 10 books, 71 pages. Cast: Sam the kitten, Pip the chickadee, Ben the dog. Each book is 6-8 pages, one simple English sentence per page, one watercolor illustration per page. Generating those 71 images by hand? I'd still be drawing.

Before any story, there's the word plan. Sight words must appear gradually, in a controlled order. Deciding which story gets which words: 40 words alone could take me a month, and that's before writing stories around them. A job like this was begging for AI.

I made my wish. Reality hit back: handing everything to AI was slow and expensive, and one story could eat half a day.

I stopped and took the job apart. What exactly is it made of? Six pieces: planning word lists, deciding stories and characters, polishing the text, writing image prompts, generating images, checking the results. Each piece needs a different kind of tool. How I matched them is today's topic.

The finished books are not the point. The underlying logic is: why can this job be done in batch, and which step should go to whom.

---

## Who Gets Which Work

The rule has one line:

**Can this step be pinned down?** If yes: prompts, process, output format can all be fixed. Write a script and call the API. Each call is stateless: prompt in, result out, no memory between calls. Running it once or a hundred times gives the same result. If no, hand it to an AI agent with context and state awareness. Exploring, trial and error, on-the-fly judgment is its job. Its job is not to execute for you; it's to turn the task into something that can be pinned down: scripts, prompts, tables.

Here's the split in the picture book project:

- **Story text and image prompts**: one-time exploration and judgment. Each story needs a plot, embedded vocabulary, controlled sentence patterns, and per-page image prompts following the character style guide. Goes to the AI agent.
- **71 illustrations**: the same action repeated 71 times. Prompts already written, no judgment needed. Goes to the API script, queued one by one.
- **Verification**: words sufficient? pages correct? images any good? Human and AI check together.

Remember the dividing line: **writing prompts is judgment work, running prompts is grunt work. Judgment happens once; grunt work goes to the script.** That's the core of this combination.

---

## The Pipeline: Five Steps

Look at the whole before the details:

```text
Constraints first → AI generates structured table → script parses Markdown → API generates/downloads images → rules + human verification
```

Each step's output is the next step's input. Break anywhere in the middle, everything after stops.

![Five-step pipeline: constraints → table → script → API → verification](illustration-pipeline.png)

### Step 1: Design Constraints First

Before writing the first story, fix the constraints. For PP level, constraints center on two things: **word distribution** and **text shape**.

Word distribution. 40 words across 10 books. Each book introduces 4-5 new words; the last one, PP10, introduces only 3. Each book reuses words from the previous one. The distribution table is fixed before any story is written:

| Story | New words | Reused from |
|:----:|------|---------|
| PP01 I Can See | I, can, see, the, a | — |
| PP02 Look! Look! | look, funny, you, we | PP01 |
| PP03 It Is Big | is, it, big, little | PP02 |
| PP04 Jump In | jump, in, my, and | PP03 |
| PP05 Go Up! | go, up, down, run | PP04 |
| PP06 Come and Play | come, here, play, find | PP05 |
| PP07 Help Me! | help, not, for, make | PP06 |
| PP08 One, Two, Said | one, two, said, me | PP07 |
| PP09 Away We Go | away, red, blue, yellow | PP08 |
| PP10 Where Is Three? | where, three, to | PP09 + earlier books |
Text constraints: 1-2 sentences per page, 3-5 words per sentence, 30-60 words per book, simple patterns only (like `I can see...`, S + can + V). Character style guide: Sam is an orange tabby kitten with a white chest and green eyes; Pip is a blue chickadee; Ben is a brown dog. Every page's image prompt must follow it.

Hard targets: each new word appears at least 3 times in its story, each reused word at least once, fixed page count per book.

These are Day 10's Constraints. Write them down first; every later step has something to check against.

### Step 2: AI Generates Structured Content

Ask the AI agent to write stories against the constraints. Each story lands in a four-column table:

| Page | Scene description | Story text | Image prompt |
|:--:|---------|---------|-----------|
| 1 | Sam wakes up in his bedroom, sunlight streaming in | I can see. | Children's book illustration, soft watercolor style. Small orange tabby kitten Sam... |
| 2 | Sam steps outside, looks at the bright sky | I can see the sun. | ... |
| 3 | Sam walks toward a big tree | I can see a tree. | ... |

One page per row. The four columns: page number, scene description (Chinese, for humans), story text (English, the book's text), image prompt (English, fed to the image API).

This is the decision everything else in the pipeline depends on: **AI's output is not a paragraph, it's a structured table.**

### Step 3: The Script Parses the Table

With the table done, the rest is grunt work. A Python script reads the Markdown, splits it into 10 sections by story title (`# PP01`, `# PP02`...), splits each line by the pipe, and extracts one image prompt per page:

```python
import re

        # Locate the table block (header is assumed to be "| Page |"; use a more tolerant regex in production, e.g. r'\|\s*Page\s*\|')
    text = open(md_path).read()
    pages = []
    # Split by story title
    for part in re.split(r'\n(?=# PP\d+)', text):
        name = re.search(r'^# (PP\d+)', part, re.M)
        if not name:
            continue
        # Locate the table block (header is assumed to be "| Page |"; use a more tolerant regex in production)
        table = part[part.find('| Page |'):]
        for line in table.split('\n'):
            cells = [c.strip() for c in line.strip('|').split('|')]
            if len(cells) < 4 or not cells[0].isdigit():
                continue
            pages.append({
                'story': name.group(1),
                'page': int(cells[0]),
                'prompt': '|'.join(cells[3:]).strip()  # Column 4 onward: contains full prompt with global style & character constraints
            })
    return pages
```

Only two things matter: **splitting stories with regex, splitting columns by the pipe**. The table format is fixed, so the script can safely assume "column 1 is the page number, column 4 is the prompt."

Note: column 4 is not a casual description. It's the global constraints assembled into a prompt: art style, character appearance, scene rules. If the prompts are sloppy, the images will collapse no matter how well the script runs. Step 2's quality directly decides Step 4's output.

### Step 4: The API Generates the Images

With the prompt list ready, call the image API. For each image: write the prompt to a temp file, call the API once, take the image URL from the JSON response, download and save.

The API is synchronous: call once, wait until it finishes generating and returns the URL, then the next image. Calls queue up one by one and run strictly sequentially. 71 images finish in about half an hour, nobody needs to watch. Doing them by hand, one at a time? Most of a day just waiting.

### Step 5: Verify and Fix

Generating isn't finishing. Checklist:

- Word counts: does every new word appear ≥3 times? A script counts faster than eyes.
- Page and word counts: do they meet the hard targets in the design doc?
- Image integrity: all 71 downloaded? Regenerate the failures.
- Audit: log every API call (time, prompt, response, image URL, file size) so problems can be traced.

I pick out the bad images (wrong proportions, blurry) and regenerate them together; no need to rerun the whole batch. This is the payoff of pinning the process down: a rerun is just another API call, nearly zero cost. If an AI agent reran the whole pipeline every time, tokens would be wasted on duplicated work.

---

## The Intermediate Output Is the Protocol

The whole pipeline runs because of that four-column table.

The table is the contract between human and AI. It's also the input protocol for every script. The script doesn't know "stories"; it knows "page number, prompt". AI output must land in this format before the script can touch it.
Two payoffs:

**Change once, everything updates.** Want to add a new word to PP01? Edit the story text in that row, regenerate images, recount words. The other 9 stories are untouched.

**Verification has a basis.** The table itself is the checklist: count rows for pages, count cells for words.

Day 10 said GCO output must be explicit. At the project level, the explicit output is this table. The clearer the format, the easier the downstream scripts.

---

## Turning the Script into a Tool

After the pipeline works, the script is still at the "edit code every run" stage: input path hardcoded, model name hardcoded, output dir hardcoded. A new story set means editing code.

Two changes turn it into a reusable tool:

**Command-line arguments.** Use argparse to make the changeable options parameters:

```python
import argparse

parser = argparse.ArgumentParser(description="Generate picture book illustrations in batch")
parser.add_argument("--input", required=True, help="Story Markdown path")
parser.add_argument("--output", default="static/images", help="Image output directory")
parser.add_argument("--story", help="Only generate one story, e.g. pp01")
parser.add_argument("--pages", help="Only generate specific pages, e.g. 3,5")
args = parser.parse_args()
print(f"Processing {args.input}...")
```

Then batch runs:

```bash
python batch_generate.py --input pp-storybook-complete.md

# pp01 pages 3 and 5 came out bad, regenerate just those
python batch_generate.py --input pp-storybook-complete.md --story pp01 --pages 3,5
```

Script vs tool: a script is written for one use; a tool is reusable, accepts new inputs, and can be shared.

The refactor is two steps: extract the parts that change (input path, output dir, which book, which pages) into variables, then wrap them in argparse. Ask AI to do it. It takes a few minutes. Once the tool exists, every similar task reuses it. The time and tokens saved pay for the refactor quickly.

**Config file.** Options that rarely change (API key, default model, image size) go into a config file read at startup. Change config, don't touch code.

---

## FAQ

**"I can't write scripts."**

Prompt an AI agent to write them. Describe the process with Day 10's GCO, verify the result with Day 11's methods, and the script is yours. That's how the scripts in this project were born: I described the process, AI wrote the code, I checked it.

**"Is API more expensive than a subscription?"**

It's not about which is cheaper. It's about the division of labor.

The AI agent's output is a script: think through the process for the task, write the prompts. Once the script exists, image generation becomes a fixed task. No more judgment, just call the API.

One note: a subscription is essentially an API with different billing. If the TOS doesn't forbid it, you can use a subscription to drive your own scripts and AI agents for personal use. **So the dividing line isn't pay-per-token vs subscription; it's whether the task can be pinned down: fixed tasks go through stateless API calls, the rest goes to an AI agent.**

Each new book in the project: AI writes a new script, images still get generated by script + API. The repeatable part always runs programmatically; writing the script for a task happens once.

**"Isn't this too complex?"**

Taken apart, it's two actions: AI generates structured content, scripts execute in batch. The complex part is designing constraints, and that part happens once.

---

## Today's Takeaways

- [ ] Can split tasks by "can it be pinned down"
- [ ] Understand the five pipeline steps: constraints → generate → parse → execute → verify
- [ ] Understand "the intermediate output is the protocol": a clear format makes downstream scripts easy
- [ ] Can add command-line arguments, moving from "editing code" to "changing parameters"

---

Day 13 is next: run this pipeline once by hand. Batch-generate a set of content via API, then have an AI agent review and filter it. Two tools working in relay. Feel it once and you'll know.

---

> This is Day 12 of the AI Path L1→L2 Upgrade Guide. The previous article was Day 11, output quality checks; the next is Day 13, combining both tools.
