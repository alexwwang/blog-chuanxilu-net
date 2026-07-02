---
title: "purr, typeflux, openquack, freeflow: Voice Input Tools Compared on Intel Mac"
slug: "macos-voice-input-tools-comparison"
date: 2026-07-02T07:00:00+08:00
draft: false
description: "An Intel MacBook Pro (MacBookPro16,2) with four open-source voice input candidates: purr, typeflux, openquack, freeflow. Hardware constraints quickly eliminate three. This post documents the comparison, the decision, and what it's like to use the winner on an Intel Mac."
tags: ["macOS", "voice input", "ASR", "typeflux", "freeflow", "Intel Mac", "open source"]
categories: ["Tool Review"]
toc: true
cover:
  image: "cover.png"
---

## Why Voice Input

Typing speed averages 50-80 WPM. Natural speech runs 150-180 WPM. For emails, notes, and even code comments, the gap is hard to ignore.[1]

What pushed me to actually look was **vibe coding**, the "describe and decide, let AI write the rest" style of programming. The bottleneck shifts from "how fast can I code" to "how fast can I articulate what I want." Rewrite a prompt, tweak a parameter, jump to another app to type — all of it breaks flow. Voice input closes that loop. Speak the intent, stay in flow.

{{< figure src="/posts/2026/07/macos-voice-input-tools-comparison/vibe-coding-concept.png" alt="Voice input vs typing: the bottleneck shifts from typing speed to intent expression speed" >}}

Commercial solutions are not in short supply. Google Docs has voice typing, Otter.ai transcribes meetings, Zoom has live captions — voice input is everywhere. But these features share two problems:

1. **Privacy and freedom.** Google Docs voice runs Google models. Otter.ai runs its own. You are locked into each vendor's ecosystem — their quality, their privacy policy, their data pipeline. No backend switching, no local model option. Feature changes, pricing changes, or shutdowns are out of your control. Closed source means no recourse.

2. **Bundled, not standalone.** These are voice features tucked inside larger applications — a word processor, a meeting tool, a transcription service. None is a dedicated voice input tool that you can point at any app and start dictating.

Every option I looked at shared the same pattern: closed source, fixed model, bundled inside a larger application, audio sent to the vendor's servers by default. None offered a standalone voice input button — just that one feature, nothing else.

I wanted something **open source**. I wanted to inspect the code, choose the ASR engine, run locally if needed, or hook into a better cloud service. And it had to support Chinese and English voice input that inserts text at the cursor position. No copy-paste, no app switching.

One more constraint: my machine is a 2020 Intel MacBook Pro (MacBookPro16,2). Core i5 at 2GHz, 4 cores, 16GB RAM. No Apple Neural Engine. A lot of tools are Apple Silicon exclusive.

Four projects on GitHub came up: iamarunbrahma/purr, mylxsw/typeflux, larryxiao/openquack, zachlatta/freeflow. I went through all four.

## The Four Projects

### purr

- GitHub: https://github.com/iamarunbrahma/purr
- Stack: SwiftUI, WhisperKit
- Focus: Minimal macOS menu-bar voice input, record, transcribe, insert

purr does not state its minimum macOS version, but its WhisperKit dependency does. WhisperKit requires Apple Silicon (M1+) and macOS 14+.[2] On Intel Mac, WhisperKit falls back to CPU inference. A few seconds of audio takes 5+ seconds to transcribe. At that point voice input loses its purpose.

purr itself is well-designed, with a clean UI and smooth interaction. But it is built for Apple Silicon.

### openquack

- GitHub: https://github.com/larryxiao/openquack
- Stack: Swift, WhisperKit, Core ML
- Focus: Free, open-source, privacy-first local transcription

openquack also uses WhisperKit and Core ML. Warm inference requires about 5GB VRAM.[3] Apple Silicon unified memory handles this fine. Intel Mac does not.

The README is upfront about it:

> A native macOS menubar voice transcription tool, powered by WhisperKit. Works on Apple Silicon.

### typeflux

- GitHub: https://github.com/mylxsw/typeflux
- Stack: Swift, multiple STT backends
- Focus: "Hold to talk, release to insert" for zero context-switch voice input

typeflux originally only supported Apple Silicon, but PR #67 (December 2025) added native Intel Mac support.[4] Instead of baking in one inference engine, it abstracts an STT provider layer:

