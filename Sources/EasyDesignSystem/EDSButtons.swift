import SwiftUI

// MARK: - 按钮的三维维度
//
// `EDSButton` 的视觉由三个**正交**维度决定，任意组合均有效：
//
// - `Emphasis`：视觉分量（实心 / 描边 / 浅底 / 纯文字）
// - `Tone`：语义色调（主题色 / 中性 / 危险 / 成功 / 警告）
// - `Size`：尺寸档位（small 28 / regular 34 / large 44）
//
// `EDSButton.Role` 是一张「预设别名表」：每个角色对应一组固定的三维组合。
// 两个入口最终都汇入同一份 `EDSButtonVisualBody` 渲染实现。

// MARK: - 内部渲染体
//
// 承载全部按钮视觉逻辑。
//
// 注意：`@Environment` / `@State` 只有定义在 `View` 上才会被 SwiftUI 注入，
// 因此这段逻辑不能直接写在 `ButtonStyle.makeBody` 里由多个样式共享，
// 必须落在一个 `View` 上，各 `ButtonStyle` 只负责把配置传进来。

struct EDSButtonVisualBody: View {
    let label: ButtonStyleConfiguration.Label
    let isPressed: Bool
    let appearance: EDSButtonAppearance

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.edsTheme) private var theme
    @Environment(\.edsInteractionProfile) private var interactionProfile
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        let metrics = EDSResolvedMetrics.resolve(
            tokens: theme,
            profile: interactionProfile,
            horizontalSizeClass: horizontalSizeClass
        )
        let visual = appearance.resolved(tokens: theme)
        let showsHover = metrics.supportsHoverEnhancement && isHovered

        label
            .edsFont(.bodyStrong, tokens: theme.typography)
            .foregroundColor(visual.foreground)
            // 胶囊按钮的宽度永远由内容决定：禁止文字换行/压缩，
            // 容器过窄时整颗按钮保持形状（宁可溢出，不变形折行）。
            // 没有这两行时，HStack 空间不足会把 Text 压成多行，按钮纵向鼓胀。
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minHeight: metrics.interactiveHeight(for: visual.height))
            .padding(.horizontal, visual.horizontalPadding)
            .background(backgroundShape(for: visual))
            .contentShape(RoundedRectangle(cornerRadius: theme.radius.md))
            .opacity(isEnabled ? (showsHover ? 0.85 : 1.0) : 0.5)
            .scaleEffect(isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }

    @ViewBuilder
    private func backgroundShape(for visual: EDSResolvedButtonVisual) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius.md)
        if let borderColor = visual.borderColor {
            shape.stroke(borderColor, lineWidth: visual.borderWidth)
        } else if let background = visual.background {
            shape.fill(background)
        } else {
            Color.clear
        }
    }
}

// MARK: - 单一按钮样式

struct EDSButtonStyleCanvas: ButtonStyle {
    let appearance: EDSButtonAppearance

    func makeBody(configuration: Configuration) -> some View {
        EDSButtonVisualBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            appearance: appearance
        )
    }
}

// MARK: - 兼容保留的四个旧样式
//
// 这四个类型此前已公开，外部 App 可能直接使用 `.buttonStyle(EDSPrimaryButtonStyle())`。
// 保留为独立类型以保证源码零破坏，内部统一转发到 `EDSButtonVisualBody`。
//
// 它们与 `EDSButton.Role` 的对应关系见 `EDSButtonAppearance` 中的别名表。

public struct EDSPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        EDSButtonVisualBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            appearance: EDSButtonAppearance(emphasis: .filled, tone: .accent, size: .regular)
        )
    }
}

public struct EDSSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        EDSButtonVisualBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            appearance: EDSButtonAppearance(emphasis: .medium, tone: .accent, size: .regular)
        )
    }
}

public struct EDSSoftButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        EDSButtonVisualBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            appearance: EDSButtonAppearance(emphasis: .soft, tone: .accent, size: .regular)
        )
    }
}

