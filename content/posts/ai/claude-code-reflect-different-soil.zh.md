---
title: "claude-code-reflect：同样的元认知，落在不同的土壤"
slug: "claude-code-reflect-different-soil"
date: 2026-04-06T14:56:00+08:00
draft: false
description: "同一套反思机制落在不同平台基座上，落地姿态和路径截然不同——从插件安装到权限暗坑到 API 并发，记录 Claude Code 上的真实开发过程。"
tags: ["AI", "agent", "claude-code", "反思", "claude-code-reflect"]
categories: ["AI 实践"]
series: ["让 AI 学会反思"]
toc: true
---

同样的元认知能力，落在不同的土壤上，发芽的姿态和路径会截然不同。

上一篇 [Aristotle：让 AI 学会从错误中反思](/posts/2026/04/aristotle-ai-reflection/) 的核心设计是三个原则：即时触发、会话隔离、人在回路。这些原则听起来平台无关，但当把同一套理念搬到 Claude Code 上时，才发现平台差异比想象中大得多。

## 第一关：插件体系差异

Claude Code 的 plugin 和 OpenCode 的 skill 是完全不同的体系。光是让插件正确安装并被识别就折腾了好几个回合。

marketplace.json 格式不对，插件装了但识别不到；skill 调用路径错误，系统找不到技能入口；加载机制理解偏差，配置改了半天不生效。AI 反复安装失败，花了多个回合才搞清楚正确的格式和位置。

这不禁让人追问：为什么同样模型驱动的 Vibe Coding，在 Claude Code 中设计开发同样目标的任务时，连插件体系都弄不对？答案或许是，不同平台的隐含规则远比表面差异深。在我过去的理解中，OpenCode 的 skill 体系和 Claude Code 是遵循相同协议、高度相似的，但实践发现， Claude Code 的 plugin 加载机制、配置格式、路径约定都有细节的差异和额外的限制约定。模型对第一个平台积累的经验不能直接迁移，每个生态的"常识"细节都需要重新学习，查文档依旧重要，只是从人查变成了教AI查。

看似简单的标准协议+"换个平台"，实际是从零开始理解另一个生态的设计细节。

## 第二关：权限模型的暗坑

真正的问题还在后面。同样的反思subagent设计，OpenCode 上的实现很顺利，在 Claude Code 上却屡屡碰壁。反思任务启动时，主 session 对话会被子任务的用户确认弹窗高频打扰，用户极容易输入错乱。这造成了上下文的严重污染，还因错误回复导致AI的误解。最后，不仅 subagent 极容易启动失败，能启动的反思任务还经常是在主session中执行，卡住用户的工作流不说，还严重污染上下文。这种体验完全背离目标设计，无法接受。

<details>
<summary><strong>为什么会这样？</strong>（点击展开技术细节）</summary>

问题的根源在于准备阶段的非原子性。反思任务的启动包含多个独立步骤：生成 session UUID、创建目录、写入 state.json、写入 prompt 文件、启动后台子进程。在 Claude Code 默认的 `ask` 权限模式下，每个 Bash 或 Write 调用都会触发用户确认弹窗。每次弹窗之间，控制权回到主会话，用户的下一条消息可能穿插进来——轻则准备流程被打断，重则反思任务直接在主会话中启动，上下文被彻底污染。

V1 版的解决方案是引入 `bypassPermissions`：跳过所有确认弹窗，让准备流程一气呵成。这确实解决了启动被打断的问题，但 `bypassPermissions` 的作用不止于此——它改变了整个反思流程的权限模型。后台子会话在非交互模式下运行时，没有它，连基本的文件写入都会被拒绝。也就是说，`bypassPermissions` 一方面是原子性的保障，另一方面又成为了后续权限问题的源头，下面会继续讨论这个细节。

</details>

<p></p>
好不容易启动了 subagent（V1 版重构引入 bypassPermissions 方案），文件写入又被拒绝。一番调查之后，发现：

> Claude Code 的后台子会话有一个已确认的 bug：`bypassPermissions` 会静默拒绝项目根目录外的写入。

方案撞到这个 bug 后，表现为：用户级的规则（比如 `~/.claude/skills/` 下的技能更新）恰恰需要写到项目根目录外。但后台子会话被设计为非交互式的，它需要写入的位置偏偏在权限边界上，于是**保存文件失败了**。

## 绕过暗坑的探索：方案迭代 v2→v3

于是有了 v2 方案，去绕过写入权限问题：把所有最终写入都移到用户确认后的交互式会话（resumed session），后台子会话只做分析和生成草稿。这样后台子会话就只写项目根目录内的 `.reflect/reflections/{id}/`，避开了那个 bug。

但 v2 仍有问题：准备阶段的原子性被忘记了。如果准备过程被打断，会留下不一致的状态，V1 版重构中被解决掉的问题又回来了。

于是又继续做了 v3 方案，把所有准备步骤合并成单条 Bash 命令，消除中断窗口。同时评估后决定放弃 OMC 依赖，只维护 standalone 分支。

### 为什么放弃 OMC 依赖

OMC 带来两个核心能力：
1.  `notepad_write_priority`，用于跨 compaction 通知——当 background subagent 完成分析后，通过 notepad 注入优先通知，确保 context 压缩后仍能看到提醒。但在 v3 版 write path 重新设计的情况下，用户需要主动 resume subagent session 来做 review 和写入，这个通知机制的价值已经大幅降低——用户本来就知道自己触发了一个 reflection，`/reflect inspect` 和 `/reflect list` 就够用了。

2.  `project_memory_add_note` / `project_memory_add_directive`，提供结构化的 project memory 管理。standalone 用 Write tool 直接写 `.reflect/project-memory.json`，功能等价，只是没有 OMC 的统一管理层。对于这个项目的使用场景来说，差异几乎感知不到。

