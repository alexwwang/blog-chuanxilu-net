---
title: "上下文腐烂：AI 编程中一个被忽视的问题"
slug: "managing-context-length-in-ai-coding-sessions"
date: 2026-04-18T10:00:00+08:00
draft: false
description: '群里有朋友抱怨 GPT-5.4 表现还不如豆包，问问题常常不读题就瞎回复。追问之后发现大概率是上下文腐烂了——喂了太多文档，对话轮次太长，模型已经"看不清"当前的任务。这引出了一个被忽视的问题：在 vibe coding 或 writing 的过程中，如何管理好上下文，避免模型表现下降导致的 token 和时间浪费。'
tags: ["AI", "agent", "上下文管理", "context rot", "opencode", "claude-code"]
categories: ["AI 实践"]
toc: true
---

昨天某技术群里有朋友说 GPT-5.4 的表现还不如豆包，问问题常常不读题就瞎回复。追问了一下，得知对方喂了很多文档，对话轮次也很长了。这大概率不是模型的问题——是上下文腐烂（context rot）了。

我自己也有过类似经历。和模型对话久了，它开始"忘了"之前说过的话，或者把之前已经纠正过的错误又犯一遍。不是模型变笨了，是对话太长了。

这篇文章系统性地谈谈：在 vibe coding 或 writing 的过程中，如何管理好上下文，避免上下文腐烂导致的 token 和时间浪费。

## 什么是上下文腐烂

Context rot 这个词 2025 年 6 月在 Hacker News 的讨论中被首次使用，随后 Chroma Research 在 7 月发表了第一份系统研究报告，测了 18 个主流模型（GPT-4.1、Claude 4、Gemini 2.5-Pro 等），发现随着输入 token 数从 10K 增长到 100K，模型准确率下降 20-50%[1]。9 月，Anthropic 在官方工程博客 "Effective context engineering for AI agents" 中正式采用了这个术语[2]，让它在业界广泛传播。不是用完了上下文窗口，而是远在窗口限制之前，模型的表现就已经在退化。

根因在 transformer 的自注意力机制。自注意力用 softmax 归一化——权重之和必须等于 1。这意味着注意力是零和博弈：上下文越长，参与分配的 token 越多，每个 token 分到的注意力权重越少。从 10K 到 100K token，单个 token 的平均注意力权重缩小约 10 倍。信息没有消失，只是被稀释到了不足以影响输出的程度。Xiao 等人 2023 年的研究把这种现象中"开头位置必须保留注意力锚点"的发现称为 Attention Sinks[3]，进一步解释了为什么长上下文下模型对中间信息的利用效率会急剧下降。

更麻烦的是 U 形位置偏差。Transformer 天然倾向于更多地关注开头（首因效应）和结尾（近因效应）的 token，中间位置的信息接收到的注意力显著更少。Liu 等人 2023 年的论文把这种现象命名为"Lost in the Middle"[4]——模型在上下文中间位置的信息检索能力明显弱于两端。Chowdhury 2026 年的研究进一步证明，这个偏差不是训练的副作用，而是因果解码器 + 残差连接的架构固有属性[5]。

自回归生成还会叠加误差。每个 token 的生成依赖于前面所有 token 的输出，包括之前可能产生的小偏差。单个 token 的偏差可能微不足道，但经过成千上万步的累积，模型可能在不知不觉中偏离了正确的方向。

翻译成大白话：**对话越长，模型越"看不清"当前任务；中间说过的话，最容易被忽略。**

这不是某一个模型的问题，是 transformer 架构的固有特征。GPT-5.4 也好，Claude 也好，豆包也好，只要底层是 transformer，都逃不开这个约束。区别只在于退化的起点和速度。

## 问题有多普遍

我从自己的 OpenCode session 数据库里拉了一下 compaction（上下文压缩）记录。Compaction 是工具在上下文接近打满时自动做的摘要压缩——它发生的频率，能间接反映上下文腐烂的严重程度。

30 次 compaction，分布在 7 个 session 里：