public struct EDSDangerButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        EDSButtonVisualBody(
            label: configuration.label,
            isPressed: configuration.isPressed,
            appearance: EDSButtonAppearance(emphasis: .filled, tone: .danger, size: .regular)
        )
    }
}

// MARK: - EDSButton：通用按钮

public struct EDSButton: View {

    // MARK: 三维维度（正交轴）

    /// 视觉分量：这块按钮"多重"，是否抢视觉焦点。
    ///
    /// 四档全部用**底色深浅**表达强弱：实心 100% → medium 25% → soft 12% → plain 无底。
    /// 描边已从按钮体系退役（0.4.0）。
    public enum Emphasis: String, Sendable, Hashable, CaseIterable {
        /// 实心：视觉最强。
        case filled
        /// 中等色底（25%）+ 深字：次级，介于实心与浅底之间。
        case medium
        /// 浅色底：较弱。
        case soft
        /// 纯文字：最弱。
        case plain

        /// 旧描边档。0.4.0 起描边退役，渲染为 `medium` 同款视觉。
        @available(*, deprecated, message: "描边已退役；请改用 medium（渲染视觉相同）。")
        case outline

        /// 手动实现：Swift 无法为含 `@available(*, deprecated)` case 的枚举
        /// 自动合成 `allCases`（合成代码引用废弃符号会被拒绝）。
        /// 顺序 = 强度从强到弱，废弃的 outline 排在最后便于矩阵页对照。
        /// outline 经 rawValue 构造，避免包内直接引用触发废弃告警。
        public static var allCases: [Emphasis] {
            var cases: [Emphasis] = [.filled, .medium, .soft, .plain]
            if let outline = Emphasis(rawValue: "outline") {
                cases.append(outline)
            }
            return cases
        }
    }

    /// 语义色调：这块按钮"是什么性质"。
    public enum Tone: String, Sendable, Hashable, CaseIterable {
        /// 主题色，用于正常操作。
        case accent
        /// 中性灰。
        case neutral
        /// 破坏性操作。
        case danger
        /// 成功 / 已完成。
        case success
        /// 警示。
        case warning
    }

    /// 尺寸档位。
    public enum Size: String, Sendable, Hashable, CaseIterable {
        /// 28pt，密集工具栏。
        case small
        /// 34pt，默认值（等于 `controlSize.buttonHeight`）。
        case regular
        /// 44pt，主行动区。
        case large
    }

    // MARK: 预设别名表
    //
    // 注意：`Role` 不是"一个维度"，而是一张快捷方式对照表。
    // 因此它内部允许混用视觉词（`.primary`）与场景词（`.done`）——
    // 类比 Bootstrap 的 `.btn-primary` / `.btn-danger` 本来就不在同一维度上。
    //
    // 新增条目须对应"真实且重复出现的场景"，建议上限 8–10 条。

    public enum Role: String, Sendable, Hashable, CaseIterable {
        /// 实心主题色。等价于 `filled + accent + regular`。
        case primary
        /// 主题色中底（25%）。等价于 `medium + accent + regular`。
        ///
        /// 0.4.0 前为 `outline + accent + regular`（白底描边），描边退役后自动
        /// 跟随到 medium——调用方源码无需改动，视觉随包升级切换。
        case secondary
        /// 主题色浅底。等价于 `soft + accent + regular`。
        case soft
        /// 实心危险色。等价于 `filled + danger + regular`。
        case danger
        /// 已完成（实心绿底 + ✓）。等价于 `filled + success + regular`。
        ///
        /// 取实心档而非浅底档：12% 浅绿在浅色外观下几乎与页面底色融为一体，
        /// 作为"点击进去有内容"的入口体量不足。实心绿同时解决了与 `EDSBadge(.success)`
        /// 的体量混淆——两者不再只是底色深浅之差。
        case done
        /// 常规灰底（12% 灰底 + 深字）。等价于 `soft + neutral + regular`。
        ///
        /// 灰底次级按钮是最常见的重复场景（工具栏"检测对话/导出/打开目录"一类），
        /// 杨哥定版 2026-09-22 收进 Role 表。
        case normal
    }

