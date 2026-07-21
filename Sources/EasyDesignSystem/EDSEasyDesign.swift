import SwiftUI

/// A semantic container scene supported by the Easy API.
public enum EDSEasyStyle: Sendable, CaseIterable {
    case page
    case content
    case section
    case group
    case card
    case plain
}

/// A semantic spacing value resolved from the current design tokens.
public enum EDSSpace: Sendable, CaseIterable {
    /// Use the selected style's recommended spacing.
    case automatic
    case none
    case xxs
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl
    case xxxl
}

/// Controls the maximum content width of an Easy style.
public enum EDSEasyWidth: Sendable, Equatable {
    /// Use the selected style's recommended width.
    case automatic
    /// Limit content to a concrete width.
    case fixed(CGFloat)
    /// Fill the available width.
    case unlimited
}

/// Controls whether a style draws its semantic background surface.
public enum EDSEasyVisibility: Sendable, Equatable {
    /// Use the selected style's recommended background policy.
    case automatic
    case visible
    case hidden
}

/// The small set of intentional overrides supported by the Easy API.
public struct EDSEasyOptions: Sendable, Equatable {
    public var padding: EDSSpace
    public var maxContentWidth: EDSEasyWidth
    public var background: EDSEasyVisibility

    public init(
        padding: EDSSpace = .automatic,
        maxContentWidth: EDSEasyWidth = .automatic,
        background: EDSEasyVisibility = .automatic
    ) {
        self.padding = padding
        self.maxContentWidth = maxContentWidth
        self.background = background
    }
}

extension EDSSpace {
    func resolve(in spacing: EDSSpacingTokens) -> CGFloat? {
        switch self {
        case .automatic: nil
        case .none: 0
        case .xxs: spacing.xxs
        case .xs: spacing.xs
        case .sm: spacing.sm
        case .md: spacing.md
        case .lg: spacing.lg
        case .xl: spacing.xl
        case .xxl: spacing.xxl
        case .xxxl: spacing.xxxl
        }
    }
}

enum EDSEasyPaddingAxis: Equatable {
    case all
    case vertical
}

enum EDSEasyResolvedWidth: Equatable {
    case unchanged
    case fixed(CGFloat)
    case fill
}

enum EDSEasyBackgroundPolicy: Equatable {
    case inherited
    case page
    case subtle
    case card
}

/// Internal, pure-value mapping from a semantic scene to concrete layout rules.
struct EDSEasyRecipe: Equatable {
    let padding: CGFloat
    let paddingAxis: EDSEasyPaddingAxis
    let width: EDSEasyResolvedWidth
    let background: EDSEasyBackgroundPolicy
    let cornerRadius: CGFloat
    let showsBorder: Bool
    let showsShadow: Bool

    static func resolve(
        style: EDSEasyStyle,
        options: EDSEasyOptions = EDSEasyOptions(),
        tokens: EDSDesignTokens
    ) -> EDSEasyRecipe {
        var recipe = base(style: style, tokens: tokens)

        if let padding = options.padding.resolve(in: tokens.spacing) {
            recipe = recipe.replacing(
                padding: padding,
                paddingAxis: .all
            )
        }

        switch options.maxContentWidth {
        case .automatic:
            break
        case .fixed(let width):
            recipe = recipe.replacing(width: .fixed(max(0, width)))
        case .unlimited:
            recipe = recipe.replacing(width: .fill)
        }

        switch options.background {
        case .automatic:
            break
        case .visible:
            if recipe.background == .inherited {
                recipe = recipe.replacing(background: .page)
            }
        case .hidden:
            recipe = recipe.replacing(background: .inherited)
        }

        return recipe
    }

    private static func base(style: EDSEasyStyle, tokens: EDSDesignTokens) -> EDSEasyRecipe {
        switch style {
        case .page:
            EDSEasyRecipe(
                padding: tokens.spacing.xxl,
                paddingAxis: .all,
                width: .fixed(880),
                background: .inherited,
                cornerRadius: 0,
                showsBorder: false,
                showsShadow: false
            )
        case .content:
            EDSEasyRecipe(
                padding: tokens.spacing.md,
                paddingAxis: .all,
                width: .fill,
                background: .inherited,
                cornerRadius: 0,
                showsBorder: false,
                showsShadow: false
            )
        case .section:
            EDSEasyRecipe(
                padding: tokens.spacing.xs,
                paddingAxis: .vertical,
                width: .fill,
                background: .inherited,
                cornerRadius: 0,
                showsBorder: false,
                showsShadow: false
            )
        case .group:
            EDSEasyRecipe(
                padding: tokens.spacing.lg,
                paddingAxis: .all,
                width: .fill,
                background: .subtle,
                cornerRadius: tokens.radius.md,
                showsBorder: false,
                showsShadow: false
            )
        case .card:
            EDSEasyRecipe(
                padding: tokens.spacing.lg,
                paddingAxis: .all,
                width: .fill,
                background: .card,
                cornerRadius: tokens.radius.md,
                showsBorder: true,
                showsShadow: true
            )
        case .plain:
            EDSEasyRecipe(
                padding: 0,
                paddingAxis: .all,
                width: .unchanged,
                background: .inherited,
                cornerRadius: 0,
                showsBorder: false,
                showsShadow: false
            )
        }
    }

