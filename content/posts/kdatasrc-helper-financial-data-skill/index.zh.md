---
title: "kdatasrc-helper：让 AI Agent 直接查金融数据的技能"
slug: "kdatasrc-helper-financial-data-skill"
date: 2026-06-21T08:00:00+08:00
draft: false
description: "kimi CLI 的 datasource plugin 能查行情、宏观数据、企业工商、学术论文，但在 AI agent 工作流里直接调用很别扭。kdatasrc-helper 做了一层封装：单条查询、批量并行、自动解析、市场感知合并。本文介绍它的设计和用法。"
tags: ["AI", "opencode", "kimi", "datasource", "金融数据", "skill", "开源"]
categories: ["AI 实践"]
toc: true
cover:
  image: "cover.png"
  alt: "终端窗口发出四股数据流——股票行情、GDP 曲线、企业信息、学术论文，统一从单一数据源涌出"
  relative: true
---

## 问题：数据源有了，但 agent 用不上

kimi CLI 的 datasource plugin 是个好东西。A 股港股美股行情、宏观经济指标、企业工商信息、学术论文检索，六个数据源，覆盖了日常投研的大部分需求。安装之后在 kimi 里敲一条命令就能查。

但我平时用 opencode 工作，不是直接用 kimi。让 AI agent 去查金融数据时，碰到几个摩擦。

**输出格式。** kimi 的 text 模式输出是自然语言，结构化数据（CSV 路径、成功/失败状态）全埋在散文里，agent 需要猜。stream-json 模式倒是结构化了，但返回的是 MCP tool 的原始 JSON，agent 拿到一堆 `is_success`、`notice`、`data_preview` 字段，得自己解析才能提取出 CSV 文件路径。

**批量查询。** 查一只股票是一条命令。查十只股票、跨三个市场、带技术指标，手动一条条敲不现实。需要并行执行、独立超时、统一收集结果。

**数据合并。** A+H 股的查询会生成两个文件：`pingan_a.csv` 和 `pingan_hk.csv`。A 股和港股的列结构不同，直接 concat 会有列对不齐的问题。需要识别市场来源、正确合并。

kdatasrc-helper 解决的就是这几个问题。它本身不是数据源，是一层封装，把 kimi datasource plugin 的能力变成 agent 可以按需调用的工具。

## 它是什么

一句话：一个 opencode agent skill，通过 kimi CLI 查询金融数据，自动解析输出，支持批量并行和市场感知合并。

工作流程：

```
用户（自然语言）
  → opencode 触发 kdatasrc-helper skill
    → 构造 kimi CLI 命令（带正确参数和模板）
      → kimi datasource plugin 查询数据源
        → 返回 stream-json
  → kdatasrc-parse.py 解析输出 → 结构化 JSON 返回给 agent
  → [多市场场景] kdatasrc-merge.py 合并文件
```

agent 拿到的不是一堆原始文本，而是 `{"success": true, "csv_paths": [...], "errors": [...]}` 这样的结构化结果。它不需要理解 stream-json 的内部结构，不需要知道 `notice` 字段里藏着 CSV 路径，不需要手动判断查询是否成功。

## 三个工具

### kdatasrc-parse.py：解析 stream-json

kimi 的 stream-json 输出长这样（简化）：

```json
{"role":"tool","content":"{\"is_success\":true,\"notice\":\"数据已保存到 /tmp/kdatasrc_stock_1718083200.csv\",\"data_preview\":[...]}"}
```

CSV 路径藏在 `notice` 字段的中文文本里。手动解析需要：提取 `content`（本身是 JSON 字符串）→ 解析出 `notice` → 正则匹配文件路径 → 检查 `is_success` 判断成功/失败。

kdatasrc-parse.py 把这些步骤封装成一个命令：

