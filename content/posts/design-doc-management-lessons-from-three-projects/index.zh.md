---
title: "rebase 一敲，三天设计草稿灰飞烟灭——用 git worktree 拯救 AI 的设计文档"
slug: "design-doc-management-lessons-from-three-projects"
date: 2026-05-08T15:00:00+08:00
draft: false
description: 'AI 辅助开发产生大量设计文档，它们被 .gitignore 忽略、被 git rebase 静默删除、被 git reflog 永远无法恢复。本文介绍一种基于 git worktree 的轻量方案，用独立的本地分支保护设计文档，并以多个项目的实战数据做佐证。'
tags: ["AI", "设计文档", "git worktree", "AI辅助开发", "文档管理"]
categories: ["AI 实践"]
toc: true
cover:
  image: "cover.png"
  alt: "设计文档在 rebase 后灰飞烟灭，git worktree 分支为其提供安全庇护"
---

那天下午，我在一个项目里做了 `git rebase -i`，整理一下最近十几条提交的历史。操作很顺利，没有冲突，rebase 完成后终端干干净净。

然后我打开 `design_plan/` 目录，准备继续完善一份协议草稿。

空的。

三天的设计讨论——架构重构思路、五个备选方案的对比分析、三阶段流水线的论证过程——全部消失。不是被移到了别的地方，是被 git rebase 静默删除了。这些文件从来没有被 git 追踪过（它们在 `.gitignore` 里），所以 `git reflog` 找不到它们，`git fsck --lost-found` 也找不到它们。从来没有进入过 git 的对象数据库，就不存在"恢复"这回事。

这已经是同一个项目里第二次丢文档了。上一次是 `git checkout` 到另一个分支再切回来，结果一样——未追踪的文件没了。

两次之后，我终于认真对待这个问题了。

---

## 为什么 AI 辅助开发中，设计文档特别容易丢

传统开发中，设计文档通常写在 Confluence、Notion 或者某个共享文档平台。版本管理是平台的事，跟 git 没有关系。

AI 辅助开发不是这样。

用 OpenCode 或 Claude Code 做项目，AI 在每个 session 里会生成大量中间文档——产品设计、技术方案、测试方案、协议草稿、模块拆分计划。这些文档有两个特点：

**第一，它们不适合提交到项目仓库。** AI 生成的设计文档包含未完成的设计思路、被否决的方案、内部决策理由。提交到仓库会污染 commit 历史，也会暴露本应内部消化的讨论过程。所以它们被放在 `.gitignore` 里，比如 `design_plan/` 或 `docs/`。

**第二，它们需要在多个 session 之间复用。** AI 的上下文不跨 session 保留，但设计决策是持久的。一个 session 里讨论并确定的架构方案，下一个 session 里 AI 需要重新读取。这些文档是 AI 跨 session 的"记忆载体"。

这两个特点组合在一起，就形成了一个危险的处境：**设计文档是项目中最重要的知识资产，但它们恰恰处于 git 的保护范围之外。**

然后 git rebase 来了。

### git 对未追踪文件的无情

这不是 git 的 bug，是 git 的设计行为。rebase 重写历史时，会先切换到目标分支的树状态。未追踪的文件不在版本控制内，git 不认为它们需要保留。checkout 同理。

更关键的是恢复路径被完全堵死：

| 恢复手段 | 能恢复什么 | 对未追踪文件 |
|----------|-----------|-------------|
| `git reflog` | 被追踪过的 commit | **无效** |
| `git fsck --lost-found` | 悬空的 blob/tree/commit | **无效** |
| `git stash -u` | 未追踪文件 | **对 gitignored 的文件无效** |
| `git checkout HEAD -- .` | 工作区恢复到最近 commit | **只恢复被追踪的文件** |

注意第三行——`git stash -u` 也不会 stash 被 `.gitignore` 忽略的文件。很多人以为 stash 能救，其实不能。

**结论：从未被 git 追踪的文件，一旦删除，永久丢失。** 没有"回收站"，没有"撤销"，没有任何恢复手段。

---

## 方案对比：我试过和没试过的路

丢了两次文档之后，我系统地考虑了所有可选方案：

| 方案 | 思路 | 问题 |
|------|------|------|
| `git stash -u` | 操作前先 stash | **不会 stash gitignored 的文件**，设计文档被忽略所以无效 |
| 云同步 (iCloud/Dropbox) | 把 `design_plan/` 放到同步目录 | 多设备同步冲突、不利于命令行操作 |
| 单独的 git 仓库 | 给设计文档建一个独立 repo | 管理成本高，需要维护两套仓库的对应关系 |
| 符号链接到安全目录 | `design_plan/` → `/safe/dir/` | rebase 时符号链接本身可能被删除 |
| rsync 到 /tmp 或其他目录 | 操作前手动 rsync | 依赖人的记忆，忘了运行就等于没保护 |
| **Git Worktree** | 独立的本地分支追踪文档 | 零额外依赖，与 git 原生集成，分支隔离保证安全 |