    private let appearance: EDSButtonAppearance
    private let action: () -> Void
    private let label: () -> AnyView

    // MARK: 初始化

    /// 使用预设角色并提供自定义标签视图。
    public init(
        _ role: Role = .primary,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> some View
    ) {
        self.appearance = role.appearance
        self.action = action
        self.label = { AnyView(label()) }
    }

    /// 文本文案按钮的便捷初始化（预设角色入口）。
    ///
    /// ```swift
    /// EDSButton("保存", role: .primary, systemImage: "checkmark") {
    ///     save()
    /// }
    /// ```
    public init(
        _ title: LocalizedStringKey,
        role: Role = .primary,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.appearance = role.appearance
        self.action = action
        let resolvedImage = systemImage ?? Self.defaultSystemImage(for: role)
        self.label = {
            if let resolvedImage {
                AnyView(Label(title, systemImage: resolvedImage))
            } else {
                AnyView(Text(title))
            }
        }
    }

    /// `String` 标题版本的预设角色初始化。
    ///
    /// 供自带本地化系统、函数返回 `String` 的 App 直接使用：
    ///
    /// ```swift
    /// EDSButton(L("button.cancel"), role: .secondary) { onCancel() }
    /// ```
    ///
    /// 与 `LocalizedStringKey` 重载并存是安全的：字面量调用（如 `EDSButton("确定")`）
    /// 由 Swift 稳定解析到 `LocalizedStringKey` 版本，不会产生歧义——
    /// 与 `EDSBadge` 的双重载策略一致。
    ///
    /// - Note: 传入的 `String` 会被当作本地化 key 再查一次表。若 App 的
    ///   `L()` 已经返回翻译好的文案，查表未命中时 SwiftUI 会原样显示该字符串，
    ///   因此结果正确，只是多一次无害的查找。
    public init(
        _ title: String,
        role: Role = .primary,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.init(LocalizedStringKey(title), role: role, systemImage: systemImage, action: action)
    }

    /// 三维原语初始化。
    ///
    /// `emphasis` **刻意不给默认值**：一旦给出，`EDSButton("确定") { }` 会同时匹配
    /// 本初始化与「预设角色」初始化，编译器将报 `ambiguous use of 'init'`。
    /// 强制调用方至少写出一个维度，是消除歧义的唯一手段。
    ///
    /// ```swift
    /// EDSButton("忽略并删除", emphasis: .soft, tone: .danger) { }
    /// EDSButton("确定", emphasis: .filled, size: .small) { }
    /// ```
    public init(
        _ title: LocalizedStringKey,
        emphasis: Emphasis,
        tone: Tone = .accent,
        size: Size = .regular,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.appearance = EDSButtonAppearance(emphasis: emphasis, tone: tone, size: size)
        self.action = action
        self.label = {
            if let systemImage {
                AnyView(Label(title, systemImage: systemImage))
            } else {
                AnyView(Text(title))
            }
        }
    }

    /// 三维原语初始化的 `String` 标题版本。
    ///
    /// ```swift
    /// EDSButton(L("toolbar.refresh"), emphasis: .medium, size: .small) { refresh() }
    /// ```
    ///
    /// 与 `LocalizedStringKey` 重载并存的安全性说明同上一处。
    public init(
        _ title: String,
        emphasis: Emphasis,
        tone: Tone = .accent,
        size: Size = .regular,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            LocalizedStringKey(title),
            emphasis: emphasis,
            tone: tone,
            size: size,
            systemImage: systemImage,
            action: action
        )
    }

    public var body: some View {
        Button(action: action) { label() }
            .buttonStyle(EDSButtonStyleCanvas(appearance: appearance))
    }

    /// `.done` 在调用方未显式指定图标时自动补 `checkmark`。
    ///
    /// 承载"已完成"语义，使颜色不再是唯一线索——同时满足
    /// `accessibilityDifferentiateWithoutColor`，与 `EDSBadge` 的既有策略一致。
    private static func defaultSystemImage(for role: Role) -> String? {
        switch role {
        case .done:
            return "checkmark"
        case .primary, .secondary, .soft, .danger, .normal:
            return nil
        }
    }
}

