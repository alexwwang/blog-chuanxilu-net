---
title: "meta-pass v1.0 Development Detours: Thirteen Lessons from 90 Commits"
slug: "meta-pass-v1-detours"
date: 2026-10-02T10:00:00+08:00
draft: true
description: "Six days after MVP shipped, meta-pass grew from two slots to three, added signatures and backups, and fixed every pitfall along the way. This post records thirteen detours from the v1.0 development cycle and what each one taught me."
tags: ["AI", "ESP32", "Firmware", "FoloToy", "AI Passport", "meta-pass", "bootloader", "OTA"]
categories: ["AI Practice", "Embedded Development"]
series: ["AI App Development"]
cover:
  image: "cover.png"
  relative: true
  alt: "meta-pass v1.0 development journey: thirteen detours from MVP to stable release"
toc: true
---

After the meta-pass MVP shipped on September 12, I spent six days expanding it from two slots to three, adding signature badges, fixing backups, and delivering single-file firmware with data-safe upgrades. 90 commits, thirteen detours[^1].

The previous post covered the two-day MVP process[2]. This one covers the six days of v1.0[^2]: the pitfalls I walked into, the wrong turns I took, and the hard lessons I pulled out of them.

## I. Designs Forced by Constraints

**Flash layout changed from two slots to three.** During MVP, factory took 3MB and left two 2MB slots. A user commented that「anything slightly practical won't fit」[^3]. In v1.0, I compressed the factory image to under 1.44MB, which freed up gaps on either side of the fixed `cardid` identity region. Slot 0 got 1.84MB, slot 2 got 2.61MB[^4].

The lesson here: idle space on Flash is not empty, it is design material. The spec that pins `cardid` in place is not an obstacle, it is an anchor point for layout calculations. Treat it as a constraint instead of an enemy, and dead space becomes usable space.

**Single-session policy changed from「rely on voluntary compliance」to「enforced by bootloader」.** The original MVP approach asked the sub-firmware hook template to simply「not write VALID」so the device would return to the launcher after each boot. But older community firmwares would still write VALID, and the policy failed silently[^5]. In v1.0, I moved the policy to the bootloader layer, which checks and erases the VALID flag in otadata before any firmware runs[^6]. The effect: no matter whether the sub-firmware complies, every power-on returns to the menu. A device that was previously locked recovers after a single power cycle once updated to this version.

The lesson: system-level constraints cannot depend on participant cooperation. The bootloader is the only layer that executes before all firmwares, so the single-session policy must live there.

## II. Four Layers of Signature System Collapse

The signature badge was the mostmost problematic part of v1.0. The switch from RSA to ECDSA took half a day[^7], but the subsequent fix chain ran for four days.

**Layer one: image_len semantic drift.** `sign-firmware.sh` initially read image_len from file size, then I realized it should come from the image header. Then I corrected byte 16 to byte 23 to align with IDF's packed struct[^8]. Four consecutive commits later, the signing script finally matched what IDF's `esp_image_verify` expects.

**Layer two: online installer page drifted from repo code.** BUG-03 took three days to trace[^9]. The repo code had already been fixed to the「single-write tail sector」flow, but the deployed page at `https://meta-pass.pages.dev/` was still the old version (pre-dbbd091), executing the three-write flow where the second `writeFlash` erased the signature sector written by the first[^10]. The real-device symptom was「signed firmware shown as unsigned」.

The lesson: repo fixes do not equal online fixes. Any installer with two copies is a permanent bug. Deployment lag continues to produce errors where you cannot see them.

**Layer three: 16B extension header contract split.** The installer page JS had `[16, 0]` auto-detection logic, but the signing script and host tests did not[^11]. The three parties derived image_len differently. I eventually ported the detection into `sign-firmware.sh` and `test_integration.c`, closing the contract gap.

**Layer four: Keychain ACL trap.** `SecItemDelete` defaults to deleting only the first match. When recreating the key, I had to add `kSecMatchLimitAll`; otherwise the old private key remained[^12]. The signing tool found the stale key and produced a signature that did not match the published public key. The device reported InvalidSignature.

