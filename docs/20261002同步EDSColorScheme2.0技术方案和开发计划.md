# EasyDesignSystem 同步 EDS ColorScheme 2.0 技术方案与开发计划

日期：2026-10-02  
状态：方案草案，尚未实施  
建议目标版本：`0.5.0`（颜色体系 Breaking Release）  
参考实现：`/Users/yangxuehui/Documents/dev_open_source/easy_design_system` Flutter `0.4.x`

## 1. 结论

Flutter 版这次升级的核心价值不是增加更多颜色字段，而是把颜色职责拆成稳定的解析链：

```text
Theme Configuration
  ├─ Chromatic Seeds
  ├─ Light/Dark Semantic Overrides
  └─ Non-color Design Tokens
          ↓
Perceptual Tonal Palettes
          ↓
Resolved Semantic Color Scheme
          ↓
Layer / Interaction Resolver
          ↓
Component Color Recipe
```

Swift 版当前仍是：

```text
EDSDesignTokens.colors
          ↓
组件直接读取 primary / success / background / border
          ↓
组件自行拼 opacity、深浅和交互态
```

建议同步 Flutter 版的设计原则和公开心智模型，但按 SwiftUI 环境系统重新实现，不机械翻译 Dart 代码。最终应达到：

- Host 通常只配置 Brand Seed；Information / Success / Warning / Danger 保持独立语义。
- Light/Dark、前景/背景、边框、禁用态、交互态由 EDS 统一解析。
- 组件只声明“语义家族 + 强调程度 + 所在 Layer”，不自行发明颜色。
- 标准组件不开放任意单实例颜色覆盖；需要完全自定义视觉时使用原生 SwiftUI 组件。
- 非颜色 Token 体系保持稳定，ColorScheme 2.0 只重构颜色子系统。

该改造合理且值得做，但属于架构变化，不适合继续塞进 `0.4.x` patch。当前项目仍处于 `0.x`，建议使用 `0.5.0` 明确承载迁移成本。

## 2. 当前 Swift 实现盘点

### 2.1 当前颜色模型

`Sources/EasyDesignSystem/EDSDesignTokens.swift` 中的 `EDSColorTokens` 同时承担了三类职责：

1. 配置入口：`primary / accent / success / warning / danger`。
2. 派生颜色：`primarySoft / successSoft / warningSoft / dangerSoft`。
3. 运行时语义颜色：`textPrimary / pageBackground / cardBackground / border` 等。

这些职责的生命周期不同，却被放在同一个 `Codable` 类型中。当前具体问题包括：

- Seed 与最终语义色混合。
- `primary / accent` 历史上语义重复，`accent` 已实际退役但仍留在模型中。
- Soft 色依赖固定透明度，背景变化后视觉强度和对比度不稳定。
- Light/Dark 主要依赖 SwiftUI 系统动态色，无法对各语义家族独立校准。
- Button、Sidebar、Surface、State、Text 等组件直接读取 `theme.colors`，每个组件自行决定映射。
- Hover / Press / Focus / Selected / Disabled 没有统一解析入口。
- Card / Group / Field 不理解自己所在的 Surface Layer。

### 2.2 当前主题模型

当前 `EDSTheme` 和 `EnvironmentValues.edsTheme` 的核心值都是 `EDSDesignTokens`。这使“完整主题配置”和“非颜色设计 Token”成为同一个对象。

ColorScheme 2.0 需要区分：

- 可持久化的主题配置。
- 非颜色 Token。
- 当前 Light/Dark 下解析完成的运行时主题。
- 当前组件所在的 Layer Context。

### 2.3 当前影响范围

直接使用 `theme.colors` 或 `tokens.colors` 的主要文件包括：

