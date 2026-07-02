---
title: "Intel Mac 上选一个中英文语音输入工具：purr、typeflux、openquack、freeflow 横向对比"
slug: "macos-voice-input-tools-comparison"
date: 2026-07-02T07:00:00+08:00
draft: false
description: "一台 Intel MacBook Pro（MacBookPro16,2），需要支持中文和英文的语音输入。GitHub 上四个项目——purr、typeflux、openquack、freeflow——各有取舍。本文从实际硬件出发做一次横向对比，记录选择过程和安装体验。"
tags: ["macOS", "语音输入", "ASR", "typeflux", "freeflow", "Intel Mac", "开源"]
categories: ["工具评测"]
toc: true
cover:
  image: "cover.png"
---

## 为什么需要语音输入

打字每分钟 50-80 字，语速正常每分钟 150-180 字。写邮件、做笔记、写代码注释，这些场景里语音输入的效率优势很明显。[1]

但真正让我认真找语音输入工具的，是 **vibe coding**。核心瓶颈从"写代码的速度"变成了"表达意图的速度"——改个 prompt 要敲半天，调个参数要切出去打字，频繁打断思路。语音输入刚好解决这个问题：想到什么直接说出来，保持 flow。

{{< figure src="vibe-coding-concept.png" alt="语音输入与打字的对比：瓶颈从打字速度转移到意图表达速度" >}}

市面上不缺语音输入方案：豆包的语音输入、微信的语音转文字、各大输入法的语音模块，都能用。但它们有两个绕不开的问题：

1. **隐私和自由度。** 豆包的语音走豆包的模型，微信的语音走微信的模型。你绑定了它们的生态，就得接受它们的识别质量、隐私策略和数据流向。不支持切换后端，不支持本地模型。哪天功能改了、收费了、下架了，你只能接受。闭源意味着不可控。
2. **硬件资源占用。** 这些方案往往是完整输入法或应用的一部分，后台常驻、内存占用不小。为了一个语音输入功能，不值得扛一个几百 MB 的输入法全家桶。

回头看市面上的方案，特点高度一致：全部闭源、无法自选模型、都是完整输入法而非独立语音工具，输入内容默认走厂商服务器。没有一款支持"我只想要一个语音输入按钮，不要输入法"。

所以我的要求很明确：**开源**，能看代码、能选语音识别引擎、能本地跑也能接云端方案。必须支持 **中文 + 英文混合输入**，文字在当前光标位置直接插入，不要复制粘贴。

还有一个限制：我手头是一台 2020 年初的 Intel MacBook Pro（MacBookPro16,2），Core i5 @ 2GHz、4 核、16GB 内存，没有 Apple Neural Engine。很多 Apple Silicon 独占的工具跑不了。

GitHub 上搜了一圈，找到四个项目：iamarunbrahma/purr、mylxsw/typeflux、larryxiao/openquack、zachlatta/freeflow。这篇把四个项目走了一遍，记下对比结果和选择过程。

## 四个项目概览

四个项目都在 macOS 上做语音输入，但技术路线和硬件要求差异很大。

### purr

- GitHub：https://github.com/iamarunbrahma/purr
- 定位：macOS 菜单栏语音输入工具，主打简洁和原生体验
- 技术栈：SwiftUI、WhisperKit
- 特色：录音后自动转写，插入当前应用；支持智能标点、自定义热键、快速复制

**硬件要求就挡在门外了。** purr 的 README 没有明确写最低 macOS 版本，但 WhisperKit 是它的底层依赖。WhisperKit 要求 Apple Silicon（M1+）和 macOS 14+。[2] Intel Mac 上 WhisperKit 虽然可以纯 CPU 推理，但性能很差——依赖 Apple Neural Engine 的优化路径全部失效，几秒的音频要处理 5 秒以上。录一句话等五秒出结果，语音输入就失去了意义。

purr 本身是个好产品，设计精致、交互流畅——前提是你有一台 Apple Silicon Mac。

### openquack

- GitHub：https://github.com/larryxiao/openquack
- 定位：受 purr 启发的开源替代，但试图走本地模型路线
- 技术栈：Swift、WhisperKit、Core ML
- 特色：开源免费，强调隐私（本地处理）

**硬件门槛更高。** openquack 也依赖 WhisperKit + Core ML 做本地推理，模型加载后单次推理需要约 5GB 显存。[3] Apple Silicon 的统一内存架构（M1/M2/M3 的 8-16GB 共享内存）刚好够用。Intel Mac 的独立显存最多 4GB（部分高配），加上 CPU/GPU 内存分离，本地推理很难跑起来。

openquack 的项目描述也直接声明了需要 Apple Silicon：

> A native macOS menubar voice transcription tool, powered by WhisperKit. Works on Apple Silicon.

### typeflux

