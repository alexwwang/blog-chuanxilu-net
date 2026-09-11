# Day 1 动手代码：跑一遍 miniharness 的 smoke test

本目录配合博客文章《Day 1｜120 行代码读懂 Agent Loop》使用。

## 内容

- `mini_loop.py`：教学用最小 Agent Loop，约 40 行，不需要 API key，用一个写死脚本的假模型演示 loop 的核心机制：模型报错 → 错误信息回灌上下文 → 模型自我修正。直接 `python3 mini_loop.py` 运行。
- 下面的「真实版练习」：克隆 miniharness 仓库，跑一次真实的 smoke test。

## 真实版练习：miniharness smoke test

```bash
# 1. 克隆并安装（uv 或 pip 均可）
git clone https://github.com/tljcpa/miniharness
cd miniharness
uv venv && source .venv/bin/activate
uv pip install -e ".[dev]"

# 2. 配置 provider 凭证
cp .env.example .env
# 编辑 .env，至少配置一个：
#   DEEPSEEK_API_KEY=sk-...
#   KIMI_API_KEY=...
#   GLM_API_KEY=...
#   QWEN_API_KEY=...

# 3. 验证配置
miniharness list-providers

# 4. 跑 smoke test（约 $0.01）
python scripts/smoke_test.py --provider deepseek
```

预期：5-10 步，agent 创建 `greet.py`、运行它、报告成功。

## 观察清单（跑的时候盯着这三件事）

1. **上下文怎么长**：每一步模型的输入里多了什么？工具结果是以什么形式回灌的？
2. **错误怎么处理**：如果环境里只有 `python3` 没有 `python`，模型第几步发现自己错了？它是怎么发现的？（提示：没有任何 harness 代码处理这个情况，注意看工具结果里的 `stderr`。）
3. **loop 在哪一步退出**：模型调用了什么来宣告完成？如果它不调用，会发生什么？

## 进阶：复现 v0.01 消融实验

```bash
python experiments/run_ablation_v0.py
# 3 次运行，总成本约 $0.004，结果写入 experiments/results_v0.md
```

对比三种工具调用格式（`native_json` / `xml` / `prompt`）的行为差异，验证文章里「发现二」：`success=OK` 的三次运行里，有两次其实没按任务指令做完整。
