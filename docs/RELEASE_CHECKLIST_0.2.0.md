# EasyDesignSystem 0.2.0 发布清单

## API 与兼容性

- [x] 公共 API Symbol Graph 未删除既有符号。
- [x] README 旧示例可编译。
- [x] 原生 macOS `NSImage` 旧入口可编译。
- [x] 旧版完整与部分主题 JSON 可读取。
- [x] 新主题 JSON 可 round-trip。

## 构建与测试

- [x] SwiftPM build/test 通过（16 项测试）。
- [x] iPhone Simulator 构建与完整 UI 测试通过。
- [x] iPad Simulator 构建、分屏、横竖屏与完整 UI 测试通过。
- [x] 原生 macOS 构建通过；窗口、鼠标和键盘 UI 测试曾通过。
- [x] Mac Catalyst 构建通过。
- [ ] Mac Catalyst 鼠标和键盘最终人工验收。

## 辅助功能与视觉

- [x] Dynamic Type 最大辅助字号通过。
- [x] VoiceOver 核心名称和系统辅助功能审计通过。
- [x] Increase Contrast 环境验证通过。
- [x] Differentiate Without Color 环境验证通过。
- [x] Reduce Motion 环境验证通过。
- [x] 深色模式和长文本通过。
- [ ] 与 0.1.0 macOS Catalog 截图完成最终对照。

## 集成与发布

- [x] 功课助手主 Target 完成最小依赖接入和 iOS／Mac Catalyst 构建。
- [ ] 确认提交中不包含无关修改。
- [ ] 将 `Unreleased` 更新为 `0.2.0` 与发布日期。
- [ ] 创建发布提交。
- [ ] 创建并验证 `0.2.0` Git Tag。
- [ ] 功课助手由本地包切换到固定版本或固定提交。
