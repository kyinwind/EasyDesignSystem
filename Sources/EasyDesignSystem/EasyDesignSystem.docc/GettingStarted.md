# 快速开始

使用默认主题和 Easy API 构建第一个共享页面。

## 配置主题

在 App 启动、UI 建立前配置一次全局主题：

```swift
import SwiftUI
import EasyDesignSystem

@main
struct MyApp: App {
    init() {
        EDSTheme.shared.applyPreset(.default)
    }

    var body: some Scene {
        WindowGroup {
            AccountPage()
        }
    }
}
```

## 构建页面

以下代码无需平台条件编译，可同时用于四个平台：

```swift
struct AccountPage: View {
    var body: some View {
        EDSPage("账户", subtitle: "管理账户设置") {
            EDSPageSection("通用") {
                EDSSettingRow("自动同步") {
                    EDSToggle(isOn: .constant(true), label: "启用")
                }
                .easyDesign(.group)
            }
        }
    }
}
```

使用 ``EDSPage`` 可获得完整页面骨架；已有滚动或导航容器时，也可以对自己的组合容器调用 `.easyDesign(.page)`。
