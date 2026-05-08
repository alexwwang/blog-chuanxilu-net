---
title: "组件单独能跑≠拼起来能跑：18 个 bug 归纳的六种死法与集成盲区"
slug: "six-bug-patterns-and-integration-gaps"
date: 2026-05-07T10:00:00+08:00
draft: true
description: 'Aristotle v1.1 发布前发现了 18 个 bug，单元测试只拦住了 4 个。剩下的都在集成层。对它们做 root cause analysis 之后，我归纳出六种 AI 辅助开发中特有的 bug 模式——不是因为问题变难了，是因为 AI 绕过了你靠经验建立的防线。'
tags: ["AI", "bug 模式", "集成测试", "Aristotle", "AI 辅助开发", "TDD"]
categories: ["AI 实践"]
series: ["让 AI 学会反思", "用 TDD 驯服 AI 编码代理"]
toc: true
cover:
  image: "cover.png"
  alt: "六种 bug 模式：组件各自正确，集成后破碎，诊断性复盘中浮现规律"
---

## 一、测试全绿，系统不能用

这次开发Aristotle，有这样一种场景，我反复经历了好多次：所有自动化测试都绿了，lint 没报错，类型检查通过。我松了一口气，准备发布。

然后我开始手动跑完整流程，但系统直接不能用。不是某个边缘场景出问题，是最基本的路径走不通。测试覆盖了每个函数的逻辑，但拼起来就不对了。

这时的 Aristotle 是一个基于 MCP 协议的多进程工具编排平台——有注册机制、进程间通信、生命周期管理。不是玩具项目，也不是大系统，就是一个中等复杂度的工具。

发布前发现了 18 个 bug。单元测试拦住了 4 个，22%。

单元测试覆盖了每个函数的逻辑正确性，这没问题。但 18 个 bug 里的 14 个，都不在函数逻辑层面——它们在组件接线、配置传递、进程启动的交叉点上。单独看每个组件，代码都是对的，拼起来就炸。

## 二、我以前不会犯这些错

这 18 个 bug 里面有几个，换作以前手写代码，我不会犯，因为手写代码的过程自带审查。写注册逻辑的时候，我会边写边想：这个服务需要在入口文件注册，那个工具要加到路由表里。写代码和检查接线是同一件事。

用 AI 之后，三分钟就能生成一整套注册逻辑。代码风格整齐、有注释、命名规范，比我自己写的还好看。我扫一眼就放过了。不是因为我偷懒，是因为我的 review 速度跟不上它的生成速度。这是第一层——速度的落差。

然后是信任。同样的逻辑如果是一个实习生写的，我可能会逐行检查。但 AI 写的代码看起来太专业了。有类型注解、有错误处理、有合理的抽象。这种整齐感会降低警觉性。我看到代码"有日志"就满意了，不会去检查日志的级别是不是对。

最隐蔽的是第三层。传统开发中，集成是一个显式动作。你把新模块接入现有系统，这个动作本身会强迫你检查接线、路径、配置。用 AI 的时候，多个组件几乎同时生成。集成的"拼装"环节被压缩了。你以为 AI 生成了完整的系统，其实它生成的是一堆能单独跑的零件。

传统开发有一个隐含的耦合：你的能力和你生成的复杂度是同步增长的。你能写多复杂的代码，通常意味着你有多大的能力去调试它。AI 打破了这个耦合。它让你以低于传统门槛的经验，生成高于传统门槛复杂度的代码。这不是 AI 的问题，是你对这种能力-复杂度脱钩还没有建立新的防御机制。

---

## 三、六种我踩过的坑

对 18 个 bug 做 root cause analysis 之后，它们集中在六种模式里。每种我都踩过不止一次。

### 路径写对了，环境不对（5/18）

想象你出差或外派，网上买了东西要送到住的酒店，但快递公司把包裹送到了你家。包裹没丢，地址也"没错"——只是和你的实际位置对不上。

根因是 AI 缺乏对部署环境的感知。代码里的路径在开发环境是对的，换到部署环境就对不上。占比最大的一类（5/18，28%），也是最让我窝火的一类。

部署之后 MCP server 启动失败。日志显示 uv 找不到项目的 Python 环境，回退到了系统自带的 Python 3.8。系统 3.8 缺少依赖模块，直接报错退出。

