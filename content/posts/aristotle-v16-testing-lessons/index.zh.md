---
title: "测试都通过了，然后 Code Review 找到 6 个 Medium：关于测试覆盖率的真相"
slug: "aristotle-v16-testing-lessons"
date: 2026-06-30T10:00:00+08:00
draft: false
description: "Python 1166 + TypeScript 约 588，共约 1754 个测试用例，覆盖了所有关键路径。全部通过。然后独立 Code Review 找到了 6 个 Medium 级问题。这不是'测试没用'的故事，是'测试和审查彼此补了对方盲区'的故事。"
tags: ["AI", "TDD", "测试", "Code Review", "质量", "aristotle"]
categories: ["AI 实践", "让 AI 学会反思"]
series: ["让 AI 学会反思"]
toc: true
---

> **TL;DR：** v1.6 有 1754 个测试，全部通过。然后 Oracle 独立审查发现了 6 个 Medium 级 bug，其中一个涉及计数逻辑在测试环境和生产环境表现不同（test-env branching）。测试和 Code Review 互为补充，不是互斥手段。测试覆盖预期中的问题，审查发现预期之外的问题。两样都做，是必要的。

在 [Watchdog-Intervention Bridge 的介绍文章](/posts/2026/06/aristotle-v16-watchdog-intervention-bridge/) 里，我把测试覆盖作为一节放在文章中段：数据、列表、一行结论。写完之后发现，测试和 Code Review 的关系比那一段话能说清的复杂得多。

v1.6.0 的测试数字：Python 侧 1166 个 pytest 覆盖 intervention 层，TypeScript 侧约 588 个测试覆盖 watchdog。共约 1754 个测试用例，从 unit 到 integration，覆盖了所有路径。

它们全部通过。

然后 Oracle（独立 AI 审查者）的 Code Review 找到了 6 个 Medium 级问题。

## 这 6 个问题是什么

Oracle 审查者发现了 6 个问题。其中一个（TDDViolationError 的计数逻辑）值得单讲，其余五个类型各异：路径遮蔽（`sys.path.insert` 可能覆盖同名包）、相对路径引起的 CWD 依赖、`run_id=0` 被 `0 or DEFAULT` 吞掉、生产分支无测试覆盖、死代码残留。

它们有一个共同点：自动化测试没有发现它们。

## 第 1 个 bug 是最有意思的

TDDViolationError 有一个 `_should_return_result` 方法，判断是否应该返回 `InterventionResult` 而不是抛出异常。

这个方法的逻辑在不同环境下表现不同：

```
测试环境（有 PYTEST_CURRENT_TEST）：返回 InterventionResult
生产环境（无 PYTEST_CURRENT_TEST）：raise TDDViolationError
```

这是有意为之的。测试时需要检查返回值，生产环境靠异常传递控制流。但问题在于 bridge 的计数逻辑需要在两条路径上都能正确分类：

- **返回结果路径：** 按 `result.success` 分类：True 计成功，False 计失败。
- **异常路径：** 从异常对象提取 `.result` 属性再计数。

初版实现只处理了异常路径，把所有 `TDDViolationError` 硬编码为 `failed`。这意味着成功执行的干预（result.success=True，但因 test-env 配置走了异常路径）被错误地计为失败。

这个 bug 中最值得关注的一点：测试看到了正确行为，但原因错了。

Pytest 环境下所有走 `_should_return_result` 返回路径的测试都通过了。但因为测试环境不存在"生产路径的 raise 行为被错误计数"的组合条件，测试和生产走了不同的代码路径。

测试和生产环境的固有差异在这里暴露了。在 pytest 里无法同时测试"返回结果"和"抛出异常"两种行为，因为必须在测试前决定 `PYTEST_CURRENT_TEST` 存在与否。

## 测试覆盖了路径，但没覆盖路径之间的偏差

1754 个测试用例做的事情很清晰：

- Python 侧覆盖 13 种违规类型、handler 分发、bridge 批量通信、audit log 缓存。
- TypeScript 侧覆盖 21 种检测信号、Interceptor/Observer 逻辑、violation gate、subprocess 容错。

分别看都很好。合在一起看，跨语言集成路径的异常组合没有被覆盖。TypeScript 发送信号、Python 返回结果、计数逻辑在异常路径下的行为，这个完整链路在自动化测试中没有端到端覆盖。

跨语言端到端测试的搭建成本远高于单侧，而且测试产出是"验证跨语言序列化/反序列化是否正确"。对于 Python 和 TypeScript 这种有成熟序列化协议的组合，出问题的概率本就不高。

但问题出在序列化和反序列化之外：在两套逻辑的执行差异上。

测试在路径内部做得很彻底。但路径之间的偏差，是另一回事。

## Code Review 在查什么

Oracle 审查者没有去跑测试。它做了两件事：

1. **读代码路径：** 跟踪 `_should_return_result` 的调用链，发现生产环境分支没被测试覆盖。
2. **找逻辑矛盾：** 计数逻辑在"返回结果"和"抛出异常"两条路径上的行为不一致。

这是测试不太擅长的事。测试验证具体行为的正确性（"给定输入 X，期待输出 Y"），审查验证逻辑的完备性（"如果有两条路径，两条都正确吗？"）。

测试枚举已知场景，审查发现未知场景。

第 4 个 bug（`run_id` 的 falsy 合并）也是同一类问题。`run_id or DEFAULT` 在 Python 里是常见写法，但 `run_id=0` 是合法值，而 `0 or DEFAULT` 在 Python 里返回 DEFAULT。这个 bug 在审查中一眼就能看出来，但单元测试很少会专门验证 `run_id=0` 的行为，因为设计者通常不会认为合法的输入值是 0。

## 测试和审查不是替代关系

我用一张对比表来理解这个问题：测试覆盖已知风险，审查覆盖未知风险，两者互为补充。

| | 测试 | Code Review |
|---|---|---|
| 优势 | 快速反馈、可重复、低成本 | 发现未预期的问题、理解上下文 |
| 劣势 | 只覆盖写了的用例 | 依赖审查者水平、耗人力 |
| 适合 | 已知的输入/输出对 | 逻辑完备性、异常组合 |

v1.6 的 6 个 bug 分布很典型：

- 测试本应发现但没发现：0 个
- 审查发现但测试不易发现：4 个
- 审查发现、测试也能发现但需要特定用例：2 个

如果 v1.6 没有测试体系，审查需要发现的问题可能是 60 个而不是 6 个。测试把已知问题降到足够少，审查者就能聚焦在未知问题上。

## 测试究竟证明了什么

1754 个测试通过了，只证明一件事：想检查的都检查了。

它们没证明的事：没想到的，依然可能出问题。

测试只能证明验证了的假设，不能证明所有假设都已找到。这是一种限制，每种质量手段都有自己的边界。

测试、审查、记录教训，三件事都要做。

没有测试，审查者会在已知问题上浪费时间，而不是聚焦在未知问题上。即使所有测试通过，独立审查者的不同视角能发现逻辑盲区。test-env branching 这类问题值得记在团队的 checklists 里，下次跨环境设计时，问自己「测试环境行为的代码路径跟生产环境一致吗？」

对于 v1.6，这三样都做了。6 个 bug 修了，遗留问题记了，本文就是"记录教训"的产物。

下一次，可能还是会有测试没发现的问题。但至少已知风险会少几个。