// MARK: - EDSButtonAppearance
//
// 三维组合的值对象。公开可构造，供包外 App 自封装预设使用。

public struct EDSButtonAppearance: Sendable, Hashable {
    public var emphasis: EDSButton.Emphasis
    public var tone: EDSButton.Tone
    public var size: EDSButton.Size

    public init(
        emphasis: EDSButton.Emphasis = .filled,
        tone: EDSButton.Tone = .accent,
        size: EDSButton.Size = .regular
    ) {
        self.emphasis = emphasis
        self.tone = tone
        self.size = size
    }
}

extension EDSButton.Role {
    /// 预设别名表：每个角色对应一组固定的三维组合。
    public var appearance: EDSButtonAppearance {
        switch self {
        case .primary:
            return EDSButtonAppearance(emphasis: .filled, tone: .accent, size: .regular)
        case .secondary:
            return EDSButtonAppearance(emphasis: .medium, tone: .accent, size: .regular)
        case .soft:
            return EDSButtonAppearance(emphasis: .soft, tone: .accent, size: .regular)
        case .danger:
            return EDSButtonAppearance(emphasis: .filled, tone: .danger, size: .regular)
        case .done:
            return EDSButtonAppearance(emphasis: .filled, tone: .success, size: .regular)
        case .normal:
            return EDSButtonAppearance(emphasis: .soft, tone: .neutral, size: .regular)
        }
    }
}

// MARK: - 解析结果

/// 三维组合经主题解析后的具体视觉值。纯计算结果，不对外暴露。
struct EDSResolvedButtonVisual {
    let foreground: Color
    let background: Color?
    let borderColor: Color?
    let borderWidth: CGFloat
    let height: CGFloat
    let horizontalPadding: CGFloat
}

extension EDSButtonAppearance {

