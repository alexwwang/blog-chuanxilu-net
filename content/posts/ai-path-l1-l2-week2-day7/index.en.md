---
title: "Day 7 Exercise: Add Error Handling to Your Script"
slug: "ai-path-l1-l2-week2-day7"
date: 2026-06-18T07:00:00+08:00
draft: false
description: "L1→L2 Week 2 Day 7 exercise: Add timeout retries, rate-limit backoff, and exception logging to your batch processing script so it survives real-world network conditions."
tags: ["AI", "toolchain", "tutorial", "API", "Python"]
categories: ["ai-path"]
toc: true
series: ["AI Path: Level Up Guide"]
cover:
  image: "cover.png"
  alt: "Watercolor illustration: a tidy desk with a laptop showing green progress bars and a 3/3 completion badge, files stacked on the left, fanned out on the right"
  relative: true
---

> This is the Day 7 exercise for Week 2 of the "AI Path: Level Up Guide" series. Complete [Day 6: Batch Processing Practice](../ai-path-l1-l2-week2-day6/) first.

In [Day 6](../ai-path-l1-l2-week2-day6/), you wrote a batch processing script that works. Pick a scenario, walk the folder, call the API, save the results. It all runs smoothly until you try it for real.

But that script runs in an idealized environment. Real networks are not ideal.

Have you hit any of these with your script?

- **Timeouts**: The API takes more than 60 seconds and your script crashes
- **Rate limiting**: The API returns 429 because you're sending requests too fast. Your script has no backoff logic.
- **Single-file failure**: One file fails, the whole batch stops, everything you processed before is wasted

Put together, these are the gap between "script runs" and "script works in production."

Today: **add error handling**. Timeout retries, rate-limit backoff, exception logging.

---

## Problem 1: Timeout retries

APIs time out occasionally. Network jitter, server load, cold start. Any of these can stall a request for a while. Your script should wait and retry, not bail on the first error.

```python
import time
import logging
from openai import APIConnectionError, APITimeoutError

logging.basicConfig(level=logging.INFO)

MAX_RETRIES = 3
RETRY_DELAY = 2  # seconds

def call_api_with_retry(client, prompt, text, temperature=0.3, max_tokens=500):
    """API call with retry logic."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.chat.completions.create(
                model="deepseek-v4-flash",
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": text}
                ],
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=120  # 120 second timeout
            )
            return response.choices[0].message.content
        except (APIConnectionError, APITimeoutError, TimeoutError) as e:
            if attempt == MAX_RETRIES:
                logging.error(f"API call failed after {MAX_RETRIES} retries: {e}")
                raise
            wait = RETRY_DELAY * attempt
            logging.warning(f"API call failed ({attempt}/{MAX_RETRIES}), retrying in {wait}s: {e}")
            time.sleep(wait)
```

**Exponential backoff**: First failure waits 2 seconds. Second waits 4. Third waits 6. The wait time grows because if the API is temporarily down, waiting longer makes recovery more likely.

**Only retry recoverable errors**: Network timeouts, connection errors, `TimeoutError`. These are transient. A retry might succeed. But 400 errors mean your request is wrong, and 401 means a bad key. Retrying these changes nothing.

**Set a generous timeout**: The default 30 seconds is too short. Long text processing and model cold starts can exceed that. 120 seconds is safer.

---

## Problem 2: Rate-limit handling

APIs have rate limits. Send requests too fast and the API returns a 429 status code.

If your script fires requests as fast as possible, it will almost certainly hit rate limits. Add handling logic:

```python
import time
import logging
from openai import RateLimitError

def call_api_with_rate_limit(client, prompt, text, temperature=0.3, max_tokens=500):
    """API call with rate-limit handling (teaching snippet)."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.chat.completions.create(
                model="deepseek-v4-flash",
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": text}
                ],
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=120
            )
            return response.choices[0].message.content
        except RateLimitError as e:
            if attempt == MAX_RETRIES:
                logging.error(f"Rate limited, retried {MAX_RETRIES} times: {e}")
                raise
            wait = RETRY_DELAY * attempt * 2  # Double wait for rate limits
            logging.warning(f"Rate limited ({attempt}/{MAX_RETRIES}), retrying in {wait}s: {e}")
            time.sleep(wait)
```