## III. Hidden Traps in the Toolchain

**esptool-js never reads the MD5 digest frame.** Browser-based backup reads took three minutes per 1MB and failed frequently[^13]. Three rounds of patches (block size, retry count, timeout settings) all failed. Then I read the stub source line by line and found the root cause: `handle_flash_read` unconditionally appends a 16-byte MD5 digest frame after sending data frames, but esptool-js never reads it[^14]. The leftover frame sits in the transfer buffer, poisoning every subsequent `readFlash` response. Protocol desync accumulated until backup always failed.

The fix: align with esptool.py's stop-and-wait semantics, read and verify the digest frame, and reduce block size to 4KB (the stub's hard limit)[^15].

**esptool-js library-level self-destruction.** After `readLoop` times out, `finally{buffer=new Uint8Array(0)}` clears the buffer, but the abandoned generator's timer still fires, swallowing valid incoming data in long sessions[^16]. `flushInput()`'s first line `await this.reader.closed` never resolves on an active serial port, so the recovery chain hangs indefinitely once it reaches that point[^17]. This is the root cause of「death after ~2 minutes, thirty minutes of silence on retry」.

The lesson: `finally{}` blocks and pending Promises in library code will kill you at moments you thought were long over. When facing persistent hangs, audit all `Promise.race` resolution paths in the library layer first[^18].

**Stale ESP-IDF sdkconfig silently overriding defaults.** After editing `sdkconfig.defaults` and running `idf.py build`, if a `sdkconfig` file exists in the project root (even though it is gitignored), IDF reuses it instead of regenerating from defaults[^19]. Two「clean builds」differed by 21% in size (1,283,232 vs 1,024,608 bytes), and the commit history showed no anomaly.

The lesson: after changing defaults, always run `rm sdkconfig && idf.py build`. CI is immune because it does a fresh checkout every time; local development is the high-risk zone[^20].

## IV. Blind Spots in Testing and CI

**Host test cross-platform traps.** Host integration tests passed on macOS but failed twice in CI (Linux)[^21]: GCC reports `-Wunused-variable` for unused `static const char *TAG`, while clang does not. `-Wl,-dead_strip` is macOS ld specific; GNU ld uses `-Wl,--gc-sections`.

The lesson:「green locally」only means one combination: clang + macOS ld. For every new compile or link flag, consider GCC/GNU ld semantics first[^22].

**A failing test exposed environment coupling.** One test directly read build artifacts from the local `build/` directory for comparison. It passed locally and crashed on CI bare checkout[^23]. I changed it to dual mode: use real artifacts when available, synthetic data otherwise, but run the same logical assertions in both cases.

The lesson: static gates must not implicitly depend on the local environment.

## V. Publishing and Collaboration Pitfalls

**Actions trap after fork-to-independent transition.** push/tag events stopped triggering Actions. The disabled state from the fork period did not automatically resume after leaving the fork network[^24]. The API reported enabled=true and all workflows active, but check-suites were empty. I had to fall back to manual workflow_dispatch. Thewas was clicking the enable banner on the Actions settings page.

The lesson: the first thing to do after fork independence is push a test commit to verify the CI event chain[^25].

**Publish artifact hash inconsistency.** The same source code produced different hashes for local builds and CI builds, because ESP-IDF embeds the compilation timestamp by default (`CONFIG_APP_COMPILE_TIME_DATE`)[^26]. This meant the plays market firmware and the GitHub Release firmware for the same version were two different byte streams.

The lesson: when publishing to the market, download and upload the CI build's release artifact instead of using the local `build/` output[^27].

**Dev copy and release copy inevitably drift.** The dev installer page used a second writeFlash to write the display name blob into the same 4KB tail sector that already contained the signature. Since esptool erases on write, the signature was wiped in the moment of burning[^28]. The structural fix: a single canonical `install-slot/` directory served by both the local dev server and Cloudflare Pages deployment, with the tail sector always written in one operation[^29].

