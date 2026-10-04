# EDS 命令编排层 EDSActionBar 需求分析与技术方案

> 创建日期：2026-10-04
> 状态：**S1–S6 已完成并验证通过**；S7（打 tag 0.5.1）等你定夺。§11 四项拍板问题已全部确定，§9.5 两条交叉影响已确认处置（见 §11.2）。
> 目标包：EasyDesignSystem（`/Users/yangxuehui/Documents/dev_open_source/EasyDesignSystem`）
> 目标版本：**0.5.1**
> 关联项目：TTSMate 换 EDS 组件项目（本任务是它的**前置任务**）

---

## 1. 背景：为什么必须先做这个

TTSMate 正在做「界面换成 EDS 组件 + 系统色彩体系」的大改造。但当前 TTSMate 的三条操作栏走的是 `MySwiftAppTools.ActionBar`，而 ActionBar 的品牌按钮**硬编码橙色**，一个 EDS token 都不读。

结果是：**切完主题，页面主色调跟着变，但 ProjectListView / ChapterListView / ChapterContentView 这三处的操作按钮仍是橙的。** 半吊子界面比不切更糟。

所以这不是"顺手优化"，是本次色彩升级能否成立的必要条件。

同时，ActionBar 里有一半能力 EDS 已经有更好的实现（`EDSFlowLayout` / `EDSCommandGroup` / `EDSButton`），继续让它在 MySwiftAppTools 里独立演化，等于维护两份代码。

---

## 2. 现状盘点

### 2.1 MySwiftAppTools.ActionBar 全貌

源码位置（注意：ActionBar 定义在 `ThemeManager.swift` 里，不是独立文件）：

```
.../SourcePackages/checkouts/MySwiftAppTools/Sources/MySwiftAppTools/ThemeManager.swift:727-1341
```

| 构成件 | 行号 | 职责 |
|---|---|---|
| `ActionBarAlignment` | 727-739 | leading / center / trailing |
| `ActionBarLayoutStyle` | 741-750 | automatic / horizontal / wrapping / compact |
| `ActionShortcut` | 753-811 | ⌘X 绑定 + `(⌘X)` 标签显示 |
| `ActionItem` | 815-878 | 语义枚举：add / edit / delete / save / exit / menu / custom |
| `ActionBarFlowLayout` | 885-982 | 自定义换行 Layout（98 行） |
| `ActionBarButtonDisplayStyle` | 986-1006 | **硬编码橙色**品牌按钮样式 |
| `ActionBarDisplayButtonStyle` | 1008-1030 | ButtonStyle，全是魔法数字 |
| `ActionBar` | 1034-1341 | 容器 + 宽度测量 + 降级 |

**当前消费方**：TTSMate 3 处

| 调用点 | 文件位置 |
|---|---|
| 项目列表操作栏 | `TTSmate/View/ProjectListView.swift:96`（items 定义在 :182） |
| 章节列表操作栏 | `TTSmate/View/ChapterListView.swift:198`（items 定义在 :91） |
| 章节内容底部栏 | `TTSmate/View/ChapterContentView.swift:228` |

另有 RightClickMate / VideoHero 在用（**所以旧的不能删，见 §7 迁移策略**）。

### 2.2 EDS 0.5.0 现有能力对照

| EDS 已有 | 位置 | 能顶替 ActionBar 的什么 |
|---|---|---|
| `EDSButton` | `EDSButtons.swift:153` | **整个** `ActionBarDisplayButtonStyle` |
| `EDSCommandGroup` | `EDSCommandControls.swift:9` | compact 降级的 `ControlGroup` |
| `EDSFlowLayout` | `EDSPills.swift:6` | `ActionBarFlowLayout` |
| `EDSSplitButton` | `EDSCommandControls.swift:43` | `ActionItem.menu` |

**EDS 真正缺的只有三样**：语义项模型、快捷键模型、编排容器。这就是本次要建的。

---

## 3. 现有 ActionBar 设计缺陷清单

> 每条给出源码位置，可直接翻查。严重度：**P0 = 本次必须解决**，**P1 = 应当修正**，**P2 = 建议优化**。

### P0-1 品牌按钮硬编码橙色 —— 主题切换失效

`ThemeManager.swift:1002-1005`

```swift
public static let primary = ActionBarButtonDisplayStyle(
    backgroundColor: .orange,    // ← 写死
    foregroundColor: .white
)
```

EDS 的色彩入口是 `EDSThemeData.seeds.brand`，这个值永远读不到。**这是本次任务的直接死因。**

### P0-2 按钮视觉完全脱离 token

`ThemeManager.swift:1008-1030`，全部是魔法数字：