```bash
# 从 stdin 解析（管道模式）
kimi -p "查询贵州茅台(600519.SH)实时行情..." --output-format stream-json 2>/dev/null \
  | python3 kdatasrc-parse.py

# 从文件解析
python3 kdatasrc-parse.py /tmp/output.ndjson

# 只提取 CSV 路径（安静模式）
python3 kdatasrc-parse.py /tmp/output.ndjson --quiet
```

输出：

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

它还处理了边界情况：content 字段可能被双重 JSON 编码，notice 文本中的路径格式不统一（有时带引号，有时不带），stream-json 中可能混入非 tool 类型的消息行。这些坑都是在实际使用中踩过才加进去的。

### kdatasrc-batch.py：批量并行查询

查十只股票，一条条跑要等十几分钟。批量工具解决两件事：并行执行和结果收集。

配置一个 JSON 文件，描述要查什么：

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

执行：

```bash
python3 kdatasrc-batch.py config.json --workers 4
```

默认 4 个 worker 并行，每个 worker 独立超时（默认 120 秒）。支持 `--parse` 参数，在每条查询完成后自动调用解析器，输出结构化结果。

几个设计决策说一下。

**为什么用线程池而不是进程池？** kimi CLI 通过 subprocess 调用，瓶颈是 I/O 等待（等 kimi 进程返回），不是 CPU 计算。`ThreadPoolExecutor` 够用。subprocess 调用期间 GIL 被释放，线程可以真正并行等待。用进程池反而多了序列化和 IPC 开销，对这个场景过度设计。

**为什么默认 4 个 worker？** 没有特殊的理论依据。4 个并行 kimi 进程在本地开发机上不会吃满资源，响应也不会太慢。可以手动调到 8，但 kimi CLI 本身的启动开销和 datasource plugin 的响应延迟摆在那里，并发数超过一定值后吞吐提升有限。

**label 的安全校验。** label 用作输出文件名，必须禁止 `/`、`\`、`..`。这不是过度防御。AI 生成的配置文件偶尔会包含路径穿越字符。

**超时在哪一层？** 在 subprocess 层，不是 future 层。`proc.communicate(timeout=N)` 直接控制 kimi 进程的生存时间，超时后进程被 kill，结果标记为失败。比 future 级超时更干净，不会留下孤儿进程。

### kdatasrc-merge.py：市场感知合并

A+H 股查询的典型场景：中国平安同时在 A 股（601318.SH）和港股（02318.HK）上市。一次查询生成两个文件：`pingan_a.csv` 和 `pingan_hk.csv`。A 股和港股的字段名、数据格式有差异，直接 concat 会导致列错位。

kdatasrc-merge.py 的工作方式：

```bash
# 自动检测市场后缀
python3 kdatasrc-merge.py \
  --dir /tmp/kdatasrc_batch \
  --auto-split \
  --output /tmp/merged.csv
```

`--auto-split` 模式下，它扫描文件名中的 `_a.csv`、`_hk.csv`、`_us.csv` 后缀，为每个文件判定市场归属，合并时自动添加 `market` 列（A/HK/US）区分来源。不同市场的列差异通过统一 header 对齐处理：先收集所有文件中出现过的全部列名，写入时按列名匹配，缺失的列留空。用的是 Python 标准库 `csv.DictReader` / `csv.DictWriter`，不依赖 pandas。

不使用 `--auto-split` 时，它就是一个纯粹的 CSV 合并工具：

```bash
python3 kdatasrc-merge.py \
  --inputs a.csv b.csv c.csv \
  --output merged.csv \
  --add-market
