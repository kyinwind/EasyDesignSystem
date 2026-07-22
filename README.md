# EasyDesignSystem

EasyDesignSystem 是一套面向 macOS SwiftUI 应用的设计系统。它希望让普通页面用尽可能少的样式代码获得整齐、统一、可适应浅色与深色模式的界面，同时为特殊页面保留完整的精细控制能力。

- macOS 14+
- Swift 6
- SwiftUI
- API 前缀：`EDS`

## 1. 设计理念

### 调用方描述“这是什么”

业务代码更适合表达页面结构和业务语义，而不是重复声明颜色、padding、圆角和阴影。

```swift
VStack {
    // 业务内容
}
.easyDesign(.card)
```

调用方只说明这是一张 Card，EasyDesignSystem 负责将它映射为卡片的内边距、语义背景、圆角、边框和阴影。

### 易用 API 与精细 API 并行

EasyDesignSystem 提供两层 API：

| API | 适合场景 | 调用方负责 | EasyDesignSystem 负责 |
| --- | --- | --- | --- |
| Easy API | 大多数普通页面 | 声明 Page、Section、Group、Card 等语义 | 整体色彩、宽度、padding 和表面层级 |
| 精细 API | 特殊布局、定制页面、底层组件 | 选择组件、Token 和具体参数 | 提供一致的 Token、组件和渲染原语 |

两层 API 不互相排斥。一个页面可以用 Easy API 管理整体层级，内部继续使用 `EDSButton`、`EDSBadge`、`EDSSettingRow` 等业务语义组件。

### 最佳实践不等于“所有地方都填色”

Page、Content、Section 和 Plain 默认继承宿主背景，让系统外观和原有容器层级自然生效。Group 和 Card 只在需要表达内容分组或独立层级时绘制自适应语义表面。

### Easy API 只作用于组合容器

Easy API 不定义 `.button` 或 `.text` 这类叶子样式。按钮的确定、次要、危险等含义仍由调用方显式提供：

```swift
EDSButton("确定", role: .primary) {
    confirm()
}

EDSButton("删除", role: .danger) {
    delete()
}
```

## 2. 安装

在 Xcode 中选择 **File > Add Package Dependencies**，输入：

```text
https://github.com/kyinwind/EasyDesignSystem.git
```

或在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(
        url: "https://github.com/kyinwind/EasyDesignSystem.git",
        branch: "main"
    )
]
```

然后在 target 中依赖 `EasyDesignSystem` product，并在 Swift 文件中导入：

```swift
import EasyDesignSystem
```

## 3. 使用向导

如果你只想快速开始，完成下面两个步骤就可以使用 EasyDesignSystem。后续章节都是更详细的规则、定制能力和组件参考，可以需要时再阅读。

### 步骤一：在 App 初始化时配置主题

首先导入 EasyDesignSystem，然后在 App 的 `init` 中完成一次全局配置：

```swift
import SwiftUI
import EasyDesignSystem

@main
struct MyApp: App {
    init() {
        EDSTheme.shared.configure { tokens in
            tokens.colors.primary = .blue
            tokens.colors.accent = .blue
        }
    }

    var body: some Scene {
        WindowGroup {
            SettingsView()
        }
    }
}
```

如果不想手动配置 Token，也可以直接选择预设主题：

```swift
init() {
    EDSTheme.shared.applyPreset(.orange)
}
```

配置应在 App 启动时完成。V1 暂不需要为运行时动态换肤准备额外状态。

### 步骤二：用 Easy API 编写页面

编写页面时，只需要记住这个常用层级：

```text
Page
└── Section
    ├── Group
    │   └── Row / Toggle / Button
    └── Card
        └── 业务内容
```

- Page 是页面根内容，使用 `.easyDesign()`。
- Section 是页面中的一个信息区块，使用 `.easyDesign(.section)`。
- Group 把同一功能的内容组织在一起，使用 `.easyDesign(.group)`。
- Card 用于需要独立视觉层级的内容，使用 `.easyDesign(.card)`。

下面是一个可直接参考的完整设置页：

```swift
import SwiftUI
import EasyDesignSystem

struct SettingsView: View {
    @State private var automaticUpdates = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                EDSPageTitle("设置", subtitle: "管理应用偏好")