查配置文件，路径写的是 `~/path/to/module`。在开发机上，shell 会自动展开 tilde，一切正常。部署时启动脚本不走 shell 展开，tilde 被当作字面字符串。模块找不到，服务起不来。

完整的链条是：`uv run --project ~/path` 不展开 tilde → 路径无效 → uv 回退到系统 Python 3.8 → 缺少模块 → MCP server 启动失败。开发时用展开后的绝对路径测试，提交配置时写成了 tilde。AI 生成的代码在当前环境"碰巧"能跑通。

以前手写路径会主动考虑环境差异。AI 生成了一个看起来合理的路径，代码太整齐了，你不会怀疑它的路径有问题。

后来我让 AI 在 CI 里加了两条 grep：

```sh
# 查找硬编码的绝对路径
grep -rn '/Users/\|/home/\|C:\\\|D:\\' --include='*.ts' --include='*.py' --include='*.json' .
# 查找未展开的 tilde
grep -rn '~/' --include='*.json' --include='*.yaml' --include='*.toml' .
```

硬编码路径和未展开的 tilde 在 CI 中直接暴露。

### 写了，但没注册（3/18）

想象你招了一个人，但忘了给他办系统权限。人坐在工位上，能力完全够，但公司的系统不认识他，他没法干活。

机制是功能实现和系统注册脱节。功能写好了，测试也过了，但真实用户调用时这个工具根本不存在。比路径问题更隐蔽。

在 Aristotle 里，有工具函数被 export 了，但从未出现在 MCP server 的 tool 注册列表中。单元测试能跑，因为测试直接调用函数——测试框架会自动发现并注册 export 的函数。真实环境没人做这件事。函数就在那里，但系统不知道它的存在。

以前写新功能，接线和实现是同一个动作的两个步骤。写完函数，下一步就去入口文件注册。AI 生成代码时，接线步骤在不同的文件、不同的上下文中。注册这个动作从它的上下文窗口里消失了。

后来我让 AI 加了这样一个检查：每次 review 包含新功能的 PR，先 grep 导出和注册的对应关系：

```sh
# 列出所有导出的函数/类
grep -rn 'export function\|export class\|def ' src/ | grep -v test
# 列出所有注册点
grep -rn 'register\|\.tool(\|mcp\.tool(' src/init.ts
```

两条命令的结果一对，导出但没注册的，就是运行时不可见的。

### 系统卡住了，不报错也不继续（2/18）

想象你在等一个朋友，他说在路上了。你一直等，不知道他其实车抛锚了。没有电话，没有短信，就是一直等，仿佛在等待戈多。

根因是初始化依赖没有超时保护。组件 A 启动慢，组件 B 的 `await` 没有 timeout，就跟着一直等。路径问题至少有错误信息，注册问题好歹能用排查工具发现。启动阻塞是什么都没有——系统卡住，无错误，无超时，就是永远等下去。

AI 生成初始化代码时，会给每个组件写"理想路径"——假设依赖都在、网络畅通、资源可用。多个组件的初始化存在依赖时，AI 不会主动建立超时级联。现实不符合假设时，系统不报错，只是永远等。

以前写初始化代码，部署环境不如开发环境干净，这种问题部署时就会暴露。但用 AI 辅助之后，本地测试环境也往往太干净了，所有依赖都在本地。开发服务器可能永远不会在没有网络的情况下启动。

后来我让 AI 做了两件事。一是在 CI 里断言启动时间不超过 5 秒，超过就失败。二是查没有 timeout 保护的调用：

```sh
# 测量启动时间
time <start-command>
# 查找没有 timeout 保护的 await/fetch/connect
grep -rn 'await\|fetch\|connect' src/init.ts | grep -v 'timeout'
```

### 比阻塞更头疼：什么都没发生（2/18）

想象一个烟雾报警器，着火的时候只是小声嘀咕了一句"有烟"，而不是大声鸣响。火在烧，但你不知道。

机制是错误被 catch 吞掉，只输出低级别日志。阻塞至少能让你知道有问题——系统卡住了嘛。静默失败是：操作失败了，但用户看不到任何反馈。日志里只有一行 `debug: task completed with errors`。一个后台任务失败了，用户等了五分钟什么都没发生。

AI 生成 catch 块时，优先保证"流程不中断"。用 `logger.debug` 或 `logger.info` 记录严重错误，用 catch 吞掉异常然后 `continue`。不是 throw，不是 error，是静默跳过。这不是 AI 有意在隐藏问题，它只是在生成代码时选择了"不破坏流程"的策略。

