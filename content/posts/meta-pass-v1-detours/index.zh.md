---
title: "meta-pass v1.0 开发弯路：六天九十个 commit 里的十三个教训"
slug: "meta-pass-v1-detours"
date: 2026-10-02T10:00:00+08:00
draft: true
description: 'MVP 上线六天后，meta-pass 从两个槽位扩到三个、补上签名和备份、修复了无数踩过的坑。这篇文章记录 v1.0 开发过程中的十三次弯路，以及每道弯路教会我的事。'
tags: ["AI", "ESP32", "固件", "FoloToy", "AI Passport", "meta-pass", "bootloader", "OTA", "踩坑"]
categories: ["AI 实践", "嵌入式开发"]
series: ["AI应用开发"]
cover:
  image: "cover.png"
  relative: true
  alt: "meta-pass v1.0 开发历程：从 MVP 到稳定版的十三次弯路"
toc: true
---

meta-pass 的 MVP 在 9 月 12 日上线后，我花了六天把它从两个槽位推到三个槽位、补上签名徽章、修好备份还原、搞定单文件固件和保数据升级。90 个 commit，十三次弯路[^1]。

上一篇复盘讲的是 MVP 的两天[2]。这篇讲的是 v1.0 的六天[^2]，那些踩过的坑、绕过的弯路，以及从坑里捞出来的几条硬道理。

## 一、约束逼出来的设计

**Flash 布局从两个槽位变成三个。** MVP 时期 factory 占 3MB，剩下两个 2MB 的槽位。有用户留言说「稍微实用点的功能都装不下」[^3]。v1.0 把 factory 压缩到 1.44MB，cardid 固定身份区前后各腾出一块夹缝空间，正好塞进两个新槽位：slot 0 拿到 1.84MB，slot 2 拿到 2.61MB[^4]。

这条改动的教训是：Flash 上的闲置空间不是真空，是设计资源。卡住 cardid 位置的那个规范不是障碍，是布局计算的锚点。把它当成约束而不是敌人，闲置空间就变出来了。

**单次会话策略从「依赖自觉」改成「bootloader 强制执行」。** MVP 最初方案是让子固件 hook 模板自己「不写 VALID」来实现在每次开机后回到启动器。但旧版社区固件照样会写 VALID，策略静默失效[^5]。v1.0 把策略挪到 bootloader 层，在任何固件运行之前检查并擦除 otadata 的 VALID 标记[^6]。效果是：无论子固件守不守规矩，开机必定回菜单；曾被锁死的设备，升级后断电重启一次就自愈。

这条教训是：系统级约束不能指望参与方配合。bootloader 是唯一能在所有固件之前执行的层，单次会话策略只能放在这里。

## 二、签名系统的四层崩塌

签名徽章是 v1.0 最折腾的部分。从 RSA 到 ECDSA 的切换只用了半天[^7]，但后续的修复链长达四天。

**第一层：image_len 语义偏差。** `sign-firmware.sh` 最初从文件大小读 image_len，后来发现应该从镜像头读；接着又把 byte 16 改成 byte 23，对齐 IDF 的 packed struct[^8]。四个连续 commit 修完，签名脚本才和 IDF 的 `esp_image_verify` 对上。

**第二层：线上安装页与仓库代码脱节。** BUG-03 排查了三天[^9]：仓库代码已经修复为「单写尾扇区」流程，但线上部署的安装页还是旧版（pre-dbbd091），执行三写流程时第二次 writeFlash 把第一次写的签名扇区擦掉了[^10]。真机表现为「签名固件显示未签名」。

这条教训是：仓库修复不等于线上修复。任何有两份副本的安装器都是常驻 bug，部署滞后会在你看不到的地方继续生效。

**第三层：16B 扩展头契约分裂。** 安装页 JS 有 `[16, 0]` 自动探测逻辑，签名脚本和宿主测试没有[^11]。三方对 image_len 的推导不一致。最终把探测移植进 `sign-firmware.sh` 和 `test_integration.c`，契约收口。

**第四层：Keychain 密钥 ACL 陷阱。** `SecItemDelete` 默认只删第一条匹配，重建钥匙必须加 `kSecMatchLimitAll`，否则旧私钥残留[^12]。签名工具查到旧钥后签出与发布公钥对不上，设备报 InvalidSignature。

