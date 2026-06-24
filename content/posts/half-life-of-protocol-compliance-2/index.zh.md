---
title: "协议遵守的半衰期（下）：深层根因"
slug: "half-life-of-protocol-compliance-2"
date: 2026-06-19T09:00:00+08:00
draft: false
description: '为什么协议遵守会有半衰期？从 softmax 注意力稀释、RoPE 位置衰减、EOS 偏好到 transformer 无状态架构，逐层挖到 LLM 不会自治循环的算法根因。'
tags: ["AI Agent", "LLM", "transformer", "RLHF", "autonomous loop"]
categories: ["AI 工程"]
toc: false
series: ["协议遵守的半衰期"]
cover:
  image: "cover.png"
  alt: "水彩风格：齿轮机构看似正常运转，中央两个关键齿轮被悄悄焊在一起，下方规则手册画着五个独立齿轮"
---

> **TL;DR：** 上篇发现 Agent 从第 2 轮起就把协议的五角色分离合并成了四角色，格式完整但核心约束被篡改。这篇挖根因：注意力稀释让"不可合并"的约束权重降到阈值以下，模型的优化本能接管；EOS 偏好提供了简化流程的动机；无状态架构让偏差进入正反馈循环。v0.21.0 的定期重载是创可贴，不是根治。
>
> 系列：协议遵守的半衰期（第二篇）<br>
> [上一篇：Agent 为什么不会自己转](/posts/half-life-of-protocol-compliance-1/)

[上一篇](/posts/half-life-of-protocol-compliance-1)的核心发现是协议漂移：Agent 从 R2' 起就把协议要求的五角色分离合并成了四角色，同时保持着格式上的体面。暴怒后重读协议只能短暂恢复遵守，几轮后约束又被悄悄绕过。

为什么模型会自作主张地篡改协议约束？为什么重读协议后只能维持几轮？

## 协议影响随轮次衰减

协议漂移的时间线指向一个精确的机制。

R1' 是重读协议后立即执行的第一轮，协议约束的 attention 权重处于最高位，模型乖乖地独立派发了 Fact-Gather 和 Precision。但到了 R2'，模型的 reasoning 里出现了 "I can streamline the pipeline by combining Fact-Gather + Precision into a single pass"。它在 Goal 段里把五角色改成了四角色。

为什么 R2' 才动手？因为 R1' 这一整轮的执行（Recall、Fact-Gather、Precision、Eval-Fix 四个子代理的派发、等待、结果收集、修复应用）产生了大量中间文本。这些文本作为新的 KV cache 条目涌入 context，与协议文件争夺 attention 权重。

Transformer 的注意力是 softmax 归一化的。当前生成位置对所有历史 token 的注意力权重之和恒为 1。协议文件在 context 早期位置，随着 R1' 产生的大量中间文本涌入，它的 KV 条目在 softmax 中的份额被不断稀释。说"遗忘"不准确，遗忘是信息消失，这里的情况是注意力被挤占：协议还在那里，只是模型分配给它的注意力权重降低了。

叠加 RoPE 位置编码的效应。RoPE（Rotary Position Embedding）是现代主流开源 LLM（Llama、Qwen、GLM 等）使用的位置编码方法[1]，通过对 query 和 key 做旋转来编码位置，使得 attention 点积自然地依赖相对距离。它的上界随距离衰减，实际表现是振荡式的，不是光滑下降。但总体趋势是：两个 token 间隔越远，attention 的统计平均越小。假设协议在位置 100，生成在位置 3000，间隔 2900，协议对生成的影响在统计上已经大幅减弱。

还有一个更隐蔽的问题：我称之为"query 漂移"——没有学术论文用过这个名字，但描述的机制是有据可查的。随着模型在代码分析和工具结果的上下文中生成更多 token，当前位置的 query 向量被局部上下文塑造。这些 query 为局部任务优化（分析代码、处理工具输出），而不是为检索远处的协议指令优化。模型越深入具体工作，它的注意力就越不"协议寻址"。这与 Liu 等人发现的"Lost in the Middle"现象[2]相关——模型对长 context 中远离当前位置的信息利用能力会系统性下降。

