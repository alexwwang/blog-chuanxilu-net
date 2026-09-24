---
title: "把 ESP32 的开机策略写进 bootloader：meta-pass 单次会话模型的方案排除与实现"
slug: "esp32-bootloader-single-session-policy"
date: 2026-09-20T15:00:00+08:00
draft: false
description: 'meta-pass 是 AI Passport 的多固件启动器。产品需求只有一句话：断电再上电必须回到启动器列表页。最顺手的工具（ESP-IDF 的 OTA 回滚机制）在这个场景里是错的，而且错得很安静。本文记录三个方案的排除过程、otadata 的字节级判定规则，以及四条从 IDF v5.5.3 源码核实出来的实现细节。'
tags: ["AI", "ESP32", "固件", "FoloToy", "AI Passport", "meta-pass", "bootloader", "OTA"]
categories: ["AI 实践", "AI应用开发"]
series: ["AI应用开发"]
toc: true
---

meta-pass 是我给 AI Passport 写的多固件启动器：设备里有一个常驻的启动器和三个装玩法固件的槽位，开机先看到列表，选一个启动。从念头到 MVP 的过程记录在[上一篇复盘](/posts/2026/09/meta-pass-multi-firmware-launcher/)里。

MVP 到 v1.0 之间，最重要的一个决策和开机有关：**断电再上电，设备必须回到启动器列表页，玩法固件不能常驻。**

这个问题的影响超出了开机本身。第一，最顺手的工具在这个场景里是错的，而且错得很安静，失效时没有任何报错，设备直接被锁死在某个玩法里。第二，它回答一个通用问题：一条要约束所有参与者的规则，应该由哪一层代码执行。第三，otadata 的字节布局，网上流传的说法和 ESP-IDF 源码不一致，下面的结论都以 v5.5.3 源码为准，并附出处。

## 背景：开机时谁在决定启动谁

ESP32 的 Flash 里可以同时放多个程序分区。每次上电，第一段可定制的代码是二级 bootloader，本文说的 bootloader 都指它。它先读一份叫 otadata 的记录，再决定把控制权交给哪个分区[1]。

otadata 是两份 32 字节的记录，各占一个扇区。每条记录里有一个状态字段 `ota_state`。ESP-IDF 的 OTA 回滚机制围绕这个字段工作：新固件启动后先处于试运行状态，自检通过后调用 `esp_ota_mark_app_valid_cancel_rollback()` 把状态写成 VALID；状态为 VALID 的分区，以后每次上电都会被直接启动；没调用这行代码的固件，下次上电就回退[2]。

这套机制的设计场景是在线升级留退路：升级失败自动回旧版本。它默认的前提是，写 VALID 的那个固件，就是设备以后该常驻的固件。

## 问题：决定权在被管理的一方手里

把这套机制搬到启动器场景，前提就变了。meta-pass 里，调用那行代码的是玩法固件，也就是被管理的对象。只要玩法固件调了它，otadata 写入 VALID，之后每次上电 bootloader 都直接启动这个玩法固件，启动器没有运行的机会。

这不是假设。一个玩法固件的仓库里存着一份旧版集成头文件拷贝，里面就是这行调用。装上它的设备被锁死在玩法里，断电重启也回不到列表页。整个过程没有任何报错：策略不是出错了，只是不生效。

## 三个方案的排除过程

**方案 A：要求玩法固件别调用。** 不成立。要求所有玩法固件（包括未来的、别人写的）自觉不调用某行代码，等于没有约束。策略如果可以由被管理的一方绕过，就不是策略。

**方案 B：启动器开机时先擦 otadata。** 它有一个绕不过的窗口：bootloader 读 otadata、选分区，发生在任何应用运行之前[1]。只要 otadata 是 VALID，设备直接引导玩法固件，启动器的擦除代码没有执行的机会。这个方案只对软重启有效，对关机再开机无效，而需求的核心场景恰恰是后者。

**方案 C（最终方案）：把策略下沉到 bootloader。** IDF 提供 bootloader hooks 机制，这是 IDF 给的、能在分区选择之前运行自己代码的入口[1]。

## 实现：四个关键点

ESP-IDF 的 bootloader hooks 是一组 weak 符号（`bootloader_after_init` 等）。项目在 `bootloader_components/<name>/` 目录下提供强定义即可覆盖，再实现 `bootloader_hooks_include()` 保证链接。

**1. 执行时机。** `bootloader_after_init` 在 flash 初始化之后、分区选择之前执行。flash 读写 API 在这个上下文可用，IDF 自己写 otadata 用的就是同一组 API[3]。

**2. 判定规则只有一句话。** otadata 的两份 32 字节记录，结构定义在 IDF 源码里[4]：

    ota_seq          u32      4B
    seq_label        u8[20]   20B（IDF v5.5.3 源码不读写此字段）
    ota_state        u32      4B   { 0=NEW, 1=PENDING_VERIFY, 2=VALID, 3=INVALID, 4=ABORTED }
    crc              u32      4B   只覆盖 ota_seq 一个字段[5]

