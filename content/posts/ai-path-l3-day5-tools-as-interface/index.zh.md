---
title: "Day 5｜工具即界面：内置、扩展、服务"
slug: "ai-path-l3-day5-tools-as-interface"
date: 2026-10-19T09:00:00+08:00
publishDate: '2026-10-19T09:00:00+08:00'
draft: false
description: 'AI 之路 L3 第五篇骨干：工具有内置、扩展、服务三种性质，不同 Harness 在三层上的取舍不同，但回答的是同一个问题。'
tags: ["AI", "教程", "Harness", "工具", "MCP"]
categories: ["ai-path"]
toc: true
series: ["AI 之路进阶升级指南"]
cover:
  image: cover.png
  alt: "水彩风格：一只机械手臂握着画笔，面前三个抽屉分别标注内置、扩展、服务"
---

> 上一篇是 [Day 4｜重写你的 AGENTS.md，并加上第一个拦截 Hook](/posts/2026/10/ai-path-l3-day4-rewrite-agents-md-hook/)。学会了让约束落地后，我们来看另一个核心问题：Agent 的工具该怎么设计？

本篇是 L3 的骨干篇。后续导航：

| Day | 类型 | 主题 |
|-----|------|------|
| Day 6 | 练习 | 给你的 Agent 装一个新工具 |
| Day 7 | 骨干 | 元架构：Everything is a Plugin |
| Day 8 | 骨干 | 记忆、轨迹与可观测性 |
| Day 9 | 练习 | 毕业项目：搭建团队级 CI/CD 自动化 Harness |
| Day 10 | 阶段小结 | L3 毕业考核 + Harness 未来趋势 |

---

## 一个被忽视的事实

前四篇我们完成了两个阶段：Day 0 建立 Harness 的整体认知，Day 1 解剖了 Agent Loop 的本质；随后进入约束阶段——Day 2 砍掉不需要的功能，Day 3 用契约和 Hook 管住 Agent 的手脚，Day 4 动手改造了真实项目。约束做足了，Agent 不乱来了。

但你可能发现了：**Agent 不乱来，不等于 Agent 干得好**。

你给 Agent 写了一份完美的 AGENTS.md，加了拦截 Hook，配好了 feature_list.json——然后它还是做不好你要的事。任务交付了，但质量平平；步骤没跑偏，但结果缺了口气。

问题出在哪？

## 结论：工具设计 = Agent UX

先给结论：**问题不在约束，在工具。你给 Agent 设计工具，就是在设计它的用户体验——决定它能看到什么、能操作什么、怎么理解"做完"的含义。**

工具是 Agent 的手和眼。你给它什么工具，它就做什么事；工具设计不好，模型再聪明也抓瞎。这句话像常识，但行业里真正当回事的人不多——大多数团队把 90% 的精力放在模型选型上，很少回头审视工具接口本身。

打个比方：工具设计就像给新员工配工位。不是东西越多越好，是他需要的触手可及，不需要的不要挡路。工位上堆满他用不上的设备，和上下文里塞满他用不上的工具 schema，是同一个错误。

## 证据：miniharness 的消融实验

这个结论有数据支撑。miniharness 的消融实验量化了工具设计对 Agent 表现的影响[1]：同样的任务，换一种工具调用格式，步骤数可以翻倍，任务完成度骤降。

| 工具格式 | 完成情况 | 步骤数 | 工具调用次数 | 总 token |
|----------|----------|--------|--------------|----------|
| native_json | ✅ 完成 | 4 | 4 | 6,618 |
| xml | ⚠️ 提前结束 | 2 | 1 | 3,188 |
| prompt | ⚠️ 未调用 finish | 2 | 2 | 2,966 |

不是模型变笨了，是工具告诉它的信息太少或太模糊。native_json 格式让模型清楚知道"我有几个参数、每个参数是什么类型"，所以它知道自己该走哪几步；XML 和 prompt 格式则让模型陷入猜测，要么提前放弃，要么绕圈子。

模型选型解决不了的差距，换工具设计可能一步跨过。

![工具格式消融实验数据：同样任务，格式不同，结果天差地别](illustration-1.png)

---

## 工具的三种性质

结论有了，证据有了。下一个问题自然浮现：要扩展 Agent 的能力，该往哪里加？

先澄清一个常见的困惑：市面上谈"扩展"时，MCP、插件、扩展、Hook 这些词经常混着用，听起来像是好几条路。**其实按工具与 Harness 的关系分，工具只有三种性质**：

**内置**：Harness 出厂自带，写死在代码里。read、write、bash 这类原子操作通常是内置的。特点是零配置可用，但你改不了它。