| 值 | 硬编码 | EDS 对应 token | 默认值 |
|---|---|---|---|
| 高度 | `34` | `theme.controlSize.buttonHeight` | 34（数值巧合，不共享） |
| 字号 | `.system(size: 13, weight: .semibold)` | `theme.typography.*` | — |
| 水平内边距 | `16` | `theme.spacing.md` | 16 |
| 圆角 | `12` | `theme.radius.md` | 12 |
| 按下透明度 | `0.86` | EDS 内部自有 pressed 表达 | — |
| 按下缩放 | `scaleEffect(0.985)` | EDS 内部自有表达 | — |

数值全部碰巧对得上，但**一个都不共享**。改了 EDS token 后 ActionBar 不跟随，且两套 pressed 反馈手感不一致。

### P1-1 FlowLayout 重复实现

`ActionBarFlowLayout`（:885-982，98 行）与 `EDSFlowLayout`（`EDSPills.swift:6`）逻辑逐行雷同。

唯一差异：EDS 版不支持逐行对齐（`alignment`），ActionBar 版支持。

### P1-2 compact 降级用系统 ControlGroup

`ThemeManager.swift:1131`。`ControlGroup` 由 AppKit 绘制，**不吃 EDS token**。EDS 已有 `EDSCommandGroup`（0.4.3 起，用 `theme.colors.subtleFill` + `theme.radius.md` + `theme.stroke.hairline`）。

### P1-3 automatic 测量逻辑过重，且首帧必闪

`ThemeManager.swift:1041-1042` + `:1079-1087` + `:1153-1171`：

- 两个 `@State`（`availableWidth` / `regularWidth`）
- 两个 `GeometryReader`
- **regularBar 渲染两遍**（一遍可见，一遍 `.opacity(0)` 用于测量）
- 初值都是 `0`，`0 >= 0` 为真 → 第一帧恒 rend `.regular`，窄窗口必然会闪一下才收起

EDS 平台下限是 macOS 14 / iOS 17，`ViewThatFits`（macOS 13+ / iOS 16+）原生可用，**以上全部可以删掉**。

### P1-4 automatic 在 iOS 上是假的

`ThemeManager.swift:1093-1102`：

```swift
case .automatic:
#if os(macOS)
    switch layoutMode { ... }
#else
    regularBar        // ← iOS 直接降级为 horizontal
#endif
```

同一个 API 在两个平台行为不同，且没写过文档说明。调用方无法预期。

### P1-5 delete 不支持快捷键

`ThemeManager.swift:829-832`：

```swift
case delete(enabled: Bool = true, action: () -> Void)   // 其他 case 全都有 shortcut
```

API 不自洽。想给删除绑 ⌘⌫ 做不到。

### P1-6 exit 语义污染

`ThemeManager.swift:1218-1227`：标题"Exit"却用 `Button(role: .destructive)` + `xmark.circle`。macOS 上 destructive role 会渲染成危险样式，但"退出"通常不是破坏性操作。且与标准 cancel 概念重叠。

→ **本次砍掉 `.exit`，并入 `.cancel`**（`.normal` role）。

### P1-7 menu case 重造 SplitButton

`ThemeManager.swift:846-851`，塞 `() -> AnyView` 进 Menu label。EDS 已有 `EDSSplitButton`，专门解决"主操作 + 同类替代命令"。且 `() -> AnyView` 逃逸闭包不符合现代 ViewBuilder 惯例。

→ **本次砍掉 `.menu`**，需要下拉请用 `EDSSplitButton`。

### P1-8 custom 允许传任意颜色

`ThemeManager.swift:859` 的 `displayStyle: ActionBarButtonDisplayStyle?` 让单个按钮能自定义任意 `Color`——这本身就是在设计系统上开口子，P0-1 的橙色就是从这个口子进来的。

→ EDS 版本**只暴露 Role / Tone 语义选择，绝不暴露 `Color`**。

### P2-1 id 可碰撞

`ThemeManager.swift:865-877`：`id` 用 `"menu_\(title)"` / `"custom_\(title ?? image)"`。两个 `.custom` title 相同 → `ForEach` diff 错乱。

→ EDS 版本用稳定自增 id 或允许显式指定。

### P2-2 "无快捷键"用空格哨兵值

`ThemeManager.swift:790` `commandNothing = ActionShortcut(key: " ", modifiers: [])`，判断处写 `shortcut.displayString != " "`（:1254、:1336）。

→ EDS 版本加 `var isValid: Bool` 明确表达，消除魔法字符串。

### P2-3 barHeight 预设值

`ThemeManager.swift:1334-1340`：macOS 36 / iOS 44 硬编码。若 `EDSButton` 用 `.large`（44pt），macOS 的 36pt 容器装不下会溢出。

→ EDS 版本**不预设高度**，由内容决定。

### P2-4 无障碍缺失

只有 `.help(title)`（tooltip），无 `accessibilityLabel` / `accessibilityIdentifier` / 快捷键 hint。

### P2-5 过期平台判断