规则收敛为一句：**任意一份记录的 `ota_state == VALID`（0x2），就擦除它所在的扇区。**

为什么不做 CRC 校验。CRC 不合法的记录，bootloader 本来就不把它当启动候选[5]，擦不擦没有区别；CRC 合法且状态为 VALID 的记录，是会让设备常驻的唯一形态，擦掉它，本次启动必然回退到启动器。试运行状态（PENDING_VERIFY）不碰：bootloader 在选择前会自己把它标成 ABORTED，这是回滚流程的一部分，动了反而破坏回滚[3]。空扇区读出来是 0xFFFFFFFF，不等于 VALID，不会误伤。

**3. 确认代码真的被链接。** 本项目实际踩过这个问题：第一次构建通过后查 bootloader 的 map 文件，`hooks.c.obj` 根本不在里面。新建的 `bootloader_components/` 目录不会触发 CMake 重新配置，组件目录还必须有自己的 `CMakeLists.txt`，缺了它构建系统不报错，只是不编译这个组件。验证方法：

    # 日志字符串必须在 bootloader 二进制里
    strings build/bootloader/bootloader.bin | grep meta-boot
    # 目标文件必须出现在 map 文件里
    grep hooks.c.obj build/bootloader/project.map

构建通过不等于代码被链接。bootloader 的改动在设备上打印出日志之前，map 文件和二进制 strings 是唯一的证据。

**4. 四个边界情况在代码里显式处理。** otadata 的地址从分区表扫描得出，不硬编码，将来布局调整时策略自动跟随；每次擦除后读回复核，确认状态不再是 VALID；深睡眠唤醒时跳过全部检查，唤醒路径不做任何 flash 写；flash 加密启用时放弃干预，此时读到的是密文，判定不可靠，策略退化为不生效，而不是误擦。

## 验证与结果

- 已经被锁死的设备，刷入新 bootloader 后断电重启一次即自愈：hook 发现两份记录都是 VALID，擦除，回退到列表页。
- QEMU 里验证了最坏情况：两份记录都写入 CRC 合法的 VALID，ota_0 放真实可引导的玩法固件。标准 bootloader 在这种状态下必然常驻引导，只有 hook 生效才会回列表页。断言用双证据：hook 的 UART 日志加列表页截图。
- 玩法固件零配合。旧模板拷贝写 VALID 也没有用，下次上电必被擦。启动策略与玩法固件解耦。
- 纵深防御：启动器 `app_main` 早期仍会擦除一次 otadata，玩法固件的 hook 模板不再调用 `cancel_rollback`。三层里任意一层生效，设备都回列表页。

## 什么时候需要把规则写进 bootloader

这次经历可以收敛成四个检查问题。如果你的系统命中了前两条，规则就应该放在不可绕过的层，而不是放在参与者的代码里：

1. **规则要约束的对象里，有没有你控制不了的？** 第三方固件、旧版本、别人按老模板编译的产物，都不会读你的约定。
2. **规则失效时，会不会有任何报错？** 这次的失效形态是安静的：没有异常，没有日志，只是策略不生效。安静的失效只能靠机制兜底，不能靠约定。
3. **你选择的执行层，是否先于所有被约束者运行？** 方案 B 失败的原因就是它不满足这一条：bootloader 读表的动作发生在任何应用运行之前。
4. **交付前，如何证明代码真的在产物里？** 查 map 文件和二进制 strings。编译通过不算数。

meta-pass v1.0.0 已发布，这个开机策略是其中一项。v1.0 相比 MVP 的完整功能清单和使用场景，见[另一篇介绍](/posts/2026/09/meta-pass-v1-release-features/)。固件和安装页开源：[meta-pass](https://github.com/alexwwang/meta-pass)。

---

## 参考

1. ESP-IDF Bootloader 文档（启动流程与 hooks 机制）：<https://docs.espressif.com/projects/esp-idf/en/v5.5.3/esp32c3/api-guides/bootloader.html>
2. ESP-IDF OTA Updates API（`esp_ota_mark_app_valid_cancel_rollback` 与回滚语义）：<https://docs.espressif.com/projects/esp-idf/en/v5.5.3/esp32c3/api-reference/system/ota.html>
3. IDF v5.5.3 源码 `bootloader_utility.c`（bootloader 写 otadata 的先例、PENDING_VERIFY 自动标 ABORTED、无候选时默认引导 factory）：<https://github.com/espressif/esp-idf/blob/v5.5.3/components/bootloader_support/src/bootloader_utility.c>
4. IDF v5.5.3 源码 `esp_flash_partitions.h`（32 字节 otadata 记录结构定义）：<https://github.com/espressif/esp-idf/blob/v5.5.3/components/bootloader_support/include/esp_flash_partitions.h>
5. IDF v5.5.3 源码 `bootloader_common_loader.c`（otadata 启动候选判定，CRC 只覆盖 `ota_seq`）：<https://github.com/espressif/esp-idf/blob/v5.5.3/components/bootloader_support/src/bootloader_common_loader.c>