以前遇到静默失败会加日志、加通知。但 AI 生成的代码"已经有日志了"——只是级别不对。review 时看到 `logger.info(...)`，不会立刻意识到这应该是 `logger.error(...)`。防线没启动，因为没意识到需要防御。

后来我让 AI 加了一条 grep 到 review 流程里：

```sh
# 查找可能不够严重的日志级别
grep -rn 'logger\.\(debug\|info\)' src/ | grep -v test
```

看每一行：这个日志的级别够不够？后台任务的失败、定时任务的异常——这些应该是 `warn` 或 `error`，不是 `debug`。

### 测试全绿，生产出 bug（2/18）

想象你在停车场里练倒车练得很熟练，但实际考试是在公路上开车。练的和考的不是同一内容。

根因是测试覆盖的路径和生产实际路径不一致。不是测试有 bug，是测试走的路径和真实用户走的路径不一样。测试全部通过，生产环境出问题。

在 Aristotle 里，有测试用 `stdin` 触发 graceful shutdown。测试覆盖了优雅关闭的完整流程——清理资源、保存状态、通知下游。全部通过。但真实场景中进程被 SIGKILL 直接杀死，连 cleanup handler 都来不及执行。测试覆盖的 graceful shutdown 路径，在生产中根本不会被走到。

AI 生成测试时，倾向于走"AI 自己的调用路径"——直接调用函数、使用测试专用的 API、模拟一个简化的输入。这些测试在验证逻辑正确性上是有效的，但它们跳过了真实用户经历的完整路径。

以前写测试会刻意模拟真实场景。这个"刻意"来自对系统的整体理解。AI 生成测试时，理解局限在当前组件的接口定义里，不知道用户实际是怎么激活这个功能的。

检查方法很直觉——看看测试用的激活机制和真实用户一样不一样：

```sh
# 查看测试用的激活机制
grep -rn 'send-keys\|stdin\|mock.*trigger' test/ | head -5
```

如果真实用户通过 CLI 触发，测试就应该用 CLI 触发。如果真实用户通过 HTTP 请求，测试就应该用 HTTP。不让测试走捷径，是预防这类 bug 唯一可靠的方式。

### 单独都对，拼起来就错（4/18）

想象两个人各说一句话的一半，一个人说英文，一个人说中文。各自说的都没错，拼在一起互相看不懂。

根因是 AI 按组件逐个实现，缺乏跨组件的接口一致性检查。单独看每个组件都没问题，放在一起就出问题。占比第二大（4/18，22%）。

AI 分别生成两个组件时，每次都"对了"，但合在一起就不对了。参数格式不一致、ID 没有正确传递、进程间通信的边界条件——这些都在拼接的缝隙里。

在 Aristotle 里，有地方用 `execFile` 做进程间通信。`execFile` 不支持双向 IPC，需要用 `spawn`。AI 在写单个调用时选择了 `execFile`——因为不需要交互，看起来合理。但整体架构需要双向通信，AI 看不到这个全局需求。

以前写代码，集成是一个显式动作。两个手写的模块接在一起，接口不匹配会立刻暴露。用 AI 的时候，多个组件几乎同时生成。每个组件都有自己的测试、都通过了 lint、都有类型定义。"应该没问题"成了下意识的判断。

后来我让 AI 用这些命令做检查：

```sh
# 检查进程间通信方式
grep -rn 'execFile\|execSync' src/
# 检查 ID 字段是否正确传递
grep -rn 'parentId\|sessionId\|ownerId' src/ | grep -v test
```

---

## 四、事后整理的检查清单

发布之后，我让 AI 把这些教训整理成了一个清单。不是理论框架，是实际踩过的坑——每一行对应一个真实遇到的 bug。

每次用 AI 生成一组新组件之后，我让它拿这个清单做 review。生成速度快，但 review 质量可以用结构化检查来保证。

对于项目中每一对交互的组件，逐行检查。任何一栏回答"不确定"，那就是盲区。

