# llms.txt 调研与博客优化方案

> 调研日期：2026-05-26
> 目标站点：blog.chuanxilu.net
> 技术栈：Hugo + PaperMod 主题，中英双语，Cloudflare Pages 部署

---

## 1. llms.txt 是什么

### 1.1 定义

`llms.txt` 是一个放在网站根路径的 Markdown 纯文本文件（`https://domain.com/llms.txt`），为 LLM（大语言模型）提供网站内容的结构化概览。

### 1.2 与其他标准的区别

| 标准 | 受众 | 目的 | 格式 |
|---|---|---|---|
| **robots.txt** | 爬虫 | 控制访问权限 | 纯文本指令 |
| **sitemap.xml** | 搜索引擎 | 罗列所有 URL | XML |
| **llms.txt** | LLM | 提供内容摘要与导航 | Markdown |

三者互补，不冲突。robots.txt 管权限，sitemap.xml 管索引，llms.txt 管语义理解。

### 1.3 规范要求

来源：[llmstxt.org](https://llmstxt.org)，Jeremy Howard（Answer.AI / FastAI）于 2024 年 9 月提出。

**必需结构**（严格顺序）：

```markdown
# 站点/项目名称

> 1-3 句站点摘要（强烈推荐，但非必须）

[可选的补充段落]

## 分区名称

- [页面标题](https://完整URL): 一句话描述

## Optional

- [低优先级内容](https://完整URL): 描述
```

**关键规则**：
- **H1 标题是唯一必须存在的部分**（blockquote 摘要强烈推荐但非必须）
- 链接使用 Markdown 格式，描述放在冒号后
- `## Optional` 段 → AI 系统可跳过，用于缩短上下文
- UTF-8 编码
- 官方规范未规定字数/词数上限；社区最佳实践建议保持精简，以 LLM 上下文窗口容纳为准

### 1.4 llms-full.txt 变体

| 特征 | llms.txt | llms-full.txt |
|---|---|---|
| 内容 | 链接 + 短描述 | 完整页面 Markdown 正文 |
| 大小 | 1-10 KB | 100 KB 至数 MB |
| 请求数 | 需逐页抓取 | 单次请求获取全部 |
| 流量 | 中位数 4-14 次/月 | 中位数 79-248 次/月 |

> 流量数据来源：[Mintlify/Profound AI Visibility 报告](https://mintlify.com)。llms-full.txt 获取 5-10 倍于 llms.txt 的流量。ChatGPT 是主要消费者。

### 1.5 行业采用情况

已部署的知名站点：Anthropic、Stripe、Cloudflare、Vercel、Next.js、Supabase。

实际影响数据（来源：各公司公开分享及社区报告）：
- zsky.ai：部署后 +2,700 日均 ChatGPT 会话
- Immagina Group：+25% AI 来源线索，+15% 营收
- 约 30,000-60,000 个 llms.txt 被 Google 索引

**成本**：零成本，零风险，约 30 分钟配置时间。

---

## 2. 当前博客现状评估

### 2.1 基本信息

| 维度 | 值 |
|---|---|
| 基础 URL | `https://blog.chuanxilu.net/` |
| 主题 | PaperMod |
| 语言 | 中文（默认）+ 英文 |
| 文章数 | ~48 篇 × 2 语言 ≈ 96 个页面 |
| 永久链接格式 | `/posts/:year/:month/:slug/` |
| 部署平台 | Cloudflare Pages |

### 2.2 llms.txt 状态

**当前状态：不存在。**

PaperMod 主题提供了模板文件 `themes/PaperMod/layouts/_default/llms.txt`，但 `hugo.toml` 的 `[outputs]` 配置中未包含 LLMS 输出格式，因此构建时不会生成该文件。

```toml
# 当前配置（hugo.toml 第 22-23 行）
[outputs]
  home = ["HTML", "RSS", "JSON"]
```

### 2.3 PaperMod 默认模板分析

PaperMod 模板（41 行）的核心逻辑：

```go
{{- define "llms_print_section" -}}
  {{- $section := .section -}}
  {{- $depth := .depth -}}
  {{- if or (gt (len $section.RegularPages) 0) (gt (len $section.Sections) 0) -}}
    {{- $hashes := strings.Repeat (add $depth 1) "#" }}
    {{ printf "%s %s" $hashes $section.Title }}
    {{- range $p := $section.RegularPages }}
      {{- if and (not $p.Params.searchHidden) (ne $p.Layout `archives`) (ne $p.Layout `search`) }}
- [{{ $p.Title }}]({{ $p.Permalink }})
      {{- end -}}
    {{- end -}}
    {{- range $s := $section.Sections -}}
      {{- template "llms_print_section" (dict "section" $s "depth" (add $depth 1)) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

# {{ site.Title }}

{{- range site.Sections -}}
  {{- template "llms_print_section" (dict "section" . "depth" 1) -}}
{{- end }}
```

**模板特点**：递归遍历 section、过滤 `searchHidden` / `archives` / `search` 页面、支持多级标题。

| # | 缺陷 | 影响 |
|---|---|---|
| 1 | **无 blockquote 摘要** | 缺少规范推荐的站点摘要，LLM 无法快速理解站点定位 |
| 2 | **无文章描述** | 只输出 `[标题](URL)`，缺少 `: 描述` 部分 |
| 3 | **双语混排** | 多语言模式下中英文文章混合输出，无分区 |
| 4 | **无 Optional 段** | 无法区分核心内容与辅助内容 |
| 5 | **依赖隐式排序** | Hugo `RegularPages` 默认按日期倒序，但未显式控制，行为依赖版本 |

### 2.4 已有的有利条件

| 条件 | 评估 |
|---|---|
| 文章 description 字段 | ✅ 每篇都有高质量描述，可直接复用 |
| robots.txt AI 爬虫配置 | ✅ 已允许 GPTBot、ClaudeBot、PerplexityBot 等主流 AI 爬虫 |
| 稳定的 URL 结构 | ✅ 永久链接格式固定，适合长期引用 |
| 双语内容完整 | ✅ 每篇都有中英文版本 |
| series 系列组织 | ✅ 有系列分组，可用于 llms.txt 分区 |

### 2.5 robots.txt 现状

robots.txt 已配置 AI 爬虫权限（允许 OpenAI、Anthropic、Google AI、Perplexity 等），站点 AI 可见性良好。

---

## 3. 优化方案

### 3.1 多语言架构决策（核心）

#### 背景：官方规范的态度

llmstxt.org 规范对多语言处理 **零指导**。这是当前规范的空白地带。

#### 行业实际做法调研

对知名多语言站点的 llms.txt 实际部署情况进行了调研：

| 站点 | 语言数 | 做法 | 文件数 |
|---|---|---|---|
| Vercel | 1（英语） | 单文件 | 1 |
| Stripe | 1（英语） | 单文件 | 1 |
| Anthropic | 13 | 单文件，英语为主，顶部列出所有语言可用性 | 1 |
| **Ant Design** | **2（中英）** | **按语言分文件：`llms-full.txt` / `llms-full-cn.txt`** | **2** |
| **Rebelytics 客户站** | **27** | **index + 按语言分文件：`/en/llms.txt`、`/fr/llms.txt` 等** | **28** |

> 来源：[Ant Design llms-full.txt](https://ant.design/llms-full.txt) | [Ant Design llms-full-cn.txt](https://ant.design/llms-full-cn.txt) | [Rebelytics: Creating a Scalable International llms.txt Structure](https://www.rebelytics.com/creating-a-scalable-international-llms-txt-structure-step-by-step/)

**Ant Design（中英双语）与本项目最接近**，采用按语言分文件的方案。

社区指南 [Limy.ai](https://limy.ai/blog/llms.txt-in-2026-the-full-guide) 也明确指出：

> "For multilingual sites, the convention is one per language root: `/en/llms.txt`, `/he/llms.txt`"

#### LLM 处理混合语言的能力

学术研究表明：

1. LLM **能**处理混合语言内容，任务准确率不会严重下降
2. 但不同模型对语言切换的策略**不一致**（GPT-5 跟随查询语言 >95%，Claude Opus 倾向延续上下文语言 <8%）
3. 对于翻译/语义理解任务，**平行数据（语言分离但内容对应）远优于混合代码切换内容**（BLEU 分 22.3 vs 9.8，来源：[arxiv 2601.00364](https://arxiv.org/html/2601.00364v2)）

#### 决策：Index + 双文件 + 多语言元数据

综合调研证据，采用 **三层方案**：

| 层 | 文件 | 内容 |
|---|---|---|
| **Index** | `/llms.txt`（默认语言 = 中文） | 中文文章索引 + 6 种语言的博客简介 + 链接到英文版 |
| **英文版** | `/en/llms.txt` | 英文文章索引 + 6 种语言的博客简介 + 链接到中文版 |

> Hugo 多语言机制下，默认语言（zh）的 llms.txt 生成在 `/llms.txt`，英文版生成在 `/en/llms.txt`。因此中文 index 与中文内容合并为同一个文件。

**为什么在 llms.txt 中加入 6 种语言的博客简介？**

类似 Anthropic 在其 llms.txt 顶部列出 13 种语言可用性的做法。本博客虽然只有中英双语文章，但通过在 llms.txt 中用西班牙语、日语、韩语、德语、法语描述博客内容，可以让使用这些语言的 LLM 用户发现并理解博客。成本极低（仅增加几行静态文本），但扩大了 AI 可发现性覆盖面。

### 3.2 目标结构

#### 中文版 `/llms.txt`（同时也是 index）

```markdown
# 能工智人的传习录

> 知行合一，以 AI 炼器 · 能工智人的实践笔记

This is a bilingual blog (Chinese & English) about AI practice, engineering methodology, and cognitive upgrade by Alex Wang.

Este blog bilingüe (chino e inglés) trata sobre la práctica de la IA, metodología de ingeniería y mejora cognitiva.

AIの実践、エンジニアリング手法、認知の向上に関するバイリンガルブログ（中国語・英語）です。

중국어와 영어로 된 블로그로, AI 실천, 엔지니어링 방법론, 인지 향상에 대해 다룹니다.

Dieser zweisprachige Blog (Chinesisch/Englisch) behandelt KI-Praxis, Engineering-Methodik und kognitive Weiterentwicklung.

Ce blog bilingue (chinois/anglais) porte sur la pratique de l'IA, la méthodologie d'ingénierie et l'amélioration cognitive.

## 文章

- [修不完的 bug 与逃不出的循环：AI 辅助根因诊断实战](https://blog.chuanxilu.net/posts/2026/05/ai-bug-root-cause-diagnosis/): 一次 15+ bug 上线攻坚的完整复盘，包含四轮归因、回归陷阱、以及 TDD 如何被痛苦逼出来的真实经历
- [别再把 AI 当搜索引擎了：3 个认知转变](https://blog.chuanxilu.net/posts/2026/05/ai-3-cognitive-shifts/): 通过 3 个真实场景的转变，帮你把认知转变成可落地的结果
- ...（按日期倒序，共约 48 篇）

## 系列

- [AI 之路初阶升级指南](https://blog.chuanxilu.net/series/ai-之路初阶升级指南/): 8 posts
- [让 AI 学会反思](https://blog.chuanxilu.net/series/让-ai-学会反思/): 2 posts
- ...

## Optional

- [关于](https://blog.chuanxilu.net/about/): 作者背景与博客使命
- [English version](https://blog.chuanxilu.net/en/llms.txt): English llms.txt
- [RSS 订阅](https://blog.chuanxilu.net/index.xml): 内容更新推送
```

> **注意**：以上为模板实际渲染结果的近似示例。blockquote 摘要直接取自 `hugo.toml` 的 `description` 字段。series URL 由 Hugo `urlize()` 生成，包含 CJK 字符（这是预期行为）。文章描述取自 frontmatter 的 `description` 字段。

#### 英文版 `/en/llms.txt`

```markdown
# Chuanxilu for Skilled Homo sapiens

> Unity of Knowledge and Action · A Skilled Homo sapiens' Practice Journal

知行合一、AIを以て器を練る。AI実践、エンジニアリング思考、認知アップグレードに関するバイリンガルブログ。

중국어와 영어로 된 블로그로, AI 실천, 엔지니어링 사고, 인지 업그레이드에 대해 다룹니다.

Einheit von Wissen und Handeln, geschmiedet mit KI. Ein zweisprachiger Blog über KI-Praxis, Engineering-Denken und kognitive Weiterentwicklung.

L'unité du savoir et de l'action, forgée avec l'IA. Un blog bilingue sur la pratique de l'IA, la pensée ingénierique et l'amélioration cognitive.

Unidad de conocimiento y acción, forjada con IA. Un blog bilingüe sobre práctica de la IA, pensamiento de ingeniería y mejora cognitiva.

## Posts

- [AI Bug Root Cause Diagnosis](https://blog.chuanxilu.net/en/posts/2026/05/ai-bug-root-cause-diagnosis/): A complete post-mortem of a 15+ bug release battle...
- ...

## Series

- [AI Evolution Path](https://blog.chuanxilu.net/en/series/ai-evolution-path/): ...
- ...

## Optional

- [About](https://blog.chuanxilu.net/en/about/): Author background and blog mission
- [中文版](https://blog.chuanxilu.net/llms.txt): 中文 llms.txt
- [RSS](https://blog.chuanxilu.net/en/index.xml): Content feed
```

### 3.3 需要修改的文件

| 文件 | 操作 | 说明 |
|---|---|---|
| `hugo.toml` | 修改 | 添加 LLMS 输出格式配置 |
| `layouts/_default/llms.txt` | **新建** | 自定义模板，覆盖 PaperMod 默认 |

> 注意：不再修改 `robots.txt`。`LLMs-Txt:` 指令并非 robots.txt 标准字段，也没有主流 LLM 爬虫声明支持该指令。llms.txt 的发现依赖 LLM 直接请求 `/llms.txt` 路径（这是社区约定），以及从 HTML 页面中的链接发现。

### 3.4 hugo.toml 配置变更

```toml
# 新增：输出格式定义
[outputFormats]
  [outputFormats.LLMS]
    mediaType = "text/plain"
    baseName = "llms"
    isPlainText = true
    notAlternative = true

# 修改：home outputs 添加 LLMS
[outputs]
  home = ["HTML", "RSS", "JSON", "LLMS"]

# minify 无需额外配置
# Hugo 的 minifier（tdewolff/minify）仅处理 HTML/CSS/JS/JSON/SVG/XML，
# 不处理 text/plain 输出格式。即使 hugo.toml 设置了 minifyOutput = true，
# llms.txt 的 Markdown 格式也不会被破坏。
```

### 3.5 自定义 llms.txt 模板代码

创建 `layouts/_default/llms.txt`，覆盖 PaperMod 默认模板：

```go
{{- /* llms.txt — 为 LLM 提供站点内容概览 */ -}}
{{- /* 双文件方案：每个语言独立生成，仅包含当前语言的内容 */ -}}
{{- /* Index 功能：在 blockquote 后追加多语言博客简介 */ -}}

# {{ .Site.Title }}

> {{ .Site.Params.description }}

{{ if eq .Site.Language.Lang "zh" }}
This is a bilingual blog (Chinese & English) about AI practice, engineering methodology, and cognitive upgrade by Alex Wang.
Este blog bilingüe (chino e inglés) trata sobre la práctica de la IA, metodología de ingeniería y mejora cognitiva.
AIの実践、エンジニアリング手法、認知の向上に関するバイリンガルブログ（中国語・英語）です。
중국어와 영어로 된 블로그로, AI 실천, 엔지니어링 방법론, 인지 향상에 대해 다룹니다.
Dieser zweisprachige Blog (Chinesisch/Englisch) behandelt KI-Praxis, Engineering-Methodik und kognitive Weiterentwicklung.
Ce blog bilingue (chinois/anglais) porte sur la pratique de l'IA, la méthodologie d'ingénierie et l'amélioration cognitive.
{{- else if eq .Site.Language.Lang "en" }}
知行合一、AIを以て器を練る。AI実践、エンジニアリング思考、認知アップグレードに関するバイリンガルブログ。
중국어와 영어로 된 블로그로, AI 실천, 엔지니어링 사고, 인지 업그레이드에 대해 다룹니다.
Einheit von Wissen und Handeln, geschmiedet mit KI. Ein zweisprachiger Blog über KI-Praxis, Engineering-Denken und kognitive Weiterentwicklung.
L'unité du savoir et de l'action, forgée avec l'IA. Un blog bilingue sur la pratique de l'IA, la pensée ingénierique et l'amélioration cognitive.
Unidad de conocimiento y acción, forjada con IA. Un blog bilingüe sobre práctica de IA, pensamiento de ingeniería y mejora cognitiva.
{{- end }}

{{- /* ── 文章列表（按日期倒序） ── */ -}}
{{- $posts := where .Site.RegularPages "Type" "in" (slice "posts") }}
{{- $posts = sort $posts "Date" "desc" }}

{{- if gt (len $posts) 0 }}
## {{ if eq .Site.Language.Lang "zh" }}文章{{ else }}Posts{{ end }}

{{- range $posts }}
{{- if and (not .Params.searchHidden) (ne .Layout "archives") (ne .Layout "search") }}
- [{{ .Title }}]({{ .Permalink }}): {{ .Params.description | default .Summary | plainify | truncate 120 }}
{{- end }}
{{- end }}
{{- end }}

{{- /* ── 系列分组 ── */ -}}
{{- $series := slice }}
{{- range $posts }}
{{- if .Params.series }}
{{- range .Params.series }}
{{- $series = $series | append . }}
{{- end }}
{{- end }}
{{- end }}
{{- $series = $series | uniq }}

{{- if gt (len $series) 0 }}

## {{ if eq .Site.Language.Lang "zh" }}系列{{ else }}Series{{ end }}

{{- range $s := $series }}
{{- $pages := where $posts "Params.series" "intersect" (slice $s) }}
{{- if gt (len $pages) 0 }}
{{- $first := index $pages 0 }}
- [{{ $s }}]({{ printf "/series/%s/" (urlize $s) | absLangURL }}): {{ $first.Params.description | default (printf "%d %s" (len $pages) (T "posts" | default "posts")) | plainify | truncate 100 }}
{{- end }}
{{- end }}
{{- end }}

{{- /* ── Optional 段 ── */ -}}

## Optional

{{- range where .Site.RegularPages "Type" "in" (slice "page") }}
{{- if not .Params.searchHidden }}
- [{{ .Title }}]({{ .Permalink }}): {{ .Params.description | default .Summary | plainify | truncate 120 }}
{{- end }}
{{- end }}

{{- /* ── 跨语言链接 ── */ -}}
{{- if .Site.IsMultiLingual }}
{{- range .Site.Languages }}
{{- if ne .LanguageCode $.Site.Language.LanguageCode }}
{{- $llmsPath := cond (eq .Lang $.Site.DefaultContentLanguage) "/llms.txt" (printf "/%s/llms.txt" .Lang) }}
- [{{ .LanguageName | default .Lang }} version]({{ $llmsPath | absURL }}): {{ .LanguageName | default .Lang }} llms.txt
{{- end }}
{{- end }}
{{- end }}

- [RSS]({{ "index.xml" | absLangURL }}): {{ if eq .Site.Language.Lang "zh" }}RSS 订阅{{ else }}Content feed{{ end }}
```

**模板设计要点**：

| 设计点 | 实现方式 |
|---|---|
| 站点摘要 | `.Site.Params.description`（hugo.toml 中已配置） |
| 多语言简介 | 根据当前语言（`eq .Site.Language.Lang`）输出 5 种外语描述 |
| 文章描述 | `.Params.description`，fallback 到 `.Summary`，截断 120 字符 |
| 倒序排列 | `sort $posts "Date" "desc"` 显式排序 |
| 系列分组 | 收集所有 series 值去重，描述取该系列最新文章的 description，fallback 到文章计数；URL 使用 `absLangURL` 确保英文版含 `/en/` 前缀 |
| Optional 段 | about 等独立页面 + 跨语言链接 + RSS |
| 双语隔离 | Hugo 多语言机制天然隔离，模板只操作当前语言的 `.Site` |
| 跨语言导航 | Optional 段中链接到另一语言的 llms.txt，`.LanguageName` 带 `| default .Lang` fallback |

> **实施注意**：`.LanguageName` 依赖 hugo.toml 中配置的 `languageName` 字段（当前已配置 `languageName = "中文"` 和 `languageName = "English"`）。如该字段为空，模板会 fallback 到语言代码（`zh`/`en`）。实施时需验证渲染结果。

### 3.6 llms-full.txt（可选，二期）

当前 ~48 篇 × 2 语言 ≈ 96 个页面，属于中等规模。如需提供 llms-full.txt：

```toml
[outputFormats.LLMSFull]
  mediaType = "text/plain"
  baseName = "llms-full"
  isPlainText = true
  notAlternative = true

[outputs]
  home = ["HTML", "RSS", "JSON", "LLMS", "LLMSFull"]
```

社区数据显示 llms-full.txt 流量是 llms.txt 的 5-10 倍。**建议一期先上 llms.txt，观察效果后再决定是否加 llms-full.txt**。

---

## 4. 验证清单

实施后的验证步骤：

- [ ] `hugo` 构建成功，`public/llms.txt` 已生成
- [ ] `public/en/llms.txt` 已生成（英文版）
- [ ] `curl https://blog.chuanxilu.net/llms.txt` 返回正确内容
- [ ] H1 标题存在，blockquote 摘要存在
- [ ] 多语言简介包含 6 种语言（ES/JA/KO/DE/FR）
- [ ] 每篇文章都有描述（冒号后内容）
- [ ] 文章按日期倒序
- [ ] Optional 段存在
- [ ] 中文版包含到英文版的链接，反之亦然
- [ ] Series URL 包含 CJK 字符（Hugo `urlize` 生成），与实际 `/series/` 目录匹配
- [ ] 英文版 RSS 链接指向 `https://blog.chuanxilu.net/en/index.xml`（使用 `absLangURL`）
- [ ] 英文版 series URL 包含 `/en/` 前缀（使用 `absLangURL`）
- [ ] 中文版标题显示"文章"和"系列"，英文版显示"Posts"和"Series"
- [ ] Markdown 格式未被 minify 破坏（空行保留、链接完整）
- [ ] 总大小合理（预估 < 25 KB）

---

## 5. 参考资料

### 规范与工具
- [llms.txt 官方规范](https://llmstxt.org)
- [Hugo 自定义输出格式文档](https://gohugo.io/templates/output-formats/)
- [Hugo 多语言配置](https://gohugo.io/content-management/multilingual/)
- [gethugothemes/hugo-modules/llms-txt](https://github.com/gethugothemes/hugo-modules/llms-txt)（Hugo 模块方案，本站未采用）
- [PaperMod llms.txt 模板源码](https://github.com/adityatelange/hugo-PaperMod/blob/master/layouts/_default/llms.txt)

### 多语言 llms.txt 实践
- [Rebelytics: Creating a Scalable International llms.txt Structure](https://www.rebelytics.com/creating-a-scalable-international-llms-txt-structure-step-by-step/) — 27 语言站点的分文件方案
- [Ant Design llms-full.txt](https://ant.design/llms-full.txt) / [llms-full-cn.txt](https://ant.design/llms-full-cn.txt) — 中英双语按语言分文件
- [Anthropic llms.txt](https://docs.anthropic.com/llms.txt) — 单文件列出 13 种语言可用性
- [Limy.ai: llms.txt in 2026](https://limy.ai/blog/llms.txt-in-2026-the-full-guide) — "convention is one per language root"
- [llms-full-txt.ru: Multilingual Examples](https://llms-full-txt.ru/en/examples/advanced/#multilingual-site) — 多语言站点示例

### LLM 混合语言处理研究
- [The Role of Mixed-Language Documents for Multilingual LLM Pretraining](https://arxiv.org/html/2601.00364v2) — 平行数据 vs 混合数据对翻译性能的影响
- [Query-Following vs Context-Anchoring](https://aclanthology.org/2026.mme-main.13.pdf) — LLM 跨语言切换策略差异