                VStack(alignment: .leading) {
                    EDSSectionTitle("通用")

                    VStack(alignment: .leading) {
                        EDSSettingRow(
                            "自动更新",
                            subtitle: "定期检查是否有新版本。"
                        ) {
                            EDSToggle(
                                isOn: $automaticUpdates,
                                label: "启用"
                            )
                        }
                    }
                    .easyDesign(.group)

                    VStack(alignment: .leading) {
                        EDSSectionTitle(
                            "专业版",
                            subtitle: "解锁更多高级功能。"
                        )

                        HStack {
                            EDSBadge("推荐", style: .accent)
                            Spacer()
                            EDSButton("立即升级", role: .primary) {
                                purchase()
                            }
                        }
                    }
                    .easyDesign(.card)
                }
                .easyDesign(.section)
            }
            .easyDesign()
        }
    }

    private func purchase() {
        // 执行业务操作
    }
}
```

这个页面中：

- `.easyDesign()` 自动应用页面 padding、居中的最大宽度、主题前景色和 tint。
- `.section` 建立页面区块的垂直节奏。
- `.group` 自动应用轻量语义背景、padding 和圆角。
- `.card` 自动应用卡片背景、padding、圆角、边框和阴影。
- `EDSButton(role:)` 和 `EDSBadge(style:)` 仍由业务代码指定“主要操作”或“强调状态”等语义。

> Easy API 不会自动添加 `ScrollView`、导航和页面标题，因为这些属于页面结构，应由调用方决定。

到这里就已经完成了 EasyDesignSystem 的基本接入。需要更多场景、局部覆盖、主题或精细组件时，再继续阅读后面的章节。

## 4. Easy API

### 最小用法

`.easyDesign()` 默认等价于 `.easyDesign(.page)`：

```swift
struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("设置")

            VStack(alignment: .leading) {
                Text("自动更新")
                EDSToggle(isOn: .constant(true), label: "启用")
            }
            .easyDesign(.group)
        }
        .easyDesign()
    }
}
```

Page 会应用主题环境、tint、默认文本样式、页面 padding 和居中的最大内容宽度。

> `.easyDesign(.page)` 是样式修饰器，不会隐式添加 `ScrollView`、导航或页面标题。需要完整页面骨架时可以使用后文的 `EDSPage`。

### 六种语义场景

| 场景 | 用途 | 默认行为 |
| --- | --- | --- |
| `.page` | 普通页面根内容 | 页面 padding、最大宽度 880、居中、继承背景 |
| `.content` | 已位于导航或滚动容器内的内容 | 轻量 padding、填满可用宽度、继承背景 |
| `.section` | 页面中的信息区块 | 垂直节奏、填满可用宽度、继承背景 |
| `.group` | 同一功能的内容集合 | 分组 padding、subtle 语义表面、圆角、无阴影 |
| `.card` | 需要独立视觉层级的内容 | 卡片 padding、语义表面、圆角、边框和阴影 |
| `.plain` | 只希望子树跟随主题 | 仅应用主题、tint 和文本样式，不改变几何尺寸 |

一个常规页面的层级通常是：

```text
Page
└── Section
    ├── Group
    │   └── Row / Toggle / Button
    └── Card
        └── 业务内容
```

### Page、Section、Group 和 Card

```swift
ScrollView {
    VStack(alignment: .leading) {
        EDSPageTitle("设置", subtitle: "管理应用偏好")

        VStack(alignment: .leading) {
            EDSSectionTitle("通用")

            VStack(alignment: .leading) {
                EDSSettingRow("自动更新") {
                    EDSToggle(isOn: $isEnabled, label: "启用")
                }
            }
            .easyDesign(.group)

            VStack(alignment: .leading) {
                Text("专业版功能")
                EDSButton("升级", role: .primary) {
                    purchase()
                }
            }
            .easyDesign(.card)
        }
        .easyDesign(.section)
    }
    .easyDesign()
}
```

### 局部覆盖

Easy API 只开放少量高频覆盖，避免将易用入口重新扩张成另一套 Token API：

```swift
ContentView()
    .easyDesign(
        .page,
        options: .init(
            padding: .xl,
            maxContentWidth: .fixed(960),
            background: .visible
        )
    )
