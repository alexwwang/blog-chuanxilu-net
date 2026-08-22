---
title: "96 条审稿意见，84 条是错的"
slug: "gemini-chrome-review-skill-dev"
date: 2026-08-18T14:00:00+08:00
draft: false
description: "让 Chrome 内置的 Gemini 给英文博客提修改意见：96 条意见 84 条是错的。三天手工审稿、一天脚本化，十几个坑，和一条最重要的边界。"
tags: ["AI", "agent", "debug", "automation", "CDP"]
categories: ["AI Practice"]
toc: true
cover:
  image: "cover.webp"
  alt: "发光的浏览器窗口，右侧停靠 AI 审稿面板，前方散落被划掉的批注纸条，一张被圈选保留"
  caption: "96 条审稿意见，84 条是错的"
---

被 AI 审稿折磨了三天，它给我的一篇英文博客提了 96 条修改意见，我采纳了 12 条。剩下 84 条里，一半是它没看原文就开炮，一半是它想把我的文章改成它自己的腔调。

但我还是决定继续使用它，因为那 12 条接受的意见里，有 8 条是写作 AI 没检查出的问题。

这么熬了三天，我把修改过程做成了一套自动化工作流，核心就两个字：保真。保的是原文的事实和风格：事情不能改，态度不能变。

## 先有 22 轮手工

我写双语博客，英文稿是中文的改写（不是翻译），写完需要做润色修改。我选中了 Chrome 内置的 Ask Gemini 面板当审稿人。它能直接"看到"渲染后的页面，还能在同一对话里追问。

审稿方法论分六个维度：逻辑、术语、结构语法、微语法、修辞风格、Markdown 格式，每个维度一个独立对话。操作全通过 Chrome 浏览器：开新对话、@ 关联文章、注入提示词、点 Submit、等 1 分钟、看回复、改文章、本地预览效果。

六维跑完，用了 22 个来回。每轮都是手写提示词，同样一串"点击、注入、轮询、提取"的循环。痛苦在累积，但思路在这一圈里成型：六维循环的 workflow、审核要点、提示词模板、停止条件，都摸清了。

这 22 轮的产出不只是一篇文章的具体修改结果。后面写脚本时，直接以这 22 轮的手工流程为起点，开始迭代。

## 决定脚本化：先划一条边界

复盘后决定：把确定性操作写成 CLI。于是有了 `glic_ops.py`，九个命令覆盖一轮流程：anchor（锚定面板）、newchat、atlink（@ 关联）、inject、submit、poll、extract、verify、commit。

当时划的线，事后看是全文最重要的决定：**确定性操作全部脚本化，语义判断一律不脚本化**。意见该不该采纳、错误恢复选哪个 fallback、什么时候停，都留给核对程序（subagent）和用户。设计文档里的理由很直接：反模式识别、语义等价核对需要语言理解，不是脚本能干的。

但脚本化只是把麻烦从"操作层"挪到了"调试层"。真正的故事从这里开始。

## 看不见的浏览器

第一个坑：操作打在了看不见的面板上。Chrome 内置的 Ask Gemini（内部代号 GLIC，Gemini Live in Chrome）是两层结构：`chrome://glic` 可信容器里，嵌一个加载 Gemini 应用的 webview。[^1] 在 CDP 里，这类嵌入页面的 target 类型就叫 `webview`，`parentId` 指向宿主容器。[^2] 历史操作（reload、关面板）会留下 Closed 容器和孤儿 webview，它们也出现在 target 列表里，甚至带着旧内容。按内容特征选 target，会选中用户根本看不到的隐藏实例：操作全打了空气，还误以为面板没反应。

{{< figure src="illustration-1.webp" alt="半透明的幽灵浏览器容器，内嵌空心 webview，旁边漂浮着几个孤儿实例" caption="看不见的浏览器：可信容器、webview 与孤儿实例" width="480" >}}

解法：只认 title 含 "Gemini in Chrome Open" 的容器，每次操作前重新枚举。顺带立了条铁律：面板 webview 禁止 reload/navigate，那会把面板搞成孤儿，body 永远卡在 24 字节的 "Conversation with Gemini"。

这是环境层的坑。下一层更阴：编辑器内部状态。

## Angular 三连坑

