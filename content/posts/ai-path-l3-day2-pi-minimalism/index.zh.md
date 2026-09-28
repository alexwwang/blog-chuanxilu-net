---
title: "Day 2｜极简主义与硬隔离：Pi 范式"
slug: "ai-path-l3-day2-pi-minimalism"
date: 2026-09-28T10:00:00+08:00
publishDate: 2026-09-28T10:00:00+08:00
draft: false
description: 'AI 之路 L3 第二篇骨干：为什么少即是多，Pi 砍掉哪些功能换来透明度和速度，以及为什么安全不能靠弹窗。'
tags: ["AI", "教程", "Harness", "Agent Loop", "Pi", "极简主义", "硬隔离"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: cover.png
  alt: "水彩风格：一张干净的工作台，只有四件工具整齐摆放，旁边一张堆满杂物的桌子形成对比"
---

> 上一篇是 [Day 1｜120 行代码读懂 Agent Loop：miniharness 拆解与 3 个反直觉发现](/posts/2026/09/ai-path-l3-day1-miniharness-agent-loop/)。理解了 loop 的核心结构后，我们来问一个更根本的问题：剩下的几千行代码里，到底该放什么、不该放什么？
>
> 本篇是 L3 的骨干篇。后续导航：
>
> | Day | 类型 | 主题 |
> |-----|------|------|
> | Day 3 | 骨干 | Harness 硬约束：静态契约与生命周期 Hook |
> | Day 4 | 练习 | 重写你的 AGENTS.md + 加一个拦截 Hook |
> | Day 5 | 骨干 | 工具即界面：三种扩展路径 |
> | Day 6 | 练习 | 给你的 Agent 装一个新工具 |
> | Day 7 | 骨干 | 元架构：Everything is a Plugin |
> | Day 8 | 骨干 | 记忆、轨迹与可观测性 |
> | Day 9 | 练习 | 毕业项目：搭建团队级 CI/CD 自动化 Harness |
> | Day 10 | 阶段小结 | L3 毕业考核 + Harness 未来趋势 |

---

## 为什么"更多功能"是反向优化

Day 1 我们拆开了 loop，核心逻辑只有百行左右。剩下的几千行是结构、约束、工具、权限、计划模式（Plan Mode），各种让 Agent "能干更多事"的附加能力。

直觉上，功能越多，Agent 越强。但实际经验给出了相反的结论：**功能每多一个，模型的决策空间就混乱一分**。

OpenAI 在 Harness Engineering 文章里提出了"上下文稀缺论"：context 是模型推理时最昂贵的瓶颈资源，工作台内置的多层预制 Prompt 逻辑会挤占真正有用的任务空间[7]。每一行不必要的系统提示词都在压缩 Agent 的思考余地。

计划模式把模型的规划能力外包给固定流程：Agent 先写计划，再执行计划。听起来合理，但效果是模型变笨了。规划输出被固定成模板，模型不需要在每一步做决策，只需要机械地填充格式。决策空间被压缩，创造性被外包。

Pi 的作者 Mario Zechner 对老一代工作台有过一段直接评价：它们变成了"一艘宇宙飞船，80% 的功能他用不上"，但每次版本更新，系统提示词和工具都在变，工作流跟着崩[4]。功能膨胀和上下文膨胀，是同一笔账：每一个你用不到的复杂度，都要买两次单：一次是装进你的内存，一次是吃掉调用模型的上下文。

## Pi 的答案：4 个工具 + 你自己扩展

Pi 的做法是反过来的：**只保留 4 个原子工具**，其余全部砍掉。

- `read`：读取文件内容
- `write`：写入新文件
- `edit`：编辑现有文件
- `bash`：执行 shell 命令

没有内置待办、没有后台 bash、没有计划模式、没有 MCP（模型上下文协议）、没有子 Agent。需要更多能力？项目级的 `.pi/skills`、`.pi/extensions`、`.pi/prompts` 三个目录约定，按需导入[1]。

![极简与繁复的对比：左边 4 个工具的干净界面，右边密密麻麻的菜单和弹窗](illustration-1.png)

这和 Unix 哲学一脉相承：每个工具只做一件事，但通过组合可以完成任意复杂的工作流。你不会找到一个"全能文本处理工具"，你有 `cat`、`grep`、`sed`、`awk`。

这种设计带来三个直接收益：**透明度**：没有任何东西在你背后偷偷修改上下文。**可调试性**：出了问题，逐层排查，是 tool 写错了，还是 extension 加载失败，还是 prompt 没生效。**可移植性**：不绑定特定模型或平台，只要支持基础 API 就能跑。

Day 1 的 miniharness 已经在实践这个原则：7 个朴素工具，没有 MCP，没有子 Agent，loop 本身具备自我恢复能力。Pi 是把同样的思路做到产品级规模的结果。

如果你想自己感受差异，可以做一个体验对比：同一个任务，在功能臃肿的传统 Harness 和极简的 Pi 上各跑一遍，对比两者的执行响应速度与上下文占用。

## 弹窗不是安全：表演式安全的批判

你用 Claude Code 写代码时，敏感命令会触发权限弹窗：`run_command: rm -rf /tmp/build`，你点了"允许"。下一次是 `run_command: npm install`，你又点了"允许"。到第三次，你连内容都没看就点了"允许"[8]。

问题在于你的习惯。当弹窗出现频率足够高，大脑会把它当作噪音过滤掉，最终变成条件反射式的点击。

Pi 的作者直接承认了这一点：有 bash 权限的编码 Agent 天然就是危险的。权限弹窗解决的是"心理安全感"这一维度，不是安全本身。Pi 干脆默认 YOLO mode，不装弹窗[4]。

OpenAI 的 Codex CLI 提供了三级审批模式，比 Claude Code 的单层弹窗精细一些[6]。但本质问题一样：安全决策发生在疲劳状态下，而疲劳状态下没有人会认真做决策。

权限弹窗就像每次进门都要按门铃，烦到你最后直接不锁门。沙箱是把整个房子围起来，你在里面干什么都不用按门铃，但你出不了院子。

![弹窗疲劳的循环：弹窗频率越高，点击越机械，安全感越假](illustration-2.png)

这里必须做一个重要的场景边界说明：**上面的批判只适用于编码/个人场景**。编码场景的特点是动作可逆（git 可回滚）、沙箱可兜底、用户是懂行的操作者。在这些条件下，权限弹窗确实变成了表演式安全。但业务动作不可逆的场景，付款、发客户邮件、改生产数据库，审批是真实控制甚至是合规要求，不存在"表演"问题。企业业务场景的安全策略留待 L4 展开。

## 正确的安全模型：在外面围起来，不在里面弹窗

Pi 选择了外部硬隔离路线：Harness 本身不做权限管理，权限由外部的容器化方案负责。常见的实现包括 Gondolin（micro-VM 方案）、Docker（通用容器隔离）、OpenShell（容器安全执行环境）[4]。Pi 自己不带沙箱，容器是外部工具，这是刻意的职责分离。

约束在 Harness 之外（物理隔离）还是之内（逻辑弹窗），这就是核心区别。

但外部容器不是唯一答案。同样做 Agent 安全这件事，DeepSeek Harness（DSH）选择了不同的分工：它不依赖外部容器，而是在 Harness 内部定义了一套可插拔的能力接缝，sandbox 和 approval policy 都是接口层上的插件[5]。这个思路更接近工具调用的拦截模式。两条路线的目标一致，实现路径不同。

从 L2 到 L3，安全思维也在升级。L2 的沙箱策略是在副本上测试，不动原件，这是文件层面的隔离。L3 用容器包住整个 Agent 运行时，不管内部发生什么，都限制在沙箱边界内，这是进程层面的隔离。

![硬隔离的比喻：房子外面围起高墙，里面的人可以自由活动，但出不去院子](illustration-3.png)



Pi 和 DSH 的共同前提是：**安全不能靠弹窗，只能靠机制**。


## 三个进阶方向

- 读懂真实产品：Pi 的核心包，一个下午读完，真实产品的 loop 也没比 miniharness 复杂多少[1]。
- 亲手造一个：《动手学 Pi》（pi-textbook），15 个可运行 checkpoint，跟着做完就懂了[2]。
- 延伸阅读：dg-ai-notes，10 章源码解读（TypeScript + Python 双版本对照，30+ 配图），外加一个可单步运行、随便改参数的 Agent Loop 实验场 notebook[3]。

## 今日收获

我们今天主要讨论了三个核心结论：

1. 为什么功能越多，模型的决策空间越混乱：上下文稀缺论和计划模式的反向优化。
2. Pi 极简主义的实质是职责分离：4 个原子工具 + 外部硬隔离。
3. 安全不能靠弹窗协商，只能靠机制强制：硬隔离 vs 内置拦截的适用边界。

减法做够了，但"薄"不等于"裸奔"。下一篇 Day 3 我们看看怎么给极简 Harness 加上硬约束，不靠弹窗，靠契约和拦截。

---

## 参考资料

1. [earendil-works/pi：极简编码 Agent 官方仓库](https://github.com/earendil-works/pi)
2. [hahhforest：Pi Textbook（动手学 Pi）](https://github.com/hahhforest/pi-textbook)
3. [buchidonggua/dg-ai-notes：Pi 源码解读与实验场](https://github.com/buchidonggua/dg-ai-notes)
4. [Pi 设计哲学原文：Mario Zechner 博客](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)
5. [DSH 架构文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md)
6. [OpenAI: Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/)
7. [OpenAI: Harness engineering](https://openai.com/index/harness-engineering/)
8. [Claude Code 权限文档](https://code.claude.com/docs/en/permissions)
9. [Aristotle Watchdog-Intervention Bridge 设计](/posts/2026/07/aristotle-v16-watchdog-intervention-bridge/)
10. [从四道伤疤到一套铠甲：Harness 工程实践](/posts/2026/04/from-scars-to-armor-harness-engineering-practice/)