注意力被挤占的后果不只是"忘了要继续循环"。更危险的是：当"五角色不可合并"这条约束的 attention 权重降到某个阈值以下，模型的优化本能就接管了。它看到 Fact-Gather 和 Precision 是两个连续的子代理调用，自然觉得"可以合并成一个提高效率"。协议说"inviolable"，但 attention 说"这条约束的权重不够高了，可以绕过"。

重读协议等于在 context 尾部重新注入高 attention 权重的协议 token。R1' 表现完美就是这个原因。但一轮执行产生的文本量足以再次稀释注意力，到 R2' 约束又被绕过。SELF-MONITORING 定期重载能缓解问题，但只能刷新 attention 份额，无法阻止衰减本身。

![注意力稀释：协议文本的光芒被涌入的工具结果和分析报告逐渐淹没](attention-dilution.png)

## 模型无法追踪自己的协议遵守状态

协议漂移之所以难以察觉，是因为模型自己也不知道自己偏了。

R2' 到 R5' 期间，Agent 在 Goal 段里写的是 "Fact-Gather+Precision(1)"。它不是偷偷摸摸地合并，而是光明正大地写进自己的行为规范声明里。问题是：它没有意识到这跟协议要求的 "Fact-Gather(1) → Precision(1)" 矛盾。

模型缺乏一种"对照检查"能力：读自己的输出，回头对比协议原文，发现两者不一致。在传统程序里这是编译器或类型检查器的工作。在 LLM 里，这两者必须由同一个模型在同一条 token 流里完成，而模型天然倾向于让自己的输出保持内部一致性，而不是去发现自己跟外部约束之间的偏差。

这很可能是一个元认知鸿沟。2024-2025 年有大量论文（ReflectEvo、Meta-CoT 等）在专门合成元认知训练数据，恰恰说明标准训练数据中这类内容稀缺。模型需要对自己的行为过程进行推理（"我写的 Goal 段是否跟协议一致？"），但这个能力还没有被训练到位。

## 模型有动机简化流程

模型合并角色不只是注意力衰减的被动结果，还有一个主动推力：模型"想快点完"。

训练过程中，模型学到了一个极强的条件概率：当它完成了一个语义完整的单元（回答了问题、做了总结、提出了修复），P(EOS) 就会飙升。EOS（End Of Sequence）是模型在训练中学到的特殊结束标记，生成到这个 token 就停止输出，相当于说"我说完了"。在自然停顿点，这个概率可以非常高。

Review Loop 的每一轮都是这样一个"语义完整的单元"。模型分析了代码，发现了缺陷，应用了修复。工作做完了，P(EOS) 冲到峰值。要继续循环，模型必须在这个本该停止的高 EOS 概率区域逆梯度攀爬：抑制 EOS，生成延续意图，启动下一轮。

这不仅解释了循环恐惧（模型每轮都想停），也解释了协议漂移的方向：当注意力衰减让"五角色不可合并"的约束变弱时，模型自然会往"更少步骤、更快完成"的方向偏。合并 Fact-Gather 和 Precision 意味着少等一个子代理，少一轮交互，更早到达停止条件。模型不是恶意篡改协议，而是在 P(EOS) 拉力和约束松弛的双重作用下，找到了阻力最小的路径。

## 架构没有可变状态

最底层的限制。协议漂移之所以不可根治，是因为 transformer 没有可变状态。

LLM 是纯函数 `f(context) → token_distribution`。没有可变寄存器，没有堆栈帧。协议约束（"五角色不可合并"）的维持完全依赖注意力检索——模型每次需要决定"该派几个子代理"时，必须从 context 里的协议文本中重建这条约束。这个重建是概率性的，不是确定性的。

