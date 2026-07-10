---
title: "从 Warp 到 Kitty：一个输入法卡顿引发的迁移"
slug: from-warp-to-kitty
date: 2026-07-10T07:00:00+08:00
draft: false
description: "在 Warp + OpenCode 下中文输入法几乎没法用，换到 Kitty 后问题消失了。顺便聊几个 GPU 终端的性能对比。"
tags: ["终端", "kitty", "warp", "ghostty", "iterm2", "opencode", "工具链"]
categories: ["技术折腾"]
toc: true
cover:
  image: "cover.png"
  alt: "水彩风格：一个输入法图标在 Warp 前被卡住，移动到 Kitty 后流畅通过"
---

> 每天在终端里跑 OpenCode，终端就是我的 IDE。但当连打字都成问题的时候，换就成了唯一的选择。

事情的起点是一个很具体的问题：**中文输入法卡顿**。

在 Warp 里跑 OpenCode，输入中文几乎没法用。每打三五个字，系统就假死几秒，输入无反应，恢复时还会吞掉个别字符。一开始我以为是 OpenCode 跑任务时系统资源不够，但观察下来发现其他 app 里输入完全正常。

这就排除了系统和输入法本身的问题。问题出在 Warp 和 OpenCode 的搭配上。

---

## 排查过程

我的排查路径很简单：

1. 在 Warp 中启动 OpenCode，打开中文输入法 → **严重卡顿，几乎不能用**
2. 在 Warp 中启动 OpenCode，只打英文 → **也卡，只是没中文那么严重**
3. 在 macOS 自带 Terminal.app 中启动 OpenCode，打中文 → **正常**

问题出在 Warp：**Warp 本身就不稳**，中文输入法和 OpenCode 只是把问题放大了。

我没兴趣深挖 root cause，不管是 Warp 的 block-based 渲染管线对 IME 事件的处理有问题，还是它的 GPU 合成层和中文输入法有冲突。总之它不好用，而我的日常工作离不开这个组合。

## 转向 Kitty

Warp 是 2024 年刚发布不久就装了，中文输入法卡顿的问题一直没解决。想起更早之前装过 Kitty（0.24 版左右，2022 年初），同期还试过 Ghostty 和 Alacritty，用了一段时间后删了。Kitty 还躺在那里，打开试了一下：**0.24 版就没问题**。于是顺手升级到最新版[^4]：

```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
```

然后打开 Kitty，在它里面启动 OpenCode，打开中文输入法。

**一切正常。** 丝滑，快速，没有卡顿，没有吞字，没有任何异常。

效果远超预期。我愣了一下。困扰了我好几周的问题，就这么无声无息地解决了。不需要配置或调优，也不用搞什么 workaround。换一个终端就好了。

那一刻的感觉很复杂。一方面是如释重负：终于可以正常工作了。另一方面是困惑：为什么 Warp 做不到？

我当时还不知道 Kitty 在性能上的具体数据，直观感受是又快又稳定。

![水彩调试矩阵：从上到下依次是冻结红色的Warp、迟缓黄色的排查过程、流畅绿色的Kitty](debug-matrix.png)

## 既然换了，顺便看看性能数据

换完之后我查了一下 Kitty 的官方性能文档和第三方评测，发现它的性能确实有数据支撑：

### Kitty 官方自测（Linux/X11 环境）

Kitty 内置了 `kitten __benchmark__` 工具来测量吞吐量，以下是官方数据[^1]（数值越高越好，单位 MB/s）：

| 终端 | 总体吞吐量 |
|------|-----------|
| **Kitty 0.33** | **134.55** |
| GNOME Terminal 3.50.1 | 61.83 |
| Alacritty 0.13.1 | 54.05 |
| WezTerm 20230712 | 48.50 |
| Konsole 23.08.04 | 27.48 |
| Alacritty + tmux | 24.73 |

Kitty 的吞吐量是第二名 GNOME Terminal 的 **两倍以上**。这组数据是在 Linux/X11 下测的，macOS 下的 iTerm2 没有包含在内。但 Kitty 在 macOS 上同样使用 OpenGL/Metal 渲染，性能特性类似。

Kitty 官方引用了第三方的键盘到屏幕延迟测试：

