---
title: "Finding a Chinese-English Voice Input Tool on Intel Mac: purr, typeflux, openquack, freeflow Compared"
slug: "macos-voice-input-tools-comparison"
date: 2026-07-02T07:00:00+08:00
draft: false
description: "An Intel MacBook Pro (MacBookPro16,2) with four open-source voice input candidates: purr, typeflux, openquack, freeflow. Hardware constraints quickly eliminate three. This post documents the comparison, the decision, and what it's like to use the winner on an Intel Mac."
tags: ["macOS", "voice input", "ASR", "typeflux", "freeflow", "Intel Mac", "open source"]
categories: ["Tool Review"]
toc: true
---

## Why Voice Input

Typing speed averages 50-80 WPM. Natural speech runs 150-180 WPM. For emails, notes, and even code comments, the gap is hard to ignore.[1]

What pushed me to actually look for a voice input tool was **vibe coding**, the "describe and decide, let AI write the rest" style of programming. The bottleneck shifts from "how fast can I code" to "how fast can I articulate what I want." Typing becomes the chokepoint. Rewriting a prompt, tweaking a parameter, jumping between apps to type, all of it breaks flow. Voice input closes that loop: speak the intent, stay in flow.

I wanted something **open source**. I wanted to inspect the code, choose the ASR engine, run locally if needed, or hook into a better cloud service. And it had to support Chinese and English voice input that inserts text at the cursor position. No copy-paste. No app switching.

One more constraint: my machine is a 2020 Intel MacBook Pro (MacBookPro16,2). Core i5 at 2GHz, 4 cores, 16GB RAM. No Apple Neural Engine. A lot of tools on the market are Apple Silicon exclusive.

Four projects on GitHub came up: iamarunbrahma/purr, mylxsw/typeflux, larryxiao/openquack, zachlatta/freeflow. I went through all four. Here is what I found.

## The Four Projects

### purr

- GitHub: https://github.com/iamarunbrahma/purr
- Stack: SwiftUI, WhisperKit
- Pitch: Minimal macOS menu-bar voice input, record, transcribe, insert

**The hardware requirement alone killed it.** purr does not advertise its minimum macOS version, but its WhisperKit dependency does. WhisperKit requires Apple Silicon (M1+) and macOS 14+.[2] On Intel Mac, WhisperKit falls back to CPU inference. A few seconds of audio takes 5+ seconds to transcribe. At that point voice input loses its purpose.

purr itself is well-designed. Clean UI, smooth interaction. But it is built for Apple Silicon.

### openquack

- GitHub: https://github.com/larryxiao/openquack
- Stack: Swift, WhisperKit, Core ML
- Pitch: Free, open-source, privacy-first local transcription

**Higher hardware bar.** openquack also uses WhisperKit and Core ML. Warm inference requires about 5GB VRAM.[3] Apple Silicon unified memory handles this fine. Intel Mac split CPU/GPU memory with at most 4GB dedicated VRAM does not.

The README is upfront about it:

> A native macOS menubar voice transcription tool, powered by WhisperKit. Works on Apple Silicon.

### typeflux

- GitHub: https://github.com/mylxsw/typeflux
- Stack: Swift, multiple STT backends
- Pitch: "Hold to talk, release to insert" for zero context-switch voice input

**The differentiator: hardware agnosticism.** typeflux originally only supported Apple Silicon, but PR #67 (December 2025) added native Intel Mac support.[4] Instead of baking in one inference engine, it abstracts an STT provider layer:

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
- Pitch: Minimal menu-bar voice input, cloud transcription

**Cloud-only by design.** freeflow relies entirely on Groq Whisper API (large-v3 and large-v3 Turbo). No local inference. Groq LPU hardware runs Whisper at 189-216x real-time, so one hour of audio transcribes in 8-12 seconds.[6]

Hardware does not matter. Intel Mac and Apple Silicon have identical experiences because the compute happens on Groq servers. Chinese WER is about 4.1%, English about 2.1%.[7] Accurate enough for everyday use, but not as good as Chinese-native engines like Alibaba Cloud Paraformer or Doubao ASR.

For Intel Mac users, freeflow is the lowest-friction option: register a Groq account (free credits available), paste an API key, done. The tradeoff is no offline capability. All audio goes to Groq servers.

## Side-by-Side

