---
title: "meta-pass Task Description Constitution: Six Principles for AI-Assisted Development"
slug: "meta-pass-task-constitution"
date: 2026-10-05T10:00:00+08:00
draft: false
description: 'meta-pass v1.0 walked into thirteen detours in six days. Almost all can be traced to the same root cause: task descriptions did not specify what "done" means. This post distills those lessons into six principles to serve as a prerequisite convention for all future development work on this project.'
tags: ["AI", "ESP32", "Firmware", "prompt", "task design", "meta-pass", "project conventions"]
categories: ["AI Practice", "AI Workflow"]
series: ["AI App Development"]
cover:
  image: "cover.png"
  relative: true
  alt: "meta-pass task description constitution: six principles"
toc: true
---

If you use AI to write embedded firmware—specifically bootloader hooks, flashing routines, and signature verification—and then discover that your device behaves completely incorrectly, host tests pass while the real device fails, or the online deployment is still running an old version, this post is for you.

Over the last six days, I analyzed the thirteen detours we took during meta-pass v1.0 development. Most were not core technical failures, but rather the same root cause resurfacing in different forms: **the task description did not specify what "done" means**.

The article starts with a clear diagnosis of the problem, then provides real incidents from the past six days as evidence, and finally gives actionable recommendations.

---

## The Diagnosis

AI can write correct code, but it will not judge when a task is complete.

It will compile green, pass tests, and submit the PR, but it will not check whether the online deployment is stale, whether the hook is actually linked into the binary, or whether the tests used real firmware images.

Those judgments must come from a person. Written where? In the task description.

This post distills the thirteen detours into six principles, to serve as a prerequisite convention for all future development work on the meta-pass project.

---

## Principle 1: Acceptance Criteria Must Exist and Must Be Specific Commands

**This principle answers one question: how do you know the task is done?**

AI has no concept of "acceptance criteria". It sees "implement bootloader hook" and writes code, runs compilation, and submits the PR. It will not ask "how do I know this is done?"

### Specific Bug

The bootloader hook compiled green on the first try, but checking the binary revealed it was never linked in. A new component directory did not trigger `cmake` reconfiguration; the component lacked a `CMakeLists.txt`[^1].

### Original Task Description

> Implement the bootloader hook so the device returns to the launcher on every power-on. Verify the config change took effect.

### Gap Analysis

This description does not answer "how do you know it is done?" AI will automatically execute: write code → compile → submit. It will not proactively verify that the hook is actually in the binary, nor will it check whether the BT optimization config in sdkconfig really took effect.

"Verify the config change took effect" is a vague outcome statement, not an acceptance criterion. AI does not know what "took effect" means or what to check.

### Template Skeleton

```
Task: One sentence describing what to do
Acceptance Criteria:
  1. Command-level verification (nm / grep / ls / serial log, etc.)
  2. Specific output expectations (=n / =y / has output / no output)
  3. Boundary conditions (max file size, version number range, etc.)
  4. Final step: run one complete end-to-end flow and confirm it works
```

### Rewritten

> I want the device to always return to the launcher on power-on instead of jumping straight into the last firmware that ran. The bootloader hook is implemented, but I need to confirm two things.
>
> First, the hook is actually linked into the binary. I run the `nm` command on my Mac to check the symbol table and confirm `bootloader_after_init` exists, search the map file for `hook called` to verify the record, and finally run `QEMU` once to check that the serial log shows the hook executing.
>
> Second, the sdkconfig settings for Bluetooth and compiler optimization took effect. I run `grep` to check `sdkconfig`: if the values for BT and compiler optimization don't match what I expect, something went wrong. Also check the firmware binary size, keep it under 1.5MB.
>
> Once all that checks out, the task is done.

---

## Principle 2: You Must Declare Environment Constraints

**This principle answers one question: in what environments can your code run?**

AI has no concept of "environment assumptions". It will not proactively check whether residual files exist in the current environment or whether the code depends on local state. It will put code wherever it can write, without automatically choosing the single correct directory.

### Specific Bug

After modifying `sdkconfig.defaults`, running `idf.py build` reused the existing `sdkconfig` cache instead of regenerating it, masking configuration changes. Furthermore, an integration test read artifacts directly from the local `build/` directory, causing it to pass on developer machines while crashing on clean CI checkouts[^2].

### Original Task Description

> Fix this test failure.

### Gap Analysis

This description does not specify the scenario where the problem occurs, nor does it specify the expected verification environment. AI will likely look for the cause in the local `build/` directory, while the problem is actually that the test depends on local state that CI does not have.

