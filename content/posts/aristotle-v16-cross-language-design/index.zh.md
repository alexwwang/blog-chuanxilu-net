---
title: "同一个系统，两门语言：Aristotle v1.6 架构决策的五个约束"
slug: "aristotle-v16-cross-language-design"
date: 2026-07-08T07:00:00+08:00
draft: false
description: "Watchdog 在 TypeScript 里做同步拦截，Intervention 在 Python 里做策略决策，中间用一个 subprocess bridge 连接。这不是架构师画出来的，是五类约束逼出来的——运行环境、已有资产、零新基础设施、启动开销、容错要求。每个决策都不是选'最优'，是选'最不坏'。"
tags: ["AI", "TDD", "aristotle", "架构决策", "驾驭工程", "设计"]
categories: ["AI 实践", "让 AI 学会反思"]
series: ["让 AI 学会反思"]
cover:
  image: "cover.png"
  alt: "分开的左右两半建筑结构，左暖琥珀色 TypeScript 塔楼，右冷青色 Python 引擎室，中央 subprocess 桥连接，五根标柱支撑"
  relative: true
toc: true
---

> **TL;DR：** Watchdog-Intervention Bridge 的跨语言架构是被五类约束逼出来的。Watchdog 必须跟 LLM tool call 做同步拦截 → TypeScript。Intervention 必须复用已有反思引擎和规则系统 → Python。Bridge 必须零新增基础设施 → subprocess。通信不能阻塞每次 tool call → 批量而非实时。这五个决策，每一个都是在特定约束下的妥协。

上一篇文章介绍了 [Aristotle v1.6 的 Watchdog-Intervention Bridge 做了什么](/posts/2026/06/aristotle-v16-watchdog-intervention-bridge/)。这篇说设计背后的约束和取舍。

## 一个看起来奇怪的选择

Watchdog-Intervention Bridge 最显眼的设计决策是：Watchdog 用 TypeScript 写，Intervention 用 Python 写。同一个系统，两门语言。

如果只从语言偏好出发，这个选择确实有问题。跨语言意味着：

- 两套开发环境、两份依赖管理、两个测试框架，以及通信协议的序列化和解析开销。

那为什么还这么选？

每个决策背后都有一组约束。最终方案是在这些约束下做的妥协，不存在脱离上下文的最优解。

## 约束一：Watchdog 必须同步

Watchdog 的逻辑是在 LLM 的 tool call 路径里做拦截。具体来说，`onToolBefore` 这个方法需要在工具调用**前**检查条件，如果违规，通过 `throw` 同步阻止工具执行。

这个需求排除了几乎所有的跨进程方案。在 tool call 路径里没法 `await` 一个远程调用的结果。每次等待都会拖住 LLM 的下一步操作。哪怕一次通信只有几毫秒延迟，累积到整条 pipeline 里就会超出可承受范围。

TypeScript 是 LLM tool call 的宿主语言。Watchdog 放在 TypeScript 侧，`onToolBefore` 可以直接读取 pipeline state，判定违规后同步 throw。调用链上不需要额外等待。

反过来，如果把 Watchdog 放在 Python 侧，每次 tool call 都需要跨进程通信才能判定违规。Python 那边的延迟还没算，光是通信开销就够让"同步拦截"这个需求变得不可行。

TypeScript 是 LLM tool call 的宿主语言，Watchdog 放在 TypeScript 侧才能做同步拦截。运行环境确定了这个方向。

## 约束二：Intervention 的资产和生态都在 Python 里

Intervention 做三类事：规则匹配、违规判定、干预策略分发。Aristotle 从 v1.0 到 v1.5 积累的规则系统、KI 文档管理、根因分析逻辑都在 Python 侧，用 pytest 写了 1166 个测试用例。

把 Intervention 放在 Python 侧，这些资产一分不浪费。规则引擎不用重写、违规 handler 不用移植、1166 个测试直接保留。

那 Intervention 为什么不用 TypeScript？系统用两门语言的原因就在这里。

Intervention 用 Python 的好处有两个。零重写成本：1166 个测试用例、规则引擎、违规 handler、KI 文档管理全部保留。然后是 pytest 的 parametrize 和 fixture 生态。pytest 的 `@pytest.mark.parametrize` 可以叠放多个 decorator 生成参数的笛卡尔积，fixture 支持依赖注入和自动 teardown。13 种违规类型做组合测试时，这套机制写起来很紧凑。Vitest 的 `it.each` 只支持单层参数化，做不到叠放；fixture 也没有直接对应物。

Intervention 用 TypeScript 的好处是开发体验统一：单一语言，没有跨语言通信；一个开发环境，一份依赖管理。

这是一个一次性成本和持续成本的权衡。重写 1166 个测试是一次性的大成本，而跨语言通信是持续但可管理的成本：Bridge 只在 checkpoint 触发，每轮交互一次，频率足够低。

Intervention 是作为 MCP 工具暴露的。MCP 同时有 TypeScript SDK 和 Python SDK。它的 subprocess 协议让通信模式不依赖语言。如果 Intervention 保持 MCP 工具的形式，无论用 Python 还是 TypeScript，和 Watchdog 的通信方式都是 subprocess，延迟和稳定性特征没有差别。按这个架构设计，通信成本由 MCP 协议决定，跟语言选择无关。

资产复用的收益超过了跨语言维护的成本。