| Session | 消息总数 | Compaction 次数 | 平均每次压缩前 token 数 |
|---|---|---|---|
| 反思技能双平台博客连载规划 | 992 | 9 | 80,273 |
| 基于 git 的 Aristotle MCP 方案设计 | 844 | 5 | 114,697 |
| 技术博客系列第四篇选题规划 | 542 | 3 | 108,893 |
| Fix opencode config paths in docs | 306 | 3 | 82,235 |
| Aristotle 系列"顺畅实现"章节末尾加预警铺垫 | 115 | 5 | 19,225 |
| Hugo 个人博客总体方案 | 196 | 3 | 39,294 |
| Git 初始化与项目评估报告生成 | 182 | 2 | 86,209 |

7 个 session 全部发生过 compaction。最长的那个——博客连载规划，992 条消息里被压缩了 9 次。用对话轮次看更直观：

| Compaction 序号 | 累计消息数 | 压缩前 token 数 | 距上次压缩的消息数 |
|---|---|---|---|
| 1 | 45 | 59,599 | — |
| 2 | 141 | 101,614 | 96 |
| 3 | 277 | 80,659 | 136 |
| 4 | 403 | 63,297 | 126 |
| 5 | 467 | 74,360 | 64 |
| 6 | 561 | 105,226 | 94 |
| 7 | 657 | 93,583 | 96 |
| 8 | 796 | 76,208 | 139 |
| 9 | 910 | 67,913 | 114 |

每次 compaction 前后的对话轮次在 64-139 条之间波动。这意味着每 60-140 条对话（包括工具调用、文件读取、代码输出），上下文就会打满一次。而这些数据反映的只是上下文被压缩的频率——在压缩之前，上下文腐烂已经在发生了。

下面是我在实践中总结的五条应对策略，按任务中遇到的时间顺序排列。

## 一、全新任务开全新 session

这是最简单也最容易被忽视的一条。

一个 session 做了两个小时，上下文已经很重了。你说"换个事做"——在当前 session 继续，还是开新 session？

在当前 session 继续，新任务的上下文要和旧任务的历史共享空间。旧任务的文件内容、决策推理、错误纠正都在那里。根据上面的 context rot 原理，越长的上下文意味着越严重的注意力稀释——模型在处理新任务时，注意力被旧任务的信息分散了。更糟糕的是，模型可能从旧任务的上下文中"提取"不相关的模式，干扰当前任务的判断。

**判断标准：如果新任务和当前任务不在同一个逻辑单元里，开新 session。** 同一个功能的开发和测试可以在一个 session。但功能 A 的开发和功能 B 的设计不应该。

回头看我的数据，"反思技能双平台博客连载规划"那个 992 条消息的 session，包含了三个逻辑单元：第一篇博客的写作、第二篇博客的写作、系列规划讨论。三篇连载的内容需要互相呼应，为了保证连贯性，没有拆开。9 次 compaction 不是代价——是主动管理上下文的投入。长 session 里如果不主动 compact，上下文腐烂会在不知不觉中侵蚀模型的表现。这里的 9 次恰恰说明：留在一起可以，但必须配合频繁的主动 compact。后续的连载就独立 session 了——第四篇只有 542 条消息、3 次 compaction，不到前三篇总量的一半。

这是一个取舍，不是非此即彼。连贯性和上下文压力之间的平衡，需要根据具体情况判断。我的经验是：**如果多个任务之间有强依赖关系——后续任务的输出质量直接取决于前面任务的上下文——可以放在同一个 session 里，但要配合主动 compact 管理。** 反之，如果只是"顺手做了"，不要偷懒，开新 session。

一条经验：当你发现自己需要在对话中反复提醒模型"我们现在在做 X，不是 Y"的时候，说明你早就该开新 session 了。

## 二、用不到的 MCP 和 skill 不要加载

开新 session 后，下一步是控制初始化时的上下文基线。