More critically, the task description does not exclude incorrect environment assumptions. AI does not know which environment states are "allowed" and which are "forbidden."

### Template Skeleton

```
Task: One sentence describing what to do
Environment Constraints:
  - Forbidden to depend on local state (build/, sdkconfig cache, etc.)
  - Must run in a clean checkout environment
  - Test data must be versionable
  - After changing XXX, must do YYY before running ZZZ
```

### Rewritten

> This test passes locally but crashes on CI because it reads directly from the untracked `build/` directory. Update the test to read from a version-controlled fixture inside the repository instead of ephemeral build artifacts, then verify that the test passes in a freshly cloned working directory.

---

## Principle 3: Verification Must Cover Deployment State and Real Data

**This principle answers two questions: how do you know the deployed version is correct? How do you know the test data is real?**

AI has no concept of "deployment state" or "real data". It fixes code, runs tests, and submits the PR, then considers the task complete. It will not check whether the online version matches the repo, and it will not confirm whether the tests used real firmware images.

### Specific Bug

BUG-03 took three days to trace[^4]. The repository code had been updated to the "single-write tail sector" flow, but the live web interface at https://meta-pass.pages.dev/ was still running stale code (pre-commit dbbd091). That older version executed a three-write sequence that wiped the signature sector, causing the physical hardware to report signed firmware as unsigned.

Host integration tests passed verification with synthetic firmware images, but the real-device behavior did not match expectations[^5]. Synthetic fixtures can only verify logical correctness, not real binary format, real key chain, or real device behavior.

### Original Task Description

> Fix this signature verification failure bug.

### Gap Analysis

This description does not require verifying deployment state, nor does it specify test data requirements. AI will likely only do two things: fix code → run tests. It will not check whether the online version is correct, nor will it verify with real firmware.

"Fix the signature verification failure bug" is an outcome statement, not an acceptance criterion. AI does not know what "fix" means.

### Template Skeleton

```
Task: One sentence describing what to do
Acceptance Criteria:
  1. Code fix
  2. Deployment verification (curl compare online file with repo source)
  3. Real-device reproduction (run one complete flow on physical device)
  4. Data requirement (must use real data, not synthetic data)
```

### Rewritten

> This bug was found on a real device: after using the new installation script, signed firmware shows as unsigned. Fix the code, then do three things.
>
> First, redeploy to the online environment. After deployment, fetch the JS file with curl and compare it against the repo source to confirm the latest code is deployed.
>
> Second, run the full flow on a real device. The task is not complete until the serial log shows signature verification passing.
>
> Additionally, perform all verification using real firmware binaries rather than mock test fixtures. Mock fixtures do not mirror the complete header structures or key chains of production builds, so green mock tests do not guarantee physical device compatibility.

---

## Principle 4: Protocol Changes Require Reading the Peer Source First

**This principle answers one question: what do you need to know before modifying the client?**

AI does not know what the peer side of a protocol looks like. It only sees the code it is responsible for and will not consider what the peer might expect. It will not proactively read the server source, nor will it proactively compare with the reference implementation.

### Specific Bug

esptool-js never reads the MD5 digest frame, causing backups to fail consistently. Three successive workaround attempts (adjusting block size, retry count, and timeouts) all failed because the fundamental issue was protocol desynchronization[^6]. Because esptool-js never read the 16-byte MD5 digest frame that `handle_flash_read` unconditionally appends after data frames, leftover bytes remained in the receive buffer. This unread frame corrupted every subsequent `readFlash` response, so backup always failed.

### Original Task Description

> Fix the backup function, it fails often.

### Gap Analysis

This description only states the symptom, not the root cause. AI will enter "blind optimization" mode: increase block size, add retries, extend timeout. All three directions are reasonable in isolation, but any optimization is futile in the presence of protocol desync.

The three rounds of patches took three weeks. The actual fix took one day: read the stub source, write out the protocol interaction sequence diagram, then compare with esptool.py's reference implementation and add MD5 digest frame reading and verification[^6].

### Template Skeleton

```
Task: One sentence describing what to do
Prerequisites:
  1. Read peer source (confirm frame format, protocol behavior)
  2. Compare with reference implementation (see how official library handles it)
  3. Write out protocol interaction sequence diagram
  4. Test client with mock server
Execution:
  Modify based on protocol understanding
```

### Rewritten