The lesson: any tool page with two copies is a permanent bug. Services must have a single source of truth[^30].

## VI. Hard Rules Pulled From the Pitfalls

These six days of stumbling produced a few rules worth remembering.

**Verify the signer first, then trace the transport path.** When「the file is valid but the device rejects it」, prove the file itself with a real signature verifier first, then trace backward along the write path[^31]. The device reads flash, not files.

**One sector, one write.** esptool/esp_ota erases on write. Writing twice to the same 4KB sector means the first write is silently lost[^32]. This is why the tail sector (MSIG/MAEG/MNAM) must be assembled in memory and written in a single operation.

**Read proven implementations line by line before building your own wheel.** The backup read problem took three weeks to fix. The root cause was esptool-js not reading the MD5 digest frame, while esptool.py's reference implementation does[^33]. When a third-party client library diverges from the reference implementation, read the server source and the reference client first, before patching failure handling[^34].

**Compilation passing does not mean the feature is present.** The bootloader hook compiled green on the first try, but the binary had no hook linked in (new component directories do not trigger cmake reconfiguration)[^35]. Before delivery, find direct evidence that「it is actually in the artifact」[^36].

**A single backslash in a comment can break the entire CI.** A `\` at the end of a `//` comment line makes the compiler swallow the next line into the comment, triggering `-Werror=comment`. The bug existed for a week before anyone noticed[^37].

**Static analysis first.** After every change, self-review (grep, map file, syntax check) before asking for acceptance[^38].

**Real-device evidence beats inference.** Whether the device screen flickered, whether the serial log contains that one line, is more credible than「it should work」[^39].

## Conclusion

Ninety commits, thirteen detours. Looking back, every detour pointed to the same problem: I thought I knew, but I did not actually know.

I thought fixing it in the repo would fix it online. It did not.
I thought compiling green meant the feature was there. It was not.
I thought host tests all green meant real-device tests would be green too. They were not.
I thought copies would not drift. They did.

These cognitive biases are especially dangerous in embedded development, because hardware constraints do not care about your assumptions. Flash space is fixed. One protocol desync poisons an entire session. Write to the same sector twice and the first write vanishes. Potholes you do not record will swallow you again[^40].

meta-pass source code is open source on GitHub (MIT license). Full design docs, the BUGS log, and development handoff notes are in the `docs/` directory[^41].

---

## References

[^1]: Six days = 2026-09-13 to 2026-09-18, 90 commits. Data source: git log.