面板 UI 是 Angular 栈，@ 菜单的弹出层挂在 `.cdk-overlay-container` 下，那是 Angular CDK 的 Overlay 容器类。[^3] 输入框是 contenteditable 富文本编辑器：DOM 和编辑器内部状态是两层，Submit 按钮的显隐绑定在内部状态上，不直接读 DOM。

{{< figure src="illustration-2.webp" alt="两块平行的半透明玻璃板，一个 @ 符号卡在两层之间的间隙里" caption="DOM 与编辑器内部状态：两层之间卡住的 @" width="480" >}}

第一坑：@ 关联文章后，输入框残留孤立 @。实测 Backspace、Cmd+A 都删不掉：键盘操作只改了可见的那层，内部状态没跟着变。试出来的解法：先插一个空格逼状态同步，再 `execCommand` selectAll+delete。它虽已被标为废弃，却仍是 contenteditable 里能触发浏览器原生编辑管线、让编辑器感知变化的路径。[^4]

第二坑：CDP 的 `Input.insertText`，官方定义就是模拟 IME、表情键盘这类"非按键"文本输入。[^5] 实测：DOM 有字了，Submit 按钮就是不出现，内部状态没跟上。修复：再补一个空格。第三坑：Enter 不触发发送，必须点 Submit 按钮。还有个隐藏坑：个别 webview 里 CDP 鼠标事件不触发 Angular 的点击处理（坐标命中正常、无遮挡），得用 JS 原生 `click()` 兜底。

每一条都来自实测。脚本化的价值在于：这些教训只踩一次。

## 自己写的工具把流程炸了

最惊险的事故来自自己的脚本。feedback 文件（上一轮被拒建议的分类清单）是用 shell 命令生成的：条目文本里带着单引号，拼进追加命令后引号解析错乱，命令没能按预期收尾；它又被丢在后台跑，重试时每次都在往文件里追加内容，重复写入累计到 418,900 行——111MB。等发现时，inject 命令正把这 111MB 塞进输入框，Chrome 直接断连（BrokenPipe）：正在审稿的面板对话当场中断，若是这堆垃圾真进了 prompt，Gemini 的上下文就被污染，整轮审稿作废。更麻烦的是它难排查，单引号嵌套和后台竞态单独看都无害，叠加起来才爆炸。

教训：工具链的 bug 和 UI 的 bug 一样致命。修复从根上换掉生成方式：改用 write 工具创建文件。它一次覆盖写，内容作为参数直接传递，不经 shell 解析，引号错乱这条根因消失；失败重试也是覆盖而非追加，文件不会越写越大，竞态膨胀这条根因也消失。再给 build_prompt.py 加 100KB 上限，超限直接报错，宁可失败，不要污染。

## 时序的战争

改了文章，verify 却报 missing，页面明明改了。两个原因：Hugo watch 重建要 4-10 秒，edit 后立刻 curl 必撞重建窗口；HTML 实体和弯引号会变样（`'` 渲染成 `&#39;`，直引号变弯引号）。解法：verify 自动重试 25 秒 + 归一化比对。

另一个伪卡死也要提一下，主要是模型的自发处理太蠢了：Gemini 停住不生成，agent 的第一反应往往是宣布它卡死了，但真正的原因是，当浏览器的 Gemini 页面不在前台时，内建的 JS 定时器不工作，面板生成流程就停住了。[^6] 用 `osascript` 把 Chrome 激活到前台，等 30 秒，它常常就继续了。这条后来被写进技能文档，变成纪律 "browser focus recovery before treating Gemini as hung" 的由来：在宣布卡死之前，先检查 Chrome 窗口是否在前端，拦住 agent 草率下结论的冲动。

## 工具全修好了，意见还是不能信

环境、模型、工具、时序都摆平了，全流程脚本化跑通。然后真正的打击来了：新文章第一轮六维跑完，Gemini 提了 96 条意见，否决 84 条，否决率 89%。

Gemini 质量没问题，问题出在维度被风格偏好淹没：它把 rhetorical question 当句子碎片、强制 SVO 句式、要求数字拼写规则、给术语做"统一化"。它把"我不喜欢这种写法"包装成"这是语法错误"。

这个问题不只是改提示词，还需要在流程里增加几个判断策略：