- GitHub：https://github.com/mylxsw/typeflux
- 定位：macOS 菜单栏语音输入工具，强调"按住说话，松开插入"的零切换工作流
- 技术栈：Swift、多种 STT 后端
- 特色：支持多个语音识别引擎（本地 + 云端），自定义热键，Persona 系统，录音历史管理

**最不一样的地方：硬件包容性。** typeflux 最早只支持 Apple Silicon，但在 2025 年底的 PR 中加入了 Intel Mac 原生支持。[4] 它的架构不绑定单一推理引擎，而是抽象出一个 STT provider 层：

{{< figure src="typeflux-architecture.png" alt="Typeflux 的 STT provider 抽象层架构示意图" >}}

| Provider | 类型 | 适用场景 |
|---|---|---|
| Typeflux Cloud | 云端 | 零配置，开箱即用 |
| Local Model | 本地 | 隐私优先、离线可用 |
| Alibaba Cloud ASR | 云端流式 | 低延迟，中文优化 |
| Doubao Realtime ASR | 云端流式 | 中文场景深度优化 |
| Google Cloud Speech | 云端 | 多语言、企业级 |
| OpenAI Whisper API | 云端 | 高准确率 |
| Groq | 云端 | 极速推理、低成本 |
| Free Models | 云端 | 自建 OpenAI 兼容端点 |

本地模型方面，typeflux 支持 SenseVoice Small、FunASR（Paraformer）、WhisperKit Medium/Large、Qwen3-ASR 多种选择。SenseVoice Small（234M 参数、~350MB 模型文件）在 Intel Mac 上通过 sherpa-onnx 运行时延迟约 2-3 秒，短句语音输入可以接受。[5]

### freeflow

- GitHub：https://github.com/zachlatta/freeflow
- 定位：macOS 菜单栏语音输入工具，主打简洁
- 技术栈：Swift、Groq Whisper API
- 特色：极简设计，安装即用（配置 Groq API key）

**纯云端路线。** freeflow 不做本地推理，完全通过 Groq 的 Whisper API（large-v3 / large-v3 Turbo）做转写。Groq 的 LPU 硬件跑 Whisper 可以达到 189-216 倍实时速度——1 小时音频 8-12 秒转写完成。[6]

不挑硬件，Intel Mac 跑起来体验跟 Apple Silicon 完全一致，因为繁重计算都在云端。中文 WER（词错误率）约 4.1%，英语约 2.1%。[7] 准确率够用，但不出彩——中文不如阿里云 Paraformer 或豆包 ASR 这些原生中文引擎。

对 Intel Mac 用户来说，freeflow 是预算最低的选择：不用下载模型，不用配置多个后端。注册 Groq（有免费额度），按每小时 $0.111 计费就能用。代价是没有本地离线能力，所有音频都要上传到 Groq 的服务器。

## 横向对比

| | purr | openquack | typeflux | freeflow |
|---|---|---|---|---|---|
| CPU 推理 | ❌（推理过慢，不可用） | ❌（不可用） | ~2-3 秒 | ❌（纯云端） |
| Apple Silicon 体验 | ✅ | ❌ | ✅ | —（纯云端） |
| 中英双语 | ✅ | ✅ | ✅ | ✅ |
| 中文专项优化 | 无 | 无 | 有（AliCloud/Doubao/SenseVoice） | 无 |
| 本地离线 | ✅ | ✅ | ✅ | ❌ |
| 云端转写 | ❌ | ❌ | ✅（多种选择） | ✅（Groq） |
| 硬件门槛 | Apple Silicon + macOS 14+ | Apple Silicon | macOS 13+，x86_64 | macOS 12+（纯云端） |
| 安装复杂度 | 低 | 低 | 低 | 低 |
| Stars | ~63 | ~31 | ~302 | ~2k |
| 开源协议 | MIT | MIT | AGPL-3.0 | MIT |

> purr 和 freeflow 走单一路线（WhisperKit 和 Groq），openquack 依赖 Apple 生态；typeflux 通过抽象 provider 层实现最广的硬件兼容。

{{< figure src="comparison-overview.png" alt="四款 macOS 语音输入工具在 Intel Mac 上的可用性对比" >}}

## 选择

Intel Mac 上能用的只有 typeflux 和 freeflow。freeflow 更简单，但一个 Groq API key 配完就固定了，没有其他选项。

我的选择是 typeflux，三个原因。

1. **中文识别能力。** freeflow 的 Groq Whisper 中文 WER 约 4.1%，安静环境下够用。typeflux 可以选阿里云 Paraformer 或豆包实时 ASR——原生中文引擎，中文准确率远高于 Whisper。[8] 也可以选 SenseVoice Small 本地跑，不依赖网络。多一个选择总是好的。

2. **Persona 系统。** typeflux 内置了两个预设 Persona——"Typeflux"和"English Translator"。默认用 Typeflux，说什么输入什么。需要英语时从菜单栏切到 English Translator，不管说什么语言都直接在焦点处输入英文，不用复制粘贴。