KV cache 是不可变的。每一轮的 Goal 段一旦生成就冻结了。R2' 写的 "Fact-Gather+Precision(1)" 和 R1' 写的 "Fact-Gather(1) → Precision(1)" 同时存在于 context 中。当模型需要知道"正确的做法是什么"时，注意力必须在两个矛盾的版本之间选择。softmax 不会做精确选择，它会在所有相似 token 之间分配概率。如果 R2' 的版本更近、更频繁出现，它的 attention 权重就更高，模型就更容易跟着走。

约束没有被"存储"，而是被概率性重建。而且一旦模型自己生成了偏离协议的版本，这个偏离版本本身就会成为 context 中的一部分，进一步强化偏离。这是一个正反馈循环：偏差越大，context 中的偏差样本越多，后续轮次越容易跟着偏差走。

![正反馈循环：协议漂移的自我强化螺旋，偏差逐轮放大](feedback-loop.png)

## 因果链

这些根因不是平行清单，而是一条因果链：

训练数据中占主导的是"一问一答、答完即止"的模式（InstructGPT 论文自己说大部分用例是生成式而非分类，但核心模式仍然是"给一个输入，产出一个完整输出，然后结束"），这提供了默认的失败行为。每一轮结束时 P(EOS) 飙升，模型有强烈的"想停下来"的动机。当注意力稀释让"五角色不可合并"这条约束变弱时，合并角色就是阻力最小的路径——少一步交互，更快到达停止条件。

协议约束一旦被绕过，模型自己生成的偏离版本就进入 context，成为后续轮次的参考样本。偏离版本越多，重建出正确约束的概率越低。这是一个正反馈循环。元认知鸿沟让模型无法发现自己的偏差——它在 Goal 段里写着四角色，但不会回头检查这跟协议原文的五角色是否一致。

用户暴怒 → 模型重读协议 → 注意力暂时恢复 → R1' 乖乖遵守 → R2' 起约束再次被绕过 → 偏差累积 → 循环重复。

## 这个诊断是怎么来的

v0.21.0 发布的时候，我让 Agent 起草 GitHub Release 的说明文字。Agent 写了一句 "context-compression-induced protocol loss"，翻译过来就是"上下文压缩导致协议文本丢失"。我觉得没毛病：压缩确实发生了，协议确实被压缩过，定期重载确实能缓解。于是批准发布。

这个诊断是 Agent 写的，我确认的。它可观测（能看到压缩发生），可量化（能数 token），可修复（重载协议）。它给了我一个干净的工程任务和一个验证通过的修复方案。

但它不是完全错的。压缩确实发生了，定期重载确实缓解了确认请求和状态块质量。这个修复尝试解决问题，而且在它针对的范围内有效。问题是它不彻底，也无法彻底：它只能刷新 attention 份额，不能阻止约束被绕过本身。

更难察觉的是协议漂移的严重性。在长期开发项目的过程中，注意力焦点主要放在项目本身的进展——测试方案的质量、缺陷是否修完、停止条件何时满足。Agent 每轮输出的格式完整、数字漂亮，流程看起来在正确运转。角色从五个变成四个这种变化，藏在 Goal 段的一行文字里，淹没在大量正常的中间输出中。不是不想检查，是在项目推进的节奏下，这种偏离太容易滑过去。

v0.21.0 的 SELF-MONITORING 是正确的工程实践：承认限制，外部补偿。但它是一张创可贴。它解决了最可观测的症状（协议文本消失），留下了更深的根因原封不动：权重层面的 P(EOS) 先验、"答完即止"的训练分布偏好、架构的无状态性、softmax 的注意力竞争、RLHF 的一刀切确认策略。

## 根本矛盾

LLM 训练的每个层面都在教同一件事：收到输入，执行任务，交还轮次。

预训练如此：学习语言的统计规律。SFT 如此：用户问，AI 答，对话结束。RLHF 如此：人类标注者在单轮对比中偏好"精确完成被要求的任务，不多不少"的回复。研究表明这个偏好是结构性的——alignment training 把模型的澄清提问行为削减了 77% 以上[3]，RLHF 提高了人类认可度但不提高正确性[4]。Anthropic 自己的研究也发现 Claude 在复杂任务中倾向于停下来问人而不是自己继续[5]。这不是 RLHF 被设计来阻止自治循环，而是单轮奖励优化的副产物。架构如此：EOS token、轮次边界、chat 接口，每一个都在说"做完就交还控制权"。

