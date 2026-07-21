import SwiftUI

// MARK: - Sidebar Components

/*
 使用 EDSSidebarGroupView 需要准备的内容
 1. 导入 DesignSystem
 确保文件头部导入了 DesignSystem：
 import SwiftUI
 // 自动会导入 EDSSurfaces, EDSButtons, EDSDesignTokens

 2. 准备菜单项数据
 // 定义你的菜单项
 struct YourMenuItem: Hashable, Identifiable {
     public let id: String
     public let label: String
     public let icon: String
     public let tint: Color
 }

 3. 使用示例
 struct ExampleView: View {
     @State private var selection: String = "home"

     // 定义分组
     let mainGroup = [
         EDSSidebarMenuItem(id: "home", label: "首页", icon: "house", tint: .blue),
         EDSSidebarMenuItem(id: "settings", label: "设置", icon: "gearshape", tint: .gray),
     ]

     let adminGroup = [
         EDSSidebarMenuItem(id: "users", label: "用户", icon: "person.2", tint: .green),
     ]

     public var body: some View {
         VStack {
             // 分组1：不需要标题
             EDSSidebarGroupView(
                 title: nil,
                 items: mainGroup,
                 selection: $selection
             )

             // 分组2：需要标题
             EDSSidebarGroupView(
                 title: "管理",
                 items: adminGroup,
                 selection: $selection
             )
         }
     }
 }

 4. 组件依赖关系
 EDSSidebarGroupView
 ├── EDSSidebarMenuItem (数据)
 └── EDSSidebarItemButton
     └── EDSSidebarIcon (来自 EDSButtons.swift)
         └── EDSSidebarIcon.PresetTint (预设颜色)

 样式依赖:
 └── EDSTheme.shared (统一访问所有 Token)
 */

// MARK: - EDSSidebarMenuItem

/// 侧边栏菜单项数据
public struct EDSSidebarMenuItem: Hashable, Identifiable {
    public let id: String
    public let label: String
    public let icon: String
    public let tint: Color

    public init(id: String = UUID().uuidString, label: String, icon: String, tint: Color) {
        self.id = id
        self.label = label
        self.icon = icon
        self.tint = tint
    }
}

// MARK: - EDSSidebarGroupView

/// 侧边栏分组视图
public struct EDSSidebarGroupView: View {
    @Environment(\.edsTheme) private var theme
    let title: String?
    let items: [EDSSidebarMenuItem]
    @Binding var selection: String

    public init(title: String? = nil, items: [EDSSidebarMenuItem], selection: Binding<String>) {
        self.title = title
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // 分组标题
            if let title {
                Text(title)
                    .font(theme.typography.captionStrong)
                    .foregroundStyle(theme.colors.textTertiary)
                    .padding(.leading, theme.spacing.sm)
            }

            // 分组内的菜单项
            VStack(spacing: theme.spacing.xxs) {
                ForEach(items) { item in
                    EDSSidebarItemButton(
                        item: item,
                        isSelected: selection == item.id
                    ) {
                        selection = item.id
                    }
                }
            }
        }
    }
}

// MARK: - EDSSidebarItemButton

/// 单个侧边栏菜单项按钮
public struct EDSSidebarItemButton: View {
    @Environment(\.edsTheme) private var theme
    let item: EDSSidebarMenuItem
    let isSelected: Bool
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.sm) {
                EDSSidebarIcon(
                    systemName: item.icon,
                    tint: item.tint,
                    size: .small
                )

                Text(item.label)
                    .font(theme.typography.body15)

                Spacer()
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
                    .fill(isSelected ? theme.colors.accentSoft : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? theme.colors.accent : theme.colors.textPrimary)
    }
}

// MARK: - Surface Components

// MARK: EDSCard

public struct EDSCard<Content: View>: View {
    @Environment(\.edsTheme) private var theme
    let padding: CGFloat?
    let backgroundStyle: AnyShapeStyle?
    let cornerRadius: CGFloat?
    let content: Content

    /// 轻量容器。默认只提供 padding，不绘制背景。
    public init(
        padding: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundStyle = nil
        self.cornerRadius = nil
        self.content = content()
    }

    /// 带背景的卡片容器。只有显式传入 `background` 时才绘制背景和圆角。
    public init(
        padding: CGFloat? = nil,
        background: some ShapeStyle,
        cornerRadius: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundStyle = AnyShapeStyle(background)
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding ?? theme.spacing.lg)
            .edsSurface(
                EDSSurfaceConfiguration(
                    background: backgroundStyle,
                    cornerRadius: cornerRadius ?? theme.radius.md
                )
            )
    }
}

// MARK: EDSGroup

public enum EDSGroupStyle {
    case filled
    case subtle
    case plain
}

public struct EDSGroup<Content: View>: View {
    @Environment(\.edsTheme) private var theme
    let title: LocalizedStringKey?
    let subtitle: LocalizedStringKey?
    let padding: CGFloat?
    let backgroundStyle: AnyShapeStyle?
    let style: EDSGroupStyle
    let cornerRadius: CGFloat?
    let showsBorder: Bool
    let content: Content