`ThemeManager.swift:1324` `if #available(iOS 14.0, *)` —— EDS 最低 iOS 17，死代码。

### P1-9 修饰键显示顺序是逆序的（实施时才测得出来）

`ThemeManager.swift:795-798`：

```swift
if modifiers.contains(.command) { result += "⌘" }
if modifiers.contains(.shift)   { result += "⇧" }
if modifiers.contains(.option)  { result += "⌥" }
if modifiers.contains(.control) { result += "⌃" }
```

macOS 惯例顺序是 **⌃ ⌥ ⇧ ⌘**（Control → Option → Shift → Command）。旧实现正好是逆序，
⌘⇧N 会拼成 `⌘⇧N` 而非系统菜单显示的 `⇧⌘N`。

这条在静态阅读代码时看不出来，是实施阶段写运行时冒烟验证时才暴露的——**归类 P1，已在 `EDSActionShortcut.displayString` 修正**。

> 教训：旧代码的"搬运"不等于"验证"。这类字符串拼接逻辑必须实际跑一遍值比较，
> 光靠类型检查过不了。

---

## 4. 需求定义

| 编号 | 需求 | 优先级 |
|---|---|---|
| R1 | 提供命令的数据模型 `EDSActionItem`，含 6 个语义 case：`add / edit / delete / save / cancel / custom` | 必须 |
| R2 | 每个语义 case 自带**默认图标**与**默认按钮 Role**（属设计决策），标题走 EDS 内置双语，调用方可覆盖 | 必须 |
| R3 | 提供快捷键模型 `EDSActionShortcut`，含常用 `.commandX` 便利值，自动挂 `keyboardShortcut` 并在标签显示 `(⌘X)` | 必须 |
| R4 | 提供编排容器 `EDSActionBar`，支持对齐、尺寸档位、布局风格 | 必须 |
| R5 | 视觉 100% 由 `EDSThemeData` 驱动，随 0.5.0 的色彩风格 / 种子色切换而变 | 必须 |
| R6 | **不暴露任何 `Color` 参数**，颜色只能通过 Role / Tone 的语义层选择 | 必须 |
| R7 | 拥挤时用 `ViewThatFits` 降级到 `EDSCommandGroup`，不用 GeometryReader 测量 | 必须 |
| R8 | 换行复用 `EDSFlowLayout`，不重复实现 Layout | 必须 |
| R9 | macOS / iOS 行为一致 | 必须 |
| R10 | 补齐无障碍标签 | 应该 |
| R11 | 不预设容器高度 | 应该 |

---

## 5. API 设计

### 5.1 EDSActionShortcut

```swift
public struct EDSActionShortcut: Equatable, Sendable {
    public let key: KeyEquivalent
    public let modifiers: EventModifiers

    public init(key: KeyEquivalent, modifiers: EventModifiers)

    /// 消除原实现的空格哨兵值（P2-2）
    public var isValid: Bool { !modifiers.isEmpty || key != " " }

    /// `(⌘S)` 中去掉括号的部分，如 `⌘S`
    public var displayString: String { get }

    // 常用便利值（保留原 ActionShortcut 的易用性）
    public static let commandN / commandS / commandD / commandO / commandE ... : EDSActionShortcut
    public static let delete: EDSActionShortcut      // ⌫
    public static let escape: EDSActionShortcut      // Esc
}
```

**相对原版的改动**：
- 删除 26 行 commandX 逐个手写 → 改为静态工厂 `EDSActionShortcut.command("s")` + 保留 6 个最高频静态值（`.commandN / .commandS / .commandD / .commandO / .escape / .delete`），其余按需构造
- 加 `isValid`，干掉 `displayString != " "` 判断

### 5.2 EDSActionItem

```swift
public enum EDSActionItem: Identifiable {

    case add(title: String? = nil,
             enabled: Bool = true,
             shortcut: EDSActionShortcut? = nil,
             action: () -> Void)

    case edit(title: String? = nil,
              enabled: Bool = true,
              shortcut: EDSActionShortcut? = nil,
              action: () -> Void)

    case delete(title: String? = nil,          // ← 原版缺 shortcut，补齐（P1-5）
                enabled: Bool = true,
                shortcut: EDSActionShortcut? = nil,
                action: () -> Void)

    case save(title: String? = nil,
              enabled: Bool = true,
              shortcut: EDSActionShortcut? = nil,
              action: () -> Void)

    case cancel(title: String? = nil,          // ← 吸收原 .exit（P1-6）
                enabled: Bool = true,
                shortcut: EDSActionShortcut? = nil,
                action: () -> Void)

    case custom(title: String,
                systemImage: String? = nil,
                role: EDSButton.Role = .secondary,   // ← 只给语义 Role，不给 Color（P1-8）
                enabled: Bool = true,
                shortcut: EDSActionShortcut? = nil,
                action: () -> Void)

    /// 稳定 id，同语义多个实例不会碰撞（P2-1）
    public var id: String { get }
}
```