    private func replacing(
        padding: CGFloat? = nil,
        paddingAxis: EDSEasyPaddingAxis? = nil,
        width: EDSEasyResolvedWidth? = nil,
        background: EDSEasyBackgroundPolicy? = nil
    ) -> EDSEasyRecipe {
        EDSEasyRecipe(
            padding: padding ?? self.padding,
            paddingAxis: paddingAxis ?? self.paddingAxis,
            width: width ?? self.width,
            background: background ?? self.background,
            cornerRadius: cornerRadius,
            showsBorder: showsBorder,
            showsShadow: showsShadow
        )
    }
}

private struct EDSEasyDesignModifier: ViewModifier {
    @Environment(\.edsTheme) private var inheritedTokens

    let style: EDSEasyStyle
    let options: EDSEasyOptions
    let localTokens: EDSDesignTokens?

    func body(content: Content) -> some View {
        let tokens = localTokens ?? inheritedTokens
        let recipe = EDSEasyRecipe.resolve(style: style, options: options, tokens: tokens)

        content
            .modifier(EDSEasyPaddingModifier(recipe: recipe))
            .modifier(EDSEasyWidthModifier(width: recipe.width))
            .modifier(EDSEasySurfaceModifier(recipe: recipe, tokens: tokens))
            .environment(\.edsTheme, tokens)
            .tint(tokens.colors.accent)
            .font(tokens.typography.body)
            .foregroundStyle(tokens.colors.textPrimary)
    }
}

private struct EDSEasyPaddingModifier: ViewModifier {
    let recipe: EDSEasyRecipe

    @ViewBuilder
    func body(content: Content) -> some View {
        if recipe.padding == 0 {
            content
        } else {
            switch recipe.paddingAxis {
            case .all:
                content.padding(recipe.padding)
            case .vertical:
                content.padding(.vertical, recipe.padding)
            }
        }
    }
}

private struct EDSEasyWidthModifier: ViewModifier {
    let width: EDSEasyResolvedWidth

    @ViewBuilder
    func body(content: Content) -> some View {
        switch width {
        case .unchanged:
            content
        case .fixed(let width):
            content
                .frame(maxWidth: width, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
        case .fill:
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct EDSEasySurfaceModifier: ViewModifier {
    let recipe: EDSEasyRecipe
    let tokens: EDSDesignTokens

    @ViewBuilder
    func body(content: Content) -> some View {
        switch recipe.background {
        case .inherited:
            content
        case .page:
            surface(content: content, color: tokens.colors.pageBackground)
        case .subtle:
            surface(content: content, color: tokens.colors.subtleFill)
        case .card:
            surface(content: content, color: tokens.colors.cardBackground)
        }
    }

    private func surface(content: Content, color: Color) -> some View {
        content.edsSurface(
            EDSSurfaceConfiguration(
                background: AnyShapeStyle(color),
                cornerRadius: recipe.cornerRadius,
                borderColor: recipe.showsBorder ? tokens.colors.border : nil,
                borderWidth: recipe.showsBorder ? tokens.stroke.hairline : 0,
                shadow: recipe.showsShadow ? tokens.shadow : nil
            )
        )
    }
}

public extension View {
    /// Applies the recommended EasyDesignSystem page styling by default.
    func easyDesign(
        _ style: EDSEasyStyle = .page,
        options: EDSEasyOptions = EDSEasyOptions()
    ) -> some View {
        modifier(EDSEasyDesignModifier(style: style, options: options, localTokens: nil))
    }

    /// Applies an Easy style and a preset theme to this view subtree.
    func easyDesign(
        _ style: EDSEasyStyle = .page,
        theme: EDSPresetTheme,
        options: EDSEasyOptions = EDSEasyOptions()
    ) -> some View {
        modifier(EDSEasyDesignModifier(style: style, options: options, localTokens: theme.tokens))
    }

    /// Applies an Easy style and concrete design tokens to this view subtree.
    func easyDesign(
        _ style: EDSEasyStyle = .page,
        tokens: EDSDesignTokens,
        options: EDSEasyOptions = EDSEasyOptions()
    ) -> some View {
        modifier(EDSEasyDesignModifier(style: style, options: options, localTokens: tokens))
    }
}