- `Sources/EasyDesignSystem/EDSButtons.swift`
- `Sources/EasyDesignSystem/EDSCommandControls.swift`
- `Sources/EasyDesignSystem/EDSComparisonSection.swift`
- `Sources/EasyDesignSystem/EDSEasyDesign.swift`
- `Sources/EasyDesignSystem/EDSLayouts.swift`
- `Sources/EasyDesignSystem/EDSRows.swift`
- `Sources/EasyDesignSystem/EDSStates.swift`
- `Sources/EasyDesignSystem/EDSSurfaces.swift`
- `Sources/EasyDesignSystem/EDSText.swift`
- `Sources/EasyDesignSystem/EDSTheme.swift`
- Catalog、主题编辑器、README、测试和 JSON Fixtures

因此这不是“替换五个字段名”的小改动，而是主题边界、JSON、组件 Recipe 和测试基线的系统性迁移。

## 3. 同步原则

### 3.1 应完整同步的设计思想

- Seed、Semantic Scheme、Component Recipe 三层公开心智模型。
- EDS 自有 Neutral Foundation。
- Brand / Information / Success / Warning / Danger 五个独立色彩家族。
- Focus、Selected、Primary Action、Active Navigation 默认归属 Brand。
- 完整值类型与 Partial Override 类型分离。
- Light/Dark Override 独立，不把一侧自动复制到另一侧。
- Layer-aware Surface 与 Field Surface。
- Hover / Press 通过 Interaction Resolver 统一生成。
- Disabled 使用独立语义角色，不对整个组件统一降低 opacity。
- 主题边界只解析一次，组件读取 resolved theme。
- 对比度以测试保护，不在运行时偷偷纠色。

### 3.2 不应机械照搬的 Flutter 实现

- Flutter 的 `BuildContext` 扩展应改成 SwiftUI `EnvironmentValues`。
- Flutter `Brightness` 应对应 SwiftUI `ColorScheme`。
- Flutter `InheritedWidget` 缓存应对应 SwiftUI Theme Resolver ViewModifier。
- Flutter `Color` 应继续映射为 SwiftUI `Color`；颜色计算内部使用明确的 sRGB/ARGB 值对象，避免直接对动态 `Color` 做数学运算。
- Flutter 的 Material Theme 桥接不是 Swift 首期目标；Swift 首期只保证 EDS 自身组件一致。
- 组件 Recipe 第一阶段保留在各组件内部，不公开大量 `EDSXxxColorRecipe` 类型。

## 4. 目标数据模型

### 4.1 `EDSThemeData`

新增真正的完整主题配置：

```swift
public struct EDSThemeData: Codable, Equatable, Sendable {
    public var seeds: EDSColorSeeds
    public var semanticOverrides: EDSSemanticOverrides
    public var tokens: EDSDesignTokens
}
```

职责：可配置、可持久化、可选择 Preset，但不保存当前外观下的解析结果。

### 4.2 `EDSDesignTokens`

继续管理非颜色 Token：

- spacing
- radius
- typography
- controlSize
- adaptiveLayout
- heroGradient
- stroke
- shadow

从中删除 `colors`。`heroGradient` 和 `shadow.color` 首期保留显式配置，不自动从 Brand Seed 推导，因为它们属于品牌视觉资产和效果 Token，而不是语义界面色。

### 4.3 `EDSColorSeeds`

```swift
public struct EDSColorSeeds: Codable, Equatable, Sendable {
    public var brand: EDSColorValue
    public var information: EDSColorValue
    public var success: EDSColorValue
    public var warning: EDSColorValue
    public var danger: EDSColorValue
}
```

建议内部配置颜色使用可稳定编码和计算的 `EDSColorValue`（sRGB RGBA），解析完成后再转换成 SwiftUI `Color`。不要直接把动态系统 `Color` 作为 Seed。

默认值与 Flutter 当前基线一致：

| Family | Seed |
|---|---|
| Brand | `#3185FF` |
| Information | `#3185FF` |
| Success | `#27B15A` |
| Warning | `#F9B135` |
| Danger | `#E54444` |

另增全部可选的 `EDSColorSeedOverrides`，用于 Preset 上的局部覆盖。完整配置与 Patch 不共用一个类型。

### 4.4 `EDSSemanticColors`

每个 Light/Dark 外观解析出一套非可选的语义色：

