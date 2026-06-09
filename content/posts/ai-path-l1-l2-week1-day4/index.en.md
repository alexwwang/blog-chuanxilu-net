---
title: "AI Path L1→L2 Upgrade Guide (2): From One Call to Batch Processing: Let Your Program Do 100 Tasks"
slug: "ai-path-l1-l2-week1-day4"
date: "2026-06-09T07:00:00+08:00"
draft: false
description: "Part 2 of the AI Path L1→L2 Upgrade Guide: learn to read files with Python, call the API, save results, then loop through an entire folder to build a complete script that auto-summarizes 100 documents."
tags: ["AI", "toolchain", "tutorial", "API", "Python"]
categories: ["ai-path"]
toc: true
series: ["AI Path L1→L2 Upgrade Guide"]
cover:
  image: "cover.jpeg"
  alt: "Watercolor illustration: a conveyor belt feeding stacks of paper into a machine, with sorted summary sheets coming out the other end"
  relative: true
---

> This is Part 2 of the "AI Path L1→L2 Upgrade Guide" series. Complete [Part 1](../ai-path-l1-l2-week1/) and the first three days of exercises ([Day 1](../ai-path-l1-l2-week1-day1/), [Day 2](../ai-path-l1-l2-week1-day2/), [Day 3](../ai-path-l1-l2-week1-day3/)) before continuing.

Part 1 taught you to make one API call. Today we're going bigger: make your program ask AI a hundred questions.

Manually pasting text into a chat window a hundred times is grunt work. Writing a ten-minute script that does it for you is leverage. You get the time back.

We'll cover three things today: reading files, writing loops, and putting it all together into a script that processes an entire folder of documents.

---

## File I/O + API: Feeding Data to the API

The code in Part 1 hardcoded the question right in the source (`content="Hello..."`). That works for learning, but real tasks don't look like that. You might need to process 10 meeting notes or 50 pieces of user feedback, all stored in files. Your program needs to read those files, send the content to the API, and save the response.

Think of it this way. Hardcoding the question is like talking to AI face to face, one sentence at a time. Reading from a file is like handing AI a stack of papers and saying "read these first." Writing the response to a file means you can come back and read the answer later without the chat window.

Start with the simplest version: read one file, send it to the API, save the reply.

Create `read_file_api.py` in your project directory:

```python
import os
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

# Read file content
with open("input.txt", "r", encoding="utf-8") as f:
    file_content = f.read()

# Send file content to AI
response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=[
        {"role": "user", "content": f"Summarize the following in 3 bullet points:\n\n{file_content}"}
    ]
)

# Get AI's reply
summary = response.choices[0].message.content

# Write reply to a new file
with open("output.txt", "w", encoding="utf-8") as f:
    f.write(summary)

print("Summary saved to output.txt")
```

Create a test file `input.txt` in the same directory with some sample content:

```
The team discussed three topics today: first, the Q3 product roadmap needs to be finalized two weeks early; second, tech debt cleanup is conflicting with feature development and needs coordination; third, the new hire onboarding process has too many steps, making the first two weeks very inefficient.
```

Run it:

```bash
uv run python read_file_api.py
```

When you see "Summary saved to output.txt", open `output.txt` and check the content. That flow, read then process then write, is the backbone of every batch processing script you'll ever write.

A few details worth knowing:

- `encoding="utf-8"` is not optional. Python's default encoding varies across operating systems. Without it, non-ASCII characters may get garbled.
- `with open(...)` is a context manager. The file closes automatically when the block ends, so you don't need to call `f.close()` yourself.
- The `f"...{file_content}"` in the prompt is an f-string, Python's most convenient way to format strings. It plugs the variable right into the string.

Try swapping `input.txt` with any text file of your own and see what the summary looks like. You can also change the prompt. Replace "Summarize the following in 3 bullet points" with "Extract action items from the following" or "Translate the following into Chinese" and watch how the output changes.

---

## Loops + Batch Processing: The Core of Automation

The previous section handled one file. What if a folder has 10? You could copy-paste the code 10 times, changing the filename each time. Obviously not. Use a loop to iterate through the folder and let the program handle each file.

Python has two common ways to list files: `os.listdir()` and `glob`. `glob` is more flexible because it supports wildcards to match specific file types. I recommend it.