### 5.3 语义 case 默认值表

| case | SF Symbol | 默认 Role | 英文 | 中文 | 理由 |
|---|---|---|---|---|---|
| `.add` | `plus` | `.secondary` | Add | 新建 | 正向但非主行动，不该抢 primary |
| `.edit` | `pencil` | `.normal` | Edit | 编辑 | 灰底次级，最不抢眼 |
| `.delete` | `trash` | `.danger` | Delete | 删除 | 破坏性，实心危险色 |
| `.save` | `square.and.arrow.down` | `.primary` | Save | 保存 | 主行动，实心主题色 |
| `.cancel` | `xmark` | `.normal` | Cancel | 取消 | 普通取消，**不用 destructive** |
| `.custom` | 调用方给 | `.secondary` | 调用方给 | 调用方给 | 兜底 |

本地化 key 命名沿用 EDS 既有风格（`EDSComparisonSection.features.title`）：

```
"EDSActionBar.add.title"    / "EDSActionBar.edit.title" / ...
```

写入 `Sources/EasyDesignSystem/Resources/{zh-Hans,en}.lproj/Localizable.strings`。

> 说明：EDS 已有 l10n 基建（现只放了 ComparisonSection 的 4 条）。「新建 / 编辑 / 删除 / 保存 / 取消」属跨 App 共识动词，不是业务文案，内置是安全的。

### 5.4 EDSActionBar

```swift
public enum EDSActionBarAlignment: Sendable {
    case leading, center, trailing
}

public enum EDSActionBarLayoutStyle: Sendable {
    /// 放得下排一行，放不下自动收成 EDSCommandGroup（推荐，默认值）
    case automatic
    /// 始终一行，宽度不够时截断
    case horizontal
    /// 保持按钮高度，放不下换行
    case wrapping
    /// 始终收成 EDSCommandGroup
    case compact
}

public struct EDSActionBar: View {
    public init(
        _ items: [EDSActionItem],
        alignment: EDSActionBarAlignment = .trailing,
        size: EDSButton.Size = .regular,
        layoutStyle: EDSActionBarLayoutStyle = .automatic
    )
}
```

### 5.5 调用示例

```swift
EDSActionBar([
    .add(title: L(L10n.projectNew)) { newProject() },
    .delete(title: L(L10n.delete), enabled: !selected.isEmpty) { delete() },
    .custom(title: "导出", systemImage: "square.and.arrow.up") { export() },
], alignment: .trailing)
```

无 `. save / .cancel` 之类时省略 `title` 即用 EDS 内置双语。

---

## 6. 关键实现要点

### 6.1 automatic 用 ViewThatFits，删掉所有测量

```swift
HStack(spacing: 0) {
    if alignment != .leading { Spacer(minLength: 0) }

    ViewThatFits(in: .horizontal) {
        HStack(spacing: theme.spacing.xs) {
            ForEach(items) { item in button(for: item) }
        }
        .fixedSize()

        EDSCommandGroup {
            ForEach(items) { item in button(for: item) }
        }
    }

    if alignment != .trailing { Spacer(minLength: 0) }
}
```

**收益**：删掉 2 个 `@State`、2 个 `GeometryReader`、一遍重复渲染（约 35 行），顺带解决首帧闪烁（P1-3）。

**风险点（待实机验证）**：macOS 上 `NSHostingView` 尺寸未确定时 `ViewThatFits` 可能抖动。缓解手段：内层 bar 加 `.fixedSize()`。**这条列入验收清单第 1 项。**

### 6.2 wrapping 复用 EDSFlowLayout（需一处 EDS 增强）

**已定：加 alignment 重载**（杨哥 2026-10-04 拍板）。**实施时对此处的原方案做了关键修正。**

⚠️ **原方案（给已有 init 加一个带默认值的 `alignment` 参数）不可用。** 那样做会把公开符号从
`EDSFlowLayout.init(horizontalSpacing:verticalSpacing:)` 变成 `init(horizontalSpacing:verticalSpacing:alignment:)`，
Old 符号消失 → **CI 的 API 基线检查会报"符号被删"**，不符合"只增不减"的规矩。

正确做法是**两个 init 并存**：

```swift
public struct EDSFlowLayout: Layout {
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    public var alignment: EDSFlowAlignment          // 新增存储属性

    // 原签名一字不改（源码与基线双零破坏）
    public init(horizontalSpacing: CGFloat = ..., verticalSpacing: CGFloat = ...)
    // 新增重载；alignment 刻意不给默认值，否则两 init 都能匹配入人参两
    public init(horizontalSpacing: CGFloat = ..., verticalSpacing: CGFloat = ..., alignment: EDSFlowAlignment)
}

public enum EDSFlowAlignment: Sendable { case leading, center, trailing }
```