## 三、工具链的隐性陷阱

**esptool-js 从不读 MD5 digest 帧。** 浏览器备份读取 1MB 要三分钟，还频繁失败[^13]。前三轮补丁（分块大小、重试次数、超时设置）全无效。后来逐行读 stub 源码才发现：`handle_flash_read` 在数据帧发完后无条件追加 16 字节 MD5 digest，但 esptool-js 从来不读这一帧[^14]。残帧留在传输缓冲里，每次 `readFlash` 调用都毒化下一次响应，协议错位累积导致备份必败。

修复方案：对齐 esptool.py 停等语义，读并校验 digest 帧，块大小降到 4KB（stub 硬上限）[^15]。

**esptool-js 库层的隐性自毁。** `readLoop` 超时后 `finally{buffer=new Uint8Array(0)}` 清空缓冲，但遗弃 generator 的定时器仍会触发，把正在流失效的数据整段吞掉[^16]。`flushInput()` 首行 `await this.reader.closed` 在活跃串口上永不落定，恢复链走到它就无限期挂死[^17]。这是「约 2 分钟必死链、重试 30 分钟零输出」的根因。

这条教训是：库代码里的 `finally{}` 与未决 Promise，会在你以为早已结束的时刻杀死你。遇到持续挂死，先审计库层所有 Promise.race 的落定路径[^18]。

**ESP-IDF 陈旧 sdkconfig 静默屏蔽。** 改完 `sdkconfig.defaults` 后 `idf.py build`，只要项目根存在 `sdkconfig`（即使被 .gitignore 忽略），IDF 直接复用而不重新生成[^19]。两次「干净构建」尺寸差 21%（1,283,232 vs 1,024,608 字节），且提交历史看不到任何异常。

这条教训是：改 defaults 后必须 `rm sdkconfig && idf.py build`。CI 每次全新 checkout 天然免疫，本地开发是高发区[^20]。

## 四、测试与 CI 的盲区

**Host 测试跨平台陷阱。** 宿主集成测试在 macOS 全绿但 CI（Linux）连挂两次[^21]：GCC 对未使用的 `static const char *TAG` 报 `-Wunused-variable`，clang 不报；`-Wl,-dead_strip` 是 macOS ld 专属，GNU ld 用 `-Wl,--gc-sections`。

这条教训是：「本地全绿」只代表 clang + macOS ld 一个组合。凡新增编译/链接参数或桩宏，先想 GCC/GNU ld 语义差异[^22]。

**一次失败的测试暴露环境耦合。** 有个测试直接读本地 `build/` 目录的构建产物做比对，本地全绿、CI 裸 checkout 后崩[^23]。改成双模式：有产物跑真比对，没产物用合成数据跑同一套逻辑断言。

这条教训是：静态门禁不允许隐式依赖本地环境。

## 五、发布与协作的坑

**Fork 转独立后的 Actions 陷阱。** push/tag 事件不触发 Actions，因为 fork 时期的禁用态在 leave fork network 后不自动恢复[^24]。API 查显示 enabled=true、workflows 全 active，但 check-suites 为空。只能手动 workflow_dispatch 兜底。根治是在 Actions 页面点启用横幅。

这条教训是：fork 独立化后第一件事推测试提交验证 CI 事件链[^25]。

**发布产物哈希不一致。** 同源码本地构建与 CI 构建哈希不同，因为 ESP-IDF 默认嵌入编译时间戳 `CONFIG_APP_COMPILE_TIME_DATE`[^26]。导致 plays 市场固件与 GitHub Release 固件同版本两个字节流。

这条教训是：发布市场时应下载 CI 构建的 release artifact 上传[^27]。

**dev 副本与发布副本必然漂移。** 开发版安装页用第二次 writeFlash 向已含签名的同一 4KB 尾扇区写显示名 blob，esptool 按写擦除，签名在烧写瞬间被抹掉[^28]。结构性修复：安装页单一规范目录，本地 dev server 与 Cloudflare Pages 部署同源，尾扇区永远单次 writeFlash 写入[^29]。

这条教训是：任何工具页有两份副本就是常驻 bug，服务必须单一来源[^30]。