    /// 内容分组。默认使用浅背景和圆角，不显示边框。
    public init(
        _ title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        padding: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        style: EDSGroupStyle = .filled,
        showsBorder: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.padding = padding
        self.backgroundStyle = nil
        self.style = style
        self.cornerRadius = cornerRadius
        self.showsBorder = showsBorder
        self.content = content()
    }

    /// 使用显式背景的内容分组。
    public init(
        _ title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        padding: CGFloat? = nil,
        background: some ShapeStyle,
        cornerRadius: CGFloat? = nil,
        style: EDSGroupStyle = .filled,
        showsBorder: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.padding = padding
        self.backgroundStyle = AnyShapeStyle(background)
        self.style = style
        self.cornerRadius = cornerRadius
        self.showsBorder = showsBorder
        self.content = content()
    }

    public var body: some View {
        groupBody
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius ?? theme.radius.md, style: .continuous)
                .stroke(
                    showsBorder ? theme.colors.border : Color.clear,
                    lineWidth: theme.stroke.hairline
                )
        )
    }

    @ViewBuilder
    private var groupBody: some View {
        if let backgroundStyle = resolvedBackgroundStyle {
            EDSCard(
                padding: padding,
                background: backgroundStyle,
                cornerRadius: cornerRadius
            ) {
                groupContent
            }
        } else {
            EDSCard(padding: padding) {
                groupContent
            }
        }
    }

    private var resolvedBackgroundStyle: AnyShapeStyle? {
        switch style {
        case .filled:
            backgroundStyle ?? AnyShapeStyle(theme.colors.cardGrayBackground)
        case .subtle:
            AnyShapeStyle(theme.colors.subtleFill)
        case .plain:
            nil
        }
    }

    private var groupContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if title != nil || subtitle != nil {
                header
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            if let title {
                Text(title)
                    .font(theme.typography.bodyStrong)
                    .foregroundStyle(theme.colors.textPrimary)
            }

            if let subtitle {
                Text(subtitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }
}

// MARK: EDSPageSection

public struct EDSPageSection<Content: View>: View {
    @Environment(\.edsTheme) private var theme
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let showsDivider: Bool?
    let content: Content

    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        showsDivider: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsDivider = showsDivider
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域 - 无背景，直接显示在页面上
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.sectionTitle)
                    .foregroundStyle(theme.colors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .padding(.bottom, theme.spacing.md)

            // 分隔线
            if let show = showsDivider, show {
                Divider()
                    .padding(.bottom, theme.spacing.md)
            }

            content
        }
    }
}

// MARK: - EDSHeroPanel（使用 EDSTheme 的 heroGradient）

/// Hero 面板，根据 EDSTheme.shared.heroGradient 渲染渐变背景
public struct EDSHeroPanel<Content: View>: View {
    @Environment(\.edsTheme) private var theme
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(theme.spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.heroGradient.gradient)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous))
            .shadow(
                color: theme.shadow.shadowColor,
                radius: theme.shadow.radius,
                x: theme.shadow.x,
                y: theme.shadow.y
            )
    }
}

// MARK: - EDSMultilineSubtitleRow

/// 多行 Subtitle 行组件（避免 SKBaseRow 的 lineLimit 限制）
public struct EDSMultilineSubtitleRow<Content: View>: View {
    @Environment(\.edsTheme) private var theme
    var systemIcon: String? = nil
    var iconImage: NSImage? = nil
    var iconColor: Color? = nil
    let title: String?
    let subtitle: String?
    let content: Content

    /// 用 @ViewBuilder 让 content 参数支持多视图
    public init(systemIcon: String? = nil,
         iconImage: NSImage? = nil,
         iconColor: Color? = nil,
         title: String? = nil,
         subtitle: String? = nil,
         @ViewBuilder content: () -> Content) {
        self.systemIcon = systemIcon
        self.iconImage = iconImage
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                if let title = title {
                    Text(title)
                        .font(theme.typography.body)
                        .foregroundStyle(.primary)
                        //.frame(minWidth: 50)
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)  // 允许多行，不限制
                        .fixedSize(horizontal: false, vertical: true)
                        //.frame(minWidth: 150)
                }
            }

            Spacer()

            content
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconImage = iconImage {
            Image(nsImage: iconImage)
                .resizable()
                .frame(width: 28, height: 28)
        } else if let systemIcon = systemIcon, let iconColor = iconColor {
            Image(systemName: systemIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(iconColor)
                )
        }
    }
}

// MARK: - EDSCollapsibleSection

public struct EDSCollapsibleSection<Content: View>: View {
    @Environment(\.edsTheme) private var theme
    var title: String? = nil
    @State private var isExpanded = false
    @ViewBuilder let content: () -> Content

    public init(_ title: String?, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header - 可点击
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    if let title = title {
                        Text(title)
                            .font(theme.typography.sectionTitle)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded {
                if title != nil {
                    Divider()
                        .padding(.horizontal)
                }
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
    }
}