```

#### Padding

```swift
padding: .automatic  // 使用场景的默认配方
padding: .none       // 明确取消 padding
padding: .xl         // 使用当前主题 spacing.xl
```

可用语义间距为 `.xxs`、`.xs`、`.sm`、`.md`、`.lg`、`.xl`、`.xxl` 和 `.xxxl`。

#### 内容宽度

```swift
maxContentWidth: .automatic
maxContentWidth: .fixed(960)
maxContentWidth: .unlimited
```

#### 背景策略

```swift
background: .automatic
background: .visible
background: .hidden
```

`.automatic` 使用场景配方。`.visible` 要求绘制对应的语义表面，`.hidden` 要求继承父容器背景。

### 嵌套 Easy API

每次显式调用都会生效：

```swift
VStack {
    DetailView()
        .easyDesign(.card)
}
.easyDesign(.page)
```

系统不会猜测或去重调用方的语义。常规页面保持 Page -> Section -> Group/Card 两到四层即可。

## 5. 主题

### 全局主题

建议在 App 初始化阶段完成全局配置：

```swift
@main
struct MyApp: App {
    init() {
        EDSTheme.shared.configure { tokens in
            tokens.colors.primary = .blue
            tokens.colors.accent = .blue
            tokens.spacing.lg = 22
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

也可以使用内置预设：

```swift
EDSTheme.shared.applyPreset(.orange)
```

当前提供 `.default`、`.blue`、`.orange` 和 `.purple`，其中 `.blue` 是 `.default` 的别名。

### 局部主题

局部主题通过 SwiftUI Environment 传递值类型 `EDSDesignTokens`，不会修改 `EDSTheme.shared`：

```swift
PurchaseCard()
    .easyDesign(.card, theme: .orange)
```

也可以直接传入 Token：

```swift
var customTokens = EDSDesignTokens()
customTokens.colors.primary = .purple

PurchaseCard()
    .easyDesign(.card, tokens: customTokens)
```

如果只希望传递主题，不应用任何 Easy 布局或表面：

```swift
ContentView()
    .easyDesignTheme(.purple)

ContentView()
    .easyDesignTheme(customTokens)
```

### 在自定义 View 中读取主题

需要跟随局部主题时，从 Environment 读取：

```swift
struct CustomPanel: View {
    @Environment(\.edsTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            // ...
        }
        .foregroundStyle(theme.colors.textPrimary)
    }
}
```

只关心全局主题时，仍可以使用简单的直接读取：

```swift
EDSTheme.shared.spacing.md
EDSTheme.shared.colors.primary
```

V1 要求在 App 启动阶段配置全局主题，暂不承诺运行时修改 `EDSTheme.shared` 后自动刷新已显示的视图。

## 6. 精细 API

当页面需要完整骨架、特殊布局或具体参数时，使用精细 API。

### 完整页面骨架

`EDSPage` 负责页面标题、可选滚动、内容限宽、padding 和 Section 节奏：

```swift
EDSPage("设置", subtitle: "管理应用偏好") {
    EDSPageSection("通用") {
        EDSGroup {
            EDSSettingRow("自动更新", subtitle: "启动后检查新版本。") {
                EDSToggle(isOn: $isEnabled, label: "启用")
            }
        }
    }
}
```

`EDSPage` 默认不显式绘制背景，让宿主窗口的语义背景自然跟随浅色与深色模式。

已经处于自定义 `ScrollView` 或导航容器时，可以只使用 `EDSPageStack`。

### 容器

```swift
// 默认 EDSGroup：浅色分组背景、padding 和圆角
EDSGroup("通用", subtitle: "常用偏好") {
    content
}

// 默认 EDSCard：只提供 padding，不绘制背景
EDSCard {
    content
}

// 需要时显式提供背景
EDSCard(background: EDSTheme.shared.colors.cardBackground) {
    content
}
```

精细组件的默认行为不强制等于 Easy Recipe。例如 Easy `.card` 会提供完整卡片表面，而精细 `EDSCard` 默认是轻量 padding 容器。

### 按钮、徽章与开关

```swift
HStack {
    EDSButton("主要操作", role: .primary) {}
    EDSButton("次要操作", role: .secondary) {}
    EDSButton("轻量操作", role: .soft) {}
    EDSButton("危险操作", role: .danger) {}
}

HStack {
    EDSBadge("Pro", style: .accent)
    EDSBadge("已完成", style: .success)
    EDSBadge("待处理", style: .warning)
    EDSBadge("失败", style: .danger)
}

EDSToggle(isOn: $isEnabled, label: "启用自动处理")
```

### 文本与行

```swift
EDSPageTitle("设置", subtitle: "管理应用偏好")
EDSSectionTitle("通用", subtitle: "基础设置")
EDSLabelText("输出路径")
EDSCaptionText("修改后会影响新文件。")
EDSMonoText("/Users/name/Documents/Exports")

EDSSettingRow("图片格式", subtitle: "批量处理的默认格式。") {
    EDSBadge("PNG", style: .accent)
}

EDSValueRow("缓存占用", value: "240 MB")
```

### 状态与特殊组件

```swift
EDSEmptyState(
    systemImage: "tray",
    title: "暂无文件",
    message: "添加文件后会显示在这里。",
    actionTitle: "添加文件"
) {
    addFiles()
}

EDSErrorState(
    title: "加载失败",
    message: "请检查网络后重试。",
    actionTitle: "重试"
) {
    retry()
}

EDSLoadingState("正在处理", message: "这通常只需要几秒。")

EDSProgressPanel(
    "模型下载",
    subtitle: "Model.zip",
    fractionCompleted: progress,
    statusText: "正在下载..."
)
```

其他可用组件还包括：

- `EDSHeroPanel`：关键信息或付费权益强调面板。
- `EDSPill` / `EDSPillFlow`：标签和自动换行的标签集合。
- `EDSCollapsibleSection`：可折叠内容区。
- `EDSComparisonSection`：功能对比列表。
- `EDSSidebarGroupView`：设置页式侧边栏分组。

### 直接使用 Token

`EDSDesignTokens` 包含：

| Token | 用途 |
| --- | --- |
| `colors` | 主题色、强调色、成功/警告/危险色及派生语义色 |
| `spacing` | `xxs` 到 `xxxl` 的间距尺度 |
| `radius` | `sm` 到 `xl` 的圆角尺度 |
| `typography` | Hero、页面标题、Section、正文、Caption 和等宽字体 |
| `controlSize` | 按钮、输入框和行高 |
| `stroke` | 边框粗细 |
| `shadow` | 阴影颜色、透明度、半径和偏移 |
| `heroGradient` | Hero 面板渐变 |

```swift
struct FineGrainedPanel: View {
    @Environment(\.edsTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("自定义面板")
                .font(theme.typography.sectionTitle)

            Text("这里使用完整 Token 进行精细控制。")
                .foregroundStyle(theme.colors.textSecondary)
        }
        .padding(theme.spacing.xxxl)
        .background(theme.colors.cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: theme.radius.lg,
                style: .continuous
            )
        )
    }
}
```

### JSON 主题

可以从 App Bundle 加载 JSON：

```swift
try EDSTheme.shared.configure(jsonResource: "MyAppTheme")
```

从文件 URL 或 Data 加载：

```swift
try EDSTheme.shared.configure(jsonFileURL: url)
try EDSTheme.shared.configure(jsonData: data)
```

导出当前主题：

```swift
let data = try EDSTheme.shared.exportJSON()
let json = try EDSTheme.shared.exportJSONString()
```

## 7. Catalog 与 Preview

Package 提供 `EasyDesignSystemCatalog` library target，用于在 Xcode Canvas 中预览设计系统。三个预览界面的职责不同：

| 预览界面 | 用途 | 适合在什么时候使用 |
| --- | --- | --- |
| `EDSDesignSystemGallery` | 精细 API 效果和组件代码参考 | 查看页面骨架、按钮、状态、Row、Pill、Group 和 Card 的实际效果 |
| `EDSDesignSystemPreview` | Token 可视化编辑器 | 调整颜色、间距、圆角、字体、控件尺寸和 Hero 渐变，并导出 JSON |
| `EDSEasyAPIDesignSystemGallery` | Easy API 效果和最短调用参考 | 对照 Page、Content、Section、Group、Card、Plain、局部主题和嵌套场景 |

### EDSDesignSystemGallery

文件：[`Examples/Catalog/EDSDesignSystemGallery.swift`](Examples/Catalog/EDSDesignSystemGallery.swift)

这是精细 API Gallery。界面左侧是组件分类，右侧是对应的设置页式效果与代码摘要。如果需要查找某个 EDS 组件的推荐组合方式，优先查看这个 Gallery。

### EDSDesignSystemPreview

文件：[`Examples/Catalog/EDSDesignSystemPreview.swift`](Examples/Catalog/EDSDesignSystemPreview.swift)

这是主题 Token 编辑器：

- 左侧实时预览组件效果。
- 右侧调整颜色、间距、圆角、字体、控件尺寸和 Hero 渐变。
- 可以选择预设、重置、应用到 Runtime，或导出 `MyAppTheme.json`。

导出的 JSON 可以加入 App target，然后通过 `EDSTheme.shared.configure(jsonResource:)` 加载。

### EDSEasyAPIDesignSystemGallery

文件：[`Examples/Catalog/EDSEasyAPIDesignSystemGallery.swift`](Examples/Catalog/EDSEasyAPIDesignSystemGallery.swift)

这是 Easy API Gallery。它同样使用左侧栏 + 右侧详情的设置页结构，并且刻意不手写容器的 Token、背景、padding、圆角或阴影。如果想看“只描述场景语义”能够获得什么效果，优先查看这个 Gallery。

### 在 Xcode 中打开预览

1. 用 Xcode 打开 EasyDesignSystem Package。
2. 选择 `EasyDesignSystemCatalog` scheme。
3. 打开上述任意一个 Swift 文件。
4. 打开 Canvas，然后启动 `#Preview`。

建议在 macOS 浅色和深色外观下都检查 Gallery，特别关注 Page 的背景继承、Group/Card 的层级以及局部主题作用域。

## 8. 开发与验证

```bash
swift build
swift test
```

如果本机同时安装了 Command Line Tools 和 Xcode，请确保使用与当前 macOS SDK 匹配的 Swift 工具链。

## 9. License

See [`LICENSE`](LICENSE).