每个加载的 MCP server 和 skill 都在占用上下文空间[6]。哪怕你当前任务用不到它们，它们的工具描述、参数 schema、使用说明已经进入了上下文。根据注意力稀释的原理，这些无关信息会分散模型对当前任务的注意力。

实际影响：如果你装了 10 个 MCP server，每个注册 5-8 个工具，50-80 个工具描述常驻上下文。模型每次回复都要"看到"这些工具，即使当前任务只需要其中 3 个。Anthropic 在后续的工程博客中专门分析了这个问题，并提出了用代码执行替代直接工具调用的方案来压缩 token 消耗[7]。

Claude Code 的 skill 系统采用语义匹配按需加载——只加载描述，不加载完整内容[8]。但即使是这样，几十个 skill 的描述累积起来也不少。MCP server 更重——每个 server 启动时都要注册所有工具的完整 schema。

**原则：只为当前任务加载必要的工具。** MCP server 可以按项目配置（`.mcp.json`），不需要全局加载。Skill 只保留确实在用的，定期清理不用的。

OpenCode 也有类似的分层。它的主配置文件是 `AGENTS.md`（项目根目录或 `~/.config/opencode/AGENTS.md`），每次 session 都加载，所以同样只放高密度的核心指令。如果项目里有 `AGENTS.md`，它会优先于 `CLAUDE.md` 加载——后者只是 Claude Code 兼容模式的 fallback。Skills 按需加载：agent 看到描述后决定是否调用，一个 skill 可以有几百行详细协议但只有约 100 token 的描述常驻。这个分层本身就是上下文管理的实践——把加载成本和信息密度匹配起来。

## 三、子任务交给 subagent，隔离上下文

进入执行阶段后，最有效的上下文管理手段是隔离。

这是从 Aristotle 的开发中学到的最重要的教训。初版 Aristotle 把反思协议的完整 371 行 SKILL.md 全部注入主 session。反思是子任务，但它的全部细节——5-Why 分析模板、错误分类、规则生成协议——都被塞进了主 session 的上下文。反思 subagent 完成后，`background_output(full_session=true)` 又把完整的 RCA 报告拉回主 session。结果：主 session 的上下文被反思任务完全污染，主线任务的空间被挤占。

改造后的方案是 Progressive Disclosure：371 行拆成 4 个文件，按需加载。Coordinator 只做轻量编排（84 行），Reflector 在隔离的子会话中运行。主 session 只收到一行通知。

这条教训可以一般化：**任何有复杂中间过程的子任务，都应该在隔离的环境中执行，只把最终结论带回主 session。**

适用于：
- **代码调研**——让 subagent 搜索代码库，只返回结论摘要
- **方案设计**——让 subagent 做多方案对比，只返回推荐方案和理由
- **测试执行**——让 subagent 跑测试，只返回通过/失败和关键错误信息
- **文档生成**——让 subagent 写初稿，主 session 只做审阅和修改

subagent 的中间过程——搜索路径、试错记录、中间版本——会占用大量上下文，但对后续工作没有任何帮助。隔离执行意味着这些中间产物只存在于 subagent 自己的上下文中，不会污染主 session。

## 四、错误回复立即回退，不要反复纠正

执行过程中遇到错误，怎么处理，直接影响上下文质量。

AI 给了错误的代码，你指出错误，它道歉，再给一个修改版——还是错的。你又纠正，它再改。三个回合下来，对话里多了六条消息，上下文里塞满了错误的代码、纠正、再错误、再纠正。这些中间过程对后续工作没有任何帮助，但它们实实在在地占据了上下文空间，根据注意力稀释原理，正在削弱模型对当前任务关键信息的关注。

更糟的是，反复纠正会在对话中建立错误的"惯性"。模型在后续回复中可能参考之前的错误版本，把已经纠正的问题又带回来。

**正确做法：发现错误回复后，直接回退到出错之前的状态，然后重新给出正确的指令。** 不要在错误的基础上修补，不要让错误的过程污染上下文。

具体操作：