> The backup function is unstable. Tuning the block size, adding retries, and increasing timeouts did not resolve the issue because `handle_flash_read` in `components/stub/src/esp_flash_hal.c` unconditionally appends a 16-byte MD5 digest after every data frame, but esptool-js never reads that frame. Those 16 bytes sit in the buffer and poison the next response, so backup always fails.
>
> To fix this, read the stub source first to understand the frame format, then compare with esptool.py's implementation and add the MD5 digest frame reading logic. Do not modify the client without first understanding what the peer expects.

---

## Principle 5: Deployables Must Have Version Tracking and Single-Source Constraints

**This principle answers two questions: how do you know which version is deployed? How do you know there is only one copy of the code?**

AI has no concept of "version tracking" or "single source". It will not proactively embed a version stamp in deployables, will not proactively check whether the online version matches the repo, and will not make choices about code placement.

### Specific Bug

Three days spent troubleshooting "signature verification failing," only to discover the online installer page was the old version[^7]. The same source code produced different hashes for local builds and CI builds, because ESP-IDF embeds the compilation timestamp by default (`CONFIG_APP_COMPILE_TIME_DATE`)[^8]. This meant the production release firmware and the GitHub Release firmware for the same version were two different byte streams.

Dev copy and release copy inevitably drift. The second writeFlash erased the signature written by the first[^9]. The dev copy's blobOffset calculated distance using total partition size instead of actual image length. As a result, writing the metadata blob 4,056 bytes past the slot boundary caused slot 0 to overwrite the cardid NVS partition, while the second write operation corrupted the MSIG sector[^9].

### Original Task Description

> Fix the bug in the installer page and deploy it online.

### Gap Analysis

This description does not specify version tracking requirements, nor does it specify code placement constraints. AI will fix the code and deploy, but it will not check whether the version number is correct after deployment, nor will it pay attention to which directory the code should go in.

The root cause of dev copy drift is that the same specification is maintained in two copies[^9]. The structural fix was to have `server.mjs` serve the canonical `install-slot/` directory directly, eliminating dev-copy drift[^9].

### Template Skeleton

```
Task: One sentence describing what to do
Version Tracking Requirements:
  - Firmware: git describe version embedded in binary
  - Web page: first log line prints git SHA at deployment time
  - After publishing, use curl to fetch response headers and confirm version
Code Placement Constraints:
  - All code lives in a single directory only
  - Dev server and deployment both read from this directory
  - No copies maintained elsewhere
```

### Rewritten

> There is a bug in the installer page. After fixing and deploying, confirm two things.
>
> First, the deployed version is the latest code. After deployment, check the version in the response headers with curl and compare it against `git describe` in the repo. If the online version is older, redeploy.
>
> Second, there is only one source for the code. All install-slot related files go in the `install-slot/` directory. Both the dev server and Pages deployment read from this directory. If someone modified a copy elsewhere, that is a drift and should not exist.
>
> Also, embed the git version number into the firmware binary so the device serial port can report which version is running after flashing.

---

## Principle 6: Device-Behavior Tasks Must Have Real-Device Evidence

**This principle answers one question: how do you know the device actually behaved as expected?**

AI has no concept of "real-device evidence". It will reason logically "it should work" but will not verify. It will write "theoretically it should work" but will not provide a serial log or screen capture.

### Specific Bug

Various inferences "it should work" but the device behaved completely differently[^10]. Host tests all green, real-device FAIL. The gap between the two required byte-level playback and a real signature verifier to locate[^11].

Host tests passed verification with synthetic images, but real-device signature verification failed[^5]. The root cause was a subtle semantic discrepancy in the signing script: it read image_len from the file size instead of the image header. This discrepancy went unnoticed in synthetic fixtures with static layouts but consistently failed on real firmware binaries[^5].

### Original Task Description

> Fix the signature verification logic, the device is not accepting it.

### Gap Analysis

This description only states the symptom, not the verification method. AI will likely only change the code and run host tests, then submit the PR. It will not verify on a real device, nor will it provide serial logs as evidence.

"It should work" does not equal "it does work." Logical correctness does not equal device behavior correctness. Embedded system behavior is affected by Flash layout, protocol timing, hardware state, and multiple other factors.

### Template Skeleton

```
Task: One sentence describing what to do
Verification Requirements:
  1. Must provide serial log or screen capture as evidence
  2. Never write "theoretically it should work"
  3. After task completion, run one complete flow on a physical device
```

### Rewritten

> The signature verification logic was changed. Host tests all pass, but the real device rejects the firmware. The root cause was a subtle semantic discrepancy in the signing script: it read image_len from the file size instead of the image header. This discrepancy went unnoticed in synthetic fixtures with static layouts but consistently failed on real firmware binaries.
>
> After the fix, do not only check the host tests. Take a real firmware image, run the full flow on a physical device, and send me the serial log screenshot. No serial log or screenshot means the task is not complete. Also, for any change that affects device behavior, "theoretically it should work" is not an acceptable statement — real-device evidence is required.