    /// 把三维组合解析为具体视觉值。
    ///
    /// 纯函数：只依赖传入的 token，不读全局单例，便于测试。
    func resolved(tokens: EDSDesignTokens) -> EDSResolvedButtonVisual {
        let colors = tokens.colors

        // 各色调的前景色基色（实心档除外，实心档文字另有规则）
        let toneColor: Color
        switch tone {
        case .accent:  toneColor = colors.primary
        case .neutral: toneColor = Color.primary
        case .danger:  toneColor = colors.danger
        case .success: toneColor = colors.success
        case .warning: toneColor = colors.warning
        }

        // 浅底档的背景色：各色调的 12% 透明版本
        let toneSoftColor: Color
        switch tone {
        case .accent:  toneSoftColor = colors.primarySoft
        case .neutral: toneSoftColor = Color.primary.opacity(0.12)
        case .danger:  toneSoftColor = colors.dangerSoft
        case .success: toneSoftColor = colors.successSoft
        case .warning: toneSoftColor = colors.warningSoft
        }

        let foreground: Color
        let background: Color?
        let borderColor: Color?

        switch emphasis {
        case .filled:
            switch tone {
            case .neutral:
                // 中性实心需要"反色"：底色是 primary 的 75%，文字用页面底色，
                // 这样浅色外观下是"深灰底 + 白字"，深色外观下是"浅灰底 + 深字"。
                foreground = colors.pageBackground
                background = Color.primary.opacity(0.75)
            case .accent, .danger:
                // 历史值：与改造前逐像素一致，保证现有 App 视觉零变化。
                foreground = .white
                background = toneColor
            case .success, .warning:
                // 杨哥定版（2026-09-22）：彩色实心档（success/warning）文字一律白色，
                // 与 accent/danger 实心档观感统一；textPrimary 近黑字目视偏重。
                // 白字在 #27B15A / #F9B135 上对比度仅约 2.8:1 / 1.9:1、不达 WCAG AA
                // ——刻意接受的取舍，主题调浅这两个色时需回评。
                foreground = .white
                background = toneColor
            }
            borderColor = nil

        case .medium, .outline:
            // 0.4.0：描边退役。`outline` 保留为废弃别名，与 medium 同视觉。
            // 中档 = 各色调 25% 底 + "深一档的同色系"文字（杨哥定版 2026-09-22）：
            // 底色与文字同色系，色彩身份贯穿 filled/medium/soft/plain 四档；
            // 文字比 tone 再压深 30%（RGB×0.7），25% 色底上对比度优于 soft 的纯 tone 字，
            // 且与 soft 拉开"文字深浅"这一维层次。neutral 无彩度，维持 textPrimary。
            // 注意：darkened 按浅色外观解析（与 tone 静态 hex 的现状一致），
            // 深色外观的适配是所有静态 tone 色的共同欠账，不单独欠在这里。
            foreground = tone == .neutral
                ? colors.textPrimary
                : EDSPlatformColorBridge.darkened(toneColor, by: 0.7) ?? colors.textPrimary
            background = toneColor.opacity(0.25)
            borderColor = nil

        case .soft:
            // 例外：成功色的浅底 + 同色文字对比度不足（#27B15A 在 12% 浅绿底上约 3.0:1，
            // 低于 WCAG AA 的 4.5:1），因此改用自适应正文色保证可读性。
            // 该组合已不再被 `.done` 使用（`.done` 取实心档），但三维入口仍可构造出
            // `.soft + .success`，故规则保留。
            foreground = tone == .success ? colors.textPrimary : toneColor
            background = toneSoftColor
            borderColor = nil

        case .plain:
            foreground = toneColor
            background = nil
            borderColor = nil
        }

        // 尺寸档位。
        //
        // `.regular` 必须读 token（而非硬编码 34），这样主题若调整 `buttonHeight`
        // 仍能跟随，且保证改造前后视觉完全一致。
        // `.small` / `.large` 用固定值：当前主题无多档 `buttonHeight`，
        // 为一个尚不存在的扩展点引入缩放系数属于过早抽象。
        let height: CGFloat
        switch size {
        case .small:   height = 28
        case .regular: height = tokens.controlSize.buttonHeight
        case .large:   height = 44
        }

        // 横向内边距。`.regular` 用 `spacing.md`(=16)，与改造前一致。
        let horizontalPadding: CGFloat
        switch size {
        case .small:   horizontalPadding = tokens.spacing.sm
        case .regular: horizontalPadding = tokens.spacing.md
        case .large:   horizontalPadding = tokens.spacing.lg
        }

        return EDSResolvedButtonVisual(
            foreground: foreground,
            background: background,
            borderColor: borderColor,
            // 历史值：现有描边按钮为 1.5pt。改用 `stroke.hairline`(=1) 会让所有
            // 描边按钮变细，属于视觉变化，因此本次保持 1.5。
            borderWidth: 1.5,
            height: height,
            horizontalPadding: horizontalPadding
        )
    }
}

// MARK: - EDSSidebarIcon

public struct EDSSidebarIcon: View {
    let systemName: String  // SF Symbol 名称
    let tint: Color          // 背景颜色
    let size: IconSize       // 图标尺寸

    public init(systemName: String, tint: Color, size: IconSize = .medium) {
        self.systemName = systemName
        self.tint = tint
        self.size = size
    }

    /// 图标尺寸枚举，提供 small/medium/large 三种尺寸
    public enum IconSize {
        case small   // 24pt 背景, 11pt 图标
        case medium  // 28pt 背景, 14pt 图标
        case large   // 32pt 背景, 16pt 图标

        /// 图标本身的字体大小
        public var iconSize: CGFloat {
            switch self {
            case .small:  return 11
            case .medium: return 14
            case .large:  return 16
            }
        }

