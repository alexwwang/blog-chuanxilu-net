---
title: "kdatasrc-helper: Let AI Agents Query Financial Data Directly"
slug: "kdatasrc-helper-financial-data-skill"
date: 2026-06-21T08:00:00+08:00
draft: false
description: "kimi CLI's datasource plugin can query stock quotes, macro indicators, corporate registries, and academic papers, but calling it from an AI agent workflow is awkward. kdatasrc-helper wraps it: single query, batch parallel, auto-parse, market-aware merge. This post covers its design and usage."
tags: ["AI", "opencode", "kimi", "datasource", "financial data", "skill", "open source"]
categories: ["AI Practice"]
toc: true
cover:
  image: "cover.png"
  alt: "A terminal window emitting four data streams: stock quotes, GDP curves, corporate info, academic papers, all flowing from a single source"
  relative: true
---

## Problem: Data Sources Exist, But Agents Can't Use Them

kimi CLI's datasource plugin is a good piece of work. A-share, HK, and US stock quotes, macroeconomic indicators, corporate registries, academic paper search: six data sources covering most day-to-day investment research needs. Install it, type one command in kimi, and you get results.

But I work in opencode, not directly in kimi. When an AI agent needs to query financial data, a few things get in the way.

**Output format.** kimi's text mode returns natural language. Structured data (CSV paths, success/failure status) is buried in prose, and the agent has to guess. The stream-json mode is structured, sure, but it returns raw MCP tool JSON. The agent gets a pile of `is_success`, `notice`, and `data_preview` fields and has to parse them itself to extract the CSV file path.

**Batch queries.** Querying one stock is one command. Querying ten stocks across three markets with technical indicators by hand is impractical. You need parallel execution, independent timeouts, and unified result collection.

**Data merging.** An A+H stock query generates two files: `pingan_a.csv` and `pingan_hk.csv`. A-share and HK columns have different structures, so a straight concat misaligns. You need to identify market origin and merge correctly.

kdatasrc-helper solves exactly these problems. It is not a data source itself. It is a wrapper layer that turns kimi's datasource plugin into a tool agents can call on demand.

## What It Is

One sentence: an opencode agent skill that queries financial data via kimi CLI, auto-parses output, supports batch parallel execution and market-aware merging.

Workflow:

```
User (natural language)
  → opencode triggers kdatasrc-helper skill
    → constructs kimi CLI command (with correct params and template)
      → kimi datasource plugin queries the data source
        → returns stream-json
  → kdatasrc-parse.py parses output → structured JSON returned to agent
  → [multi-market scenario] kdatasrc-merge.py merges files
```

What the agent gets is not raw text, but structured results like `{"success": true, "csv_paths": [...], "errors": [...]}`. It does not need to understand the internal structure of stream-json, does not need to know that the CSV path is hidden in the `notice` field, does not need to manually check whether the query succeeded.

## Three Tools

### kdatasrc-parse.py: Parse stream-json

kimi's stream-json output looks like this (simplified):

```json
{"role":"tool","content":"{\"is_success\":true,\"notice\":\"数据已保存到 /tmp/kdatasrc_stock_1718083200.csv\",\"data_preview\":[...]}"}
```

The CSV path is buried in the Chinese text of the `notice` field. Manual parsing requires: extract `content` (itself a JSON string) → parse out `notice` → regex-match the file path → check `is_success` for success/failure.

kdatasrc-parse.py wraps these steps into one command:

```bash
# Parse from stdin (pipe mode)
kimi -p "查询贵州茅台(600519.SH)实时行情..." --output-format stream-json 2>/dev/null \
  | python3 kdatasrc-parse.py

# Parse from file
python3 kdatasrc-parse.py /tmp/output.ndjson

# Extract only CSV paths (quiet mode)
python3 kdatasrc-parse.py /tmp/output.ndjson --quiet
```

Output:

```json
{
  "success": true,
  "csv_paths": ["/tmp/kdatasrc_stock_1718083200.csv"],
  "market_splits": {},
  "single_paths": ["/tmp/kdatasrc_stock_1718083200.csv"],
  "has_split": false,
  "errors": []
}
```

It also handles edge cases: the content field may be double-JSON-encoded, path formats in the notice text are inconsistent (sometimes quoted, sometimes not), and non-tool message lines may be mixed into the stream-json. These pitfalls were all discovered the hard way during actual use.

### kdatasrc-batch.py: Batch Parallel Queries

Querying ten stocks one by one takes minutes. The batch tool solves two things: parallel execution and result collection.

Write a JSON config describing what to query:

```json
{
  "output_dir": "/tmp/kdatasrc_batch",
  "prompts": [
    {"prompt": "查询腾讯(0700.HK)实时行情", "label": "tencent"},
    {"prompt": "查询苹果(AAPL.US)实时行情", "label": "apple"},
    {"prompt": "查询茅台(600519.SH)实时行情", "label": "maotai"}
  ]
}
```

Run:

```bash
python3 kdatasrc-batch.py config.json --workers 4
```

By default, 4 workers run in parallel, each with an independent timeout (default 120 seconds). The `--parse` flag auto-invokes the parser after each query completes, outputting structured results.

A few design decisions worth explaining.

**Why thread pool instead of process pool?** kimi CLI is called via subprocess. The bottleneck is I/O wait (waiting for the kimi process to return), not CPU. `ThreadPoolExecutor` is sufficient. The GIL is released during subprocess calls, so threads can genuinely wait in parallel. A process pool adds serialization and IPC overhead, which is over-engineering for this scenario.

**Why 4 workers by default?** No special theoretical basis. 4 parallel kimi processes on a local dev machine won't max out resources, and response times stay reasonable. You can bump it to 8, but kimi CLI's own startup overhead and the datasource plugin's response latency are fixed bottlenecks. Beyond a certain concurrency level, throughput gains diminish.