- Surface：`surfacePage / Base / Raised / Sunken / Overlay / Disabled`
- Foreground：`foregroundPrimary / Secondary / Tertiary / Disabled / Inverse`
- Border：`borderSubtle / Default / Strong / Selected / Focus / Disabled / Danger`
- 每个彩色 Family：`Foreground / Surface / SurfaceStrong / Border / OnStrong`

不单独新增 `selectedSurface`：Selected 直接使用 Brand Family，避免同义 Token 膨胀。

### 4.5 Override

新增：

```swift
public struct EDSSemanticColorOverrides { /* 全部 Optional */ }
public struct EDSSemanticOverrides {
    public var light: EDSSemanticColorOverrides?
    public var dark: EDSSemanticColorOverrides?
}
```

高级 Host 可以覆盖最终语义角色。未提供的字段继续采用自动生成值；Light 与 Dark 互不复制。

### 4.6 `EDSResolvedTheme`

```swift
public struct EDSResolvedTheme: Equatable, Sendable {
    public let configuration: EDSThemeData
    public let colors: EDSSemanticColors
    public let colorScheme: ColorScheme
}
```

组件通过环境读取 `edsResolvedTheme`、`edsColors` 和非颜色 `edsTokens`，不再自行调用 Palette Resolver。

## 5. 颜色解析实现

### 5.1 Palette Engine

Flutter 使用 Material Color Utilities 的 HCT Tonal Palette。Swift 要得到跨端一致结果，也应使用相同算法，而不是用 RGB 乘法或简单 `opacity` 模拟。

官方 Material Color Utilities 仓库包含 Swift 实现，但其 Swift Package 位于仓库的 `swift/` 子目录，直接把仓库根 URL 作为 SwiftPM dependency 的可维护性需要先做验证。建议按以下优先级决策：

1. 验证官方仓库是否已有可直接依赖的稳定 tag/package URL。
2. 若不能直接稳定依赖，将官方 Swift 实现中 HCT、TonalPalette 及其必需数学代码以固定上游 commit 引入内部 vendor 目录，保留 Apache 2.0 License 和来源说明。
3. 不建议自行发明 RGB/HSL 算法代替 HCT，否则 Flutter/Swift 同一 Seed 会生成不同颜色，失去同步意义。

EDS 自身必须再包一层内部 `EDSTonalPalette`，组件与公开 API 不直接暴露第三方类型。这样未来替换引擎只影响一处。

### 5.2 Tone Mapping

首版同步 Flutter 已校准的映射：

| Role | Light | Dark |
|---|---:|---:|
| Foreground | 35 | 85 |
| Surface | 95 | 20 |
| SurfaceStrong | 40 | 80 |
| Border | 55 | 60 |
| OnStrong | 100 | 10 |

每个 Family 保留独立 `EDSFamilyToneMap`，即使第一版多数值相同。Warning 必须可以单独调节。

### 5.3 Neutral Foundation

Neutral 不从 Host Brand 推导，由 EDS 固定控制。这样品牌换色不会污染页面底色、普通文字、边框和 Disabled。

SwiftUI 系统动态色可以作为平台研究参考，但首版应使用与 Flutter 对齐的确定性 sRGB 基线，否则跨端截图和对比度测试无法稳定复现。若希望 Apple 平台更原生，应以独立 Preset 表达，而不是让默认 Scheme 随系统私有颜色漂移。

### 5.4 Resolver

新增纯函数 `EDSColorResolver.resolve(seeds:colorScheme:overrides:)`：

1. Seed 生成五套 Tonal Palette。
2. Neutral Foundation 提供基础 Surface/Foreground/Border。
3. Tone Map 生成彩色 Semantic Families。
4. Focus/Selected 映射到 Brand。
5. 合并对应 Light 或 Dark Override。
6. 返回完整 `EDSSemanticColors`。

解析函数必须不读全局单例，便于单元测试和 Preview。

## 6. SwiftUI 主题环境

新增内部 `EDSResolvedThemeModifier`：