Create `batch_basic.py` in your project directory:

```python
import os
import glob
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

# Get all .txt files
input_files = glob.glob("input/*.txt")
print(f"Found {len(input_files)} files")

# Make sure output directory exists
os.makedirs("output", exist_ok=True)

# Process each file
for i, filepath in enumerate(input_files, 1):
    filename = os.path.basename(filepath)
    print(f"\nProcessing {i}/{len(input_files)}: {filename}")

    # Read file
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Call API
    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[
            {"role": "user", "content": f"Summarize the following in 3 bullet points:\n\n{content}"}
        ]
    )

    # Save result
    summary = response.choices[0].message.content
    output_path = os.path.join("output", filename)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(summary)

print(f"\nAll done! {len(input_files)} files processed")
```

Before running, prepare some test data:

```bash
mkdir -p input
echo "Content of meeting note one..." > input/meeting_01.txt
echo "Content of meeting note two..." > input/meeting_02.txt
echo "Content of meeting note three..." > input/meeting_03.txt
```

Of course, you can put your own real `.txt` or `.md` files in the `input/` folder instead. Then run:

```bash
uv run python batch_basic.py
```

You'll see output like this:

```
Found 3 files

Processing 1/3: meeting_01.txt
Processing 2/3: meeting_02.txt
Processing 3/3: meeting_03.txt

All done! 3 files processed
```

Open the `output/` folder. Each input file has a corresponding output file.

`glob.glob("input/*.txt")` returns all matching file paths. Change `"*.txt"` to `"*.md"` to process Markdown files instead. `enumerate(input_files, 1)` adds a counter to the loop, starting at 1. `os.path.basename(filepath)` extracts just the filename from the full path.

One thing about speed: this script calls the API one after another, which is serial processing. With 10 files and roughly 2 seconds per request, the whole thing takes about 20 seconds. Day 6 covers parallel processing (sending multiple requests at once), but serial is simpler, more stable, and easier to debug. Learn serial first.

Try changing `glob.glob("input/*.txt")` to `"input/*.md"`, put a few Markdown files in `input/`, and run it again.

---

## Complete Script: Batch Summarize Documents

The previous two sections built up the pieces. Now we assemble them into something you'd actually use. The scenario is simple: you have a folder of documents, and you want AI to generate a summary for each one, saving the results to a new folder.

Meeting notes, article drafts, user feedback, research notes. Any collection of text files works.

Create `batch_summarize.py`:

```python
import os
import glob
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

def summarize_file(input_path, output_dir):
    """Read a single file, call API for summary, save result"""
    # Read original
    with open(input_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Call API
    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[
            {"role": "system", "content": "You are a document summarizer. Summarize the user's text in 3 concise bullet points."},
            {"role": "user", "content": content}
        ],
        temperature=0.3,
        max_tokens=500
    )

    # Save result
    filename = os.path.basename(input_path)
    output_path = os.path.join(output_dir, filename)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(response.choices[0].message.content)

def main():
    input_dir = "documents"
    output_dir = "summaries"

    # Check input directory
    if not os.path.exists(input_dir):
        print(f"Error: input directory '{input_dir}' not found")
        print("Create a folder and put your documents in it")
        return

    # Get files to process
    files = glob.glob(os.path.join(input_dir, "*.md"))
    files += glob.glob(os.path.join(input_dir, "*.txt"))

    if not files:
        print(f"Error: no .md or .txt files in '{input_dir}'")
        return

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    print(f"Preparing to process {len(files)} files...")
    print(f"Input:  {input_dir}/")
    print(f"Output: {output_dir}/")
    print("-" * 40)

    # Batch process
    for i, filepath in enumerate(files, 1):
        filename = os.path.basename(filepath)
        print(f"[{i}/{len(files)}] {filename}", end=" ")

        try:
            summarize_file(filepath, output_dir)
            print("OK")
        except Exception as e:
            print(f"FAILED: {e}")
            continue

    print("-" * 40)
    print(f"Done! Results saved in {output_dir}/")

if __name__ == "__main__":
    main()
```

Usage:

1. Create the input folder: `mkdir documents`
2. Copy your `.md` or `.txt` files into it
3. Run: `uv run python batch_summarize.py`
4. Check the `summaries/` folder for results