| | purr | openquack | freeflow | typeflux |
|---|---|---|---|---|
| CPU Inference | ~5s | ❌ (unusable) | ❌ (cloud-only) | ~2-3s |
| Apple Silicon Experience | ✅ | ❌ | ✅ | ✅ |
| Chinese + English | ✅ | ✅ | ✅ | ✅ |
| Chinese-Specific Optimization | None | None | None | Yes (AliCloud/Doubao/SenseVoice) |
| Offline Capable | ✅ | ✅ | ❌ | ✅ |
| Cloud Backends | None | None | Groq | Multiple options |
| Hardware Requirement | Apple Silicon + macOS 14+ | Apple Silicon | macOS 12+ (cloud-only) | macOS 13+, x86_64 |
| Setup Complexity | Low | Low | Low | Low |
| Stars | ~305 | ~100+ | ~2064 | ~305 |
| License | MIT | MIT | -- | AGPL-3.0 |

> purr and freeflow take the single-backend path (WhisperKit and Groq respectively). openquack is Apple-ecosystem only. typeflux abstracts the backend layer, so it supports the widest range of hardware and providers.

## The Decision

On Intel Mac, only typeflux and freeflow are viable. freeflow is simpler but more limited. One Groq API key, fixed recognition quality.

I went with typeflux, for three reasons.

1. **Chinese recognition.** freeflow Groq Whisper at 4.1% WER is fine in quiet conditions. typeflux can use Alibaba Cloud Paraformer or Doubao Realtime ASR, native Chinese engines that consistently outperform Whisper on Mandarin.[8] Or SenseVoice Small locally, no network required. More options are better.

2. **Persona system.** typeflux has built-in personas: preset rewrite instructions like "formal tone for emails," "English for code comments," "timestamped meeting notes." After transcription, an LLM rewrites the output according to the active persona. For bilingual workflows, this makes a real difference.

3. **Fallback paths.** typeflux STT Router has a fallback chain: if the primary STT fails, it degrades to Apple Speech (the system-level recognizer).[9] On Intel Mac where local model latency is unpredictable, this prevents deadlocks.

## Installing Typeflux

The latest release offers two download options: the full bundle (about 190MB, includes SenseVoice model files) and the app-only version (about 12MB, models download on first launch).

I ended up with the app-only version. Drag to /Applications. Local models are not automatic though. Go to Settings, Model, and click "Prepare Local Model." It downloads in a few minutes. Model files land in ~/Library/Application Support/Typeflux/. Total disk usage is about 377MB (45MB app plus 332MB models and data).

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
- **Personas**: Two, "English Email" and "Chinese Notes"

Typeflux Cloud latency is about 0.5-1 second. SenseVoice Small takes about 2-3 seconds on Intel Mac. Cloud is the daily driver; local handles offline scenarios.

## Postscript: Freeflow's Appeal

If you just need basic English and Chinese voice input and do not want to configure multiple backends or manage model files, freeflow plus Groq is the fastest path to working. Groq offers free credits on signup; whisper-large-v3 is $0.111/hour, whisper-large-v3-turbo is $0.04/hour.[10] An hour of daily use costs pocket change.

What freeflow lacks: rewrite capability, personas, and Chinese-specific optimization. Voice input is raw transcription. What you say is what you get. That is fine if you do not need post-processing.

## References

1. Speech-to-text throughput advantage is well-documented. See Karat et al., "Patterns of entry and correction in multimodal interaction with a speech style dictator" (1999), and more recent studies from Microsoft Research. WER data from the Hugging Face Open ASR Leaderboard and vendor benchmarks.

2. WhisperKit system requirements: Apple Silicon (M1+), macOS 14+. https://github.com/argmaxinc/WhisperKit

3. openquack README: about 5GB VRAM during warm inference. https://github.com/larryxiao/openquack

4. PR #67: "Add Intel Mac support for x86_64 architecture", merged December 2025. typeflux v0.2.0+.

5. SenseVoice Small: 234M params, about 350MB, FunASR Chinese benchmark CER 7.81%. https://github.com/modelscope/FunASR

6. Groq Whisper benchmark: 189x real-time (large-v3), 216x (large-v3 Turbo). Artificial Analysis, January 2025. https://groq.com

7. SayToWords multilingual benchmark (January 2026): Whisper large-v3 Chinese WER 4.1%, English 2.1%. https://www.saytowords.com/blogs/Whisper-V3-Benchmarks

8. Paraformer-realtime-v2 (Alibaba Cloud) and Doubao Realtime ASR both use non-autoregressive architectures optimized for Mandarin Chinese. Both outperform Whisper on Chinese-only benchmarks.

9. typeflux STT fallback: STTRouter routes failed transcriptions to AppleSpeechTranscriber. Source: Sources/Typeflux/STT/STTRouter+Fallbacks.swift.

10. Groq pricing as of June 2026. https://console.groq.com/docs/model/whisper-large-v3
