# Changelog

本项目遵循语义化版本管理。`1.0.0` 前，patch 版本用于向后兼容的新增、可见性提升和 Bug 修复；minor 版本用于有架构意义的节点、行为变更或新的对外模型。`1.0.0` 后，新增公开 API 按标准语义化版本管理进入 minor 版本。

## Unreleased

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
