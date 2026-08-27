---
title: "Day 0｜L3 启航：从工作台到极简与元架构的 Harness 演进史"
slug: "ai-path-l3-day0-harness-evolution"
date: 2026-08-25T18:00:00+08:00
draft: false
description: "AI 之路 L3 开篇：从你 L2 写过的批量脚本出发，看懂 Harness 是什么、为什么它比模型更决定成败，以及从工作台模式到 Pi 与 DeepSeek Harness 两条路线的演进。"
tags: ["AI", "教程", "Harness", "Pi", "DeepSeek Harness", "Agent"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: cover.png
  alt: "水彩风格：一座半建成的塔楼被木质脚手架环绕，未完工的楼层透出暖光，旁边立着细长的起重机剪影"
---

> 上一篇是 [Day 16｜L2 完结！下一站 Harness：驾驭工程的演进与 L3 蓝图预告](/posts/2026/08/ai-path-l1-l2-week5-day16/)。
> 确认你已经了解或掌握了 Day 16 所讨论的所有技能后，让我们从这里开始 L3 的学习吧。
>
> 本篇是 L3 的入口。后续导航：
>
> | Day | 类型 | 主题 |
> |-----|------|------|
> | Day 1 | 练习 | 120 行代码读懂 Agent Loop |
> | Day 2 | 骨干 | 约束与拦截：Hooks 与权限 |
> | Day 3 | 练习 | 用 Claude Code Hooks 做审批 |
> | Day 4 | 骨干 | 扩展与插件：Pi vs DSH |
> | Day 5 | 练习 | 写一个 Pi 扩展 |
> | Day 6 | 练习 | 用 DSH Cordis 插件组合模式 |
> | Day 7 | 骨干 | Agent Teams 与任务 DAG |
> | Day 8 | 骨干 | 记忆与学习：Hermes、Nowledge Mem、EvoMap |
> | Day 9 | 练习 | 设计自己的 Skill 系统 |
> | Day 10 | 阶段小结 | L3 毕业考核 |

---

## 先回想一下你的 Day 4 脚本

回忆一下 L2 的 Day 4，那节课我们写过一个批量处理脚本：读文件夹里的文件，逐个调 API，把结果写回去，哪一步报错了就把错误先记下来，然后继续跑。

当时你可能觉得这只是在"调 API"。现在回头看，那个脚本做的事情可真多：它决定了模型每次能看到什么（你怎么拼 prompt）、按什么顺序干活（逐个文件）、出错了怎么办（记下来继续还是停下来）。**这些"模型之外、任务之内"的决定，合起来就是一个简单的 Harness 了。**

Harness 作动词是"驾驭"，作名词原指套在马身上的挽具：把马的力量引导到要去的方向。放到 AI 上，Harness 就是把模型的能力引导到任务上的那层结构。换成工地语言，它是脚手架：不亲自砌砖，但没有它工人没法把楼按设计正确地盖起来。这里模型是干活的工人，Harness 就是脚手架。

L3 的学习目标，就是在理解的基础上，知道如何选择和构建适合自己任务的脚手架。

## 一个对照实验：脚手架值多少钱

2026 年 3 月，Anthropic 公布了一份对照实验的结果[1]：用同一个模型（Claude Opus 4.5），同一个提示词任务"做一个 2D 复古游戏编辑器，包含关卡编辑器、精灵编辑器、实体行为和可玩的测试模式。"跑实验对照，结果

没有 harness 的对照组：花费 20 分钟 9 美元，界面有模有样，精灵编辑器能点，菜单能展开，但进入试玩模式，游戏角色对操作输入没有反应，查 bug 发现是模型没有把前端交互界面和游戏运行时的接线接起来。

加上完整 harness 的实验组：花费 6 小时 200 美元，结果是真的能玩：角色能移动、能跳、能生成关卡。[1]

花的时间涨 18 倍，钱涨 22 倍，但产出从"看起来像但不能用"变成"真的能用"了，这里的关键就在那套 harness 定义的分工：三个 Agent，各自承担不同的职责。
![同一个模型同一句话：没有 harness 的街机只是看着像，有 harness 的街机真的能玩](illustration-1.png)

- **planner（规划者）**：把一句话扩展成 16 项功能的需求清单，拆成 10 步。这个工作我们在 L2 的 Day 10 做过：用 GCO 框架把"帮我分析一下"变成清晰指令，这就是 planner 的工作。
- **generator（生成者）**：一次只做一步，照着清单实现。这是 L2 Day 4 到 Day 7 介绍的让 agent 写脚本干的事。
- **evaluator（评估者）**：每步任务的代码生成完成后，它像真实用户一样做一轮检验、找 bug。这是 L2 Day 11 介绍过的输出质量检查。

在 L2 时，我们是让一个 Agent 先后承担这三种角色。但在更复杂的任务里，Anthropic 是让三个独立的 Agent 交替循环。**模型还是那个模型，但 Agent 的定义和使用方式变了。**

## Harness 是什么：三个等价定义

有了体感，再看定义。不同团队对 Harness 的组成部分定义不一样，但目标是一样的：把 LLM 从"会说话的模型"变成"能干活的 Agent"的那套结构和约束。

1. **DeepSeek 的公式**：Model + Harness = Agent。模型是大脑，Harness 是身体。[2]
2. **李博杰《深入理解 AI Agent》**：Agent = LLM + 上下文 + 工具。上下文和工具合起来，就是 Harness 的主体。[3]
3. **walkinglabs 五子系统**：Instructions（给模型的指令）+ State（任务进行到哪的状态）+ Verification（怎么验证做对了）+ Scope（允许碰什么范围）+ Lifecycle（长任务怎么开始、暂停、结束）。这是把 Harness 拆成工程零件，本系列后面每篇基本都在设计其中一个零件。[4]

一句话概括：Harness 是模型与真实任务之间的中间层。它决定模型看到什么、能调用什么、怎么判断完成、出错怎么恢复、长期任务怎么交接。

我 Vibecoding 有快一年了，最深的体会是：模型能力过去一年已经不是瓶颈，真正制约模型表现的是"拿到任务后，使用什么流程拆解，节点怎么设计，怎么定义 agent 的角色并分工"，这就是 L3 的学习目标。

## 工作台模式：别人替你写好的脚手架

2025 年前后，一批产品把这个"中间层"做成了开箱即用的东西，在L2的时候我曾叫它们“自主型Agent”，但在现在，它们更适合被称为"Agent 工作台"：给你一个聊天窗口，模型能读文件、跑命令、改代码、问你要权限。

它们的价值一句话就能说清：把原先你需要手写的那种脚本，变成模型可以自动实现（这也是我们在 L2 阶段体验过的）。

- **Claude Code**：第一个让我愿意天天用的编码 Agent。核心是一个循环：模型想一步、调用一个工具、看结果、再想一步。这个循环加上文件系统访问，证明真的能干活。
- **Codex CLI**：OpenAI 的对应物，后来用 Rust 重写，强调沙箱和审批模式。沙箱就是把 AI 关在一个隔离环境里运行，防止它乱动你的电脑。[5]
- **OpenCode**：开源替代，社区驱动，多模型支持。它是模块化的工作台，支持插件和 Hook（在工具执行前后插入你自己的规则），不是封闭黑盒。[6]

这些产品把一个原本只能在对话框里聊天的东西，变成了能真正出活的助手。

## 用久了会撞上的五个痛点

但是我用 Claude Code、OpenCode 这类工具越久，越觉得它们像一个封闭的魔法盒。Pi 作者 Mario Zechner 说得最直接，我按自己的使用体验重新排了序。[7]
![打开封闭的魔法盒：提示词卷轴、齿轮和管线从箱中升起](illustration-2.png)

**1. 上下文隐藏注入**

上下文窗口是有限的，但工作台在你写的 prompt 之外，还会往消息上下文里塞系统提示词、工具说明、项目约定。这些塞进去的东西挤占了窗口长度，但你无法直观的看见它们，你想弄清楚，得用工具监测网络通信，抓取发出的请求，并比较你的输入和抓取内容，找到差异，这不是普通用户能熟练做的事情。

**2. 脆弱升级**

在定义和实现工作流的技能时，我们会优先把确定的工作流程写成固定的脚本，为什么要这样而不是直接让 agent 每次自己跑呢？省钱是一方面，但更重要的考虑是因为工作台内部的系统提示词和工具可能版本升级后就变了，如果我们只提供提示词，每次都当场生成代码，不同版本的工作台里的 agent 生成的代码会不一样，出错的可能性会大幅提高，任务的完成率可能就崩了。这个升级通常还是强制的，你想固定版本，那有些更合理的新功能或新模型就用不了了。

**3. 膨胀**

功能膨胀：工作台 80% 的功能其实你是用不到的，但你要为它们的复杂度买单：更多的内存占用，更慢的启动时间等等。Mario 说有些工具"turned into a spaceship with 80% of functionality I have no use for"。[7] 这些功能还有可能导致上下文的膨胀：工作台内置的多层预制 prompt 占用了大量上下文，真正留给任务的窗口变小，比如 Opencode 的插件 oh-my-opencode，就以复杂的系统提示词出名。即便是用支持 1M 上下文的模型，实测消耗的 token 也会更多，哪怕命中缓存比例高，但这么做仍然不经济，能少我为什么要多呢？干点别的不好吗？

**4. 表演式安全**

permission 弹窗制造安全幻觉。用户习惯性点"允许"，弹窗反而成了流程噪音。因此 Pi 干脆默认不做权限的弹窗确认，直接 YOLO。理由也很直接：一个能跑命令行的编码 Agent，天生就是危险的，弹窗并不会让它更安全。[7]

**5. 长程任务目标漂移**

使用 Vibecoding 久了，都应该遇到过"做完了，但不是我要的"情况，尤其是长任务里这种跑偏更容易被放大：上下文随对话堆积腐化，早期约束退化，于是 Agent 悄悄偏离了最初的目标。Agent 停机宣布"完成"时，交付物可能已经偏离当初要求。Anthropic 的长任务 harness 正是针对这个动机设计的。[1][8]

这五个痛点是第一代"把 Harness 当成封闭黑盒整体设计"这个模式本身的结构性问题，因此之后出现的工具，就开始逐步尝试解决这些问题了。

## 两条路线：极简与元架构

针对工作台模式的弱点，我观察到行业里逐渐成形了两条设计路线，我认为这两条路的尝试很有意义，也很有意思，因此把它们作为 L3 系列的两大主角来介绍。

### 路线一：Pi，极简主义

Pi 的思路是回到你自己拼脚本的状态，只留最小内核：不内置子 Agent、没有 MCP（一种让 AI 调用外部工具的通用协议）、没有计划模式、没有内置待办。它只给模型 4 个原子工具：`read`、`write`、`edit`、`bash`（命令行）。[9]

其他一切能力，靠扩展和 skill 按需导入。这里说的 skill，就是你 Day 13 做的那种技能包：一个带说明文档的能力文件夹。项目级约定是 `.pi/skills/`、`.pi/extensions/`、`.pi/prompts/` 这几个目录。[9][10] 一句话总结：核心做小，其他交给用户扩展。

有趣的是，OpenClaw 的底层框架经历过几次升级之后，现在也改成 Pi 了，如果你是 OpenClaw 半年以上的用户，你有留意到什么差别吗？

### 路线二：DeepSeek Harness，元架构 / 插件网络

DeepSeek Harness 走向了另一个方向：把所有Harness 相关的东西当作插件，用一个叫 Cordis 的内核把它们组织起来。模型、工具、会话、甚至其他 Agent，都是插件。它的思路是不内置具体功能，而是定义好接口契约，让开发者按契约约定开发具体的功能，然后用户像拼乐高一样按需组合插件，搭建自己的脚手架。[2][11]

官方提供了四种场景的搭建样例：Standard（日常编码）、Code（让模型自己编排多轮工具调用）、Minimal（只留最基础工具，适合做测试）、Creator（可以检查当前运行环境、临时测试插件、组合出新模式）。[2]

## 保留、舍弃、优化

我把这两条路线的共同点拿出来和老模式做对比，能清楚地看到新路线的取舍思路，这也是本系列讨论的主线。

| | 保留 | 舍弃 | 优化 |
|---|---|---|---|
| 结构 | Agent 循环、工具调用、会话持久化 | 隐藏上下文注入、单体架构 | 可回放轨迹、可组合性 |
| 功能 | skill / prompt 系统 | 固定功能集 | 按需加载、插件 vs 扩展 |
| 安全 | 权限边界 | 表演式弹窗 | 显式策略、可审计日志 |
| 长期任务 | 增量交付 | 一次做完的幻觉 | 任务级检查、上下文交接 |

Pi 选择做减法：把核心压到最小，让扩展承担所有附加功能。DeepSeek Harness 选择做加法：用插件网络把每个能力都变成可组合、可替换的单元。两种思路看起来相反，但共同点是：不再把 Harness 当成黑盒，而是把"里面藏了什么"这个问题摊到桌面上，让用户看清楚后自己选择。

以上就是截至 2026 年中的Harness工程的发展脉络的一个小结。需要说明的是，Harness 领域仍在快速演化，新的作品会不断改写今天的分类，我的教程可能也会不断迭代，但我的目标是尽可能沉淀下那些不变的东西。

## L3 系列路线图

本系列按四个阶段展开：

1. **减法**：把harness架构拆到最简，理解harness的核心 Agent 循环的本质（Day 1）。
2. **约束**：建立契约与拦截，理解 Harness 的逻辑，能在给定的输入下，对harness的行为做出预期（Day 2-3）。
3. **加法**：理解插件化组合的思路、原理，扩展Agent系统的能力边界（Day 4-7）。
4. **演化**：搭建harness的记忆系统，观测harness行为，理解harness系统如何实现长期学习和改进（Day 8-10）。

这么设计的思路是，先看到 Harness 的核心：Agent 循环（减法），来帮助理解为什么要用 Hook 和权限策略去约束它（约束）；当约束稳定可靠了，才谈得上安全地添加插件（加法）；使用插件、将 Agent 能力提升到能做复杂任务了，才需要记忆和观测，让你的 agent 系统能长期演化（演化），效率越来越高，做任务越来越稳。

下一篇 Day 1，我们会拆开一个叫 miniharness 的最小 Harness 来看看。它的核心逻辑大约 120 行代码。你不需要会写，目标是理解原理：就像看菜谱，知道怎么做，但不需要自己动手。

---

## 注释与引用

1. Anthropic, *Harness design for long-running application development*, 2026-03-24. 对照实验数据：Claude Opus 4.5，提示词 "Create a 2D retro game maker with features including a level editor, sprite editor, entity behaviors, and a playable test mode."；无 harness 20 min / $9；完整 harness（planner + generator + evaluator）6 hr / $200。访问时间 2026-08-25。https://www.anthropic.com/engineering/harness-design-long-running-apps
2. deepseek-ai/deepseek-harness GitHub 仓库与官方文档。基于 Cordis 内核，模型、工具、会话、Agent 全部抽象为插件。访问时间 2026-08-25。https://github.com/deepseek-ai/deepseek-harness
3. 李博杰，*深入理解 AI Agent*，第 1 章。Agent = LLM + 上下文 + 工具。https://github.com/bojieli/ai-agent-book
4. walkinglabs, *Learn Harness Engineering*, Lecture 02. 五子系统框架：Instructions + State + Verification + Scope + Lifecycle。访问时间 2026-08-25。https://github.com/walkinglabs/learn-harness-engineering
5. OpenAI, *Unrolling the Codex agent loop*, Michael Bolin. Codex agent loop、Rust 重写与审批模式。访问时间 2026-08-25。https://openai.com/index/unrolling-the-codex-agent-loop/
6. anomalyco/opencode GitHub 仓库。开源模块化编码工作台，支持插件与 Hook。https://github.com/anomalyco/opencode
7. Mario Zechner, *Pi: a coding agent that is just right for me*, 2025-11-30. Pi 设计哲学原文，包含对工作台式 Harness 的批判、默认无确认弹窗的立场、"spaceship" 比喻。访问时间 2026-08-25。https://mariozechner.at/posts/2025-11-30-pi-coding-agent/
8. Anthropic, *Effective harnesses for long-running agents*, 2025-11-26. 介绍 initializer agent 与 coding agent 的上下文交接机制。访问时间 2026-08-25。https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
9. Pi 官方文档：*harness.md*。定义 Pi 的核心约束：4 个原子工具（read/write/edit/bash）、三存储结构、会话树、操作状态机。访问时间 2026-08-25。https://github.com/earendil-works/pi/blob/main/packages/agent/docs/harness.md
10. Pi 官方文档：*extensions.md*。扩展自动发现目录（`~/.pi/agent/extensions/`、`.pi/extensions/`）、工具注册、事件订阅、命令注册。访问时间 2026-08-25。https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md
11. DeepSeek Harness 官方文档：*architecture.md*。Cordis 内核、capability seams、事件流。访问时间 2026-08-25。https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md