This script has a few upgrades over the previous version:

**Breaking it into functions.** `summarize_file()` wraps the full "read, call, write" logic. `main()` handles flow control. Functions keep code clear and make reuse easy.

**System prompt added.** The `messages` list now includes a `"role": "system"` entry to set the AI's identity and task rules. System prompts are billed as regular input tokens. They take up a bit of the conversation length, but they improve output quality and stability, saving you from rework. `temperature=0.3` produces more uniform summaries. `max_tokens=500` caps output length.

**Error handling.** Each file's processing is wrapped in `try/except`. One file failing won't crash the whole program. It prints the error and moves on to the next.

Expected folder structure:

```
your-project/
├── .env
├── .venv/
├── batch_summarize.py
├── documents/          # Put your originals here
│   ├── article_01.md
│   ├── article_02.md
│   └── notes.txt
└── summaries/          # Auto-generated
    ├── article_01.md
    ├── article_02.md
    └── notes.txt
```

Grab 3 to 5 of your own documents and run it. If the documents are long, keep an eye on cost. Long texts consume more input tokens. At DeepSeek V4-Flash pricing ($0.14/1M input tokens, roughly ¥1/1M), even a batch of 100 files should cost under $0.50 (roughly ¥3.60). But it adds up faster than you'd expect.

---

## Error Handling Basics: Making Scripts Resilient

Real-world scripts hit problems. Network hiccups, temporary API outages, locked files. These aren't "if" questions. They're "when." A script without error handling crashes on the first exception and forces you to start over.

The code above already wraps each file in `try/except`, but that's just a safety net. A production script needs to handle several common scenarios: network timeouts, API error responses, file I/O failures.

This section won't cover every scenario (Day 7 goes deep on that). Just two techniques you can apply right now.

**Distinguish error types**

Not all errors are equal. Network issues might resolve with a retry. An invalid API key won't. Python's exception types help you tell them apart:

```python
from openai import APIError, APITimeoutError

try:
    response = client.chat.completions.create(...)
except APITimeoutError:
    print("Request timed out, retry in a few seconds")
except APIError as e:
    print(f"API error: {e}")
except Exception as e:
    print(f"Other error: {e}")
```

**Auto-retry on network issues**

Day 7 will cover a more complete retry mechanism (with exponential backoff and max retry count). For now, a simple version:

```python
import time

def call_api_with_retry(client, **kwargs):
    """Simple retry: wait 3 seconds and try once more on failure"""
    for attempt in range(2):
        try:
            return client.chat.completions.create(**kwargs)
        except APITimeoutError:
            if attempt == 0:
                print("  Timeout, waiting 3 seconds before retry...")
                time.sleep(3)
            else:
                raise
```

Replace the direct API call in your script with this function, and momentary network blips won't kill the task.

At minimum, wrap your API calls in `try/except`. One file failing shouldn't abort an entire batch. That's the biggest mindset shift between single calls and batch processing.

One more thing you'll run into with batch processing (covered in detail on Day 7): API rate limits. Most platforms cap how many requests you can send per second. DeepSeek, for example, allows about 2 per second on the basic tier. If you have many files and the loop runs fast, you might hit the limit and get a 429 error. The quick fix for now: if you see a 429, wait a few seconds and retry. A cleaner solution comes on Day 7.

---

## What You Did Today

Read files with Python and sent them to the API. Used `glob` plus a `for` loop to batch-process an entire folder. Assembled a complete script that handles any document folder, with `try/except` to ensure one failed file doesn't bring down the whole run.

The code isn't long, but conceptually this is a real leap. Going from "make one API call" to "batch-process a folder" means you're no longer just using an API. You're building tools with one. That difference is what separates L1 from L2.

---

## Next Up

Today was backbone code. The next three days are companion exercises:

- **Day 5**: Write a script that reads multiple file formats (not just `.md` and `.txt`)
- **Day 6**: Add a progress bar and cost tracking to the batch script
- **Day 7**: Full error handling with retries, logging, and timeout control

Part 3 enters new territory: autonomous AI. Not just reading and writing files, but AI that plans its own steps, calls tools, and completes complex tasks without hand-holding.

---

*Script won't run? Read the error message first (don't paste your API key), then check your `.env` file location, folder name, and network connection.*