## 六、从坑里捞出来的硬道理

这六天踩的坑，可以提炼成几条值得记住的规则。

**先验签名者，再查传输路径。** 「文件有效但设备不认」时，先用真实验签器证明文件本身，再沿写入路径回溯[^31]。设备读的是 flash，不是文件。

**一个扇区，一次写入。** esptool/esp_ota 按写擦除，对同一 4KB 扇区写两次等于第一次静默丢失[^32]。这就是尾扇区（MSIG/MAEG/MNAM）必须在内存拼好、单次写入的原因。

**造轮子前先逐行读久经考验的同类实现。** 备份读取问题修了三周，根源是 esptool-js 不读 MD5 digest 帧，而 esptool.py 的参照实现会读[^33]。当第三方客户端库与参照实现行为不一致时，先读服务端源码和参照客户端，再考虑修补失败处理[^34]。

**编译通过不等于功能在里面。** bootloader hook 第一次编译全绿，但检查二进制发现 hook 根本没被链接进去（新建组件目录不触发 cmake 重新配置）[^35]。交付前要找「它在产物里」的直接证据[^36]。

**注释里的一个反斜杠能炸掉整条 CI。** `//` 注释行尾带 `\`，编译器把下一行吞进注释，`-Werror=comment` 直接报错，存在一周多才被发现[^37]。

**静态分析先行。** 每次改完先自查（grep、map 文件、语法检查），再请验收[^38]。

**真机证据大于推断。** 设备屏幕闪没闪、串口日志有没有那行字，比「应该可以」可信[^39]。

## 结语

九十个 commit，十三次弯路。回头看，每一条弯路都指向同一个问题：我以为我知道，但实际上我不知道。

我以为仓库修复了线上就会修复，但它没有。
我以为编译通过功能就在，但它不在。
我以为 host 测试全绿真机也会全绿，但它没有。
我以为副本不会漂移，但它漂了。

这些认知偏差在嵌入式开发里尤其危险，因为硬件约束是不讲情面的。Flash 空间就那么大，协议错位一次就毒化整个会话，一个扇区写两次第一次就消失。踩过的坑如果没记下来，下次还会踩[^40]。

meta-pass 的源码在 GitHub 上开源（MIT），完整的设计文档、BUGS 清单和开发交接笔记在 `docs/` 目录下[^41]。

---

## 参考

[^1]: 6 天 = 2026-09-13 → 2026-09-18，90 个 commit。数据来源：git log。

[^2]: [给孩子的 AI 玩具做个多卡带启动器：meta-pass 开发复盘](/posts/2026/09/meta-pass-multi-firmware-launcher/)

[^3]: 用户留言原文：「没啥用，这玩意占用 3mb，剩下的也就两个 2mb 大小的空间了，稍微实用点的功能都装不下。」来源：FoloToy plays 市场 meta-pass 页面评论区。

[^4]: Flash 布局数据来源：`docs/assets/meta-pass-design.zh_CN.md` §3。

[^5]: 单次会话策略失效原因：旧版子固件 hook 模板拷贝一直是旧版，不写 VALID 的策略静默失效。来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md`。

[^6]: Bootloader 强制执行方案：`bootloader_components/meta_boot_hooks/` 注册 `bootloader_after_init` hook，检查并擦除 otadata 的 VALID 标记。来源：`docs/assets/meta-pass-design.zh_CN.md` §4。

[^7]: RSA-2048 → ECDSA-P256 切换原因：RSA 公钥 294B 太大，挤占固件空间；ECDSA 公钥仅 91B。来源：git log `ea21e03`（2026-09-13 22:13）和 `994caaf`（2026-09-13 23:40）。

[^8]: image_len 修复链：`24b82c0`（文件→镜像头）、`4dd6f78`（byte 16→byte 23）、`325d01f`（digest 范围）、`aa25c52`（Keychain 公钥嵌入）。来源：git log。

[^9]: BUG-03 排查耗时三天。来源：`docs/assets/handoff-unsigned-rootcause.zh_CN.md` §0。

[^10]: 线上安装页滞后原因：pages.yml 从 main 部署，但线上站点滞后于 main HEAD。实测抓取确认线上为 pre-dbbd091 旧版。来源：`docs/assets/handoff-unsigned-rootcause.zh_CN.md` §3.1。