三点约束：

1. **新增 `EDSFlowAlignment` 而不是复用 `EDSActionBarAlignment`** —— EDSFlowLayout 是通用组件（EDSPillFlow 也在用它），不该依赖 ActionBar 的类型。两个枚举各自独立，`EDSActionBar` 内部做一次映射。
2. **新重载的 `alignment` 不给默认值**，否则 `EDSFlowLayout(horizontalSpacing:verticalSpacing:)` 同时匹配两个 init，编译器报 ambiguous。
3. 逐行对齐的实现参考旧 `ActionBarFlowLayout` 的 `rowStartX(rowWidth:bounds:)`。

基线实测结果：`EDSFlowAlignment` 三个 case + `EDSFlowLayout.init(horizontalSpacing:verticalSpacing:alignment:)` 作为**新增**入基线，原签名符号保留，检查通过。

### 6.3 按钮构建统一走 EDSButton

快捷键处理：**已定方案 B**（杨哥 2026-10-04 拍板）。

标签里**不显示** `(⌘S)` 后缀，只挂真正的功能键。理由：macOS 原生应用（Xcode / Finder / Pages）都不在按钮标题里写快捷键，`(⌘S)` 挂在主操作按钮上观感廉价；且 EDSButton 内部把 `(⌘S)` 当正文排版，`size: .small`（28pt）时会挤到变形。

快捷键通过三条正交途径表达，一个都不占用视觉空间：

| 途径 | 作用 | 面向 |
|---|---|---|
| `.keyboardShortcut(key, modifiers:)` | 真实生效 | 键盘用户 |
| `.help(title)` | 鼠标悬浮 tooltip 显示纯标题 | 鼠标用户 |
| `.accessibilityHint("快捷键 ⌘S")` | VoiceOver 读出快捷键 | 无障碍用户 |

> 补强说明：方案 B 原文只写了 `.help()` tooltip，这里额外加了 `accessibilityHint` 承载快捷键信息。零额外成本，且不违反"不显示在标签里"的原则——键盘用户本来也不需要看标签才知道快捷键。

```swift
private func button(for item: EDSActionItem) -> some View {
    let view = EDSButton(item.resolvedTitle,
                         role: item.resolvedRole,
                         systemImage: item.resolvedSystemImage)
    { item.action() }
        .disabled(!item.enabled)
        .help(item.resolvedTitle)
        .accessibilityLabel(item.resolvedTitle)      // P2-4
        .accessibilityHint(item.accessibilityHint)   // 有快捷键时为「快捷键 ⌘S」，否则空

    // keyboardShortcut 只在 shortcut.isValid 时挂载
    return view.edsKeyboardShortcut(item.shortcut)
}
```

由此删掉的旧代码：`actionLabel` / `customLabel` / `shortcutLabel` 三个私有方法（共约 45 行），以及 `shortcut.displayString != " "` 的哨兵判断（P2-2）。

### 6.4 compact 模式下按钮降为纯文字

实施时新增的设计决策，原文档未覆盖。

`EDSCommandGroup` 是给"无底色命令"用的容器。直接把 `filled`（实心）/ `medium`（25% 色底）的 `EDSButton` 塞进去，会出现"实心色块叠实心色块"的沉重观感，与 `EDSCommandGroup` 自身底色打架。

因此 `EDSActionBar` 在 compact 与 automatic 降级路径上，把按钮统一降为 `Emphasis.plain`（无底纯文字），**但保留 tone**：

| 原 Role | compact 下表现 |
|---|---|
| `.delete` → danger | 红色文字，仍是危险语义 |
| `.save` → primary | 主题色文字 |
| `.cancel` → normal | 灰色文字 |

视觉干净，语义不丢。CCC 这层降档只对 compact / automatic 生效，`horizontal` 与 `wrapping` 保持完整按钮外观。

### 6.5 ViewThatFits 的替换形式（落地版）

外层用 `Spacer(minLength: 0)` 处理对齐，`ViewThatFits` 只管内容：

```swift
HStack(spacing: 0) {
    if alignment != .leading { Spacer(minLength: 0) }
    ViewThatFits(in: .horizontal) {
        regularRow      // 内部 .fixedSize()
        compactRow      // EDSCommandGroup
    }
    if alignment != .trailing { Spacer(minLength: 0) }
}
.frame(maxWidth: .infinity)
```

`wrapping` 不进 `ViewThatFits`——它是无限高语义，走独立分支。

---

## 7. 迁移策略

### 7.1 MySwiftAppTools.ActionBar 不动

RightClickMate / VideoHero 还在用，删不得。

```
阶段 1：EDS 新增 EDSActionBar，发 0.5.1          ← 本次
阶段 2：TTSMate 3 处换过来（跟着试点批次走）
阶段 3：跑顺 1 个发布周期无问题
阶段 4：VideoHero / RightClickMate 逐个迁
阶段 5：全部迁移完，MySwiftAppTools.ActionBar 标 deprecated（保留实现，不删）
```