因此结论是 standalone 完全够用，main 分支的 OMC 依赖性价比不高：
* 首先，OMC 本身也需要单独安装，对用户是额外的安装步骤和认知负担，而它带来的收益已经很边缘。
* 其次，standalone 的 file-based 方案更透明——写到哪个文件、写了什么，用户完全可见可控，符合这个项目 human-in-the-loop 的设计哲学。
* 第三，维护两个分支本身有持续成本，每次 SKILL.md 有改动都要同步，而已经有了 write path redesign 这个大改动要做。

于是有了 v3 版方案：

| 阶段 | 会话类型 | bypassPermissions | 写入范围 |
|---|---|---|---|
| 准备 | 主会话（1 次原子 Bash 调用） | 是——原子性 | `.reflect/reflections/` |
| 后台分析 | 后台子会话 | 是——非交互写入必需 | `.reflect/reflections/{id}/` |
| 审阅+写入 | 交互式（恢复的）会话 | 否 | `.reflect/` + `~/.claude/` |

## 基于 v3 方案的坎坷实现

用 ralph loop 执行 v3 方案变更。跨平台路径兼容性是一个细节——Windows Git Bash 和 POSIX 系统的路径处理方式不同，需要统一处理。

这一步比较顺，v3 方案的核心是把"准备"和"分析"的边界划清楚，把写入权限问题集中解决。接下来才是真正踩的坑。

### 测试发现 `bypassPermissions` 不能丢

v3 方案在理论上认为：后台子会话只写项目根目录内的 `.reflect/reflections/{id}/`，理论上不需要 `bypassPermissions`。

实测发现不设置 `bypassPermissions`，连文件都写不了。理论和平台现实有差距。

最终方案加回了 `bypassPermissions`，同时在 prompt 中添加路径限制作为纵深防御：权限上开放，逻辑上约束。

做个表回顾从 V1 到 V3 的迭代，三个方案在关键维度上的差异便一目了然，回头看很简单，但搞清楚着实费了一番功夫：

| 维度 | V1 | V2 | V3 |
|---|---|---|---|
| 准备阶段 | 多步独立调用，可被打断 | 多步独立调用（同 V1） | 单条原子 Bash 命令 |
| 后台写入位置 | 尝试写 `~/.claude/`（被拒） | 只写项目根目录 | 只写项目根目录 |
| 最终写入位置 | 后台子会话直接写 | 移到 resumed session | 移到 resumed session |
| bypassPermissions | 引入——抑制弹窗 | 尝试去掉——理论不需要 | 加回——实测必须 |
| OMC 依赖 | 有 | 有 | 放弃，standalone only |

迭代不是线性的进步，而是在原子性、权限安全性、依赖复杂度之间不断权衡。每个方案解决上一版的问题，又暴露新的边界条件。

### 测试发现 API 并发错误

另一个问题是在测试中发现的。主会话和子会话共用 API endpoint，并发请求时触发了 ECONNRESET 错误。

排查过程走了几个弯路：先尝试指定模型，怀疑是模型切换问题；查第三方 API 配置，怀疑是路由问题。最终确认是所用 API 侧的并发限制——同一个 endpoint 的并发请求会被拒绝，换一个限制更宽松的API，这个问题就消失了。

### 解决：重试机制

既然并发限制是客观存在的，那就加一个重试机制：

```bash
(
  MAX_RETRIES=3
  RETRY_DELAY=10
  attempt=0
  while [ $attempt -lt $MAX_RETRIES ]; do
    claude -p "$(cat prompt.txt)" \
      --session-id $SESSION_ID \
      --model ${REFLECT_SUBAGENT_MODEL:-sonnet} \
      --permission-mode bypassPermissions \
      --output-format json 2>>stderr.log
    [ $? -eq 0 ] && break
    attempt=$((attempt + 1))
    sleep $RETRY_DELAY
  done
) &
```

后台拉起子 shell 包裹 `claude -p` 调用，失败后等待 10 秒重试，最多 3 次。同时添加可配置的模型参数 `REFLECT_SUBAGENT_MODEL`，允许用户根据自己 API 的并发限制选择模型。

验证成功，与期望一致。但这是来自外部的不可控风险，当前的设计机制只能缓和它的影响，并不能彻底消除。

## 最终：6 个已知问题仍在

不是每个问题都有优雅的解法，诚实面对未解决的问题：

1. 准备阶段让用户困惑（看起来像假死，实际是在后台分析）
2. 子会话完成后无法自动通知用户
3. 重试时 session ID 可能冲突
4. Read 工具渲染 markdown 时显示不准确
5. 错误恢复选项不足
6. 跨 compaction 通知可靠性

这些问题的解决需要平台层面的支持，或者在当前约束下做出取舍。工程就是这样，不是所有问题都有完美解法。

## One more thing：AI 驱动测试的价值

整个测试流程由 AI 驱动完成。这不是重点，重点是测试中发现的几个问题都在原始方案文档的盲区里：`bypassPermissions` 权限是平台特性，不是设计问题；API 并发是环境限制，也不是设计问题；`heredoc` 变量不展开是 Bash 实现细节，更不是设计问题。

如果按传统方式设计，这些问题可能在上线后才暴露。让 AI 来测试系统，AI 能发现人类方案中未预见的边界情况。这一点值得强调——如果你在设计一个系统，让 AI 来测试它，AI 不只是执行者，还是设计验证的参与者。

## 下篇预告

下一篇将系统比较两个系统的差异——从技能体系到权限模型到并发控制到底层设计哲学的思考，看看同一套元认知机制在不同土壤上长成了什么样，对我们未来的 AI 实践有什么启发。
