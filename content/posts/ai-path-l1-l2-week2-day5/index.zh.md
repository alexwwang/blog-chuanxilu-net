---
title: "Day 5 练习：让脚本读懂更多格式的文件"
slug: "ai-path-l1-l2-week2-day5"
date: 2026-06-12T07:00:00+08:00
draft: false
description: "L1→L2 第二周配套练习 Day 5：扩展 Part 2 的脚本，让它能读取 PDF、Word、CSV 等多种格式文件，不再只限于 .md 和 .txt。"
tags: ["AI", "工具链", "教程", "API", "Python"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: "cover.jpeg"
  alt: "水彩插画：各种文件（PDF、Word、CSV）像积木一样被投入一个漏斗，另一端流出整齐的文本"
  relative: true
---

> 这是「AI 之路进阶升级指南」第二周 Day 5 的配套练习。你需要先读完 [Part 2](../ai-path-l1-l2-week1-day4/)，再回来动手。

[Part 2](../ai-path-l1-l2-week1-day4/) 的 `batch_summarize.py` 能批量处理 `.md` 和 `.txt` 文件。但真实文件远不止这两种。PDF 报告、Word 合同、CSV 数据表、JSON 配置文件——它们就在你的桌面上，脚本却读不了。

今天做一件事：**写一个 `read_file()` 函数，根据文件后缀自动选择读取方式，接进 Part 2 的批量脚本。**

---

## 安装新的读取库

读 `.txt` 和 `.md` 只需要 Python 内置的 `open()`。读 PDF、Word 等格式需要第三方库。

在项目目录下执行：

```bash
uv add pypdf python-docx
```

`pypdf` 读 PDF（`PyPDF2` 是老名字，现在叫 `pypdf`），`python-docx` 读 Word 文档。`csv` 和 `json` 是 Python 内置模块，不用装。

---

## 逐个击破：四种格式的读取方式

### 1. PDF：pypdf

```python
from pypdf import PdfReader

def read_pdf(filepath):
    reader = PdfReader(filepath)
    text = ""
    for page in reader.pages:
        text += page.extract_text() or ""
    return text
```

PDF 的每一页是一个对象，`extract_text()` 把页面内容提取为纯文本。有些 PDF 是扫描件（图片形式的），`extract_text()` 会返回空字符串，这种需要 OCR 才能处理，今天不涉及。

### 2. Word (.docx)：python-docx

```python
from docx import Document

def read_docx(filepath):
    doc = Document(filepath)
    paragraphs = [p.text for p in doc.paragraphs]
    return "\n".join(paragraphs)
```

Word 文档的内容按段落存储。这里只读正文段落，不读表格和页眉页脚。对于大多数文档来说够用了。

### 3. CSV：csv 模块（内置）

```python
import csv

def read_csv(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        rows = list(reader)
    # 把每行拼成字符串，用 | 分隔
    return "\n".join(" | ".join(row) for row in rows)
```

CSV 的本质是表格。把每行用 `|` 连接，AI 就能理解成结构化文本。如果 CSV 包含中文，`encoding="utf-8"` 别漏。

### 4. JSON：json 模块（内置）

```python
import json

def read_json(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    return json.dumps(data, ensure_ascii=False, indent=2)
```

`json.load()` 把文件解析成 Python 对象（字典或列表），`json.dumps()` 再转回可读字符串。`ensure_ascii=False` 保证中文不会被转义成 `\uXXXX`——如果忘了加这个参数，你看到的会是一堆 `\u4f60\u597d`。

---

## 合成一个统一函数

现在把四种格式装进一个函数，根据文件后缀自动分派：

```python
import os
import csv
import json
from pypdf import PdfReader
from docx import Document

def read_file(filepath):
    """根据文件后缀自动选择读取方式，返回纯文本"""
    ext = os.path.splitext(filepath)[1].lower()

    if ext in (".txt", ".md"):
        with open(filepath, "r", encoding="utf-8") as f:
            return f.read()

    elif ext == ".pdf":
        reader = PdfReader(filepath)
        text = ""
        for page in reader.pages:
            text += page.extract_text() or ""
        return text

    elif ext == ".docx":
        doc = Document(filepath)
        return "\n".join(p.text for p in doc.paragraphs)

    elif ext == ".csv":
        with open(filepath, "r", encoding="utf-8") as f:
            rows = list(csv.reader(f))
        return "\n".join(" | ".join(row) for row in rows)

    elif ext == ".json":
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        return json.dumps(data, ensure_ascii=False, indent=2)

    else:
        raise ValueError(f"不支持的格式: {ext}")
```

`os.path.splitext()` 提取后缀，`lower()` 统一小写，`if/elif` 分派到对应的读取逻辑。

---

## 接进 Part 2 的批量脚本

把 `read_file()` 替换掉 Part 2 的 `batch_summarize.py` 里的 `open(...).read()`，再把文件匹配从 `*.md` + `*.txt` 扩展到更多格式。完整脚本如下：

```python
import os
import glob
import csv
import json
from dotenv import load_dotenv
from openai import OpenAI
from pypdf import PdfReader
from docx import Document

load_dotenv()

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    raise ValueError("未设置 DEEPSEEK_API_KEY，请检查 .env 文件。")

client = OpenAI(
    api_key=api_key,
    base_url="https://api.deepseek.com"
)

def read_file(filepath):
    """根据文件后缀自动选择读取方式"""
    ext = os.path.splitext(filepath)[1].lower()

    if ext in (".txt", ".md"):
        with open(filepath, "r", encoding="utf-8") as f:
            return f.read()

    elif ext == ".pdf":
        reader = PdfReader(filepath)
        return "".join(page.extract_text() or "" for page in reader.pages)

    elif ext == ".docx":
        doc = Document(filepath)
        return "\n".join(p.text for p in doc.paragraphs)

    elif ext == ".csv":
        with open(filepath, "r", encoding="utf-8") as f:
            rows = list(csv.reader(f))
        return "\n".join(" | ".join(row) for row in rows)

    elif ext == ".json":
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        return json.dumps(data, ensure_ascii=False, indent=2)

    else:
        raise ValueError(f"不支持的格式: {ext}")

def summarize_file(input_path, output_dir):
    """读取文件，调用 API 总结，保存结果"""
    content = read_file(input_path)

    if not content.strip():
        print("跳过（内容为空）")
        return

    response = client.chat.completions.create(
        model="deepseek-v4-flash",
        messages=[
            {"role": "system", "content": "你是一个文档总结助手。请用3个简洁的要点总结用户提供的文本。"},
            {"role": "user", "content": content}
        ],
        temperature=0.3,
        max_tokens=500
    )

    filename = os.path.splitext(os.path.basename(input_path))[0] + ".md"
    output_path = os.path.join(output_dir, filename)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(response.choices[0].message.content)

def main():
    input_dir = "documents"
    output_dir = "summaries"

    if not os.path.exists(input_dir):
        print(f"错误：找不到输入目录 '{input_dir}'")
        return

    # 匹配所有支持的格式
    extensions = ["*.txt", "*.md", "*.pdf", "*.docx", "*.csv", "*.json"]
    files = []
    for ext in extensions:
        files += glob.glob(os.path.join(input_dir, ext))

    if not files:
        print(f"错误：'{input_dir}' 里没有可处理的文件")
        return

    os.makedirs(output_dir, exist_ok=True)

    print(f"准备处理 {len(files)} 个文件...")
    print(f"输入: {input_dir}/")
    print(f"输出: {output_dir}/")
    print("-" * 40)

    for i, filepath in enumerate(files, 1):
        filename = os.path.basename(filepath)
        print(f"[{i}/{len(files)}] {filename}", end=" ")

        try:
            summarize_file(filepath, output_dir)
            print("OK")
        except Exception as e:
            print(f"失败: {e}")
            continue

    print("-" * 40)
    print(f"完成！结果保存在 {output_dir}/")

if __name__ == "__main__":
    main()
```

改动集中在三处：

**读取方式。** `summarize_file()` 里的 `open(...).read()` 换成了 `read_file(input_path)`，函数会根据后缀自动选择读取逻辑。

**文件匹配。** `glob.glob()` 的匹配列表从 `*.md` + `*.txt` 扩展到了 6 种格式。

**输出文件名。** 所有总结结果统一存为 `.md` 文件（`文件名.md`），不管输入是 PDF 还是 CSV。这样用 Markdown 编辑器就能直接阅读所有结果。

还有一个细节：加了 `content.strip()` 判断。有些 PDF 的文本提取结果是空的（扫描件），遇到空内容直接跳过，不浪费 API 调用。

---

## 动手试试

在 `documents/` 文件夹里放几种不同格式的文件——随便找一个 PDF、一个 Word 文档、一个 CSV 都行。然后运行：

```bash
uv run python batch_summarize.py
```

你会看到脚本自动识别了每种格式，逐个处理。到 `summaries/` 文件夹看结果。

试着加一个 `.json` 文件进去。比如创建 `documents/config.json`：

```json
{
  "name": "AI 工具箱",
  "version": "1.0",
  "features": ["批量处理", "多格式读取", "错误重试"]
}
```

再跑一次，看看 AI 怎么总结 JSON 的内容。

---

## 今天做到的事

- [ ] 安装了 `pypdf` 和 `python-docx` 两个读取库
- [ ] 学会了 PDF、Word、CSV、JSON 四种格式的读取方式
- [ ] 写了统一的 `read_file()` 函数，根据后缀自动分派
- [ ] 把它接进了 Part 2 的批量脚本，现在能处理 6 种文件格式

**下一步**：Day 6 选一个真实场景（翻译、摘要、改写），跑通完整的批量处理流程。

---

*脚本跑不起来？先看错误信息（不要贴 API Key），检查 .env 文件位置、文件夹名、网络连接。*