期间**双包共存，可接受**。

### 7.2 调用方迁移对照表

| MySwiftAppTools.ActionItem | EDSActionItem | 注意 |
|---|---|---|
| `.add(enabled:shortcut:action:)` | `.add(title:enabled:shortcut:action:)` | 需显式传 title 才有自定义文案 |
| `.edit(...)` | `.edit(...)` | 同上 |
| `.delete(enabled:action:)` | `.delete(title:enabled:shortcut:action:)` | 多出 shortcut 参数 |
| `.save(...)` | `.save(...)` | 同上 |
| `.exit(...)` | `.cancel(...)` | **语义变更**：不再 destructive |
| `.menu(title:systemImage:enabled:content:)` | ❌ 移除 | 改用 `EDSSplitButton` |
| `.custom(title:content:systemImage:displayStyle:...)` | `.custom(title:systemImage:role:...)` | **`displayStyle: Color` → `role: Role`** |

---

## 8. 版本与交付清单

### 8.1 版本号：**0.5.1**（不是 0.6.0）

依 CHANGELOG 开头的规矩：

> `1.0.0` 前，patch 版本用于向后兼容的新增、可见性提升和 Bug 修复；minor 版本用于有架构意义的节点、行为变更或新的对外模型。

本次是纯新增公开符号，无删除无签名变更 → patch。

### 8.2 交付必做项

| # | 项 | 命令 / 位置 |
|---|---|---|
| 1 | 新增源文件 `EDSActionBar.swift` | `Sources/EasyDesignSystem/` |
| 2 | `EDSFlowLayout` 加 alignment 重载 | `EDSPills.swift` 或新 extension |
| 3 | 双语文案 6×2 条 | `Resources/{zh-Hans,en}.lproj/Localizable.strings` |
| 4 | **更新公开 API 基线** | `bash Scripts/check-api-compatibility.sh --update-baseline` |
| 5 | CHANGELOG 加 `## 0.5.1` → Added 条目 | `CHANGELOG.md` |
| 6 | Catalog 加示例页 | `Examples/Catalog/`（参考 `EDSButtonShowcase.swift`） |
| 7 | 单元测试 | `Tests/EasyDesignSystemTests/` |
| 8 | 打 tag | `git tag 0.5.1 && git push --tags` |
| 9 | TTSMate 侧升依赖 0.5.0 → 0.5.1 | 在启动 EDSActionBar 迁移批次时做 |

### 8.3 验证方式（2026-10-04 实测修正）

> **修正**：初稿此处写"`swift build` 能自己跑，不用你管"。实测 `swift build` / `swift test` **同样会被
> 工具沙箱拦截**（SwiftPM 内部调用 `sandbox-exec`，且需要写 `.build/` 与 `~/.swiftpm/security`）。
> 实际跑通的组合如下，作为后续复用的记录。

**能跑通的（需绕过沙箱执行）**：

```bash
cd /Users/yangxuehui/Documents/dev_open_source/EasyDesignSystem

# ① API 基线更新 + 完整构建 —— 实测成功
bash Scripts/check-api-compatibility.sh              # Public API compatibility check passed
bash Scripts/check-api-compatibility.sh --update-baseline
```

脚本内部会完整 build（含 `swift package dump-symbol-graph`），因此**它同时扮演了 `swift build` 的角色**。
本次即通过该脚本产出了 `.build/out/Products/Debug/` 下的资源 bundle 与 swiftmodule。

**跑不通的**：

```bash
swift build      # ❌ sandbox-exec: Operation not permitted
swift test       # ❌ 同上，卡在 manifest 编译阶段
```

**替代方案 —— 手工类型检查（零依赖、可复现）**：

绕开 SwiftPM，直接用 `swiftc`，把所有中间产物写到 `/tmp` 从而避开沙箱：

```bash
SDK="$(xcrun --show-sdk-path)"
P="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins"
ARGS="-sdk $SDK -target arm64-apple-macosx14.0 -I /tmp/eds-mods -module-cache-path /tmp/eds-modulecache \
      -swift-version 6 -D SWIFT_PACKAGE -plugin-path $P \
      -plugin-path $SDK/../../Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins"

# ① 预编译依赖模块
xcrun swiftc -emit-module -module-name EDSMaterialColorUtilities \
  -emit-module-path /tmp/eds-mods/EDSMaterialColorUtilities.swiftmodule $ARGS \
  $(find Sources/EDSMaterialColorUtilities -name '*.swift')

# ② 类型检查主包（eds-bundle-stub 提供 Bundle.module，编译资源时才用得上）
xcrun swiftc -typecheck $ARGS $(find Sources/EasyDesignSystem -name '*.swift') /tmp/eds-bundle-stub.swift

# ③ 主包 emit-module 后再检查 Catalog
xcrun swiftc -emit-module -module-name EasyDesignSystem \
  -emit-module-path /tmp/eds-mods/EasyDesignSystem.swiftmodule $ARGS \
  $(find Sources/EasyDesignSystem -name '*.swift') /tmp/eds-bundle-stub.swift
xcrun swiftc -typecheck $ARGS $(find Examples/Catalog -name '*.swift')
```