```swift
@Environment(\.colorScheme) private var colorScheme

func body(content: Content) -> some View {
    let resolved = EDSThemeResolver.resolve(theme, colorScheme: colorScheme)
    content
        .environment(\.edsResolvedTheme, resolved)
        .environment(\.edsTheme, resolved.configuration.tokens)
        .tint(resolved.colors.brandSurfaceStrong)
}
```

公开入口建议调整为：

```swift
view.easyDesignTheme(EDSThemeData(...))
view.easyDesignTheme(.blue)
view.easyDesignSeedOverrides(...)
```

`EDSTheme.shared` 改为持有 `EDSThemeData`。为了避免每个组件重复构建 HCT Palette，解析只发生在主题配置或 `colorScheme` 改变时。

## 7. Layer 与 Interaction

### 7.1 Layer

新增：

```swift
public enum EDSLayer: Sendable {
    case base
    case raised
    case nested
    case overlay
}
```

通过 Environment 传播当前 Layer。`EDSLayerResolver` 负责：

- 容器 Surface。
- Field Surface 与父层形成对比。
- Layer 对应的默认 Border。

建议映射：

| Layer | Surface | Field Surface | Border |
|---|---|---|---|
| base | surfacePage | surfaceBase | borderSubtle |
| raised | surfaceRaised | surfaceSunken | borderDefault |
| nested | surfaceSunken | surfaceBase | borderDefault |
| overlay | surfaceOverlay | surfaceBase | borderStrong |

`EDSPage / EDSGroup / EDSCard / Dialog / Menu / Popover` 建立 Layer；TextField、Dropdown 等消费 Layer。

### 7.2 Interaction

新增内部：

- `EDSInteractionState`: rest / hovered / pressed
- `EDSInteractionColorFamily`: brand / information / success / warning / danger
- `EDSInteractionColorResolver`

Hover/Press 应沿 tonal palette 改变 tone，不能对整个控件统一 opacity。Selection 仍是组件语义状态，不塞进 Interaction Resolver。

## 8. 组件迁移

### 8.1 Button

- `EDSButton.Tone.accent` 改为 `.brand`。
- 新增 `.information`。
- filled / medium / soft / plain / outline 从 Semantic Family 和 Interaction Resolver 取色。
- filled 文字统一读取 `OnStrong`，不再硬编码 `.white`。
- neutral 使用 Neutral Foundation。
- Disabled 使用 `surfaceDisabled / foregroundDisabled / borderDisabled`。
- Focus 使用 `borderFocus`；尺寸和 ring geometry 仍属于组件样式。

### 8.2 Surface 与 Easy API

- Page → `surfacePage` / base layer。
- Card → `surfaceRaised` / raised layer。
- Group → 根据 style 使用 raised 或 nested。
- Dialog / Menu / Popover → `surfaceOverlay` / overlay layer。
- 标准 Card/Group 不再以 Raw Color 作为常规主题入口；如保留显式背景初始化，应明确归类为 escape hatch，并不承诺自动语义适配。

### 8.3 Text、Rows、States、Sidebar、Command Controls

- Text 统一使用 foreground roles。
- Selected Sidebar / active navigation 使用 Brand。
- Error / Empty / Success 状态使用对应 Family。
- 普通分隔线、边框使用 Border roles。
- `EDSValueRow` 等公开 Raw Color tone 应改为语义枚举。
- CommandGroup / SplitButton / CommandPopover 使用 Layer + Button Recipe，不自行拼色。

### 8.4 组件 API 边界

Host 可以：

- 选择 Preset。
- 覆盖 Seeds。
- 高级覆盖 Semantic Roles。
- 配置非颜色 Token。

Host 不应：

- 为单个标准按钮传 hoverColor。
- 为单个输入框传 focusColor。
- 修改组件到 Semantic Role 的映射。

## 9. 数据库与持久化变化

**无数据库变更。** EasyDesignSystem 是 Swift Package，不维护数据库。

但存在明确的主题 JSON 持久化 Breaking Change。

旧结构：

