# Changelog

本项目遵循语义化版本管理。`1.0.0` 前，patch 版本用于向后兼容的新增、可见性提升和 Bug 修复；minor 版本用于有架构意义的节点、行为变更或新的对外模型。`1.0.0` 后，新增公开 API 按标准语义化版本管理进入 minor 版本。

## 0.4.0 — 2026-09-21

### Changed（行为变更）

- **按钮描边退役，新增 `Emphasis.medium`（50% 中底档）**：四档 emphasis 统一为
  **底色深浅梯度**——`filled` 100% 实心 → `medium` 50% 色底 → `soft` 12% 浅底 →
  `plain` 无底。medium 文字用 `textPrimary`（同色字在 50% 彩底上对比度不达 WCAG）。
- **`Emphasis.outline` 废弃**：保留为废弃别名，渲染与 `medium` 完全一致；已用
  `emphasis: .outline` 的源码照常编译（仅废弃告警），视觉随包升级自动切换。
- **`Role.secondary` 视觉跟随**：别名从 `outline + accent` 改指 `medium + accent`，
  调用方源码零改动，取消/工具键由"白底描边"变"主题色 50% 中底"。
- `CaseIterable` 合成无法处理废弃 case，`Emphasis.allCases` 改为手动实现
  （含全部 5 个 case，outline 排最后）；Catalog 矩阵页 outline 行标注废弃。
- **需要随包重新目视的调用方**：VideoHero 44 处已迁移按钮（P2/B1–B7）中所有
  `role: .secondary` / `soft + neutral` 调用点视觉改变。

### Fixed

- **`EDSButton` 不再被容器压缩变形**：标签补 `.lineLimit(1)` + `.fixedSize(horizontal: true, vertical: false)`，
  按钮宽度永远由内容决定。此前标签 `Text` 默认可换行——父容器（HStack 等）横向空间不足时
  文字被压成多行，按钮纵向鼓胀（实例：VideoHero 场景卡「设置选中文字音色」窄窗口下折成三行）。
  修复后空间不足时整颗按钮保持胶囊形状，宁可溢出不折行。

### Changed（工具链）

- `Scripts/check-api-compatibility.sh` 的判据由 **mangled name** 换成**符号路径**（symbolgraph 的
  `pathComponents` 拼接，形如 `EDSButton.init(_:role:systemImage:action:)`）。
  mangled name 会把**外部模块名**编进去（`7SwiftUI18LocalizedStringKeyV`、`7SwiftUI4ViewRz`），
  而 Apple 在 Xcode 16 → 27 之间把 SwiftUI 拆出了 SwiftUICore，同一个 commit 在两台机器上
  会算出不同的 identifier。实测 CI（Swift 6.1.2 / Xcode 16.4）因此误报 3 条 `EDSButton`
  符号被删除，而那 3 个符号的代码一行未动。
- 基线文件随之重建为路径口径（451 条，含 medium 新符号）。跨模块扩展符号（本模块对 SwiftUI 类型所做
  extension 的成员）带 `@` 前缀，其**缺失降级为告警**而不判失败：这批符号的产出数量受
  Apple 模块拆分影响（同一 commit 本机 17 条、CI 15 条），计入失败等于把"Apple 调整了
  模块组织"变成红灯。真正的删除仍会出现在日志与 annotation 里。
- 新增 `--update-baseline` 选项，用于显式重建基线。
- `Scripts/check-api-compatibility.sh` 新增**崩溃自证**：`EXIT` trap 捕获任何非 0 退出
  （包括被 signal 打断），把"死在哪个阶段 + 之前的输出 + 工具链版本"写进 `::error::`；
  启动时先发一条 `::notice::` 心跳。所有外部命令调用都显式兜底，不再让 `set -o pipefail`
  把某个命令的 signal 退出码传播成脚本自身的失败。
  起因：一次 CI 上脚本以 **exit 134（SIGABRT）** 结束且没有留下任何 annotation，
  唯一的线索是"相比上一版只多了一处 `xcodebuild -version` 调用"。
- `Scripts/check-api-compatibility.sh` 在 GitHub Actions 下把诊断结论写入 **annotation**。
  本仓库的 job 日志接口需要 admin 权限（`/actions/jobs/{id}/logs` 返回 403），公开可读的
  只有 annotations —— 此前 CI 失败只能看到一句 `Process completed with exit code 1`，
  拿不到任何有用信息。现在失败时会带上"哪几条符号消失了"与工具链版本，成功时也会发一条
  `notice` 记录 core / external 计数。

## 0.3.1

### Added

- `EDSButton` 新增两个 `String` 标题初始化（预设角色版与三维原语版）。此前标题参数只接受
  `LocalizedStringKey`，自带本地化函数（返回 `String`）的 App 只能退回 `label:` 闭包写法。
  现在 `EDSButton(L("button.cancel"), role: .secondary) {}` 可直接编译。`String` 与
  `LocalizedStringKey` 重载并存安全：字面量调用稳定命中后者，不产生歧义。