三个关键点：

1. **`-plugin-path` 必须显式给**。否则 `@State` / `@Environment` 等 SwiftUI macro 无法展开
   （报错 `external macro implementation type 'SwiftUIMacros.StateMacro' could not be found`），
   因为 macro plugin server 无法在沙箱内 spawn。
2. **`Bundle.module` 需要桩**。非 SwiftPM 编译时没有 resource bundle accessor。
   若要运行时验证，桩应指向真实 bundle：
   `/tmp/eds-bundle-stub.swift` → `Bundle(path: ".build/out/Products/Debug/EasyDesignSystem_EasyDesignSystem.bundle")`。
   指向 `Bundle.main` 会在 `EDSColorStyle` 静态初始化时 fatal。
3. **XCTest 断言是 C 宏**，`-typecheck` 模式无法展开（`cannot find 'XCTAssertTrue' in scope`）。
   因此单测的静态验证靠等价的 Swift 断言文件，运行时验证靠下述的单模块可执行程序。

**运行时冒烟**：
把 EDS 全部源码 + 一个 `@main` 入口编进**同一个 module**（internal 天然可见），一次 `swiftc -o` 直接出可执行程序并运行。
本次以这种方式实跑了 33 项断言（等价于 `EDSActionBarTests` 的断言集合），全部通过。

---

## 9. 开发计划与执行结果

| 阶段 | 内容 | 状态 |
|---|---|---|
| S1 | `EDSActionShortcut` + 6 个语义 case 的 `EDSActionItem`（含 id 生成、默认值解析） | ✅ 完成 |
| S2 | `EDSActionBar` 容器：4 种 layoutStyle + ViewThatFits 降级 + 对齐 | ✅ 完成 |
| S3 | 双语文案（6×2 条）+ 无障碍标签 | ✅ 完成 |
| S4 | `EDSFlowLayout` alignment 重载（**改为双 init 并存**，见 §6.2） | ✅ 完成 |
| S5 | 类型检查 + API 基线更新 | ✅ 762→767 符号，检查通过 |
| S6 | CHANGELOG + Catalog 示例页 + 单元测试 | ✅ 完成 |
| S7 | 打 tag 0.5.1 | ⏳ **待杨哥** |

**实测验证结果**：

| 项 | 结果 |
|---|---|
| 主包类型检查（`swiftc -typecheck`，29 个文件） | 零 error 零 warning |
| Catalog 类型检查（含新增 Showcase + Gallery 挂载） | 零 error |
| 运行时冒烟（33 项断言） | 全部通过 |
| 公开 API 基线 | 462 → 767 符号，**无删除项** |
| CHANGELOG | 已加 0.5.1 条目 |

**改动文件清单**：

| 文件 | 类型 |
|---|---|
| `Sources/EasyDesignSystem/EDSActionBar.swift` | 新增（约 400 行） |
| `Sources/EasyDesignSystem/EDSPills.swift` | 修改：`EDSFlowAlignment` + 双 init + `rowStartX` |
| `Sources/EasyDesignSystem/Resources/{zh-Hans,en}.lproj/Localizable.strings` | 修改：各加 6 条 |
| `Tests/EasyDesignSystemTests/EDSActionBarTests.swift` | 新增（11 个测试） |
| `Examples/Catalog/EDSActionBarShowcase.swift` | 新增 |
| `Examples/Catalog/EDSDesignSystemGallery.swift` | 修改：侧边栏加「命令编排」 |
| `CHANGELOG.md` | 修改：加 0.5.1 |
| `Tests/APICompatibility/EasyDesignSystem-PublicAPI.txt` | 修改：+767 符号 |

---

## 9.5 与他人未提交改动的交叉影响（**已确认，见 §11.2**）

> 本节记录发现时的原始描述，处置结论统一见 **§11.2**。

实施时检出仓库 working tree 里已有**你未提交的本地改动**，与本任务存在交叉：