**扩展**：代码注入到 Agent 进程内，运行时注册。工具就是函数，调用就是函数调用，可以访问会话状态、监听事件、控制终端渲染。特点是完全控制，但绑定具体的 Harness。

**服务**：工具跑在独立进程里，通过协议与 Agent 通信。MCP 就是这条路的开放标准。特点是跨产品可移植，代价是每次调用多一层通信开销。

三种性质不是互斥的选项——一个成熟的 Harness 通常三层都有。真正的区别在于：**每一层放多少东西**。这个取舍，就是不同 Harness 的设计哲学。

---

## 五种产品，五种取舍

### Pi：内置极简，扩展全能

Pi 的内置层只有 4 个原子工具：read、write、bash、edit[2]。待办不内置（`write` 一个 TODO.md 就能实现），网页访问不内置，全都留给用户自己扩展。

敢这么砍，是因为扩展层足够强。Pi 扩展是进程内的 TypeScript 模块[3]，放在 `~/.pi/agent/extensions/`（全局）或项目的 `.pi/extensions/`（项目级），启动时自动加载：

```typescript
// Pi 扩展示例：注册一个规则搜索工具
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "search_rules",
    description: "按关键词搜索规则库，返回匹配的规则摘要",
    inputSchema: {
      type: "object",
      properties: {
        keyword: { type: "string", description: "搜索关键词" },
        limit: { type: "integer", description: "返回结果数量上限，默认10" }
      },
      required: ["keyword"]
    },
    handler: async ({ keyword, limit = 10 }) => {
      // 直接读写文件系统，无网络开销
      const rules = await pi.readRules();
      const matches = rules.filter(r => r.content.includes(keyword));
      return matches.slice(0, limit);
    }
  });
}
```

扩展拿到的能力不止注册工具：可以监听工具执行事件做拦截（Day 3 的 Hook 就是这么实现的）、注入上下文、注册自定义斜杠命令、控制结果的终端渲染。会写 Hook（Day 4 练过）就已经掌握了扩展的事件 API，把 `pi.on(...)` 换成 `pi.registerTool(...)`，就从"监听别人的工具"升级到"注册自己的工具"。

服务层 Pi 也支持 MCP，但它明显把赌注押在扩展层：内置极简是态度，扩展全能是底气。

### Claude Code：内置够用，服务开放

Claude Code 的内置层厚得多：文件操作、搜索、WebFetch、WebSearch、子 Agent 调度，十几个工具开箱即用。设计目标很明确——降低上手门槛，新手不需要先学扩展机制就能干活。