**Label validation.** The label is used as the output filename, so `/`, `\`, and `..` must be rejected. This is not over-defensive. AI-generated config files occasionally contain path traversal characters.

**Timeout layer.** At the subprocess level, not the future level. `proc.communicate(timeout=N)` directly controls the kimi process's lifetime. On timeout, the process is killed and the result is marked as failed. Cleaner than future-level timeout, with no orphan processes.

### kdatasrc-merge.py: Market-Aware Merging

A typical A+H stock scenario: Ping An is listed on both A-shares (601318.SH) and HKEX (02318.HK). One query generates two files: `pingan_a.csv` and `pingan_hk.csv`. A-share and HK field names and data formats differ, so a straight concat causes column misalignment.

How kdatasrc-merge.py works:

```bash
# Auto-detect market suffixes
python3 kdatasrc-merge.py \
  --dir /tmp/kdatasrc_batch \
  --auto-split \
  --output /tmp/merged.csv
```

In `--auto-split` mode, it scans filenames for `_a.csv`, `_hk.csv`, `_us.csv` suffixes, determines the market for each file, and automatically adds a `market` column (A/HK/US) during merge to distinguish sources. Column differences across markets are handled by aligning headers: collect all column names that appear across all files, match by column name during write, and leave missing columns blank. It uses Python's standard `csv.DictReader` / `csv.DictWriter`, with no pandas dependency.

Without `--auto-split`, it is a plain CSV merge tool:

```bash
python3 kdatasrc-merge.py \
  --inputs a.csv b.csv c.csv \
  --output merged.csv \
  --add-market
```

## Data Source Coverage

The tool itself does not produce data. Data comes from kimi's datasource plugin. Currently supported sources:

| Data Source | Capability | Constraint |
|-------------|-----------|------------|
| `stock_finance_data` | A-share/HK/US quotes and financials | Real-time max 3 tickers, historical max 10 |
| `yahoo_finance` | Global financial data | - |
| `world_bank_open_data` | Macro indicators (189 countries, 50+ years) | Max 5 countries |
| `tianyancha` | Corporate registry info | Max 3 companies, full legal name required |
| `arxiv` | Preprint papers | - |
| `scholar` | Highly-cited papers | - |

These constraints are on the data source side, not the tool side. What the tool can do is help you spend quota wisely: batch queries resolve multiple tickers in one call, and mixed templates query multiple data types in one call.

## Template System

The skill ships with 7 query templates, loaded on demand:

| Template | Purpose |
|----------|---------|
| `stock-realtime.md` | Real-time quotes (price, change, minute candles) |
| `stock-history.md` | Historical daily/weekly candles |
| `stock-tech.md` | Technical indicators (MA/MACD/KDJ/RSI/BOLL) |
| `macro.md` | Macro indicators (GDP/CPI/population/trade) |
| `enterprise.md` | Corporate registry (shareholders/legal/patents) |
| `academic.md` | Academic papers (arxiv/scholar) |
| `batch-mixed.md` | Mixed data types in a single call, saves quota |

Templates are not mandatory. The agent can construct queries freely. What templates provide is verified prompt patterns that reduce format friction with the datasource plugin. For example, the rule that enterprise queries must use the full legal name is already baked into the template as a reminder.

## Using in opencode

Install:

```bash
cp -r skills/kdatasrc-helper ~/.config/opencode/skills/
```

No manual invocation needed after install. opencode auto-triggers via keywords:

| Keyword | Example |
|---------|---------|
| `kdatasrc` | "用 kdatasrc 查一下茅台" |
| `查股票` / `查行情` / `查财报` | "查股票贵州茅台" |
| `查宏观经济` | "查宏观经济中国 GDP" |
| `查企业工商` | "查企业工商阿里巴巴" |
| `查论文` | "查论文 transformer" |
| `datasource` / `数据源` | "datasource 查询股票" |

Include any keyword in a message and the skill loads. The agent picks up the templates and tool docs, then auto-constructs the correct kimi CLI command, parses output, and returns structured results.

## Design Principles

A few decisions run through the entire design.

**Separate tool code from prompts.** Parsing, batching, and merging are deterministic logic: regex-matching CSV paths, subprocess parallel scheduling, csv module merging. These are written in Python, not delegated to AI via prompts. The AI's job is understanding user intent, constructing query prompts, and handling edge cases. Deterministic work goes to code. Fuzzy work goes to AI.

**stream-json first.** Text mode loses information. stream-json preserves the MCP tool's original structured data. CSV paths are extracted precisely from the `notice` field. Success/failure is determined from `is_success`. You can run in text mode, but the parse results are unreliable: paths may be omitted in the narrative, status may be paraphrased. stream-json is the only output format that guarantees data integrity.

**Market-aware, not format-aware.** The core logic of the merge tool is "understanding which market a file came from", not mechanically aligning CSV columns. The `_a.csv` and `_hk.csv` suffixes are semantic signals telling the tool that these files come from different data sources with potentially different schemas. During merge, each row is tagged with its market based on the suffix, and missing columns are left blank rather than misaligned. This is why market awareness matters.

## Open Source

The project is open source on [GitHub](https://github.com/alexwwang/kdatasrc-helper) under the MIT license.

One caveat: the MIT license covers the tool code itself. All data accessed through this tool (financial quotes, macro indicators, corporate registries, academic papers, etc.) is copyrighted by the respective data sources. Usage is subject to the Kimi/Moonshot AI terms of service and the terms of the corresponding data sources. The tool provides query capability only and assumes no responsibility for the lawful use of the data.

---

> kdatasrc-helper is open source on [GitHub](https://github.com/alexwwang/kdatasrc-helper) under the MIT license.