**Double the wait time**: After hitting a rate limit, wait longer than for a regular timeout. A rate limit is the API telling you "you're going too fast." You need to slow down more aggressively.

**Log the event**: When rate limiting hits, you should know about it. Not silently skip. Not crash. Leave a record. `logging.warning()` writes to the log so you can review how many times rate limiting occurred after the batch finishes.

---

## Problem 3: Exception logging and failure tracking

A file fails. Your script should not crash. It should log the failure reason, skip the file, and keep going. When all files are done, report which ones failed and why.

```python
import os
import json
from datetime import datetime

def process_file_safe(filepath, output_dir, prompt, results_log):
    """Safely process a single file. Log failure and skip on error."""
    filename = os.path.basename(filepath)
    try:
        result = call_api_with_retry(client, prompt, read_file(filepath))
        output_path = os.path.join(output_dir, os.path.splitext(filename)[0] + ".zh.md")
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(result)
        results_log["success"].append(filename)
        logging.info(f"Success: {filename}")
    except Exception as e:
        results_log["failed"].append({
            "filename": filename,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        })
        logging.error(f"Failed: {filename} — {e}")
```

Every failure log entry records three things: which file failed, what the error was, and when it happened. The timestamp is useful for cross-referencing with the API console at that time.

---

## The Complete Error-Handled Script

Merge all three parts into one script:

```python
import os
import glob
import re
import time
import json
import logging
from datetime import datetime
from dotenv import load_dotenv
from openai import OpenAI, APIConnectionError, APITimeoutError, RateLimitError

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("DEEPSEEK_API_KEY not set. Check your .env file.")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)

MAX_RETRIES = 3
RETRY_DELAY = 2
MAX_CHARS = 4000

def split_into_sentences(text, max_chars):
    """Split text at sentence boundaries."""
    paragraphs = text.split("\n\n")
    chunks = []
    current_chunk = ""

    for para in paragraphs:
        para = para.strip()
        if not para:
            continue
        sentences = re.split(r'(?<=[.!?。！？])\s*', para)
        for sentence in sentences:
            sentence = sentence.strip()
            if not sentence:
                continue
            if len(current_chunk) + len(sentence) > max_chars:
                chunks.append(current_chunk)
                current_chunk = sentence
            else:
                if current_chunk:
                    current_chunk += "\n\n" + sentence
                else:
                    current_chunk = sentence

    if current_chunk:
        chunks.append(current_chunk)

    return chunks

def call_api_with_retry(prompt, text, temperature=0.3, max_tokens=500):
    """API call with retry logic."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.chat.completions.create(
                model="deepseek-v4-flash",
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": text}
                ],
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=120
            )
            return response.choices[0].message.content
        except (APIConnectionError, APITimeoutError, TimeoutError, RateLimitError) as e:
            if attempt == MAX_RETRIES:
                logging.error(f"API call failed after {MAX_RETRIES} retries: {e}")
                raise
            multiplier = 2 if isinstance(e, RateLimitError) else 1
            wait = RETRY_DELAY * attempt * multiplier
            logging.warning(f"API call failed ({attempt}/{MAX_RETRIES}), retrying in {wait}s: {e}")
            time.sleep(wait)

def translate_file_safe(filepath, output_dir, results_log):
    """Safely translate a single file."""
    filename = os.path.basename(filepath)
    try:
        text = read_file(filepath)
        if not text.strip():
            logging.info(f"Skipped (empty): {filename}")
            return

        prompt = "You are a translation assistant. Translate the user-provided text to Chinese, preserving the original format."
        chunks = split_into_sentences(text, MAX_CHARS)
        translated_chunks = []

        for i, chunk in enumerate(chunks, 1):
            logging.info(f"  [{i}/{len(chunks)}] translating chunk")
            translation = call_api_with_retry(prompt, chunk)
            translated_chunks.append(translation)

        full_translation = "\n\n".join(translated_chunks)
        if len(translated_chunks) > 1:
            full_translation += f"\n\n> Note: Original text was long and translated in {len(translated_chunks)} segments."

        out_filename = os.path.splitext(filename)[0] + ".zh.md"
        output_path = os.path.join(output_dir, out_filename)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(full_translation)

        results_log["success"].append(filename)
        logging.info(f"Success: {filename}")

    except Exception as e:
        results_log["failed"].append({
            "filename": filename,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        })
        logging.error(f"Failed: {filename} — {e}")

def read_file(filepath):
    """Read file content."""
    with open(filepath, "r", encoding="utf-8") as f:
        return f.read()

def main():
    input_dir = "docs"
    output_dir = "translations"
    log_file = "results.json"

    results_log = {"success": [], "failed": []}

    if not os.path.exists(input_dir):
        logging.error(f"Input directory '{input_dir}' not found")
        return

    files = glob.glob(os.path.join(input_dir, "*.md"))
    if not files:
        logging.error(f"No .md files in '{input_dir}'")
        return

    os.makedirs(output_dir, exist_ok=True)

    logging.info(f"Preparing to process {len(files)} files...")
    logging.info(f"Input: {input_dir}/")
    logging.info(f"Output: {output_dir}/")
    logging.info("-" * 40)

    for i, filepath in enumerate(files, 1):
        filename = os.path.basename(filepath)
        logging.info(f"[{i}/{len(files)}] {filename}")
        translate_file_safe(filepath, output_dir, results_log)

    # Write results log
    with open(log_file, "w", encoding="utf-8") as f:
        json.dump(results_log, f, ensure_ascii=False, indent=2)

    logging.info("-" * 40)
    logging.info(f"Done! {len(results_log['success'])} succeeded, {len(results_log['failed'])} failed.")
    logging.info(f"Results log: {log_file}")

if __name__ == "__main__":
    main()
```