```json
{
  "colors": {
    "primary": "#3185FF",
    "accent": "#3185FF",
    "success": "#27B15A",
    "warning": "#F9B135",
    "danger": "#E54444"
  }
}
```

新结构：

```json
{
  "colors": {
    "seeds": {
      "brand": "#3185FF",
      "information": "#3185FF",
      "success": "#27B15A",
      "warning": "#F9B135",
      "danger": "#E54444"
    },
    "semanticOverrides": {
      "light": {},
      "dark": {}
    }
  },
  "spacing": {},
  "radius": {}
}
```

建议 `0.5.0` 不静默兼容旧 colors schema：发现 `colors.primary/accent/...` 时抛出带迁移说明的解码错误。原因是自动迁移无法恢复旧主题在 Light/Dark 下的真实设计意图。

可单独提供一次性迁移工具或文档映射：

- `primary` → `colors.seeds.brand`
- `accent` → 删除；若旧项目只设置 accent，则人工确认后迁入 brand
- `success/warning/danger` → 同名 seeds
- `information` → 默认值或人工设置

非颜色字段保持原 schema，旧数据只需迁移 colors 分支。

## 10. 界面变化

这是视觉体系升级，会有可见变化：

- Brand、状态色的浅底不再是固定 12% 透明色，而是感知均匀的 tone。
- Light/Dark 下同一语义角色分别校准。
- filled 按钮文字由 `OnStrong` 决定，Warning/Success 不再依赖硬编码白色。
- 页面、卡片、嵌套区域、弹层形成稳定层级。
- Hover/Press 改变 tonal surface，不再整体淡化。
- Disabled 的文字、背景、边框分别解析。
- Focus、Selected、Active Navigation 统一跟随 Brand。

需新增 ColorScheme 校准页，至少同时展示：

- 全部 Semantic Roles。
- 五个 Family 的 Foreground/Surface/Strong/Border/OnStrong。
- 四种 Layer 及嵌套 Field。
- Button component matrix。
- Blue / Orange / Purple Preset。
- Light / Dark 并排对照。
- Interaction 状态与 Disabled。

## 11. 预计新增文件

建议按职责拆分，具体名称实施时可微调：

- `Sources/EasyDesignSystem/Color/EDSColorValue.swift`
- `Sources/EasyDesignSystem/Color/EDSColorSeeds.swift`
- `Sources/EasyDesignSystem/Color/EDSTonalPalette.swift`
- `Sources/EasyDesignSystem/Color/EDSFamilyToneMap.swift`
- `Sources/EasyDesignSystem/Color/EDSNeutralFoundation.swift`
- `Sources/EasyDesignSystem/Color/EDSSemanticColors.swift`
- `Sources/EasyDesignSystem/Color/EDSSemanticOverrides.swift`
- `Sources/EasyDesignSystem/Color/EDSColorResolver.swift`
- `Sources/EasyDesignSystem/Color/EDSInteractionColorResolver.swift`
- `Sources/EasyDesignSystem/Color/EDSLayer.swift`
- `Sources/EasyDesignSystem/Color/EDSLayerResolver.swift`
- `Sources/EasyDesignSystem/Theme/EDSThemeData.swift`
- `Sources/EasyDesignSystem/Theme/EDSResolvedTheme.swift`
- `Sources/EasyDesignSystem/Theme/EDSThemeResolver.swift`
- `Examples/Catalog/EDSColorSchemeShowcase.swift`
- `Tests/EasyDesignSystemTests/EDSColorSchemeTests.swift`
- `Tests/EasyDesignSystemTests/EDSColorContrastTests.swift`
- `Tests/EasyDesignSystemTests/EDSInteractionColorTests.swift`
- `Tests/EasyDesignSystemTests/EDSLayerTests.swift`
- `Tests/EasyDesignSystemTests/EDSThemeJSONV2Tests.swift`
- Material Color Utilities vendor 文件及 `NOTICE`（仅在依赖验证不通过时）

## 12. 预计修改文件