3. **容错路径。** typeflux 的 STT Router 有 fallback：首选 STT 失败后自动降级到 Apple Speech 兜底。[9] Intel Mac 跑本地模型偶尔会慢，有这个至少不会卡死。

## 安装过程

typeflux 的最新 release 有两种下载方式：完整安装包（~190MB，内含 SenseVoice 模型文件）和应用-only 安装包（~12MB，首次启动时自动下载模型）。

实际装的是 app-only 版——下载后拖入 `/Applications` 即可。本地模型需要手动准备：在设置 → 模型设置里点击「准备本地模型」，等几分钟下载完成。模型文件存放在 `~/Library/Application Support/Typeflux/`，总磁盘占用约 377MB（app 45MB + 模型和数据 332MB）。

用 OpenCode 这类工具的话，下载安装 typeflux 交给 agent 就行。开个新 session，告诉它「下载安装 typeflux」，剩下自动搞定。装完手动配置一下。

启动后需要授予三个权限：
- **麦克风**：录音需要
- **辅助功能**：文字插入（模拟键盘输入）
- **语音识别**：Apple Speech fallback 需要

默认热键是 `Fn`。但 Fn 还要用来按功能键（F1-F12），所以我改成了 `Control + Fn`。双击 `Fn` 在 macOS 里默认是切换输入法，我就把 Ask Anything 触发改成了双击 `Option`，用于语音提问或内容改写。

关于 Apple Speech 多说一句。在设置 → 高级设置里，最后一项是「启用 Apple 回退」，默认关闭。打开后，Apple Speech 会在其他 STT 都失败时作为兜底。注意两点：

- 这是 macOS 系统级语音识别，最终走 Apple 服务器，需要网络
- 音频会上传 Apple 服务器处理

## 当前状态

typeflux 在我这台 Intel MacBook Pro 上跑了一段时间了。日常工作流：

- **默认后端**：Typeflux Cloud（零配置）
- **本地离线**：SenseVoice Small（无网自动切换）
- **兜底**：Apple Speech（STT Router fallback）
- **Persona**：系统自带两个——"Typeflux"和"English Translator"

Typeflux Cloud 延迟约 0.5-1 秒，SenseVoice Small 在 Intel Mac 上大约 2-3 秒。日常以云端为主，本地负责无网场景。

## 补充：freeflow 的体验

如果只需要基本的英文+中文语音输入，不想配置多个后端、不想管理模型文件，freeflow + Groq API 是上手最快的方案。Groq 注册后赠送免费额度，`whisper-large-v3` 定价 $0.111/小时，`whisper-large-v3-turbo` 定价 $0.04/小时。[10] 一天用一两个小时，一个月花不了几美元。

freeflow 的不足：没有改写能力、没有 Persona、没有中文专项优化。语音进去是什么就是什么，适合不需要后处理的场景。

## 参考

1. Speech-to-text benchmarks suggest a 3-4x throughput advantage over typing for English prose. See for instance Karat et al., "Patterns of entry and correction in multimodal interaction with a speech style dictator" (1999), and more recent user studies from Microsoft and Google. WER data is from the Hugging Face Open ASR Leaderboard and vendor-published benchmarks.

2. WhisperKit system requirements specify Apple Silicon (M1 or later) and macOS 14+. See https://github.com/argmaxinc/WhisperKit.

3. openquack README documents ~5GB VRAM usage during warm inference. See https://github.com/larryxiao/openquack.

4. PR #67: "Add Intel Mac support for x86_64 architecture", merged December 2025. typeflux v0.2.0+ runs natively on Intel Macs.

5. SenseVoice Small model specs: 234M parameters, ~350MB, FunASR Chinese benchmark CER 7.81%. See https://github.com/modelscope/FunASR.

6. Groq Whisper benchmark: 189x real-time (large-v3) and 216x (large-v3 Turbo) as measured by Artificial Analysis (January 2025). See https://artificialanalysis.ai.

7. SayToWords multilingual benchmark (January 2026): Whisper large-v3 achieves 4.1% WER on Chinese vs 2.1% on English. See https://www.saytowords.com/zh/blogs/Whisper-V3-Benchmarks.

8. Alibaba Cloud ASR (Paraformer-realtime-v2) uses a non-autoregressive architecture optimized for Mandarin. Doubao Realtime ASR is similarly optimized for Chinese. Both consistently outperform Whisper on Chinese-only benchmarks.

9. typeflux STT fallback chain: the `STTRouter` routes failed transcriptions through `AppleSpeechTranscriber` as a system-level fallback. Source: `Sources/Typeflux/STT/STTRouter+Fallbacks.swift`.

10. Groq pricing as of June 2026: `whisper-large-v3` at $0.111/hr, `whisper-large-v3-turbo` at $0.04/hr, `distil-whisper` at $0.02/hr. See https://console.groq.com/docs/model/whisper-large-v3.