## 约束三：零新增基础设施

跨语言连接有几种常见方案：

- **IPC（Unix domain socket / named pipe）：** 需要管理 socket 生命周期、处理重连、处理并发。
- **HTTP server：** 需要启动一个轻量 server，管理端口、处理请求排队、处理服务挂了的情况。
- **Subprocess：** 每次需要时启动子进程，执行完退出，不需要状态管理。

给一个现存项目引入 IPC 或 HTTP，就要面对新的故障模式：socket 断连、server 意外退出、端口冲突。每个问题都有标准解法，但这些复杂度会一直存在，需要持续应对。

Subprocess 是比较直接的方式。每次使用启动一个进程，执行完就退出，不需要维护状态。没有连接池，也没有端口管理。失败判断也简单：退出码非零就是失败，不需要区分是"服务挂了"还是"请求超时"。

而且 Aristotle 已经有了 `idle-handler.ts` 里的 `callMCP()` 模式，通过 subprocess 调用 Python 模块。这个模式在实际使用中表现稳定，没有必要引入新的基础设施。

Bridge 选了 subprocess，每次启动约 400ms。性能不是亮点，稳定性经过了实际运行的检验。

## 约束四：400ms 不能阻塞每次 tool call

Subprocess 每次启动约 400ms。如果每次 tool call 都启动 subprocess 跟 Python Intervention 通信，累积的延迟会让 pipeline 响应时间变得不可接受。

这就需要一个缓存策略。违规信号先在 TypeScript 侧缓存到 audit log，等 checkpoint 调用时再批量发送给 Python。

这里有一个技术前提：`onToolBefore` 的判定不需要异步等待 Python。它自己就能判定违规并直接 `throw`。只有干预决策（quarantine / rollback / suspend / instruct）需要 Python 处理，而且这些决策不需要在 tool call 路径里实时完成。

1. `onToolBefore` / `onToolAfter` 同步检测违规，信号写入 audit log。
2. `tdd_checkpoint` 调用时，violation gate 批量读取 audit log，通过 subprocess 发送给 Python。
3. Python 返回 `InterventionResult`，TypeScript 应用决策。
4. 零违规时零额外开销：没有信号就不启动 subprocess。

400ms 的开销决定了必须用批量方式。

## 约束五：MCP 的工作模式让跨语言不额外引入风险

Intervention 选 Python 而不选 TypeScript，会不会增加系统复杂度？

不会。因为 Intervention 是作为 MCP 工具暴露的。MCP 工具的运行模型就是 subprocess：主进程发起请求，子进程执行，返回结果后退出。请求超时或进程崩溃，返回空结果，主进程自己决定怎么处理。这套契约和跨语言通信天然匹配。

落实到架构上：

- Bridge 的 subprocess 调用失败时返回空 envelope，TypeScript 侧按 MCP 协议处理。这是 MCP 工具的标准行为，并非给 Python 做的特殊容错。
- Watchdog 的 violation gate 在 TS 侧独立运行，它写入 audit log 时并不需要确认 Python 是否存活。subprocess 失败只影响干预决策的完整性，不影响拦截的有效性。
- 不管 Intervention 用 Python 还是 TypeScript，它和 Watchdog 之间都有一层 MCP 协议的调用边界。这套协议已经定义了失败处理方式。

"跨语言加高了系统复杂度"这个说法忽略了 MCP 协议的作用。Intervention 选 Python，是因为 MCP 的协议已经处理好了跨语言通信。

## 额外决策：Stub-first

v1.6 新实现了 15 个 MCP 工具（从 stub 到完整实现），加上 v1.5 已有的 10 个，总数达到 25 个。这些工具有一个不那么明显的安排。

这 15 个新工具（rule lifecycle 10 个、KI doc 2 个、rollback 3 个）在开发初期以 stub 形式出现。它们列在工具列表里，但调用返回"未实现"。看起来不太像一个完整的设计。既然最终要全部实现，为什么不一次做完？

v1.6 的主线是 Watchdog-Intervention Bridge，MCP 工具只是基础设施增强。watchdog 没跑通之前，把 15 个工具全部实现完没有意义。

Stub-first 就是在 roadmap 上留个位置：AI 看到列表知道以后会有，人看到 stub 知道还没做。比直接隐藏起来、等发布了再"惊喜"要诚实。

## 设计决策的约束本质

![五个约束对应五个决策，每个柱子是一组约束→选择映射](constraints.png "五个架构约束与决策对照图")

五个决策汇总：

| 决策 | 约束 | 选了 |
|------|------|------|
| Watchdog 语言 | 同步拦截，宿主环境 | TypeScript |
| Intervention 语言 | 已有资产，测试生态 | Python |
| Bridge 方式 | 零新基础设施 | Subprocess |
| 通信模式 | 400ms 不可阻塞每次 tool call | 批量 + 缓存 |
| 容错策略 | MCP 工具模型使跨语言风险可控 | 空 envelope + 独立运行 |

这些决策都是在当时的约束下做出的，没有一个可以脱离上下文评判优劣。

方案 A 好，方案 B 也好，挑一个就行。在约束 X 下找出 A 和 B 哪个更不坏，才是设计要处理的问题。

亚里士多德把这种追求叫作"善"。在真实约束下实现一个能跑、能持续迭代的方案，这就是工程师所说的"善"。