- `Package.swift`：Palette Engine 依赖或 vendor target；保持现有最低平台和 Swift 6.1。
- `Sources/EasyDesignSystem/EDSDesignTokens.swift`：删除 `EDSColorTokens` 与 `colors` 字段，保留非颜色 Token。
- `Sources/EasyDesignSystem/EDSTheme.swift`：从 tokens store 升级为 theme data store，更新 Preset。
- `Sources/EasyDesignSystem/EDSThemeEnvironment.swift`：注入 resolved theme、semantic colors、tokens 和 layer。
- `Sources/EasyDesignSystem/EDSButtons.swift`
- `Sources/EasyDesignSystem/EDSCommandControls.swift`
- `Sources/EasyDesignSystem/EDSComparisonSection.swift`
- `Sources/EasyDesignSystem/EDSEasyDesign.swift`
- `Sources/EasyDesignSystem/EDSLayouts.swift`
- `Sources/EasyDesignSystem/EDSRows.swift`
- `Sources/EasyDesignSystem/EDSStates.swift`
- `Sources/EasyDesignSystem/EDSSurfaces.swift`
- `Sources/EasyDesignSystem/EDSText.swift`
- `Sources/EasyDesignSystem/Resources/EDSDefaultTheme.json`
- Catalog Gallery、Theme Playground、Theme Preview。
- `Tests/EasyDesignSystemTests/EasyDesignSystemTests.swift` 与 Fixtures。
- `Tests/APICompatibility/EasyDesignSystem-PublicAPI.txt`。
- `README.md`、DocC、`CHANGELOG.md`、迁移指南。

## 13. 兼容性与版本策略

建议版本：`0.5.0`。

明确 Breaking API：

- 删除 `EDSColorTokens`。
- 删除 `EDSDesignTokens.colors`。
- `EDSButton.Tone.accent` 改为 `.brand`。
- 主题入口从 `EDSDesignTokens` 改为 `EDSThemeData`。
- JSON colors schema 改变。
- 依赖 Raw Color 的 ValueRow/Card/Group 等 API 需要语义化调整。

不变内容：

- iOS 17 / iPadOS 17 / macOS 14 / Mac Catalyst 17。
- Swift tools 6.1，除非 Palette Engine 的技术验证证明无法满足。
- spacing / radius / typography / controlSize / adaptiveLayout / heroGradient / stroke / shadow。
- 非颜色布局、交互尺寸和字体缩放原则。

因为本次目标正是消除旧模型，不建议同时维持两套颜色 API。若业务 App 无法同步迁移，可先在独立分支完成 `0.5.0`，宿主按自己的节奏升级依赖。

## 14. 风险与控制

### R1：Swift Palette Engine 集成不稳定

官方 Swift 包位于上游仓库子目录，直接依赖方式需验证。实施前做最小 Spike，锁定版本或上游 commit，并用 Flutter Golden Values 验证同 Seed/tone 输出。

### R2：SwiftUI `Color` 难以稳定做颜色数学

内部计算统一使用 sRGB/ARGB 值对象；只在 API 边界转换 `Color`。动态系统色不参与 Seed 计算。

### R3：跨端同名角色视觉不一致

建立 Flutter 导出的 Seed/tone/semantic golden fixture，Swift 测试逐项比对 RGB。

### R4：Warning 和浅色文字对比度不足

每个 Family 保持独立 Tone Map；关键正文目标 WCAG AA 4.5:1，控件边界和 Focus 指示参考 3:1。

### R5：一次迁移文件多，容易混入非颜色行为变化

分阶段提交，先基础设施和测试，再逐类迁移组件；除颜色和必要主题入口外，不重构布局或业务行为。

### R6：全局主题与局部主题解析不一致

所有公开入口最终都经过同一个 `EDSThemeResolver`；组件禁止直接读取 `EDSTheme.shared`。

### R7：颜色体系被组件 escape hatch 绕开

逐个审查公开 Raw Color 参数。保留时明确标记为高级自定义入口，标准 Preset 和 Easy API 不使用它。

## 15. 实施计划

### Phase 0：契约与技术验证