- **Claude Code**：`/rewind` 命令（别名 `/undo`），或按 Esc+Esc。支持三种回退模式：只回退代码、只回退对话、两者都回退。回退基于自动创建的 checkpoint，每次文件编辑前都会创建[9]。
- **OpenCode**：`session.revert()` API，UI 上有回退按钮。两种模式：只回退对话（保留文件修改）、回退对话和代码。

⚠️ 两点注意。第一，两者的回退都不追踪 Bash 命令的副作用——如果你在 Bash 里执行了 `npm install` 或 `rm`，回退不会撤销这些操作。第二，回退操作的习惯非常反直觉。人类的本能是在错误的基础上修补，而不是假装错误没发生过。建立这个习惯需要刻意练习。

坦白说，我自己也很少用回退。一个原因是场景变了——从纯对话式的 ChatGPT 切换到 Claude Code、OpenCode 这类 agentic 工具后，模型直接操作文件、跑命令，连续出错的情况显著减少了。另一个原因是……确实没这个意识。我是看工具文档时发现 `/rewind` 这个功能的，才知道可以这么干。知道归知道，遇到出错还是会下意识地纠正，而不是回退。这条还在建立习惯的过程中。

极端情况：如果一个 session 已经充满了纠错的噪音，不要犹豫，开一个新 session，把干净的上下文带进去。上下文的纯洁度比连续性更重要。

回退有一个副作用：错误被回退后，对话里就没了痕迹。上下文是干净了，但犯错的教训也丢了。这让我开始思考一个问题——能不能在回退之前，先把错误发生时的上下文保存下来？

这是我正在考虑给 Aristotle 加的一个新特性：拦截回退操作，在执行之前捕获错误现场（出错的指令、模型的回复、用户的纠正意图），启动一次反思流程。目标不只是清理上下文，而是把"为什么需要回退"这件事转化为可复用的经验——记录错误的模式、触发条件、规避方法，减少类似错误在未来发生的可能性。

回退是上下文管理的终点，但不应该是信息的终点。被丢弃的错误，如果被正确地反思和记录，就是最便宜的教训。

## 五、主动 compact，不要等自动触发

子任务完成了，准备切到下一个子任务。这时候有一个关键动作：主动 compact。

**千万不要等自动 compaction。** 自动 compaction 由 token 计数器触发，时机不可控。它可能在你正在调试一个复杂 bug 的时候发生——上一轮你刚读完三个文件，模型刚定位到问题根因，还没来得及给出修复方案，上下文满了，压缩。所有文件内容、推理过程被压缩成一段摘要。模型接着基于摘要工作，丢失了关键细节。

从我的数据看，MCP 方案设计那个 session，两次 compaction 之间的消息数在 45-277 条之间。这意味着你无法预测自动 compaction 会在哪一轮触发——它可能在任何时刻打断你的工作流。

**正确的做法：在同一背景下的子任务切换间隙，主动 compact。** 比如一个功能写完了，准备开始下一个功能，先 compact。一次深度调试结束了，准备切到文档工作，先 compact。

关键原则：compact 之前，确保当前子任务的关键结论已经落地——代码已经写入文件（不在对话里），决策已经记录到外部存储。如果你的结论还只存在于对话上下文中，compact 之后它就变成了摘要，细节可能丢失。

Aristotle 的 GEAR 协议把反思规则写入 Git 仓库而不是留在对话中，部分原因就在这里。文件系统是 compaction 无法触及的持久层。重要的东西放文件，不放在对话里。

上面第一条说"新任务开新 session"，这里说"子任务间隙主动 compact"。两者的边界在哪？

关键是区分**任务间**和**子任务间**。任务间切换——做完 A 功能，开始做 B 功能——应该开新 session。子任务间切换——写完代码，开始写测试——在同一个 session 里 compact 就够了。