它的扩展层是 hooks 和 plugins——hook 管事件拦截（Day 3 练过），plugin 把 slash command、subagent、hook、MCP server 打包成分发单元。但注意一个关键事实：**给 Claude Code 注册一个新工具，几乎只有 MCP 一条路**。进程内没有注册工具的入口，生态重心因此落在服务层：Claude Code 是 [MCP（Model Context Protocol）](https://modelcontextprotocol.io/) 的最早采用者[4]。MCP 是 Anthropic 推出的开放协议，让 Agent 通过标准接口调用外部工具——Server 用任何语言写都行，Claude Code 能用，Codex 也能用。

一个 MCP Server 的工具定义长这样：

```json
// MCP Server 的工具定义示例
{
  "tools": [
    {
      "name": "search_rules",
      "description": "按关键词搜索规则库",
      "inputSchema": {
        "type": "object",
        "properties": {
          "keyword": { "type": "string", "description": "搜索关键词" },
          "limit": { "type": "integer", "description": "返回结果数量上限" }
        },
        "required": ["keyword"]
      }
    }
  ]
}
```

Agent 启动时加载所有 MCP Server，把工具 schema 注入上下文。注意 `description` 字段——它就是 Agent 对这个工具的全部认知。写得好，Agent 第一次调用就用对参数；写得含糊，Agent 会反复试错。这个字段值得花一半的开发时间打磨。

Claude Code 的取舍很清晰：内置层管"够用"，服务层管"开放"，让社区生态去填满长尾需求。

### Codex：内置精简，沙箱优先

Codex 是 OpenAI 的对应物，从 TypeScript 重写到 Rust，设计重心不在工具层，而在执行环境：审批模式加操作系统级沙箱（macOS 用 Seatbelt，Linux 用 Landlock，网络默认关闭），把"Agent 能做什么"的限制从工具设计挪到了运行时[5]。

内置层因此保持精简：shell 执行和文件补丁是核心，工具数量压得很低——沙箱兜底了安全，内置层就不必靠"少给工具"来防风险。

扩展层 2025 年底以来补齐了 hooks、Skills、Plugins 等机制[6]，但拆开看：hook 管事件拦截（Day 3 的话题），skill 是指令包，plugin 是分发格式——**给 Codex 加一个新工具，仍然只有 MCP 一条路**。

Codex 代表另一种思路：**工具层保持简单，把复杂度交给执行环境和打包生态**。

### OpenCode：社区路线，两层都给

OpenCode 是开源阵营的代表：社区驱动、多模型支持、高度模块化[7]。它的特殊之处在于两层都给了完整答案——扩展层支持自定义工具（TypeScript 编写，放入项目的工具目录即被加载）和事件插件；服务层完整支持 MCP。

也就是说，Pi 的"进程内扩展"思路，开源世界里 OpenCode 在做同样的事；Claude Code 的"MCP 服务"思路，它也照单全收。代价是没有强烈的取舍主张——什么都能做，意味着你要自己判断哪层适合你的场景。

### DeepSeek Harness：内置消解，一切皆插件

DSH 走向了极端[8]：**一切皆插件**。模型适配器是插件，工具注册表是插件，Session 存储是插件，连 Agent Loop 本身都是插件[9]。

这意味着它的"内置层"被消解了——没有什么是写死的，三层统一成了一种形态：插件。插件之间通过服务（services）和类型化事件（typed events）通信，效果可逆（reversible effects）。

```yaml
# DSH 配置文件：声明要加载哪些插件
plugins:
  - name: search-rules
    type: tool
    source: npm:ds-tool-search-rules
    config:
      keyword: "linter"
      limit: 10

  - name: code-reviewer
    type: agent
    source: github:myorg/code-reviewer-plugin
    config:
      model: deepseek-chat
      temperature: 0.3
```

### 殊途同归

把五种产品的分层策略放在一起看：

| 产品 | 内置层 | 扩展层 | 服务层 |
|------|--------|--------|--------|
| Pi | 4 个原子工具 | TypeScript 模块，能注册工具 | 支持 MCP |
| Claude Code | 十几个工具，开箱即用 | hooks + plugins，不能注册工具 | MCP 最早采用者 |
| Codex | 精简，沙箱兜底 | hooks + skills + plugins，不能注册工具 | 支持 MCP |
| OpenCode | 标准编码工具集 | 自定义工具 + 事件插件 | 支持 MCP |
| DeepSeek Harness | 消解为插件 | Cordis 插件，扩展到极致 | 支持 MCP |

看出共同点了吗？**三层结构是共有的，取舍不同而已**。Pi 赌扩展层，所以内置砍到 4 个；Claude Code 赌服务层，进程内干脆不给注册入口；Codex 把筹码押在执行环境，工具层保持简单；OpenCode 两层都给，把判断留给用户；DSH 把扩展层做到极致，连内置层都吞了进去。

路径不同，回答的是同一个问题：**如何让 Agent 获得恰到好处的工具——既不缺，也不滥**。理解了这一层，再看任何新出的 Harness，你都能快速定位它的设计哲学：它的内置层有多厚？扩展层能拿到什么权限？服务层支持什么协议？

---

## 工具设计的核心原则

三种性质、五种产品讲完了。不管你的工具落在哪一层，有几个跨层的共识。Anthropic 官方的工具设计方法论[10]与这些原则相互印证，感兴趣可以对照阅读。

### 原则一：少而精

Day 2 讲过 Pi 为什么只留 4 个原子工具——每个工具都是一份永久占用上下文的"税"。**你加的每个工具，模型启动时都要看一遍它的 schema**。工具从 4 个涨到 24 个，即使一个都不调用，上下文已经被吃掉一截。Aristotle 的 MCP server 有 25 个工具，启动时光是工具定义就是一笔不小的固定开销，这是我在设计时反复权衡过的。

反例是 OpenClaw——它从编码工具扩展到个人助理平台，积累了 20+ 渠道连接、语音、摄像头、屏幕操作等能力。功能丰富了，但启动时间、内存占用、上下文开销也随之膨胀。Mario Zechner 批评老一代 Harness "turned into a spaceship with 80% of functionality I have no use for"[11]，说的就是这个现象。

**判断标准**：如果一个功能用户能用现有工具组合出来，就不该给。Pi 没有内置待办，`write` 一个 TODO.md 就能实现。Pi 内置了搜索，原因不在用户做不到（`bash` 调 `grep` 就行），而在 grep 的输出格式对模型不友好——提供结构化匹配结果，省模型一轮解析。要不要给工具，看的是模型做起来费不费劲。

### 原则二：错误信息回灌上下文

工具调用失败时，不要只返回一个错误码。把**原因**和**解决办法**一起封装成结果，回灌给模型。

这个原则在 Day 1 就有实证：miniharness 的模型遇到 `python: not found`，自己执行 `which python3` 修正了——loop 的自我恢复能力，完全建立在错误信息足够明确的前提上。

dg-ai-notes 的实战细则[12]把这条原则落到了具体写法上：报错信息要按错误类型说清楚**为什么错、怎么改**——别只回一句"查询失败"，告诉模型"表不存在，库里只有 sales、products、users"，它马上就知道换表名重试，而不是停在原地乱猜。

对照两种写法：

```
❌ 错误：TABLE_NOT_FOUND
✅ 错误：表 orders_2024 不存在。可用表：orders_2025、customers、products。
   提示：如果你想查 2024 年的订单，试试 orders_2025（2024 年数据已归档其中）。
```

第二种写法把"下一步该做什么"也告诉了模型。工具设计者多花两分钟写错误提示，省下模型三四轮无效试错——每轮都是真金白银的 token。

### 原则三：工具结果分离

同一份工具输出，模型和用户需要看的内容不同。模型要的是能继续推理的结构化数据；用户要的是能快速扫懂的摘要。把它们混在一份输出里，要么模型被无关细节淹没，要么用户面对一堆 JSON 发呆。

Pi 的 structured split tool results 机制正好解决这个矛盾：一份输出拆成两部分——一段给模型看的结构化数据（用于后续推理），一段给 UI 看的富文本（用于用户理解）。模型看到 JSON，用户看到高亮的 diff 或渲染后的报告。两部分从同一次工具调用产生，不存在不一致的问题。

这听起来是 UX 问题，但本质是上下文工程问题：模型只需要它需要的那部分，其他内容不会占用 token。给用户看的那份再华丽，也不进上下文。

---

## 我的工具设计实践

原则讲完了，落到我自己的项目。下面两条经验是从 Aristotle 里长出来的，一条关于"读"方向（工具返回什么），一条关于"写"方向（工具允许什么），都是围绕同一个主题：**上下文经济是工具设计的第一约束**。

### 两轮查询：list_rules 只回元数据

Aristotle 的规则库目前有约 30 条生效规则。最早的 `list_rules` 工具直接把匹配的规则正文全部返回——主 Agent 一次调用吞掉几千 token，其中大部分与当前任务无关，而且正文从此留在主会话里，后续每轮推理都带着它们。

改造后的设计分两轮：

- **第一轮**：`list_rules` 只返回元数据（规则名、标签、匹配分数），不返回正文。粗筛用流式 frontmatter 搜索——只扫每个文件的 YAML 头，实测全部规则文件 20ms 内完成。
- **第二轮**：主 Agent 根据元数据挑出候选，派 N 个并行评分 subagent 各读一条规则正文打分，取 Top-5 汇总。

关键判断：**主 Agent 不读规则正文**。正文只在被选中之后才进入上下文，而且进入的是隔离的子会话，不污染主会话。同一份信息，按需、按量、按地点送达。这是"工具结果分离"原则在架构层面的应用。

这里有个容易忽略的点：两轮查询多了一次工具调用，为什么反而更省？因为上下文成本按"进入主会话的 token 数"算，不按调用次数算。多一次调用只花几百 token 往返，而把十条无关规则正文挡在主会话外，省的是几千 token 的常驻污染。

### 信任门：写入前必经用户审批

另一条经验关于工具的"写"方向。Aristotle 允许 AI 从反思中提炼新规则，但**所有规则写入前必须经过用户审批**。

原因很简单：AI 可能会把一次临时性的纠正误判为通用规则。某次报错只是因为当次环境缺了一个依赖，AI 却可能提炼出"以后都要先检查 X"的永久规则。这类误判积累多了，规则库就悄悄腐烂了——每条规则单看都合理，合在一起让系统越来越僵硬。

工具层面的实现是：写入工具不直接落盘，而是生成一个待审批条目（规则正文、触发条件、来源反思），用户确认后才生效。审批界面一行摘要加"接受/拒绝"就够——成本极低，收益是规则库质量始终有人类把关。

用户的判断是最后一道防线，不能交给模型自己。这和 Day 2 讲的"表演式安全"不矛盾：弹窗是表演，因为它出现在**高频、可逆、用户没空细看**的编码场景；规则写入是**低频、不可逆、值得花十秒看一眼**的操作。频率低、代价高、判断确实需要人类——这时候审批是真实控制，不是表演。

---

## 行动：给你的工具找对层

理解了三种性质，动手前只需要回答一个问题：**你的工具该落在哪一层？**

对号入座：

1. **逻辑简单、用现有工具能组合出来？**——别造工具。写进 AGENTS.md 用契约约束（Day 3 的方法），或者教 Agent 用 bash 组合现有命令。
2. **团队共享、跨产品复用？**——放服务层。写一个 MCP Server，一次写好，多个 Harness 都能用。调试可以用任意 HTTP 客户端独立验证。
3. **高频调用、性能敏感、需要会话状态？**——放扩展层。进程内调用零开销，能读到会话里的全部上下文。代价是绑定你用的 Harness，换产品要重写。

我自己的经验是：**从服务层起步，有需要再下沉**。Aristotle 项目就是一个完整案例：OpenCode skill（协议文件按需加载）第一版，MCP Server（25 个工具，Git 背书规则管理）第二版。先写服务，验证思路；遇到性能瓶颈或需要进程内状态时，再下沉为扩展——这个升级方向是顺的，反过来就麻烦。

明天的 Day 6 是练习篇：你真的要给 Agent 装一个新工具。今天讲的三层框架和三条原则，都会用到。

---

## 和 L2 的衔接

L2 的 Day 12 讲过"什么时候用脚本，什么时候用 Agent"——那是工具箱层面的分工判断。L3 这一篇进一步问：**Agent 的工具该怎么设计？**

区别在于：脚本时代，你写死流程，模型只负责填空；Agent 时代，模型自己决定调用什么工具、按什么顺序。控制权移交了，但移交的前提是工具设计得够好——接口模糊，自由度就变成随机性；接口清晰，自由度才变成能动性。L2 你给模型传的"参数"变成了工具的 `inputSchema`，打印到终端的"输出"变成了工具的返回结果。写法变了，目标没变：**让模型一次拿到需要的全部信息，不产生歧义，不浪费 token**。

---

## 延伸阅读

想深入"从功能设计到交互设计"的完整过程，推荐 Anthropic 官方的 [Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents)。它给出了一套评估驱动的迭代方法：先快速搭出工具原型，再生成贴近真实场景的评测任务跑评估，最后把评估记录交给 Agent 分析、让它自己改进工具——Anthropic 内部用这个循环迭代出来的工具，在留出测试集上的性能超过了研究员手工调优的版本。文中"选择正确的工具""为工具描述做提示工程"等原则，可以对照本文的三条原则阅读。这是 Day 6 练习的前哨。

---

## 今日收获

1. **问题**：Agent 不乱来，不等于干得好。约束管住了行为，管不住质量。
2. **结论**：工具设计 = Agent UX。你设计的不是工具本身，是模型与世界的交互界面。
3. **证据**：miniharness 消融实验——同一个模型，换一种工具格式，步骤数翻倍，完成度骤降。
4. **框架**：工具只有三种性质——内置、扩展、服务。成熟 Harness 三层都有，区别在每层放多少。
5. **洞察**：Pi 赌扩展层，Claude Code 赌服务层，Codex 押执行环境，OpenCode 两层都给，DSH 消解内置层——路径不同，殊途同归，都在回答"如何让 Agent 获得恰到好处的工具"。
6. **行动**：给你的工具找对层——能组合就别造，要共享放服务层，要性能放扩展层。Day 6 动手装一个。

---

## 参考资料

1. [tljcpa/miniharness：工具格式消融实验数据](https://github.com/tljcpa/miniharness)
2. [Pi 官方文档：tools.md](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/tools.md)
3. [Pi 官方文档：extensions.md](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md)
4. [MCP 规范与快速上手](https://modelcontextprotocol.io/docs/getting-started/intro)
5. [OpenAI：Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/)
6. [OpenAI Codex 官方文档：hooks 与 plugins](https://developers.openai.com/codex/cli/hooks)
7. [anomalyco/opencode 仓库](https://github.com/anomalyco/opencode)
8. [DeepSeek Harness 官方文档：architecture.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md)
9. [DeepSeek Harness 官方文档：cordis-primer.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/cordis-primer.md)
10. [Anthropic：Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents)
11. [Mario Zechner：Pi: a coding agent that is just right for me](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)
12. [buchidonggua/dg-ai-notes：pi-agent 实战教程第 5 章"定义工具——从功能实现到交互体验"（pi_sdk_learn/docs 目录）](https://github.com/buchidonggua/dg-ai-notes/tree/main/pi-agent/pi_sdk_learn/docs)