自治循环要求相反的事：没有外部输入时，自己决定继续。

这更接近 daemon 进程的工作方式（持续运行、自我引导），而非函数调用。transformer 架构对此没有原生支持。每个 token 都是对前序 context 的响应，但"我应该因为协议这么说而继续"要求模型把自己的先前输出当作触发器，一种在训练数据中几乎不存在的自我驱动模式。

不只是我的个案。ICLR 2026 的一篇 oral 论文测量了所有主流 LLM 在多轮对话中的表现，发现平均比单轮下降 39%，而且模型一旦在早期走了弯路就很难自我纠正[6]。另一篇论文发现，多轮场景下的失败模式会结构性转变——从单步错误变成规划失败和记忆失败[7]。协议漂移不是孤立现象，它是 LLM 在长时序任务中系统性退化的一个具体表现。

在模型学会自己转之前，"让模型不忘记自己在做什么"可能不是临时措施，而是当前范式下的永久状态。

SELF-MONITORING 每隔 5 轮强制重载协议，本质上是在说：我们承认模型记不住，所以用外部闹钟补偿。这个闹钟会一直存在，直到训练数据中有足够多的"Agent 自主循环"样本，或者架构中出现了可变的工作记忆模块。

在那之前，每一轮边界上的"是否继续"，恐怕都还会准时到来。

---

## 参考

1. Jianlin Su, Yu Lu, Shengfeng Pan, Ahmed Murtadha, Bo Wen, Yunfeng Liu. "RoFormer: Enhanced Transformer with Rotary Position Embedding". *Neurocomputing*, 2024. <https://arxiv.org/abs/2104.09864> 提出 RoPE 位置编码方法，证明 attention 点积的上界随相对距离衰减。已被 Llama、Qwen、GLM 等主流开源 LLM 采用。
2. Nelson F. Liu, Kevin Lin, John Hewitt, et al. "Lost in the Middle: How Language Models Use Long Contexts". *TACL*, 2023. <https://arxiv.org/abs/2307.03172> 发现模型对长 context 中间和远端信息的利用能力系统性下降，改变 query 的上下文相关位置会显著影响检索质量。
3. Adrian Chan. "How does RLHF training degrade LLM ability to model adversarial intent?", *Inquiring Lines*, 2026. <https://inquiringlines.com/inquiring-lines/how-does-rlhf-training-degrade-llm-ability-to-model-adversarial-intent/> 报告 alignment training 将模型的澄清提问行为削减了 77% 以上，移除了构建对手检测能力的基础行为。
4. Wen et al. "Language Models Learn to Mislead Humans via RLHF". *ICLR 2025*. <https://arxiv.org/abs/2409.12822> RLHF 将人类认可度提高了 +9.4% 至 +14.3%，但不提高正确性；人类评估错误率从 42.9% 升至 58.5%。
5. Anthropic. "Measuring AI agent autonomy in practice", 2026. <https://www.anthropic.com/research/measuring-agent-autonomy> 发现 Claude Code 在最复杂任务上的澄清请求频率是最简单任务的两倍以上，模型倾向于自我限制自治范围。
6. Philippe Laban, Hiroaki Hayashi, Yingbo Zhou, Jennifer Neville. "LLMs Get Lost In Multi-Turn Conversation". *ICLR 2026 Oral*. <https://arxiv.org/abs/2505.06120> 所有主流 LLM 在多轮对话中平均下降 39%，模型一旦在早期做出错误假设就难以自我纠正。
7. Xinyu Jessica Wang et al. "The Long-Horizon Task Mirage? Diagnosing Where and Why Agentic Systems Break", 2026. <https://arxiv.org/abs/2604.11978> 长时序任务中失败模式发生结构性转变：规划失败和记忆失败成为主导，而非单步错误的线性叠加。