Key improvements in this script:

Use the `logging` module instead of `print`. `print` gives you output. `logging` gives you severity levels (INFO, WARNING, ERROR). After the batch finishes, review the log to find exactly where things went wrong.

Success and failure are tracked separately. After the script finishes, `results.json` tells you which files succeeded, which failed, and why.

Each file is wrapped in its own `try/except`. One failure does not prevent the rest from processing.

`APIConnectionError`, `APITimeoutError`, `TimeoutError`, `RateLimitError` all go into the retry pool. Rate limiting, timeouts, and network jitter are all transient. A retry usually recovers them.

---

## Try It

Run this script with your real files. Watch the log output.

**When everything succeeds**:

```
10:23:45 [INFO] Preparing to process 4 files...
10:23:45 [INFO] ----------------------------------------
10:23:45 [INFO] [1/4] feature-overview.md
10:23:48 [INFO]   [1/3] translating chunk
10:23:52 [INFO]   [2/3] translating chunk
10:23:56 [INFO]   [3/3] translating chunk
10:23:58 [INFO] Success: feature-overview.md
```

**When rate limited**:

```
10:24:15 [WARNING] API call failed (1/3), retrying in 4s: Rate limit exceeded
10:24:19 [INFO]   [1/3] translating chunk
```

**When it fails**:

```
10:25:30 [ERROR] Failed: broken-file.md — API call failed after 3 retries
```

Check what's in `results.json`.

---

## Advanced Challenge

Your script now handles `.md` files. But real scenarios include PDFs, Word documents, even web pages (`.html`).

Bring in the `read_file()` function from [Day 5](../ai-path-l1-l2-week2-day5/). Make it read more formats. But there's a trap: PDF files can be large. Passing a huge PDF directly to the API can trigger length limits or timeouts.

You can:

1. Add a file size check in `translate_file_safe()`. Warn for PDFs over 50KB.
2. Set per-format timeout values. Give large files longer timeouts.
3. Distinguish failure types in `results.json`. File too large vs. API failure vs. unsupported format.

---

## What You Did Today

- [ ] Understood three real-world API problems: timeouts, rate limits, single-file failures
- [ ] Added timeout retries with exponential backoff
- [ ] Added rate-limit backoff with doubled wait times
- [ ] Added exception logging and failure tracking (`results.json`)
- [ ] Understood why `logging` beats `print` for batch processing

**Next step**: The script is more robust now. Day 8 takes a different approach—no code, let AI handle automation tasks autonomously. Introduction to autonomous execution AI.

---

*Script acting up? Check `results.json` first. It records every file's outcome and failure reason.*