Git Worktree 胜出的理由很简单：**它是 git 原生功能，不需要安装任何东西，不需要改变日常工作流，而且分支级别的隔离是结构性的安全保障——主分支的 rebase/checkout/reset 在物理上不可能影响另一个 worktree 里的文件。**

---

## 方案详解：design-doc-worktree

### 双 worktree 架构

```
project/                        # 主 worktree（main 分支，日常开发在这里）
├── .gitignore                  # 忽略 design_plan/
├── design_plan/                # 未追踪，日常编辑在此
└── scripts/dp-save.sh          # 同步脚本

<project>-local-assets/         # assets worktree（local-assets 分支）
└── design_plan/                # 被 git 追踪，永久存储
```

两个 worktree 共享同一个 `.git` 仓库（在物理上是同一组对象和引用），但 checkout 到不同的分支。主 worktree 在 `main` 上开发，assets worktree 在 `local-assets` 分支上存储设计文档。

**关键不变量：`local-assets` 分支永远不会推送到远程。** 这个分支只存在于本地，它的唯一目的是给设计文档提供一个被 git 追踪的安全空间。

### 工作原理

主 worktree 的 `design_plan/` 目录被 `.gitignore` 忽略，日常编辑不受任何影响。`dp-save.sh` 脚本把文件同步到 assets worktree，然后在 assets worktree 里执行 `git add` 和 `git commit`。

因为 assets worktree 是一个独立的 worktree，主 worktree 的任何操作——rebase、checkout、reset、clean——都不会影响它。这是 git worktree 的架构保证，不是约定。

### 日常使用：三条命令

**保存（默认加性同步）：**

```bash
./scripts/dp-save.sh "draft: new feature design"
```

加性的意思是：只往 assets worktree 里添加和更新文件，**不删除** assets worktree 中独有的文件。这保护了一个重要的工作流——有时候我直接在 assets worktree 里编辑文档（因为文件始终被追踪，编辑完直接 commit），加性同步不会意外删除这些文件。

**镜像清理：**

```bash
./scripts/dp-save.sh --prune "sync with main worktree"
```

加上 `--prune` 后，同步会删除 assets worktree 中存在但主 worktree 中不存在的文件，让两边完全一致。用于定期清理。

**恢复（rebase 后救命用）：**

```bash
./scripts/dp-save.sh --restore
```

从 assets worktree 把文件复制回主 worktree。这就是 rebase 导致文档丢失后的恢复手段——文件在 assets worktree 里是安全的，随时可以恢复。

### dp-save.sh 的核心逻辑

整个脚本只有 105 行，核心逻辑更短：

```bash
# 加性同步（默认）
rsync -a "$REPO_ROOT/$DOCS_DIR/" "$WORKTREE/$DOCS_DIR/"
git -C "$WORKTREE" add -f "$DOCS_DIR/"
git -C "$WORKTREE" commit -m "$MSG"

# 恢复（rebase 后）
rsync -a "$WORKTREE/$DOCS_DIR/" "$REPO_ROOT/$DOCS_DIR/"
```

几个设计决策值得说一下：

**为什么用 `rsync` 而不是 `cp`？** rsync 增量同步，只传输变化的文件，对于包含大量归档文档的目录效率更高。

**为什么默认加性？** 因为我在实际使用中发现，有时候直接在 assets worktree 里编辑文档更方便——文件始终被追踪，编辑完直接 commit 就行。如果同步时默认删除 assets worktree 中独有的文件，这个工作流就被破坏了。

**安全守卫。** 脚本在同步前会检测 assets worktree 中是否有未提交的变更。如果有，说明用户在 assets worktree 里做了编辑但还没 commit，直接同步会覆盖这些变更。脚本会报错退出，提醒用户先处理。`--force` 参数可以跳过这个检查，但需要显式使用。

---

## 归档约定

随着项目演进，设计文档会越来越多。在实践中自然演化出了这样的归档结构：

```
design_plan/
├── archive/
│   ├── 260420/          # YYMMDD 格式
│   ├── 260425/
│   └── 260503/
└── protocol_draft/      # 活跃草稿
```

活跃草稿直接放在 `protocol_draft/`（或根目录）。当一个设计阶段完成，把文档按日期移到 `archive/` 下。日期用六位数字（YYMMDD），简单且够用。

这个结构的好处是：AI 读取时可以只加载 `protocol_draft/`，不用加载整个归档历史。需要回顾旧方案时，按日期定位很快。

---

## 实战数据

我在几个项目中都踩过同样的坑。领域、复杂度、工具链各不相同，但在设计文档管理上的经历惊人地一致。

### 项目 A：痛得最早

700 多个 session 的项目，设计文档密度最高。引入 worktree 前经历了至少 2 次文档丢失——开头讲的那次是其中之一。

引入后，`local-assets` 分支的提交历史大致是这样演化的：