[^11]: 16B 扩展头契约分裂来源：`docs/assets/handoff-unsigned-rootcause.zh_CN.md` §5。

[^12]: Keychain ACL 陷阱来源：nmem memory `f7518c1b`（2026-09-14）。

[^13]: 备份读取性能数据：修复前 1MB 读三分钟。来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md` 教训 3。

[^14]: esptool-js 不读 MD5 digest 帧根因：vendored esptool-js 从零版本起就不读 stub 无条件追加的 16 字节 digest 帧。来源：`docs/development/engineering/debugging-workflow.zh_CN.md` §1 第四轮。

[^15]: 修复方案：esptool.py 停等语义 + 读取校验 digest 帧 + 块大小 ≤ 4KB。来源：`docs/development/engineering/debugging-workflow.zh_CN.md` §1 第四轮。

[^16]: finally 块自毁根因：`FLASH_READ_TIMEOUT=100s` 与实测「约 2 分钟死链」精确吻合。来源：`docs/development/engineering/debugging-workflow.zh_CN.md` §1 第五轮。

[^17]: flushInput 挂死根因：`await this.reader.closed` 在活跃串口上永不落定。来源：`docs/development/engineering/debugging-workflow.zh_CN.md` §1 第五轮。

[^18]: 教训总结来源：`docs/development/engineering/debugging-workflow.zh_CN.md` §1 第五轮。

[^19]: sdkconfig 屏蔽数据：两次构建尺寸差 21%（1,283,232 vs 1,024,608 字节）。来源：nmem memory `09741cfa`（2026-09-13）。

[^20]: 修复习惯来源：nmem memory `09741cfa`。

[^21]: 跨平台陷阱来源：nmem memory `3bc116e3`（2026-09-13）。

[^22]: 教训总结来源：nmem memory `3bc116e3`。

[^23]: 测试依赖本地 build/ 来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md` 教训 4。

[^24]: Fork 转独立 Actions 陷阱来源：nmem memory `74a8042f`（2026-09-11）。

[^25]: 教训总结来源：nmem memory `74a8042f`。

[^26]: 哈希不一致原因：ESP-IDF 默认嵌入编译时间戳 `CONFIG_APP_COMPILE_TIME_DATE`。来源：nmem memory `17fcbeb8`（2026-09-11）。

[^27]: 教训总结来源：nmem memory `17fcbeb8`。

[^28]: dev 副本漂移根因：dev 副本 blobOffset 传分区大小而非镜像长度，name blob 写到槽位末尾外 4056 字节（slot 0 写进 cardid NVS 分区），双写擦掉 MSIG。来源：nmem memory `c158ba6f`（2026-09-15）。

[^29]: 结构性修复：`server.mjs` 直接服务规范的 `install-slot/`，杜绝开发副本漂移。来源：`docs/BUGS.zh_CN.md` BUG-03。

[^30]: 教训总结来源：nmem memory `c158ba6f`。

[^31]: 工作流来源：`docs/development/engineering/debugging-workflow.zh_CN.md` §2 教训 1。

[^32]: 教训来源：`docs/development/engineering/debugging-workflow.zh_CN.md` §2 教训 3。

[^33]: esptool.py 参照实现来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md` 教训 3。

[^34]: 教训来源：`docs/development/engineering/debugging-workflow.zh_CN.md` §1 第四轮。

[^35]: 编译通过 ≠ 功能在里面来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md` 教训 2。

[^36]: 教训来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md` 教训 2。

[^37]: 反斜杠炸 CI 来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md` 教训 5。

[^38]: 静态分析先行来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md` 工程习惯。

[^39]: 真机证据 > 推断来源：`docs/assets/meta-pass-v1-retrospective.zh_CN.md` 工程习惯。

[^40]: 踩过的坑如果没记下来，下次还会踩。所以我把这些都写进了 `docs/BUGS.md` 和 `docs/development/engineering/debugging-workflow.md`。

[^41]: meta-pass 仓库：[alexwwang/meta-pass](https://github.com/alexwwang/meta-pass)。设计文档、BUGS 清单、开发交接笔记均在 `docs/` 目录。