| 维度 | 问什么 | 怎么查 | 案例 |
|------|--------|--------|------|
| Schema | 组件间数据格式是否一致？ | 比较每个边界的输入/输出 schema | A 输出 `id`，B 期望 `userId` |
| State | 跨进程的状态管理是否正确？ | 检查：谁创建、谁读取、谁清理临时文件 | 临时文件没人清理，下次启动读到脏数据 |
| Timing | 是否存在竞态条件？ | 检查：启动顺序、空闲检测、轮询间隔 | A 还没启动完，B 就开始调用 A 的接口 |
| Error propagation | A 的错误能在 B 中体现吗？ | 在 A 注入错误，验证 B 能检测并处理 | A 的进程崩了，B 永远等下去不报错 |
| Config propagation | 同一份配置到达所有组件了吗？ | 比较每个组件的已解析配置（不是配置文件） | 配置文件写对了，但环境变量覆盖了一个组件的值 |
| Registration chain | 每个服务消费者能找到它需要的提供者吗？ | 枚举已注册的工具/服务，和预期列表对比 | 工具函数写了但没注册，运行时不存在 |
| Lifecycle | 启动创建的东西关停时清理了吗？ | Kill 进程，检查残留文件/进程 | PID 文件没删，下次启动认为"已在运行" |
| Freshness | 全新环境能跑吗？有残留状态的环境也能跑吗？ | 分别在干净和脏环境中测试 | 开发机上能跑（有上次运行的缓存），CI 上挂了 |

有一个维度不在这个清单里：测试-生产差异。它不是集成检查能发现的，需要在测试设计阶段就介入——确保测试用和真实用户一样的激活路径。

---

## 五、还没踩到的坑

18 个 bug 只覆盖了六种模式。但多组件系统中，我在其他项目里遇到的 bug 类型不止这些。把常见的列出来，和 Aristotle v1.1 的情况对一下，就知道下一步该防什么了。

| 传统开发中的常见 bug 类型 | Aristotle v1.1 是否出现 | 下一步 |
|---|---|---|
| 路径/配置不一致 <sup>1,2</sup> | ✅ 5 个 | 已有 CI grep 检查 |
| 注册/接线遗漏 <sup>1</sup> | ✅ 3 个 | 已加入 review checklist |
| 启动阻塞 <sup>1</sup> | ✅ 2 个 | 已加启动时间断言 |
| 静默失败 <sup>3</sup> | ✅ 2 个 | 已加日志级别 grep |
| 测试-生产路径差异 <sup>2,4</sup> | ✅ 2 个 | E2E 用真实激活路径 |
| 集成拼接错误 <sup>1,5</sup> | ✅ 4 个 | 八维度清单逐项检查 |
| 资源泄漏（内存、文件描述符、连接池） <sup>6</sup> | ❌ | 下个版本加长时间运行的 soak test |
| 竞态条件（并发访问共享状态） <sup>1,6</sup> | ❌ | 八维度清单里有 Timing，但从没实际测过 |
| 数据序列化边界（编码、精度、特殊字符） <sup>1,5</sup> | ❌ | 跨语言组件间需要加 schema 验证 |
| 版本偏移（组件 A 升级了，B 还在用旧接口） <sup>1,2</sup> | ❌ | 加 contract test，锁定组件间的接口契约 |
| 优雅降级（非关键依赖挂了，系统怎么办） <sup>7</sup> | ❌ | 需要设计 fallback 策略，不只是加 timeout |
| 权限/认证边界（组件间的访问控制不一致） <sup>4,8</sup> | ❌ | 多租户场景才会出现，当前项目暂未涉及 |
| 错误处理缺陷（错误处理代码本身有 bug） <sup>9</sup> | ❌ | 区别于静默失败：静默失败是没有处理，这个是有处理但写错了——错误被放大、fallback 逻辑有缺陷、异常类型不匹配 |
| 性能逻辑缺陷（特定场景下性能急剧退化） <sup>6,10</sup> | ❌ | 区别于资源泄漏：不是泄漏，是逻辑导致——N+1 查询、慢路径未优化、批量操作走了单条路径 |
| 级联/连锁故障（单点故障通过依赖链扩散） <sup>2,11</sup> | ❌ | 区别于优雅降级：优雅降级是期望行为，级联故障是实际灾难——一个组件挂了，重试风暴把下游也打挂 |
| 隐式契约违反（未文档化的语义假设被打破） <sup>5</sup> | ❌ | 区别于集成拼接错误：集成错误是显式接口不匹配，这个是隐式假设——调用顺序、线程安全、同步/异步语义 |

