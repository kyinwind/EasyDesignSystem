# 平台自适应

理解统一 API 如何保持各平台一致性和原生交互体验。

## 交互档案

EasyDesignSystem 默认自动解析：

- iPhone 和 iPad 使用 ``EDSInteractionProfile/touch``。
- 原生 macOS 使用 ``EDSInteractionProfile/pointer``。
- Mac Catalyst 使用 ``EDSInteractionProfile/hybrid``。

Touch 与 Hybrid 保证最小触控目标；Pointer 保留桌面端紧凑视觉尺寸；Pointer 与 Hybrid 支持 Hover 增强。

测试或特殊硬件场景可局部覆盖：

```swift
PreviewPage()
    .easyDesignInteractionProfile(.hybrid)
```

## 自适应 Token

通过 ``EDSAdaptiveLayoutTokens`` 统一调整紧凑/常规页面边距、可读内容宽度与最小交互尺寸：

```swift
EDSTheme.shared.configure { tokens in
    tokens.adaptiveLayout.compactPagePadding = 20
    tokens.adaptiveLayout.regularPagePadding = 36
    tokens.adaptiveLayout.readableContentMaxWidth = 960
}
```

显式传给 Easy API 的 padding 和 maxWidth 始终优先。所有 EDS 字体角色会跟随 Dynamic Type；支持删除的 Pill 在触控环境持续显示删除入口，在指针环境保留 Hover 增强。