```
update design_plan 2026-05-03 22:41
clean: keep only design_plan/ and scripts/ in local-assets
archive: organize design_plan by creation date
tool: add dp-save.sh script for design_plan branch sync
local: track design_plan in local-assets branch (never push)
```

从底部往上看：先创建分支，再添加同步脚本，再整理归档结构，再清理分支内容只保留设计文档和脚本。这是一个自然演化的过程，不是一步到位的。

这个项目后来还加了第三个 worktree，专门追踪 undo 操作的历史。三个 worktree 共存，互不干扰——说明 worktree 方案的扩展性没问题。

### 项目 B：放在仓库外面，也能活，但不优雅

300 多个 session。这个项目走了另一条路——把设计文档放在代码仓库的上层目录：

```
workspace/
├── project/          # git 仓库
│   ├── .git/
│   └── src/
└── design_plan/      # 仓库外面，git 管不着
```

这样做确实避开了 rebase 的问题——rebase 只在仓库内部生效，外面的文件不受影响。但代价是**文档和代码的对应关系靠人的记忆维护**。哪个设计文档对应哪次重构？哪份技术方案是在哪个 commit 之后写的？git log 里查不到，只能靠目录里的日期和文件名推断。

用了一段时间后，我还是给它切到了 worktree 方案。不是"放外面"不行，是"放外面"的信息密度太低——git 仓库知道每一次代码变更的上下文，但不知道任何一次设计变更的上下文。worktree 至少让设计文档有了 commit 历史。

### 项目 C：从第一天就用上

不到 100 个 session，最轻量的项目。但它是唯一一个**从第一个 commit 就包含 worktree 配置的**。

因为前两个项目的教训已经内化。搭建项目的第一个 commit 就包含了 `dp-save.sh` 和 `.gitignore` 配置。结果：**文档丢失次数为零。**

### 数据汇总

| 项目 | Session 数 | 引入 Worktree 前文档丢失 | 引入 Worktree 后文档丢失 | Worktree 状态 |
|------|-----------|------------------------|------------------------|--------------|
| 项目 A | 700+ | 2 次 | 0 | 活跃使用（含第三个 undo worktree） |
| 项目 B | 300+ | 1 次 | 0 | 早期用上层目录，后迁移到 worktree |
| 项目 C | ~100 | 0（从一开始就用） | 0 | 活跃使用 |

三个数据点，一个结论：**worktree 一经引入，文档丢失归零。** 项目 B 的经历还说明，"放仓库外面"虽然能跑，但在信息关联性上远不如 worktree。

---

## 搭建指南：从零开始

如果你决定用这套方案，以下是完整的搭建步骤。

**第一步：创建 local-assets 分支和 worktree**

```bash
# 在项目根目录
git branch local-assets
git worktree add ../<project>-local-assets local-assets
```

**第二步：在主 worktree 的 `.gitignore` 里添加设计文档目录**

```
design_plan/
```

**第三步：创建 `scripts/dp-save.sh`**

105 行脚本，核心逻辑上面已经给出。完整脚本包括参数解析、安全守卫、`--prune`/`--restore`/`--force` 选项。

**第四步：日常使用**

```bash
# 编辑设计文档（主 worktree 里正常操作）
vim design_plan/protocol_draft/new-feature.md

# 保存到 worktree
./scripts/dp-save.sh "draft: new feature design"

# 如果要 rebase 主分支，rebase 前不特殊操作，rebase 后：
./scripts/dp-save.sh --restore
```

**关键提醒：** `local-assets` 分支不要推送。在 `.git/config` 或 CI 配置中确保这个分支永远不会被 push。

---

## 适用边界

最后说清楚这套方案适合什么、不适合什么。

**适合：** AI 辅助开发的中大型项目，设计文档需要跨 session 复用，团队使用 git 管理代码，频繁进行 rebase/checkout 操作。

**不适合小型脚本和一次性任务。** 几百行代码的脚本，设计文档可能只有几行注释，用 worktree 是过度工程化。

**不适合已经用云文档平台管理设计的团队。** 如果设计文档已经在 Confluence/Notion 上有版本管理，不需要再引入 worktree。

**不适合不用 git 的项目。** 这是废话，但根据防呆设计的理念，还是提一嘴——worktree 是 git 原生功能，前提是你用 git。

**核心判断标准：设计文档对你的项目有多重要？** 如果答案是"丢了会心痛"，那就值得花三分钟搭建 worktree。

---

一句话总结：**git 保护不了它不知道存在的文件。** 设计文档在 AI 辅助开发中是核心资产，把它们放在 git 的盲区里，等于把钱包放在没锁的车里。Git worktree 不是最优雅的方案，但它是最务实的——零依赖、十分钟搭建、结构性安全保障。引入后文档丢失归零的数据已经说明了一切。

我把这个方法做成了skill，放在了Github上： [alexwwang/design-doc-worktree](https://github.com/alexwwang/design-doc-worktree) ，只要在你的编程助手比如Claude Code 或者 Opencode 里安装，就可以轻松使用了。