        /// 外层背景的尺寸
        public var frameSize: CGFloat {
            switch self {
            case .small:  return 24
            case .medium: return 28
            case .large:  return 32
            }
        }
    }

    public var body: some View {
        ZStack {
            // 圆角矩形背景，带颜色
            RoundedRectangle(cornerRadius: size.frameSize * 0.22)
                .fill(tint.opacity(0.9))
                .frame(width: size.frameSize, height: size.frameSize)

            // 白色 SF Symbol 图标
            Image(systemName: systemName)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - EDSSidebarIconPresetTint

public enum EDSSidebarIconPresetTint {
    case blue
    case green
    case orange
    case red
    case gray
    case pink
    case purple
    case teal
    case indigo

    public var color: Color {
        switch self {
        case .blue: return EDSTheme.shared.colors.primary
        case .green: return EDSTheme.shared.colors.success
        case .orange: return EDSTheme.shared.colors.warning
        case .red: return EDSTheme.shared.colors.danger
        case .gray: return .secondary
        case .pink: return .pink
        case .purple: return .purple
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
}

// MARK: - EDSBadge

public struct EDSBadge: View {
    @Environment(\.edsTheme) private var theme
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    public enum Style {
        case neutral   // 中性：灰色
        case accent    // 主题色：跟随 primary
        case success   // 成功：绿色
        case warning   // 警告：橙色
        case danger    // 危险：红色
    }

    private enum TextSource {
        case localized(LocalizedStringKey)
        case verbatim(String)
    }

    private let text: TextSource
    private let style: Style

    public init(_ text: LocalizedStringKey, style: Style = .accent) {
        self.text = .localized(text)
        self.style = style
    }

    /// 支持外部项目直接传入 `String` 变量。
    public init(_ text: String, style: Style = .accent) {
        self.text = .localized(LocalizedStringKey(text))
        self.style = style
    }

    /// 明确按原文显示，不走本地化 key 查找。
    public init(verbatim text: String, style: Style = .accent) {
        self.text = .verbatim(text)
        self.style = style
    }

    public var body: some View {
        HStack(spacing: theme.spacing.xxs) {
            badgeText
            differentiationIcon
        }
            .edsFont(.captionStrong, tokens: theme.typography)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, theme.spacing.xs)
            .padding(.vertical, theme.spacing.xxs)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }

    @ViewBuilder
    private var differentiationIcon: some View {
        if differentiateWithoutColor {
            switch style {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .accessibilityHidden(true)
            case .warning:
                Image(systemName: "exclamationmark.triangle.fill")
                    .accessibilityHidden(true)
            case .danger:
                Image(systemName: "xmark.octagon.fill")
                    .accessibilityHidden(true)
            case .neutral, .accent:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var badgeText: some View {
        switch text {
        case .localized(let key):
            Text(key)
        case .verbatim(let string):
            Text(verbatim: string)
        }
    }

    /// 前景色（文字颜色）
    private var foregroundColor: Color {
        switch style {
        case .neutral:  return theme.colors.textSecondary
        case .accent:   return theme.colors.primary
        case .success:  return theme.colors.success
        case .warning:  return theme.colors.warning
        case .danger:   return theme.colors.danger
        }
    }

    /// 背景色：前景色的 12% 透明度
    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

// MARK: - EDSToggle

public struct EDSToggle: View {
    @Environment(\.edsTheme) private var theme
    @Binding private var isOn: Bool
    private let label: LocalizedStringKey

    public init(isOn: Binding<Bool>, label: String) {
        self._isOn = isOn
        self.label = LocalizedStringKey(label)
    }

    public init(isOn: Binding<Bool>, localizedLabel: LocalizedStringKey) {
        self._isOn = isOn
        self.label = localizedLabel
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Text(label)
                .edsFont(.body, tokens: theme.typography)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: theme.colors.primary))
                .accessibilityLabel(label)
        }
        .padding(.vertical, theme.spacing.sm)
    }
}