- `EDSColorTokens` 新增派生色 `primarySoft`（`primary` 的 12% 透明版本）。包内"主题色浅底"
  统一改读它。

### Changed

- **行为变更 · 主题色收敛为单一来源 `primary`。**
  这是对既有缺陷的修复：包内对"主题色"的读取此前是**分裂**的——浅底档按钮的**底色**读
  `accentSoft`（→ `accent`），**文字**读 `primary`；`EDSSidebarItemButton` 选中态与
  `EDSEasyDesign` 的全局 `.tint()` 也读 `accent`。后果是 App 只设置 `primary` 时，浅底档
  按钮渲染成"12% 蓝底 + 橙字"，侧边栏选中项与全局 tint 停留在蓝色。
  0.3.1 起以下读取点全部改为 `primary`：
  - `EDSColorTokens.accentSoft` → 等价于 `primarySoft`（不再跟随 `accent`）
  - `EDSSidebarItemButton` 的选中底色与选中字色
  - `EDSEasyDesign` 的全局 `.tint()`
  - 按钮浅底档（`emphasis: .soft`）在 `tone: .accent` 下的底色
- `Scripts/check-api-compatibility.sh` 加固两处：
  - 对非本模块符号做前缀归一化（`s:<len><外部模块名>` → `s:EXTERNAL_`）。跨模块扩展符号的
    标识符首段是被扩展类型所属的外部模块，Xcode 16.4 → 27 之间 SwiftUI 拆出 SwiftUICore
    会改变该前缀——业务代码一字未改却被判"公开 API 被删"，是此前 CI 与本地结论不一致的根源。
    归一化后其余部分仍严格比对。
  - 基线缺失/符号图未生成时明确报根因（附 symbolgraph 清单），不再把整份基线误报成"已删除"。
- `Scripts/run-ui-tests.sh` 去掉 `-quiet`：此前失败时 CI 日志只剩一句 `Failing tests:`，
  连审计报的问题描述都看不到，无从定位。
- `Examples/PlatformCatalog/UITests/EDSPlatformCatalogUITests.swift` 的无障碍审计改用带
  handler 的重载，把问题类型与**出问题的元素**一起打印（`EDS_A11Y_AUDIT_ISSUE | …`）。

### Deprecated

- `EDSColorTokens.accent`：**包内不再读取，写它不会有任何效果。** 保留字段仅为兼容既有主题
  JSON 与 `init(primary:accent:…)` 调用方，删除会造成 API 断裂。**要变更主题色请改 `primary`。**
- `EDSColorTokens.accentSoft`：保留为 `primarySoft` 的别名，新代码请用 `primarySoft`。

### Fixed

- 修复 `EDSThemeBar`（Examples 主题预览栏）导致 iPhone 侧 UI 测试
  `testAdaptiveCatalogPassesSystemAccessibilityAudit` 确定性失败的问题（`2c554e04` 之后的 CI 红灯）：
  - 栏内文字由 `typography.captionStrong` / `monoCaption` 改用 `edsFont(...)`。前者返回
    `.system(size:)` 固定字号，**不参与 Dynamic Type 缩放**，会被 `.dynamicType` 审计判为
    "Dynamic Type font sizes are unsupported"。
  - 栏内不再使用 `ViewThatFits`。实测只要内容被包进 `ViewThatFits`，栏内**每一个** Text
    （包括完全不加字号修饰的裸 `Text`）都会被判 "partially unsupported"；换成普通
    `HStack` / `VStack` 后同样内容 0 问题。属审计误判，与字体无关。
  - 移除 `entry.detail` 详情行（`monoCaption` + `lineLimit(1)` 稳定被判 `Text clipped`）。
    主题名 Picker 与语义色色块已足够表达当前主题。
  - iPad 组审计项不含 `.dynamicType`，所以此前"iPhone 必挂、iPad 通过"。

### Compatibility

- 无破坏性变更，无公开符号被移除（`accent` 字段与四个旧 `ButtonStyle` 均保留）。
- 使用 `applyPreset(_:)` 或内置预设的 App：**零视觉变化**。三个预设的 `primary` 与 `accent`
  本来同值（`#3185FF` / `#FF6B00` / `#8B5CF6`），收敛读取点不改变它们的外观。
- 只设置 `primary` 的 App：蓝色残留被修正为跟随 `primary`，属缺陷修复。
- ⚠️ 只设置 `accent` 的 App：**该改动会静默失效**，需把赋值改到 `primary`。

### Docs

- 新增 `docs/20260921CI失败排查与修复.md`：CI 历史对照、根因对照实验、复现命令与
  `-only-testing` 三段式陷阱。
- 新增 `docs/20260921EDS0.3.1修复方案与开发计划.md`。

## 0.3.0

### Added