前六行是踩过的坑，后十行是还没踩到但迟早会来的，比如资源泄漏和竞态条件——这两个在长时间运行和并发场景下几乎必然出现，只是 Aristotle v1.1 还没跑到那个复杂度。

---

## 你经历过哪些恼人时刻？

这六种 bug 模式来自一个中等复杂度项目的 18 个真实 bug。你的项目可能复杂度不同、技术栈不同，但 AI 辅助开发带来的能力-复杂度脱钩是一样的。

如果你也在用 AI 写代码，欢迎在评论区聊聊：

- 你遇到过哪种 bug 模式？有没有这里没列到的？
- 文末那个八维度清单，你觉得还缺什么维度？
- 你有自己的一套 review 或检查机制吗？效果怎么样？

---

## 参考

1. Chillarege et al., "Orthogonal Defect Classification" (ODC), IBM Research, 1992. ODC v5.11 将缺陷分为 8 种类型和 10+ 种触发条件。路径/配置 → Trigger: Configuration；注册遗漏 → Type: Interface/Missing；启动阻塞 → Trigger: Startup/Restart；竞态条件 → Type: Timing/Serialization；数据序列化 → Type: Checking；版本偏移 → Trigger: Backward/Lateral Compatibility；集成拼接 → Type: Interface/Relationship。 [DOI](https://doi.org/10.1109/32.177364)
2. Google SRE Workbook, Appendix C. 基于数千份 postmortem 的根因统计：配置变更占故障触发因素的 31%，二进制发布占 37%，性能退化占 5%。 [sre.google](https://sre.google/workbook/chapters/postmortem-analysis/)
3. Google SRE Book, Chapter 14: "Emergency Response". 分布式系统中的 omission fault（系统未能执行预期动作）是静默失败在故障分类中的正式名称。 [sre.google](https://sre.google/sre-book/emergency-response/)
4. Catolino et al., "Not all bugs are the same: Quantifying bug types in open-source software", *Journal of Systems and Software*, 2019. 基于 Mozilla/Apache/Eclipse 共 1280 个 bug 报告的实证分析。 [DOI](https://doi.org/10.1016/j.jss.2019.03.002)
5. Tang et al., "Cross-System Interaction Failures in Cloud Computing", UIUC, 2023. 研究了 Google/Azure/AWS 的 11 个重大事故和 120 个案例，发现 69% 的 control-plane 故障根因是系统间的隐式语义假设被违反。 [DOI](https://doi.org/10.1145/3552326.3587448)
6. Leesatapornwongsa et al., "TaxDC: A Taxonomy of Non-Deterministic Concurrency Bugs in Distributed Systems", *ASPLOS*, 2016. TaxPerf 后续研究将性能逻辑缺陷列为分布式性能 bug 的六大根因之一，资源泄漏列为 Resource 类别的首要模式。 [DOI](https://doi.org/10.1145/2872362.2872374)
7. Nygard, *Release It!*, 2nd ed., Pragmatic Bookshelf, 2018. 系统韧性模式（Circuit Breaker、Bulkhead、Timeout、Fallback）的行业标准参考。 [pragprog.com](https://pragprog.com/titles/mnee2/release-it-second-edition/)
8. MITRE CWE (Common Weakness Enumeration). CWE-862: Missing Authorization; CWE-863: Incorrect Authorization. 权限/认证边界的标准化弱点分类。 [CWE-862](https://cwe.mitre.org/data/definitions/862.html) · [CWE-863](https://cwe.mitre.org/data/definitions/863.html)
9. Gunawi et al., "What Bugs Live in the Cloud? A Study of Bugs in Distributed Systems", *ACM Computing Surveys*, 2016. 错误处理占分布式系统软件 bug 的 18%。Linux kernel 的 `eBugs` 数据集记录了 210 个错误处理缺陷案例。 [DOI](https://doi.org/10.1145/2670979.2670986)
10. Jin et al., "Understanding and Solving Real-World Performance Bugs in Software", *ASPLOS*, 2012. 对 5 个大型开源项目（Apache、Mozilla、GCC、MySQL、PostgreSQL）中 109 个性能 bug 的根因分类。 [DOI](https://doi.org/10.1145/2254064.2254075)
11. Google SRE Book, Chapter 22: "Addressing Cascading Failures". 级联故障的防御策略：限流、降级、取消请求，防止单点故障通过依赖链扩散。 [sre.google](https://sre.google/sre-book/addressing-cascading-failures/)