- [x] 冻结 Swift 版公开命名、Semantic Roles 和 JSON v2 schema。
- [x] 验证 Material Color Utilities Swift 的依赖方式、许可证、构建平台和 Swift 6.1 兼容性。
- [ ] 从 Flutter 版导出 Blue/Orange/Purple、Light/Dark 的 golden semantic colors。
- [x] 确认默认 Neutral Foundation 与 Flutter 当前 `0.4.x` 完全一致。
- [x] 写迁移指南草案和 breaking API 清单。

### Phase 1：颜色基础设施

- [ ] 新增 `EDSColorValue`、Seeds、Seed Overrides。
- [x] 新增 Tonal Palette 封装与 Family Tone Map。
- [x] 新增 Neutral Foundation。
- [x] 新增完整 Semantic Colors 与 Partial Overrides。
- [x] 新增 Color Resolver、Contrast 计算和 golden tests。
- [ ] 验证相同 Seed/tone 与 Flutter 输出一致。

### Phase 2：主题与持久化

- [x] 新增 `EDSThemeData`、`EDSResolvedTheme`、`EDSThemeResolver`。
- [ ] `EDSDesignTokens` 移除 colors，只保留非颜色 Token。
- [x] 重构 `EDSTheme.shared` 与 SwiftUI Environment 注入。
- [x] 实现 JSON v2 编解码和旧 schema 明确拒绝。
- [x] 迁移 Blue/Orange/Purple Preset 和默认主题资源。
- [x] 覆盖全局主题、局部主题、Light/Dark 切换和 JSON round-trip 测试。

### Phase 3：Layer 与 Interaction

- [x] 新增 Layer Environment 和 Layer Resolver。
- [x] 新增 Interaction Color Resolver。
- [ ] Page/Card/Group/Dialog/Menu/Popover 建立正确 Layer。
- [ ] Field 类组件根据父 Layer 选择 Surface。
- [x] 添加 Hover/Press/Focus/Selected/Disabled 状态测试。

### Phase 4：组件迁移

- [x] Button 与旧 ButtonStyle 转发层。
- [x] Text、Rows、Comparison、States。
- [x] Sidebar 与 Active Navigation。
- [x] CommandGroup、SplitButton、CommandPopover。
- [x] Surface、Easy API 与所有剩余 `theme.colors/tokens.colors` 调用点。
- [ ] 清零组件内固定 opacity/RGB darken 和硬编码语义色。

### Phase 5：Catalog、文档与宿主迁移准备

- [ ] 新增 ColorScheme 2.0 校准页和组件矩阵。
- [ ] Theme Playground 改为 Seed 与 Semantic Override 编辑器。
- [x] 更新 README、DocC、CHANGELOG。
- [x] 完成 `0.4.x → 0.5.0` Breaking Migration Guide。
- [x] 更新公开 API 基线。
- [ ] 为主要宿主列出实际迁移点和截图回归清单。

### Phase 6：发布验收

- [x] `swift build` 与 `swift test` 全绿。
- [x] iOS、iPadOS、macOS、Mac Catalyst 构建通过。
- [x] iPhone/iPad UI tests 通过，无已知 flaky 结果混入发布判断。
- [x] Public API 检查只出现本版本已批准的 Breaking 清单。
- [ ] 全部 Palette/Semantic golden tests 与 Flutter `0.4.x` 对齐。
- [ ] Light/Dark、五个 Family、四个 Layer 完成目视校准。
- [ ] 关键文字对比度达到 4.5:1，关键边界/Focus 达到 3:1；例外需在文档中逐项记录。
- [x] 主题 JSON v2 round-trip、缺字段默认值、非法旧 schema 错误信息验证通过。
- [x] README 示例和 Catalog 全部编译运行。

## 16. 建议的提交边界

为降低回归定位成本，建议至少拆成以下提交：

1. `docs: define Swift ColorScheme 2.0 contract`
2. `feat: add tonal palette and semantic color resolver`
3. `feat: introduce theme data and resolved theme environment`
4. `feat: add layer and interaction color resolution`
5. `refactor: migrate EDS components to semantic colors`
6. `docs: add ColorScheme 2.0 catalog and migration guide`