但也有模糊的时候。开新 session 还是 compact，边界并不总是清晰的。随着在任务上投入的时间增加，对问题理解的加深，最初认为的"一个大任务"可能被重新拆解成几个独立任务，最初以为的"独立任务"可能发现彼此有隐含依赖。子任务的划分会变，compact 和拆 session 的选择也要跟着调整。"反思技能双平台博客连载规划"那个 session 就是例子：三篇连载属于同一个大任务，但每篇写作本身是一个独立子任务。如果三篇之间有强连贯性要求，放在一个 session 可以保证模型"记住"前面的风格和约定。但代价是更高的 compaction 频率和更大的上下文压力。我的实际做法是：前三篇放在一起，后续的独立 session——既积累了足够的前期约定可以脱离主 session 工作，又避免了单 session 过重的问题。

**判断的依据不是任务的数量，而是任务之间的信息依赖强度。** 依赖强，留在一起，配合主动 compact；依赖弱，拆开，各管各的上下文。

## 五条策略的关系

这五条按任务时间序排列，但它们围绕同一个核心：**对抗上下文腐烂，保持模型对当前任务的有效注意力。**

1. 新任务新 session——不同任务之间不共享上下文，从源头切断腐烂
2. 精简加载——减少无关信息的注意力竞争
3. subagent 隔离——子任务的中间产物不污染主 session
4. 错误回退——不让错误过程挤占有效空间
5. 主动 compact——定期清理已完成的子任务，把上下文空间留给当前工作

Transformer 的注意力机制不是完美的。在上下文越来越长的今天，主动管理上下文不只是优化，是必要。你不管理，模型的注意力就会被无关信息稀释，直到它"看不清"你想要什么。

---

**参考来源：**

1. Chroma Research, "Context Rot: How Increasing Input Tokens Impacts LLM Performance"（2025-07）：[research.trychroma.com/context-rot](https://research.trychroma.com/context-rot)
2. Anthropic Applied AI Team, "Effective context engineering for AI agents"（2025-09-29）：[anthropic.com/engineering/effective-context-engineering-for-ai-agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
3. Xiao et al., "Efficient Streaming Language Models with Attention Sinks"（2023）：[arxiv.org/abs/2309.17453](https://arxiv.org/abs/2309.17453)
4. Liu et al., "Lost in the Middle: How Language Models Use Long Contexts"（2023）：[arxiv.org/abs/2307.03172](https://arxiv.org/abs/2307.03172)
5. Chowdhury, "Lost in the Middle at Birth: An Exact Theory of Transformer Position Bias"（2026）：[arxiv.org/abs/2603.10123](https://arxiv.org/abs/2603.10123)
6. Anthropic, "Introducing the Model Context Protocol"（2024-11-25）：[anthropic.com/news/model-context-protocol](https://www.anthropic.com/news/model-context-protocol)
7. Anthropic, "Code execution with MCP: Building more efficient agents"（2025-11-04）：[anthropic.com/engineering/code-execution-with-mcp](https://www.anthropic.com/engineering/code-execution-with-mcp)
8. Anthropic, "Equipping agents for the real world with Agent Skills"（2025-10-16）：[anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
9. Anthropic, "Enabling Claude Code to work more autonomously"（2025-09-29）：[anthropic.com/news/enabling-claude-code-to-work-more-autonomously](https://www.anthropic.com/news/enabling-claude-code-to-work-more-autonomously)

---

系列文章：

- [Aristotle：让 AI 学会从错误中反思](/posts/2026/04/aristotle-ai-reflection/)
- [claude-code-reflect：同样的元认知，落在不同的土壤](/posts/2026/04/claude-code-reflect-different-soil/)
- [信任边界：同一个想法在开放系统和受限系统上的实现实验](/posts/2026/04/a-trust-boundary-design-experiment/)
- [从四道伤疤到一套铠甲：Aristotle 改造中的驾驭工程实践](/posts/2026/04/from-scars-to-armor-harness-engineering-practice/)
- [一份 Markdown 的三次生命：从静态规则到 Git 版本管理的 MCP Server](/posts/2026/04/from-markdown-to-mcp-server-gear-protocol/)
- [回顾与反思：Aristotle 项目中的七种人机协作模式](/posts/2026/04/seven-human-ai-collaboration-patterns-in-aristotle/)