{{< figure src="/posts/2026/07/macos-voice-input-tools-comparison/typeflux-architecture.png" alt="Typeflux STT provider abstraction layer architecture" >}}

| Provider | Type | Best For |
|---|---|---|
| Typeflux Cloud | Cloud | Zero-config, balanced accuracy |
| Local Model | Local | Privacy, offline use |
| Alibaba Cloud ASR | Cloud streaming | Low latency, Chinese |
| Doubao Realtime ASR | Cloud streaming | Chinese optimization |
| Google Cloud Speech | Cloud | Multi-language, enterprise |
| OpenAI (Whisper API) | Cloud | High accuracy |
| Groq | Cloud | Fast inference, low cost |
| Free Models | Cloud | Bring-your-own endpoint |

For local inference, typeflux supports SenseVoice Small, FunASR (Paraformer), WhisperKit Medium/Large, and Qwen3-ASR. SenseVoice Small (234M params, about 350MB) runs via sherpa-onnx and delivers about 2-3 seconds of latency on Intel Mac, acceptable for short dictation sentences.[5]

### freeflow

- GitHub: https://github.com/zachlatta/freeflow
- Stack: Swift, Groq Whisper API
- Focus: Minimal menu-bar voice input, cloud transcription

freeflow relies entirely on Groq Whisper API (large-v3 and large-v3 Turbo). No local inference. Groq LPU hardware runs Whisper at 189-216x real-time, so one hour of audio transcribes in 8-12 seconds.[6]

Hardware does not matter. Intel Mac and Apple Silicon have identical experiences because the compute happens on Groq servers. Chinese WER is about 4.1%, English about 2.1%.[7] Good for everyday use, but not as good as Chinese-native engines like Alibaba Cloud Paraformer or Doubao ASR.

For Intel Mac users, freeflow is the lowest-friction option: register a Groq account (free credits available), paste an API key, done. The tradeoff is no offline capability. All audio goes to Groq servers.

## Side by Side

| | purr | openquack | typeflux | freeflow |
|---|---|---|---|---|---|
| CPU Inference | ❌ (impractically slow on Intel) | ❌ (unusable) | ~2-3s | ❌ (cloud-only) |
| Apple Silicon Experience | ✅ | ❌ | ✅ | — (cloud only) |
| Chinese + English | ✅ | ✅ | ✅ | ✅ |
| Chinese-Specific Optimization | None | None | Yes (AliCloud/Doubao/SenseVoice) | None |
| Offline Capable | ✅ | ✅ | ✅ | ❌ |
| Cloud Backends | None | None | Multiple options | Groq |
| Hardware Requirement | Apple Silicon + macOS 14+ | Apple Silicon | macOS 13+, x86_64 | macOS 12+ (cloud-only) |
| Setup Complexity | Low | Low | Low | Low |
| Stars | ~63 | ~31 | ~302 | ~2k |
| License | MIT | MIT | AGPL-3.0 | MIT |

> purr and freeflow take the single-backend path (WhisperKit and Groq respectively). openquack is Apple-ecosystem only. typeflux abstracts the backend layer, so it supports the widest range of hardware and providers.

## The Decision

On Intel Mac, only typeflux and freeflow are viable. freeflow is simpler but more limited. One Groq API key, fixed recognition quality.

I went with typeflux for three reasons.

{{< figure src="/posts/2026/07/macos-voice-input-tools-comparison/comparison-overview.png" alt="Four tools compared on Intel Mac compatibility" >}}

1. **Chinese recognition.** freeflow's Groq Whisper at 4.1% WER is fine in quiet conditions. typeflux can use Alibaba Cloud Paraformer or Doubao Realtime ASR, native Chinese engines that consistently outperform Whisper on Mandarin.[8] Or SenseVoice Small locally, no network required. More options are better.

2. **Persona system.** typeflux ships with two built-in personas: "Typeflux" and "English Translator." Default is Typeflux, say whatever language and it transcribes verbatim. Switch to English Translator from the menu bar, and regardless of what language you speak, the output is in English at the cursor position. No copy-paste needed.

3. **Fallback paths.** typeflux STT Router has a fallback chain: if the primary STT fails, it degrades to Apple Speech (the system-level recognizer).[9] On Intel Mac where local model latency is unpredictable, this prevents deadlocks.