---

## Summary: Three Meta-Principles

Organize these six principles into three meta-principles:

**Meta-Principle 1: Task Descriptions Must Be Self-Contained**
AI cannot infer unstated requirements from context. All constraints, acceptance criteria, and environment assumptions must be explicitly documented within the task description.

**Meta-Principle 2: Task Descriptions Must Be Executable**
Every acceptance criterion must be verifiable by a single command or one observable action. Do not write "looks right" or "should work" types of statements.

**Meta-Principle 3: Task Descriptions Must Cover AI Blind Spots**
AI writes code, but it will not verify deployments, check online versions, or judge protocol alignment. These blind spots must be written into the task description by a person.

---

## Deliverable: Firmware Task Scaffolding Skill

Distill the six principles into a reusable skill file. Before asking AI to write embedded firmware code, use this skill to generate a template, then fill in the specifics.

```yaml
# skill: firmware-task-scaffold
# Purpose: Derive a complete acceptance template from a vague task description
# Usage: Input vague description → Output task description with template skeleton

task_template:
  title: "Task title (one sentence describing what to do)"
  description: "Task background and problem phenomenon"

  acceptance_criteria:
    - command: "nm build/meta-pass.elf | grep <symbol>"
      expected: "has output"
    - command: "grep -r <keyword> build/meta-pass.map"
      expected: "has record"
    - command: "Run QEMU once, serial log contains <message>"
      expected: "see expected log"
    - command: "grep CONFIG_<X> build/sdkconfig"
      expected: "=n or =y"
    - command: "ls -la build/meta-pass.bin"
      expected: "size < 1.5MB"

  environment_constraints:
    - "Forbidden to depend on local build/ directory"
    - "Forbidden to depend on network availability"
    - "Must run in a clean checkout environment"
    - "Test data must be versionable"

  verification_steps:
    - step: 1
      action: "Code fix"
    - step: 2
      action: "Redeploy to online environment"
    - step: 3
      action: "curl compare online file with repo source"
    - step: 4
      action: "Run one complete flow on real device"
    - step: 5
      action: "Provide serial log or screenshot"

  data_requirements:
    - "Must use real firmware images, not synthetic data"
    - "Test data must be versionable"

  deployment_checks:
    - "Ensure firmware embeds the output of `git describe`."
    - "Verify the web interface prints the current git SHA on initialization."
    - "Confirm the deployed version header using `curl -I <URL>` post-publish."

  code_placement:
    - "All install-slot code lives only in install-slot/ directory"
    - "Dev server and Pages deployment both read from this directory"
    - "No copies maintained elsewhere"
```

Usage:

1. When receiving a vague task description, check each item in the skill template for missing items
2. Fill missing items with specific commands, expected outputs, and constraint conditions
3. Output a complete task description including acceptance criteria, environment constraints, and verification steps

---

## References

[^1]: "Compiles green ≠ feature present" source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` lesson 2.

[^2]: Test depending on local build/ source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` lesson 4.

[^3]: sdkconfig masking data: two "clean builds" differed by 21% in size (1,283,232 vs 1,024,608 bytes). Source: nmem memory `09741cfa` (2026-09-13).

[^4]: BUG-03 took three days to trace. Source: `docs/assets/handoff-unsigned-rootcause.zh_CN.md` §0.

[^5]: Necessity of real-image verification source. Source: `docs/assets/handoff-unsigned-rootcause.zh_CN.md` §2.

[^6]: Root cause of esptool-js not reading MD5 digest frame. Source: `docs/development/engineering/debugging-workflow.zh_CN.md` §1 Round 4.

[^7]: Online installer page lag cause. Source: `docs/assets/handoff-unsigned-rootcause.zh_CN.md` §3.1.

[^8]: Hash inconsistency cause: ESP-IDF embeds compilation timestamp by default (`CONFIG_APP_COMPILE_TIME_DATE`). Source: nmem memory `17fcbeb8` (2026-09-11).

[^9]: Dev copy drift root cause. Source: nmem memory `c158ba6f` (2026-09-15).

[^10]: Real-device evidence > inference source: `docs/assets/meta-pass-v1-retrospective.zh_CN.md` engineering habits.

[^11]: Troubleshooting method when host and device conclusions diverge. Source: `docs/assets/handoff-unsigned-rootcause.zh_CN.md` §0.
