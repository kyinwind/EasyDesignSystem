import SwiftUI

/// Complete host-configurable theme. Chromatic seeds are deliberately kept
/// separate from non-color design tokens; semantic colors are resolved at use.
public struct EDSThemeData: Codable, Equatable, Sendable {
    public var seeds: EDSColorSeeds
    public var semanticOverrides: EDSSemanticColorOverrides
    public var colorStyle: EDSColorStyle
    public var tokens: EDSDesignTokens

    public init(
        seeds: EDSColorSeeds = EDSColorSeeds(),
        semanticOverrides: EDSSemanticColorOverrides = EDSSemanticColorOverrides(),
        colorStyle: EDSColorStyle = .default,
        tokens: EDSDesignTokens = EDSDesignTokens()
    ) {
        self.seeds = seeds; self.semanticOverrides = semanticOverrides; self.colorStyle = colorStyle; self.tokens = tokens
    }

    public func resolvedColors(for brightness: EDSBrightness) -> EDSSemanticColors {
        EDSColorResolver.resolve(seeds: seeds, overrides: semanticOverrides, style: colorStyle, brightness: brightness)
    }

    public func withSeedOverrides(_ overrides: EDSColorSeedOverrides) -> EDSThemeData {
        var copy = self
        copy.seeds = seeds.applying(overrides)
        return copy
    }

    /// Adaptive compatibility facade used by existing EDS components. Every
    /// value maps to a ColorScheme 2.0 semantic role and follows appearance.
    public var colors: EDSAdaptiveColors {
        EDSAdaptiveColors(light: resolvedColors(for: .light), dark: resolvedColors(for: .dark))
    }

    public var spacing: EDSSpacingTokens { get { tokens.spacing } set { tokens.spacing = newValue } }
    public var radius: EDSRadiusTokens { get { tokens.radius } set { tokens.radius = newValue } }
    public var typography: EDSTypographyTokens { get { tokens.typography } set { tokens.typography = newValue } }
    public var controlSize: EDSControlSizeTokens { get { tokens.controlSize } set { tokens.controlSize = newValue } }
    public var adaptiveLayout: EDSAdaptiveLayoutTokens { get { tokens.adaptiveLayout } set { tokens.adaptiveLayout = newValue } }
    public var heroGradient: EDSHeroGradient { get { tokens.heroGradient } set { tokens.heroGradient = newValue } }
    public var stroke: EDSStrokeTokens { get { tokens.stroke } set { tokens.stroke = newValue } }
    public var shadow: EDSShadowTokens { get { tokens.shadow } set { tokens.shadow = newValue } }

