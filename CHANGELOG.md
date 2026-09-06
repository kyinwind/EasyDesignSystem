# Changelog

本项目遵循语义化版本管理。首个多平台版本目标为 `0.2.0`；正式打 Tag 前，修改继续记录在 `Unreleased`。

## Unreleased

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