- 第三方测量在各种系统上的比较显示，Kitty 拥有 **同类最佳（best in class）** 的键盘到屏幕延迟
- 在 macOS 上，硬件测量显示 **Kitty 和 Apple 的 Terminal.app 并列第一**
- 在 Linux 上，Typometer 测量显示 **Kitty 的延迟远超其他测试终端**

### 第三方评测（macOS，2026）

[DevToolReviews](https://www.devtoolreviews.com/) 在 M3 Max MacBook Pro 上做了一组横向对比[^2]：

| 基准 | Ghostty | Kitty | Alacritty | Warp | iTerm2 |
|------|---------|-------|-----------|------|--------|
| 100K 行输出 | 0.7s | 0.8s | 0.9s | 1.8s | 2.4s |
| 1M 行输出 | 5.1s | 5.8s | 6.2s | 14.2s | 22.1s |
| 输入延迟 | ~2ms | ~3ms | ~3ms | ~8ms | ~12ms |
| 空闲内存 (1 tab) | 28MB | 35MB | 22MB | 210MB | 85MB |
| 8 tabs 4小时后 | 95MB | 110MB | 45MB | 380MB | 290MB |

对比中能看到几组差异：

- **吞吐量（cat 大文件）**：Ghostty 和 Kitty 几乎持平，Alacritty 紧随其后。Warp 慢了约一倍，iTerm2 慢了约三倍。
- **输入延迟**：Ghostty 2ms、Kitty 3ms，都在感知阈值以下，体感无区别。Warp 的 8ms 对于快速打字能感觉到，iTerm2 的 12ms 就明显了。我遇到的中文输入法卡顿比这个数字要严重得多，是几秒的假死，远不止几毫秒的延迟。
- **内存占用**：Warp 的空闲内存是 Kitty 的 **6 倍**，是 Ghostty 的 **7.5 倍**。考虑到我每天开 5-6 个标签页各跑一个 OpenCode session，这个差距对应几百 MB 的实际差异。
- **纯吞吐量（Kitty 官方 Linux 测试）**：Kitty 134.55 MB/s vs Alacritty 54.05 MB/s

Kitty 的官方 Linux 测试和第三方 macOS 测试排名不同，因为测试维度不一样：
- Kitty 官方测试的是**纯解析吞吐量**（parser throughput，不渲染），使用 SIMD 向量指令并行解析转义序列，这是 Kitty 0.33 加入的"猎豹速度"优化。在这个维度 Kitty 优势明显。
- 第三方测试是**端到端渲染**（cat 文件到屏幕），这里面 GPU 渲染管线是瓶颈，而 Ghostty 的自定义 Metal 渲染引擎在这方面做了大量优化。

大量转义序列处理的场景（比如 OpenCode TUI 的频繁局部刷新），Kitty 的 parser 优势明显。快速翻看大文件输出的场景，Ghostty 略快一点。两者差距很小，体感都很快。

![性能对比图：五款终端在渲染速度和内存占用两个维度的对比柱状图](benchmark-visual.png)

---

## 实际配置

迁移到 Kitty 后，我主要做了两件事：把界面清干净，再配了 session 保存和加载的快捷键。

### 界面清理

顶部保留 tab 栏用于切换 session，其余所有空间全部留给 OpenCode：

```bash
# kitty.conf 配置
font_family      Iosevka Fixed Slab
font_size        15.0

# 隐藏不必要的 UI 元素
hide_window_decorations titlebar-only
tab_bar_style      powerline
tab_bar_edge       top

# 性能相关
input_delay        3
sync_to_monitor    no
```

### Session 配置

用 Kitty 的 session 功能配了一个工作区，电脑重启后一键还原：

```bash
# ~/.config/kitty/sessions/daily_work.kitty-session
new_tab
cd ~/Projects/vibe-quant
launch omo

new_tab
cd ~/Projects/blog
launch omo

new_tab
cd ~/Develop
launch omo

new_tab
cd ~/Projects/daily-stats
launch

focus_tab 2
```

### 快捷键

映射了两个快捷键来保存和加载 session：

```bash
# kitty.conf
map ctrl+cmd+s save_session ~/.config/kitty/sessions/last_session.kitty-session
map ctrl+cmd+shift+s load_session ~/.config/kitty/sessions/last_session.kitty-session
```

每个标签页在自己的目录里启动 OpenCode，互不干扰。Warp 没有 session 功能，每次重启都要手动恢复，这也是一个小摩擦点。

我甚至没有调整过 Kitty 的 layout 和解绑默认快捷键。默认配置对我已经足够：我需要的就是一个稳定的"宿主"来运行 OpenCode。Kitty 恰好就是那个宿主。

## 关于其他选择

还有其他几个 GPU 加速渲染的终端，四五年前也都用过，不过最后我只留了 Kitty 和 iTerm2，这次又顺便看了看它们的近况，最后还是选择了 Kitty。

**Ghostty** 性能领先，输入延迟最低（~2ms），内存最小（28MB 空闲），冷启动最快（68ms）。Hashicorp 创始人 Mitchell Hashimoto 的作品。我对 Hashicorp 有亲切感，以前还做过它周边的开发，但 Ghostty 在 2022 年试用过之后就删掉了，留下了 Kitty。以后合适的时候再试试。

**Alacritty** 内存最小（22MB 空闲），极简主义风格。但它的 Shift+Enter 等组合键在 AI 终端里经常无法正确识别[^3]，这不是 Alacritty 独有的问题，各家终端对 Kitty 键盘协议的支持程度不同，大多数都需要手动配 escape sequence。

**iTerm2** 功能全面的老牌终端，也有 Metal GPU 渲染。但性能数据摆在那里：22.1 秒处理 1M 行输出，12ms 输入延迟，8 个标签页持续运行后内存达到 290MB[^2]，每一项都排在这组末位。

Kitty 对我来说是那个"刚刚好"的选择。

---

## Warp 和 Kitty 的哲学分野

Warp 和 Kitty 是两种不同的设计哲学：

Warp 的哲学是：终端应该被重新设计，加 AI、加协作、加云同步、加团队功能。它是一顿饭，前菜、主菜、甜点、咖啡都给你端上来。

Kitty 的哲学是：终端应该高效、可靠、可扩展，剩下的让工具自己做。它是一个好锅，你用它能做出什么菜取决于你自己。

选择取决于你的工作模式适合哪种哲学。

如果工作流里跑的是**自己的命令**（敲 git、docker、ssh、npm），Warp 的 AI 补全和块输出确实能提升效率。

但如果工作流像我一样，**终端里跑的是一个 AI 代理，由它处理所有 CLI 交互**，那么终端自身的 AI 能力就是冗余的。需要的只是一个稳定、轻量、渲染优良的"宿主"。

Kitty 是那个宿主。

![工具 vs 平台对比图：左侧工具阵营（Kitty, Alacritty）轻量专注，右侧平台阵营（Warp）功能膨胀](tool-vs-platform.png)

## 当工具变成平台

Warp 从一个终端模拟器，变成了一个"agentic development environment"。这个转变对它的商业模式也许是必要的，但对一个只需要终端的人来说，换来的是不断的膨胀、分心和摩擦。

Kitty 做了相反的事：十年如一日地做好终端本身。它只专注终端模拟这件事，不搞平台锁定，也不追风口加无关功能。它的竞争力来自 GPU 加速渲染、键盘协议、图形协议和 extensibility，让用户自己决定怎么用。

切换终端是一件小事。但换完之后，我少了一个需要操心的工具。那感觉很好。

---

## 结语

这次迁移的起点就是一个很具体的问题：中文输入法卡顿。尝试了一个 n 年前装过的终端，发现它能解决问题，效果还远超预期。

还有一个意料之中的发现：Warp 的增值功能变得**完全用不上**了。在 OpenCode 里工作，所有的 CLI 交互都由 AI 代理完成，我不再需要 Warp 的智能补全、AI 命令搜索、错误解释。终端回归到了它的本职：渲染 TUI 应用的输出和接收键盘输入。

换完之后，我少了一个需要操心的工具。不需要登录或调优，也不用关注更新公告。它就在那里，安静地把 OpenCode 渲染好，然后让我打字。

对于每天在终端里工作的人来说，这种"不存在感"可能就是工具能提供的最舒服的体验。

---

## 参考

1. [Kitty 官方性能文档 — 吞吐量和延迟基准](https://sw.kovidgoyal.net/kitty/performance/)
2. [DevToolReviews — 2026 最佳终端模拟器](https://www.devtoolreviews.com/reviews/best-terminal-emulators-2026)
3. [OpenCode 官方文档 — Keybinds / Shift+Enter](https://opencode.ai/docs/keybinds/#shiftenter)
4. [Kitty 官方安装文档 — Binary install](https://sw.kovidgoyal.net/kitty/binary/)