在 Phase 1–3 完成前不迁移组件；在所有组件迁移完成前不删除旧 `EDSColorTokens`。最终合并到发布分支时再形成一致的 Breaking Release，避免主分支长期处于两套模型混用状态。

## 17. 验收结论标准

只有同时满足以下条件，才可认为 Swift 已真正同步 Flutter 的最新设计思想：

- Host 通过 Seed 定义品牌色，而不是维护一组组件颜色。
- 组件只消费 Semantic Roles，不直接消费 Seed。
- 同一 Seed 在 Swift/Flutter 生成一致的关键 tone。
- Light/Dark、Layer、Interaction 都由统一 Resolver 决定。
- 标准组件不再各自使用 opacity、RGB darken 或硬编码白字解决状态颜色。
- 主题 JSON 保存配置，不保存运行时派生色。
- 非颜色 Token 与多平台适配能力保持稳定。

仅仅把 `primary` 重命名成 `brand`，或增加几十个颜色字段，不算完成 ColorScheme 2.0。

## 18. 2026-10-02 实施记录

- ColorScheme 2.0 核心链路已落地：Seeds、HCT Tonal Palette、Semantic Colors、Brightness Overrides、Layer、Interaction、ThemeData 与 JSON v2。
- `EDSDesignTokens.colors` 暂时保留为源码兼容层；`EDSThemeData` 的 JSON 编解码不会读取或输出它，运行时组件颜色也已改由语义解析结果提供。后续删除该兼容字段时，应单独评估宿主迁移窗口。
- `EDSDefaultTheme.json` 的 Seeds 与非颜色 Token 已和 Flutter 对齐；随后按本节方案增加了 Swift 侧的 `colors.style` 字段。
- Swift 验证：`swift test` 共 34 项通过；Public API compatibility 通过；iOS、iPadOS、macOS、Mac Catalyst 构建通过；iPhone UI tests 8 项通过（1 项按设备条件跳过），iPad UI tests 8 项通过。
- Flutter 参考验证：`flutter test test/color test/theme/eds_theme_json_v2_test.dart` 共 31 项通过。
- 数据库与业务持久化仍无变化；唯一持久化兼容变化是主题 JSON 的 `colors` 分支升级为 v2 schema。

## 19. JSON 色彩风格扩展

为避免把产品风格固定在 Swift 代码里，tone map 与交互态偏移改由随包 JSON 资源定义。Seed 仍表示“是什么色系”，Color Style 表示“这套色系呈现得多浓烈或多淡雅”。

- `default`：平衡风格，也是未配置时的默认值。
- `vivid`：更浓烈的 strong/medium 表面，适合 VideoHero 这类强调品牌主操作的产品。
- `elegant`：更高 tone、更柔和的表面，适合信息密集或克制的界面。
- 调用者可以通过 `theme.colorStyle` 选择内置风格，也可以用 `EDSColorStyle.load(jsonFileURL:)` 加载自己的 JSON。
- Catalog 的统一主题栏同时提供 Seed/主题预设与 Color Style 选择器；两者任一变化都会更新全局 ThemeData，并通过重建预览子树让所有 Catalog 页面实时显示组合效果。
- 主题 JSON 通过 `colors.style` 保存内置风格 ID；Seeds、Semantic Overrides 和非颜色 Token 的职责不变。
- [x] Color Style JSON 支持可选 `contentColors.light/dark`，可覆盖正文与 `onStrong` 等文字/图标前景色；未配置角色继续使用 Material tonal palette 自动结果，主题级 `semanticOverrides` 仍拥有最高优先级。
- [x] `contentColors` 只接受前景语义角色和 `#RRGGBB`，避免把 surface/border 配置混入字体色定义。
- 无数据库变更。若宿主将主题 JSON 持久化，缺少 `colors.style` 的 v2 文件自动使用 `default`，无需数据迁移。