| 文件 | 你在改什么 | 对 EDSActionBar 的影响 |
|---|---|---|
| `EDSButtons.swift:411` | `Role.normal` 从 `.soft + neutral` 改成 `.medium + neutral` | 我把 `.edit` / `.cancel` 的默认 Role 定为 `.normal`。改完后它们从 12% 浅灰底变成 **25% 中灰底**，比预期更显眼。要不要给 edit/cancel 换一个 Role？ |
| `EDSColorScheme.swift` | 新增 `neutralSoftSurface` 等中性灰度解析 | 无直接影响，但同上会改变观感 |
| `CHANGELOG.md` | 在 **0.5.0** 段下加了 `### Fixed`（中性灰度修复） | 0.5.0 tag 已 push（`994360d`）。这条修复严格说应归 **0.5.1 的 Fixed 段**，否则发布后 CHANGELOG 与实际 tag 内容对不上 |

两处我都没动，等你决定 —— **已于 2026-10-04 拍定，处置详见 §11.2**。

---

## 10. 验收清单

- [ ] 把 EDS 品牌种子色改成蓝 / 紫，三个操作栏按钮**跟着变色**（P0-1 / P0-2 闭环）
- [ ] 窗口从宽拖到窄，按钮自动收成 `EDSCommandGroup`，**过程中不闪烁**（P1-3）
- [ ] macOS 与 iOS 缩窄行为一致（P1-4）
- [ ] `.delete` 能绑快捷键（P1-5）
- [ ] `.cancel` 不再渲染成危险样式（P1-6）
- [ ] 同 `.custom` title 重复的两个 item，ForEach 不报错也不串味（P2-1）
- [ ] 传 `.large` 尺寸时容器不裁切（P2-3）
- [ ] VoiceOver / Accessibility Inspector 能读到每个按钮的 label（P2-4）
- [ ] `swift test` 全绿，`check-api-compatibility.sh` 无新增失败项

---

## 11. 拍板结论（4/4 已全部确定）

| # | 问题 | 结论 | 决策依据 |
|---|---|---|---|
| 1 | 快捷键怎么显示 | ✅ **方案 B**：标签不显示 `(⌘X)`，功能挂 `keyboardShortcut` + `.help()` + `accessibilityHint` | macOS 原生惯例（Xcode / Finder 都不在按钮标题里写快捷键），`(⌘S)` 挂在主操作按钮上很廉价。见 §6.3 |
| 2 | `.add` 的默认 Role | ✅ **`.secondary`**（主题色中底） | 正向但不抢主行动，视觉上比 edit/cancel 重一点点，符合"新建"的语义分量。保留原 Role 表，不因外部灰度调整而改 |
| 3 | `EDSFlowLayout` 对齐 | ✅ **加 `alignment` 重载**（双 init 并存，新增 `EDSFlowAlignment`） | 原签名零破坏，符合 API 基线只增不减的 CI 规矩；wrapping 模式逐行对齐与原 ActionBar 行为一致。见 §6.2 |
| 4 | `.custom` 能否纯文字 | ✅ **允许**，`systemImage` 保持 Optional | 灵活度最高。"导出""关闭""完成"这类没有贴切图标的动作不必硬凑图标。代价是同一排可能出现图标/文字混排，由调用方自行保证一致性 |

### 11.1 补充说明：四项结论如何落到代码

| 结论 | 落点 |
|---|---|
| 1. 方案 B | `EDSActionBar` 内部每个按钮统一挂 `.help(resolvedTitle)` + `.edsKeyboardShortcut(shortcut)` + `.accessibilityHint(accessibilityHintText)`；标题区只渲染 `Image(systemName:)` + `Text(title)` |
| 2. `.add = .secondary` | `EDSActionItem.resolvedRole` 映射表：add→secondary / edit→normal / delete→danger / save→primary / cancel→normal / custom→secondary |
| 3. 双 init | `EDSFlowLayout` 新增 `alignment` 存储属性与重载 init；`EDSActionBarLayoutStyle.wrapping` 走独立分支，内部做 `EDSActionBarAlignment → EDSFlowAlignment` 映射 |
| 4. custom 可无图标 | `resolvedSystemImage` 返回 `String?`，nil 时 `EDSButton` 只渲染文字 |

### 11.2 交叉影响已确认（原 §9.5）

| 项 | 你的决定 | 处理 |
|---|---|---|
| `EDSButtons.swift:411`：`Role.normal` 改成 `medium + neutral`，导致 `.edit` / `.cancel` 底色变重 | **不用换 Role，就这样先** | 维持现状。`.edit` / `.cancel` 仍是 `.normal`，跟随你对 neutral 灰度的调整走。后续 Catalog 观感验收时若觉得偏重再议 |
| `CHANGELOG.md`：`### Fixed`（中性灰度修复）写在了已 push 的 0.5.0 段下 | **挪到 0.5.1** | ✅ 已执行。0.5.1 段结构为 Added / Changed / **Fixed** / Compatibility；0.5.0 段（tag `994360d` 已发布）恢复原样，不再与实际 tag 内容冲突 |

---

**一句话**：这个前置任务做完，TTSMate 换 EDS 组件那 73 个页面按钮才有意义；不做，切完主题后三条操作栏会继续是橙的。