- **反模式门**：核对程序收到意见先过我日常收集整理的反模式清单：em dash、we、AI slop 词、语义不等价、教学内容保真。
- **事实核对**：一篇文章里它建议删掉 scheduler、Ubuntu 22.04，但核对程序查过技术事实后，把这两处都留下了。数字、版本、限定词丢了，语义就不等价了。
- **渲染差异认知**：某次微语法维度首轮，16 条意见里 13 条是"缺反引号/bold/标题级别"，它看的是渲染后的 HTML，md 源里全都有。这类意见先 grep 源文件验证。

## 驯服摇摆、偷懒和重复

Gemini 的三种"非质量问题"：

- **摇摆**：同一位置来回改：driven/caused、parse/evaluate、prevents/targets……光记在案的就 8 组。协议：无实质改进的摇摆建议跳过。
- **懒哨兵**：不能在提示词里写 "If no issues output NO_ISSUES" 这类哨兵指令，否则 Gemini 会偷懒，图省事直接回哨兵。提示词只要求 Gemini 输出问题和修改建议，不要让它自己下结论。
- **重复误报**：一轮意见全是上一轮重复项，说明它在循环提被拒过的意见。于是在提示词里加入反馈循环：把被拒建议分类汇总后，追加入下一轮提示词，逼它重新思考被拒的建议是否需要提出，同时继续寻找新问题，这样同类误报明显减少。

停止规则也改了：一轮 0 修改不能立即判停（可能是全否决轮），必须追加一轮带反馈块的追问，连续两轮 0 修改才停。

## 脚本化的边界

回头看，技能真正的核心是边界，27KB 的 SKILL.md 和那几行 Python 只是载体：

- **确定性 → 脚本**：九个命令
- **语义 → LLM**：核对程序（subagent）独立判意见
- **裁决 → 人**：用户推翻过核对程序的否决

配套两条工程纪律：每轮修改后本地 commit（可回滚到上一轮）；主 agent 不读 Gemini 输出全文，只把文件路径交给 subagent（防上下文污染）。

现在审一篇文章：一条 ensure 检测面板，九个命令跑一轮，六维 × 若干轮。当初手写的 op 编号们退役了。

回到开头那 84 条错意见，它们没进回收站，被分类、写进反馈块、注入下一轮提示词，逼审稿人重新思考。几轮之后，它不再提那些意见了。

审稿人还是那个审稿人，只是学会了闭嘴。

[^1]: Chromium 源码 commit [d288e68「Add webui / webview for glic」](https://chromium.googlesource.com/chromium/src/+/d288e68eea0d53bb2bb9654e43c2b1ba0c941a56)：chrome://glic WebUI 持有 webview；Chromium [issue 502779725](https://issues.chromium.org/issues/502779725)：可信 WebUI（chrome://glic）承载 untrusted guest 页面。
[^2]: CDP 官方文档 [TargetInfo.parentId](https://chromedevtools.github.io/devtools-protocol/tot/Target/#type-TargetInfo)：「Id of the parent target, if any」；chromium [devtools_agent_host_impl.cc](https://source.chromium.org/chromium/chromium/src/+/main:content/browser/devtools/devtools_agent_host_impl.cc)：`kTypeGuest[] = "webview"`。
[^3]: @ 菜单弹出层挂在 `.cdk-overlay-container` 下，angular/components [overlay-container.ts](https://github.com/angular/components/blob/main/src/cdk/overlay/overlay-container.ts)：OverlayContainer 创建的容器 div；Angular 变更检测由 zone.js 补丁的异步任务触发（[angular.love](https://angular.love/change-detection-big-picture-rendering-cycle)）。
[^4]: MDN [Document.execCommand](https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand)（已废弃但仍受支持）；W3C [execCommand spec](https://w3c.github.io/editing/docs/execCommand)：编辑命令映射为 inputType，产生 isTrusted 的 InputEvent。
[^5]: CDP [Input.insertText](https://chromedevtools.github.io/devtools-protocol/tot/Input/#method-insertText) 官方文档："emulates inserting text that doesn't come from a key press, for example an emoji keyboard or an IME."
[^6]: Chrome for Developers「[Background tabs in chrome 57](https://developer.chrome.com/blog/background_tabs)」：Chrome 对后台标签页的页面运行做节流；「[Heavy throttling of chained JS timers beginning in Chrome 88](https://developer.chrome.com/blog/timer-throttling-in-chrome-88)」（Jake Archibald）：Chrome 88 起对后台页链式 timer 重节流。