```

## 数据源覆盖

工具本身不产生数据，数据来自 kimi 的 datasource plugin。当前支持的数据源：

| 数据源 | 能力 | 约束 |
|--------|------|------|
| `stock_finance_data` | A 股/港股/美股行情财务 | 实时最多 3 ticker，历史最多 10 |
| `yahoo_finance` | 全球金融数据 | — |
| `world_bank_open_data` | 宏观经济（189 国，50 年+） | 最多 5 个国家 |
| `tianyancha` | 企业工商信息 | 最多 3 家，须用企业全称 |
| `arxiv` | 预印本论文 | — |
| `scholar` | 高引文献 | — |

约束是数据源侧的限制，不是工具的限制。工具能做的是帮你把配额用在刀刃上：批量查询一次解决多个 ticker，混合模板一次查多种数据类型。

## 模板系统

skill 内置了 7 个查询模板，按场景加载：

| 模板 | 用途 |
|------|------|
| `stock-realtime.md` | 实时行情（价格、涨跌幅、分钟K） |
| `stock-history.md` | 历史日K线、周K线 |
| `stock-tech.md` | 技术指标（MA/MACD/KDJ/RSI/BOLL） |
| `macro.md` | 宏观经济（GDP/CPI/人口/贸易） |
| `enterprise.md` | 企业工商（股东/司法/专利） |
| `academic.md` | 学术论文（arxiv/scholar） |
| `batch-mixed.md` | 单次调用混合多种数据类型，省配额 |

模板不是必须使用的。agent 可以自由构造查询。模板的作用是提供经过验证的 prompt 模式，减少和 datasource plugin 的格式摩擦。比如企业查询必须用全称这条规则，模板里已经写死了提醒。

## 在 opencode 中使用

安装：

```bash
cp -r skills/kdatasrc-helper ~/.config/opencode/skills/
```

安装后不需要手动调用。opencode 通过关键词自动触发，常用的中文关键词：

| 关键词 | 示例 |
|--------|------|
| `kdatasrc` | "用 kdatasrc 查一下茅台" |
| `查股票` / `查行情` / `查财报` | "查股票贵州茅台" |
| `查宏观经济` | "查宏观经济中国 GDP" |
| `查企业工商` | "查企业工商阿里巴巴" |
| `查论文` | "查论文 transformer" |
| `datasource` / `数据源` | "datasource 查询股票" |

消息里包含任意一个关键词，skill 就会加载。agent 拿到模板和工具说明后，自动构造正确的 kimi CLI 命令、解析输出、返回结构化结果。

## 设计原则

几条决策贯穿了整个设计。

**工具代码和 prompt 分离。** 解析、批量、合并是确定性逻辑：正则匹配 CSV 路径、subprocess 并行调度、csv 模块合并。这些用 Python 写，不用 prompt 让 AI 去做。AI 的职责是理解用户意图、构造查询 prompt、处理异常情况。确定性的事交给代码，模糊的事交给 AI。

**stream-json 优先。** text 模式丢信息。stream-json 保留 MCP tool 的原始结构化数据，CSV 路径从 `notice` 字段精确提取，成功/失败从 `is_success` 判定。用 text 模式也能跑，但解析结果不可靠：路径可能在叙述中被省略，状态可能被改写。stream-json 是唯一能保证数据完整性的输出格式。

**市场感知而非格式感知。** 合并工具的核心逻辑在于"理解文件来自哪个市场"，而不是机械地对齐 CSV 列。`_a.csv` 和 `_hk.csv` 的后缀是语义信号，告诉工具这些文件来自不同的数据源、可能有不同的 schema。合并时根据后缀为每行打上市场标签，缺失的列留空而不是错位。这是市场感知带来的正确性保证。

## 开源

项目已在 [GitHub](https://github.com/alexwwang/kdatasrc-helper) 开源，MIT 协议。

有一点需要说明：MIT 协议覆盖的是工具代码本身。通过本工具访问的所有数据（金融行情、宏观经济、企业工商、学术论文等）版权归各自数据源所有，使用受 Kimi/Moonshot AI 服务条款及相应数据源条款约束。工具只提供查询能力，不对数据的合法使用承担责任。

---

> kdatasrc-helper 项目在 [GitHub](https://github.com/alexwwang/kdatasrc-helper) 开源，MIT 协议。