- `EDSButton` 新增 `Emphasis`、`Tone`、`Size` 三个正交维度：外观由视觉分量、语义色调、尺寸档位三者自由组合决定，此前一维 `Role` 无法表达的组合（如"次要但危险"、"纯文字"、"成功语义"、"小尺寸工具栏"）现已可用。
- 新增 `EDSButtonAppearance` 值对象与 `EDSButton.Role.appearance` 别名表，供上层以三维组合自封装预设。
- `EDSButton.Role` 新增 `.done`：实心成功色底 + 自适应正文色 + `checkmark` 图标，用于表达"已完成 / 点击查看"。
- `EDSButton.Role` / `Emphasis` / `Tone` / `Size` 均实现 `CaseIterable`、`Hashable`、`Sendable`。
- 新增三维原语初始化 `EDSButton(_:emphasis:tone:size:systemImage:action:)`。`emphasis` 无默认值，用于与既有一维初始化在编译期区分。
- `EDSColorTokens` 新增派生色 `successSoft`、`warningSoft`、`dangerSoft`（各为该语义色的 12% 透明版本，与既有 `accentSoft` 对称）。
- `EDSButton.Size` 提供 `.small`（28pt）/ `.regular`（34pt，读取 `controlSize.buttonHeight`）/ `.large`（44pt）三档。

### Changed

- 按钮视觉实现收敛为单一 `EDSButtonVisualBody`，四个旧 `ButtonStyle` 改为转发，消除原有四份近似重复实现。
- `.default` 预设补齐此前缺失的语义色：`success` = `#27B15A`、`warning` = `#F9B135`、`danger` = `#E54444`，与 `.orange` / `.purple` 预设一致。**此前 `.default` 的语义色会落到动态系统色。此改动会使使用 `.default` 主题的 App 中语义色发生变化**（例如危险按钮的红色由系统红变为 `#E54444`）。
- 实心档文字色按背景亮度选取：`accent` / `danger` 保持历史值 `.white`；`success` / `warning` 因白字对比度不足（约 2.8:1 / 1.9:1）改用自适应正文色。

### Compatibility

- 无破坏性变更。既有 `EDSButton(role:)`、`EDSButton(_:role:systemImage:action:)`、`EDSButton(action:label:)` 三个初始化签名与行为保持不变；四个旧 `ButtonStyle` 类型保留。
- 公开 API 兼容性检查通过（无任何公开符号被移除）。
- `.regular` 档复用 `controlSize.buttonHeight`，描边宽度与内边距沿用历史值，因此现有按钮的尺寸与描边视觉不变。

### Docs

- 新增 `docs/20260920按钮组件技术方案设计.md`、`docs/20260920按钮组件开发计划.md`。
- 新增 `Examples/Catalog/EDSButtonShowcase.swift`，展示三维组合矩阵、尺寸档位、`.done` 与 `EDSBadge` 的可点击性对照、别名等价性；Gallery 新增对应分组。

## 0.2.1

### Added

- 公开 `EDSInteractionProfile.resolved`，供上层读取按平台解析后的交互档案。
- 公开 `EDSResolvedMetrics`、`resolve(tokens:profile:horizontalSizeClass:)` 和 `interactiveHeight(for:)`，供上层复用自适应度量。
- 公开 `EDSFontRole` 和 `View.edsFont(_:tokens:)`，并新增跟随当前主题的 `View.edsFont(_:)`。

### Docs

- 说明 pointer 档案的 `minimumInteractiveDimension` 为零，行高应通过 `interactiveHeight(for:)` 计算。

### Fixed

- 将 Swift tools 最低版本从误设的 6.3 调整为 6.1，使包与 GitHub Actions `macos-15` 工具链及 Swift 6.1 宿主兼容。
- 兼容 Swift 6.1 符号图工具对 SwiftPM 临时测试模块的已知失败，确保公开 API 检查只验证主库符号图。

## 0.2.0

### Added

- 支持 iOS 17、iPadOS 17、macOS 14 和 Mac Catalyst 17。
- 新增 Touch、Pointer、Hybrid 自动交互档案及局部覆盖 API。
- 新增自适应页面边距、可读内容宽度和最小触控目标 Token。
- 新增真实多平台 Catalog 宿主工程和四平台构建检查脚本。
- 新增旧主题 Fixture、跨平台 Recipe 测试和公开 API 兼容检查。
- `EDSMultilineSubtitleRow` 新增跨平台 SwiftUI `Image` 初始化方式。

### Changed

- Page、PageStack、按钮、设置行和 Pill 根据平台能力与宽度自动调整。
- Pill 删除入口在 Touch/Hybrid 环境持续可见，并增加选择和删除无障碍语义。
- Token 编辑器在原生 macOS 使用 `NSColorWell`，在 iOS/iPadOS/Catalyst 使用 SwiftUI `ColorPicker`。
- 动态系统颜色导出为 JSON 时统一按浅色外观解析为静态 RGB。

### Compatibility

- 保留现有 Easy API、精细组件 API、预设主题 ID 和原生 macOS `NSImage` 初始化方法。
- 旧版完整和部分主题 JSON 缺少新增字段时使用兼容默认值。