    private struct ColorBranch: Codable {
        var seeds = EDSColorSeeds()
        var semanticOverrides = EDSSemanticColorOverrides()
        var style = EDSColorStyle.default
        private enum CodingKeys: String, CodingKey { case seeds, semanticOverrides, style, primary, accent, success, warning, danger }
        init() {}
        init(seeds: EDSColorSeeds, semanticOverrides: EDSSemanticColorOverrides, style: EDSColorStyle) { self.seeds = seeds; self.semanticOverrides = semanticOverrides; self.style = style }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            if !c.contains(.seeds) && ([CodingKeys.primary, .accent, .success, .warning, .danger].contains { c.contains($0) }) {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Legacy colors schema is not supported. Use colors.seeds.*."))
            }
            seeds = try c.decodeIfPresent(EDSColorSeeds.self, forKey: .seeds) ?? EDSColorSeeds()
            semanticOverrides = try c.decodeIfPresent(EDSSemanticColorOverrides.self, forKey: .semanticOverrides) ?? EDSSemanticColorOverrides()
            if let id = try c.decodeIfPresent(String.self, forKey: .style) { style = try EDSColorStyle.builtIn(id: id) }
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(seeds, forKey: .seeds)
            try c.encode(style.id, forKey: .style)
            if !semanticOverrides.light.isEmpty || !semanticOverrides.dark.isEmpty { try c.encode(semanticOverrides, forKey: .semanticOverrides) }
        }
    }

    private enum CodingKeys: String, CodingKey { case colors, spacing, radius, typography, controlSize, adaptiveLayout, heroGradient, stroke, shadow }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let colors = try c.decodeIfPresent(ColorBranch.self, forKey: .colors) ?? ColorBranch()
        seeds = colors.seeds; semanticOverrides = colors.semanticOverrides; colorStyle = colors.style
        var t = EDSDesignTokens()
        t.spacing = try c.decodeIfPresent(EDSSpacingTokens.self, forKey: .spacing) ?? t.spacing
        t.radius = try c.decodeIfPresent(EDSRadiusTokens.self, forKey: .radius) ?? t.radius
        t.typography = try c.decodeIfPresent(EDSTypographyTokens.self, forKey: .typography) ?? t.typography
        t.controlSize = try c.decodeIfPresent(EDSControlSizeTokens.self, forKey: .controlSize) ?? t.controlSize
        t.adaptiveLayout = try c.decodeIfPresent(EDSAdaptiveLayoutTokens.self, forKey: .adaptiveLayout) ?? t.adaptiveLayout
        t.heroGradient = try c.decodeIfPresent(EDSHeroGradient.self, forKey: .heroGradient) ?? t.heroGradient
        t.stroke = try c.decodeIfPresent(EDSStrokeTokens.self, forKey: .stroke) ?? t.stroke
        t.shadow = try c.decodeIfPresent(EDSShadowTokens.self, forKey: .shadow) ?? t.shadow
        tokens = t
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(ColorBranch(seeds: seeds, semanticOverrides: semanticOverrides, style: colorStyle), forKey: .colors)
        try c.encode(spacing, forKey: .spacing); try c.encode(radius, forKey: .radius); try c.encode(typography, forKey: .typography)
        try c.encode(controlSize, forKey: .controlSize); try c.encode(adaptiveLayout, forKey: .adaptiveLayout)
        try c.encode(heroGradient, forKey: .heroGradient); try c.encode(stroke, forKey: .stroke); try c.encode(shadow, forKey: .shadow)
    }
}

public struct EDSResolvedTheme: Equatable, Sendable {
    public let colors: EDSSemanticColors
    public let tokens: EDSDesignTokens
}

public enum EDSThemeResolver {
    public static func resolve(_ theme: EDSThemeData, brightness: EDSBrightness) -> EDSResolvedTheme {
        EDSResolvedTheme(colors: theme.resolvedColors(for: brightness), tokens: theme.tokens)
    }
}

public struct EDSAdaptiveColors: Sendable {
    public let primary, primarySoft, accentSoft, success, successSoft, warning, warningSoft, danger, dangerSoft: Color
    public let textPrimary, textSecondary, textTertiary, pageBackground, cardBackground, cardGrayBackground, subtleFill, border: Color
    init(light: EDSSemanticColors, dark: EDSSemanticColors) {
        func adaptive(_ light: Color, _ dark: Color) -> Color { Color.edsAdaptive(light: light, dark: dark) }
        primary = adaptive(light.brandForeground, dark.brandForeground)
        primarySoft = adaptive(light.brandSurface, dark.brandSurface); accentSoft = primarySoft
        success = adaptive(light.successForeground, dark.successForeground); successSoft = adaptive(light.successSurface, dark.successSurface)
        warning = adaptive(light.warningForeground, dark.warningForeground); warningSoft = adaptive(light.warningSurface, dark.warningSurface)
        danger = adaptive(light.dangerForeground, dark.dangerForeground); dangerSoft = adaptive(light.dangerSurface, dark.dangerSurface)
        textPrimary = adaptive(light.foregroundPrimary, dark.foregroundPrimary)
        textSecondary = adaptive(light.foregroundSecondary, dark.foregroundSecondary)
        textTertiary = adaptive(light.foregroundTertiary, dark.foregroundTertiary)
        pageBackground = adaptive(light.surfacePage, dark.surfacePage)
        cardBackground = adaptive(light.surfaceRaised, dark.surfaceRaised)
        cardGrayBackground = adaptive(light.surfaceSunken, dark.surfaceSunken)
        subtleFill = adaptive(light.surfaceSunken, dark.surfaceSunken)
        border = adaptive(light.borderDefault, dark.borderDefault)
    }
}

private extension Color {
    static func edsAdaptive(light: Color, dark: Color) -> Color {
        #if os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
        #else
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #endif
    }
}
