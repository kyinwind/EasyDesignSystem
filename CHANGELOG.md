# Changelog

本项目遵循语义化版本管理。`1.0.0` 前，patch 版本用于向后兼容的新增、可见性提升和 Bug 修复；minor 版本用于有架构意义的节点、行为变更或新的对外模型。`1.0.0` 后，新增公开 API 按标准语义化版本管理进入 minor 版本。

## Unreleased

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