[^2]: [Building a Multi-Cartridge Launcher for My Kid's AI Toy: meta-pass Dev Retrospective](/en/posts/2026/09/meta-pass-multi-firmware-launcher/)

[^3]: User comment:「Not useful. This thing takes up 3MB, leaving only two 2MB slots. Anything slightly practical won't fit.」Source: FoloToy plays market meta-pass page comments.

[^4]: Flash layout data source: `docs/assets/meta-pass-design.zh_CN.md` §3.

[^5]: Single-session policy failure cause: the old sub-firmware hook template copy was always the old version, so the「do not write VALID」policy failed silently. Source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md`.

[^6]: Bootloader enforcement approach: `bootloader_components/meta_boot_hooks/` registers a `bootloader_after_init` hook that checks and erases the VALID flag in otadata. Source: `docs/assets/meta-pass-design.zh_CN.md` §4.

[^7]: RSA-2048 to ECDSA-P256 switch reason: RSA public key at 294B was too large for firmware space; ECDSA public key is only 91B. Source: git log `ea21e03` (2026-09-13 22:13) and `994caaf` (2026-09-13 23:40).

[^8]: image_len fix chain: `24b82c0` (file size to image header), `4dd6f78` (byte 16 to byte 23), `325d01f` (digest scope), `aa25c52` (Keychain public key embedding). Source: git log.

[^9]: BUG-03 took three days to trace. Source: `docs/assets/handoff-unsigned-rootcause.zh_CN.md` §0.

[^10]: Online installer page lag cause: pages.yml deploys from main, but the live site lagged behind main HEAD. Live fetch confirmed the deployed version was pre-dbbd091. Source: `docs/assets/handoff-unsigned-rootcause.zh_CN.md` §3.1.

[^11]: 16B extension header contract split source: `docs/assets/handoff-unsigned-rootcause.zh_CN.md` §5.

[^12]: Keychain ACL trap source: nmem memory `f7518c1b` (2026-09-14).

[^13]: Backup read performance data: before fix, 1MB read took three minutes. Source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` lesson 3.

[^14]: Root cause of esptool-js not reading MD5 digest frame: vendored esptool-js never reads the 16-byte digest frame that stub unconditionally appends. Source: `docs/development/engineering/debugging-workflow.zh_CN.md` §1 Round 4.

[^15]: Fix approach: esptool.py stop-and-wait semantics + read-and-verify digest frame + block size ≤ 4KB. Source: `docs/development/engineering/debugging-workflow.zh_CN.md` §1 Round 4.

[^16]: finally-block self-destruction root cause: `FLASH_READ_TIMEOUT=100s` matched the observed「~2 minute death chain」exactly. Source: `docs/development/engineering/debugging-workflow.zh_CN.md` §1 Round 5.

[^17]: flushInput hang root cause: `await this.reader.closed` never resolves on an active serial port. Source: `docs/development/engineering/debugging-workflow.zh_CN.md` §1 Round 5.

[^18]: Lesson summary source: `docs/development/engineering/debugging-workflow.zh_CN.md` §1 Round 5.

[^19]: sdkconfig masking data: two「clean builds」differed by 21% in size (1,283,232 vs 1,024,608 bytes). Source: nmem memory `09741cfa` (2026-09-13).

[^20]: Fix habit source: nmem memory `09741cfa`.

[^21]: Cross-platform trap source: nmem memory `3bc116e3` (2026-09-13).

[^22]: Lesson summary source: nmem memory `3bc116e3`.

[^23]: Test depending on local build/ source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` lesson 4.

[^24]: Fork-to-independent Actions trap source: nmem memory `74a8042f` (2026-09-11).

[^25]: Lesson summary source: nmem memory `74a8042f`.

[^26]: Hash inconsistency cause: ESP-IDF embeds compilation timestamp by default (`CONFIG_APP_COMPILE_TIME_DATE`). Source: nmem memory `17fcbeb8` (2026-09-11).

[^27]: Lesson summary source: nmem memory `17fcbeb8`.

[^28]: Dev copy drift root cause: dev copy blobOffset passed partition size instead of image length, name blob wrote 4056 bytes past slot end (slot 0 wrote into cardid NVS partition), double-write erased MSIG. Source: nmem memory `c158ba6f` (2026-09-15).

[^29]: Structural fix: `server.mjs` serves the canonical `install-slot/` directory directly, eliminating dev-copy drift. Source: `docs/BUGS.zh_CN.md` BUG-03.

[^30]: Lesson summary source: nmem memory `c158ba6f`.

[^31]: Workflow source: `docs/development/engineering/debugging-workflow.zh_CN.md` §2 lesson 1.

[^32]: Lesson source: `docs/development/engineering/debugging-workflow.zh_CN.md` §2 lesson 3.

[^33]: esptool.py reference implementation source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` lesson 3.

[^34]: Lesson source: `docs/development/engineering/debugging-workflow.zh_CN.md` §1 Round 4.

[^35]:「Compiles green ≠ feature present」source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` lesson 2.

[^36]: Lesson source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` lesson 2.

[^37]: Backslash breaking CI source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` lesson 5.

[^38]: Static analysis first source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` engineering habits.

[^39]: Real-device evidence > inference source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` engineering habits.

[^40]: Potholes you do not record will swallow you again. That is why I wrote everything into `docs/BUGS.md` and `docs/development/engineering/debugging-workflow.md`.

[^41]: meta-pass repository: [alexwwang/meta-pass](https://github.com/alexwwang/meta-pass). Design docs, BUGS log, and development handoff notes are all in the `docs/` directory.