## Installing typeflux

The latest release offers two download options: the full bundle (about 190MB, includes SenseVoice model files) and the app-only version (about 12MB, models download on first launch).

I installed the app-only version. Drag to /Applications. Local models are not automatic though. Go to Settings, Model, and click "Prepare Local Model." It downloads in a few minutes. Model files land in ~/Library/Application Support/Typeflux/. Total disk usage is about 377MB (45MB app plus 332MB models and data).

If you use OpenCode or similar AI coding tools, you can offload the download and installation: open a new session and tell the agent "download typeflux and install it to /Applications." It handles the rest. Configuration is still manual.

Three permissions required:
- **Microphone**: for recording
- **Accessibility**: for text injection
- **Speech Recognition**: for Apple Speech fallback

Default hotkey is Fn. But Fn is also needed for function keys (F1-F12), so I changed it to Control+Fn. Double-press Fn is the default input source switch in macOS, so I mapped Ask Anything (voice Q&A or content rewriting) to double-press Option instead.

One thing about Apple Speech: it is in Settings, Advanced Settings, last item "Enable Apple Fallback." It is off by default. You need to toggle it on manually. Once enabled, Apple Speech steps in as a system-level fallback when all other STT options fail. A few caveats:

- Apple Speech is a macOS system-level service. Audio ultimately goes through Apple servers, so it requires network access.
- Privacy: audio is uploaded to Apple servers for processing.

## Current Setup

typeflux has been running on my Intel MacBook Pro for a while now. My daily workflow:

- **Default backend**: Typeflux Cloud (built-in, zero config)
- **Offline**: SenseVoice Small (local, kicks in when offline)
- **Fallback**: Apple Speech (auto fallback via STT Router)
- **Personas**: Two built-in, "Typeflux" and "English Translator"

Typeflux Cloud latency is about 0.5-1 second. SenseVoice Small takes about 2-3 seconds on Intel Mac. I use the cloud version daily; local handles offline scenarios.

## Freeflow, if you want simple

If you just need basic English and Chinese voice input and do not want to configure multiple backends or manage model files, freeflow plus Groq is the fastest path to working. Groq offers free credits on signup; whisper-large-v3 is $0.111/hour, whisper-large-v3-turbo is $0.04/hour.[10] An hour of daily use costs a few dollars a month.

freeflow lacks rewrite capability, personas, and Chinese-specific optimization. It does raw transcription — what you say is what you get — which is fine if you do not need post-processing.

## References

1. Speech-to-text throughput advantage is well-documented. See Karat et al., "Patterns of entry and correction in multimodal interaction with a speech style dictator" (1999), and more recent studies from Microsoft Research and Google. WER data from the Hugging Face Open ASR Leaderboard and vendor benchmarks.

2. WhisperKit system requirements: Apple Silicon (M1+), macOS 14+. https://github.com/argmaxinc/WhisperKit

3. openquack README: about 5GB VRAM during warm inference. https://github.com/larryxiao/openquack

4. PR #67: "Add Intel Mac support for x86_64 architecture", merged December 2025. typeflux v0.2.0+.

5. SenseVoice Small: 234M params, about 350MB, FunASR Chinese benchmark CER 7.81%. https://github.com/modelscope/FunASR

6. Groq Whisper benchmark: 189x real-time (large-v3), 216x (large-v3 Turbo). Artificial Analysis, January 2025. https://artificialanalysis.ai

7. SayToWords multilingual benchmark (January 2026): Whisper large-v3 Chinese WER 4.1%, English 2.1%. https://www.saytowords.com/blogs/Whisper-V3-Benchmarks

8. Paraformer-realtime-v2 (Alibaba Cloud) and Doubao Realtime ASR both use non-autoregressive architectures optimized for Mandarin Chinese. Both outperform Whisper on Chinese-only benchmarks.

9. typeflux STT fallback: STTRouter routes failed transcriptions to AppleSpeechTranscriber. Source: Sources/Typeflux/STT/STTRouter+Fallbacks.swift.

10. Groq pricing as of June 2026: whisper-large-v3 at $0.111/hr, whisper-large-v3-turbo at $0.04/hr, distil-whisper at $0.02/hr. https://console.groq.com/docs/model/whisper-large-v3
