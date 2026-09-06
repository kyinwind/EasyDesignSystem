import SwiftUI

// MARK: - EDSButtonStyle 样式定义

public struct EDSPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.edsTheme) private var theme
    @Environment(\.edsInteractionProfile) private var interactionProfile
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let metrics = EDSResolvedMetrics.resolve(
            tokens: theme,
            profile: interactionProfile,
            horizontalSizeClass: horizontalSizeClass
        )
        let showsHover = metrics.supportsHoverEnhancement && isHovered

        configuration.label
            .edsFont(.bodyStrong, tokens: theme.typography)
            .foregroundColor(.white)
            .frame(minHeight: metrics.interactiveHeight(for: theme.controlSize.buttonHeight))
            .padding(.horizontal, theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.md)
                    .fill(theme.colors.primary)
            )
            .contentShape(RoundedRectangle(cornerRadius: theme.radius.md))
            .opacity(isEnabled ? (showsHover ? 0.85 : 1.0) : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct EDSSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.edsTheme) private var theme
    @Environment(\.edsInteractionProfile) private var interactionProfile
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let metrics = EDSResolvedMetrics.resolve(
            tokens: theme,
            profile: interactionProfile,
            horizontalSizeClass: horizontalSizeClass
        )
        let showsHover = metrics.supportsHoverEnhancement && isHovered

        configuration.label
            .edsFont(.bodyStrong, tokens: theme.typography)
            .foregroundColor(theme.colors.primary)
            .frame(minHeight: metrics.interactiveHeight(for: theme.controlSize.buttonHeight))
            .padding(.horizontal, theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.md)
                    .stroke(theme.colors.primary, lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: theme.radius.md))
            .opacity(isEnabled ? (showsHover ? 0.85 : 1.0) : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct EDSSoftButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.edsTheme) private var theme
    @Environment(\.edsInteractionProfile) private var interactionProfile
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let metrics = EDSResolvedMetrics.resolve(
            tokens: theme,
            profile: interactionProfile,
            horizontalSizeClass: horizontalSizeClass
        )
        let showsHover = metrics.supportsHoverEnhancement && isHovered

        configuration.label
            .edsFont(.bodyStrong, tokens: theme.typography)
            .foregroundColor(theme.colors.primary)
            .frame(minHeight: metrics.interactiveHeight(for: theme.controlSize.buttonHeight))
            .padding(.horizontal, theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.md)
                    .fill(theme.colors.accentSoft)
            )
            .contentShape(RoundedRectangle(cornerRadius: theme.radius.md))
            .opacity(isEnabled ? (showsHover ? 0.85 : 1.0) : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct EDSDangerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.edsTheme) private var theme
    @Environment(\.edsInteractionProfile) private var interactionProfile
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let metrics = EDSResolvedMetrics.resolve(
            tokens: theme,
            profile: interactionProfile,
            horizontalSizeClass: horizontalSizeClass
        )
        let showsHover = metrics.supportsHoverEnhancement && isHovered

        configuration.label
            .edsFont(.bodyStrong, tokens: theme.typography)
            .foregroundColor(.white)
            .frame(minHeight: metrics.interactiveHeight(for: theme.controlSize.buttonHeight))
            .padding(.horizontal, theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.md)
                    .fill(theme.colors.danger)
            )
            .contentShape(RoundedRectangle(cornerRadius: theme.radius.md))
            .opacity(isEnabled ? (showsHover ? 0.85 : 1.0) : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - EDSButton：通用按钮

public struct EDSButton: View {
    public enum Role {
        case primary
        case secondary
        case soft
        case danger
    }

    private let role: Role
    private let action: () -> Void
    private let label: () -> AnyView

    public init(
        _ role: Role = .primary,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> some View
    ) {
        self.role = role
        self.action = action
        self.label = { AnyView(label()) }
    }

    /// 文本文案按钮的便捷初始化。
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
        self.role = role
        self.action = action
        self.label = {
            if let systemImage {
                AnyView(Label(title, systemImage: systemImage))
            } else {
                AnyView(Text(title))
            }
        }
    }

    public var body: some View {
        Group {
            switch role {
            case .primary:
                Button(action: action) { label() }
                    .buttonStyle(EDSPrimaryButtonStyle())
            case .secondary:
                Button(action: action) { label() }
                    .buttonStyle(EDSSecondaryButtonStyle())
            case .soft:
                Button(action: action) { label() }
                    .buttonStyle(EDSSoftButtonStyle())
            case .danger:
                Button(action: action) { label() }
                    .buttonStyle(EDSDangerButtonStyle())
            }
        }
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
