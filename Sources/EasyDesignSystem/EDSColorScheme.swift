import SwiftUI
import EDSMaterialColorUtilities

public enum EDSBrightness: String, Codable, Sendable { case light, dark }

public struct EDSColorSeeds: Codable, Equatable, Sendable {
    public var brand: Color
    public var information: Color
    public var success: Color
    public var warning: Color
    public var danger: Color

    public init(
        brand: Color = Color(hexRGB: "#3185FF"),
        information: Color = Color(hexRGB: "#3185FF"),
        success: Color = Color(hexRGB: "#27B15A"),
        warning: Color = Color(hexRGB: "#F9B135"),
        danger: Color = Color(hexRGB: "#E54444")
    ) {
        self.brand = brand; self.information = information; self.success = success
        self.warning = warning; self.danger = danger
    }

    private enum CodingKeys: String, CodingKey { case brand, information, success, warning, danger }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = EDSColorSeeds()
        brand = Color(hexRGB: try c.decodeIfPresent(String.self, forKey: .brand) ?? d.brand.toHex())
        information = Color(hexRGB: try c.decodeIfPresent(String.self, forKey: .information) ?? d.information.toHex())
        success = Color(hexRGB: try c.decodeIfPresent(String.self, forKey: .success) ?? d.success.toHex())
        warning = Color(hexRGB: try c.decodeIfPresent(String.self, forKey: .warning) ?? d.warning.toHex())
        danger = Color(hexRGB: try c.decodeIfPresent(String.self, forKey: .danger) ?? d.danger.toHex())
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(brand.toHex(), forKey: .brand); try c.encode(information.toHex(), forKey: .information)
        try c.encode(success.toHex(), forKey: .success); try c.encode(warning.toHex(), forKey: .warning)
        try c.encode(danger.toHex(), forKey: .danger)
    }
}

public struct EDSColorSeedOverrides: Equatable, Sendable {
    public var brand, information, success, warning, danger: Color?
    public init(brand: Color? = nil, information: Color? = nil, success: Color? = nil, warning: Color? = nil, danger: Color? = nil) {
        self.brand = brand; self.information = information; self.success = success; self.warning = warning; self.danger = danger
    }
    public var isEmpty: Bool { brand == nil && information == nil && success == nil && warning == nil && danger == nil }
}

public extension EDSColorSeeds {
    func applying(_ patch: EDSColorSeedOverrides) -> EDSColorSeeds {
        EDSColorSeeds(
            brand: patch.brand ?? brand,
            information: patch.information ?? information,
            success: patch.success ?? success,
            warning: patch.warning ?? warning,
            danger: patch.danger ?? danger
        )
    }
}

public struct EDSFamilyToneMap: Equatable, Sendable {
    public let foreground, surface, strong, border, onStrong: Double
    public static let light = EDSFamilyToneMap(foreground: 35, surface: 95, strong: 40, border: 55, onStrong: 100)
    public static let dark = EDSFamilyToneMap(foreground: 85, surface: 20, strong: 80, border: 60, onStrong: 10)
}

public enum EDSSemanticColorRole: String, Codable, CaseIterable, Sendable {
    case surfacePage, surfaceBase, surfaceRaised, surfaceSunken, surfaceOverlay, surfaceDisabled
    case foregroundPrimary, foregroundSecondary, foregroundTertiary, foregroundDisabled, foregroundInverse
    case borderSubtle, borderDefault, borderStrong, borderSelected, borderFocus, borderDisabled, borderDanger
    case brandForeground, brandSurface, brandSurfaceStrong, brandBorder, brandOnStrong
    case informationForeground, informationSurface, informationSurfaceStrong, informationBorder, informationOnStrong
    case successForeground, successSurface, successSurfaceStrong, successBorder, successOnStrong
    case warningForeground, warningSurface, warningSurfaceStrong, warningBorder, warningOnStrong
    case dangerForeground, dangerSurface, dangerSurfaceStrong, dangerBorder, dangerOnStrong
}

public struct EDSSemanticColorOverrides: Codable, Equatable, Sendable {
    public var light: [EDSSemanticColorRole: String]
    public var dark: [EDSSemanticColorRole: String]
    public init(light: [EDSSemanticColorRole: String] = [:], dark: [EDSSemanticColorRole: String] = [:]) {
        self.light = light; self.dark = dark
    }
    public func color(for role: EDSSemanticColorRole, brightness: EDSBrightness) -> Color? {
        let value = (brightness == .light ? light : dark)[role]
        return value.map(Color.init(hexRGB:))
    }

    private enum CodingKeys: String, CodingKey { case light, dark }
    private struct RoleKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func decode(_ key: CodingKeys) throws -> [EDSSemanticColorRole: String] {
            guard c.contains(key) else { return [:] }
            let nested = try c.nestedContainer(keyedBy: RoleKey.self, forKey: key)
            var result: [EDSSemanticColorRole: String] = [:]
            for rawKey in nested.allKeys {
                guard let role = EDSSemanticColorRole(rawValue: rawKey.stringValue) else { continue }
                let value = try nested.decode(String.self, forKey: rawKey)
                guard value.range(of: #"^#[0-9A-Fa-f]{6}$"#, options: .regularExpression) != nil else {
                    throw DecodingError.dataCorruptedError(forKey: rawKey, in: nested, debugDescription: "Expected #RRGGBB for \(rawKey.stringValue).")
                }
                result[role] = value.uppercased()
            }
            return result
        }
        light = try decode(.light); dark = try decode(.dark)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        func encode(_ values: [EDSSemanticColorRole: String], key: CodingKeys) throws {
            guard !values.isEmpty else { return }
            var nested = c.nestedContainer(keyedBy: RoleKey.self, forKey: key)
            for (role, value) in values {
                try nested.encode(value, forKey: RoleKey(stringValue: role.rawValue)!)
            }
        }
        try encode(light, key: .light); try encode(dark, key: .dark)
    }
}

public struct EDSSemanticColors: Equatable, Sendable {
    public let values: [EDSSemanticColorRole: Color]
    public subscript(_ role: EDSSemanticColorRole) -> Color { values[role] ?? .clear }
    public var surfacePage: Color { self[.surfacePage] }; public var surfaceBase: Color { self[.surfaceBase] }
    public var surfaceRaised: Color { self[.surfaceRaised] }; public var surfaceSunken: Color { self[.surfaceSunken] }
    public var surfaceOverlay: Color { self[.surfaceOverlay] }; public var surfaceDisabled: Color { self[.surfaceDisabled] }
    public var foregroundPrimary: Color { self[.foregroundPrimary] }; public var foregroundSecondary: Color { self[.foregroundSecondary] }
    public var foregroundTertiary: Color { self[.foregroundTertiary] }; public var foregroundDisabled: Color { self[.foregroundDisabled] }
    public var foregroundInverse: Color { self[.foregroundInverse] }
    public var borderSubtle: Color { self[.borderSubtle] }; public var borderDefault: Color { self[.borderDefault] }
    public var borderStrong: Color { self[.borderStrong] }; public var borderSelected: Color { self[.borderSelected] }
    public var borderFocus: Color { self[.borderFocus] }; public var borderDisabled: Color { self[.borderDisabled] }
    public var borderDanger: Color { self[.borderDanger] }
    public var brandForeground: Color { self[.brandForeground] }; public var brandSurface: Color { self[.brandSurface] }
    public var brandSurfaceStrong: Color { self[.brandSurfaceStrong] }; public var brandBorder: Color { self[.brandBorder] }
    public var brandOnStrong: Color { self[.brandOnStrong] }
    public var informationForeground: Color { self[.informationForeground] }; public var informationSurface: Color { self[.informationSurface] }
    public var informationSurfaceStrong: Color { self[.informationSurfaceStrong] }; public var informationBorder: Color { self[.informationBorder] }
    public var informationOnStrong: Color { self[.informationOnStrong] }
    public var successForeground: Color { self[.successForeground] }; public var successSurface: Color { self[.successSurface] }
    public var successSurfaceStrong: Color { self[.successSurfaceStrong] }; public var successBorder: Color { self[.successBorder] }
    public var successOnStrong: Color { self[.successOnStrong] }
    public var warningForeground: Color { self[.warningForeground] }; public var warningSurface: Color { self[.warningSurface] }
    public var warningSurfaceStrong: Color { self[.warningSurfaceStrong] }; public var warningBorder: Color { self[.warningBorder] }
    public var warningOnStrong: Color { self[.warningOnStrong] }
    public var dangerForeground: Color { self[.dangerForeground] }; public var dangerSurface: Color { self[.dangerSurface] }
    public var dangerSurfaceStrong: Color { self[.dangerSurfaceStrong] }; public var dangerBorder: Color { self[.dangerBorder] }
    public var dangerOnStrong: Color { self[.dangerOnStrong] }
}

public enum EDSColorResolver {
    public static func resolve(
        seeds: EDSColorSeeds = EDSColorSeeds(),
        overrides: EDSSemanticColorOverrides = EDSSemanticColorOverrides(),
        style: EDSColorStyle = .default,
        brightness: EDSBrightness
    ) -> EDSSemanticColors {
        let dark = brightness == .dark
        var v: [EDSSemanticColorRole: Color] = [:]
        let neutralLight: [EDSSemanticColorRole: String] = [
            .surfacePage:"#F7F7F7", .surfaceBase:"#FFFFFF", .surfaceRaised:"#FFFFFF", .surfaceSunken:"#F1F1F2", .surfaceOverlay:"#FFFFFF", .surfaceDisabled:"#F0F0F1",
            .foregroundPrimary:"#111113", .foregroundSecondary:"#626267", .foregroundTertiary:"#6C6C72", .foregroundDisabled:"#B3B3B8", .foregroundInverse:"#FFFFFF",
            .borderSubtle:"#E7E7E9", .borderDefault:"#D7D7DA", .borderStrong:"#8A8A90", .borderDisabled:"#E4E4E6"
        ]
        let neutralDark: [EDSSemanticColorRole: String] = [
            .surfacePage:"#1E1E20", .surfaceBase:"#242426", .surfaceRaised:"#2A2A2C", .surfaceSunken:"#18181A", .surfaceOverlay:"#303034", .surfaceDisabled:"#27272A",
            .foregroundPrimary:"#F5F5F6", .foregroundSecondary:"#B6B6BC", .foregroundTertiary:"#97979F", .foregroundDisabled:"#66666D", .foregroundInverse:"#111113",
            .borderSubtle:"#333337", .borderDefault:"#44444A", .borderStrong:"#76767E", .borderDisabled:"#343438"
        ]
        for (role, hex) in dark ? neutralDark : neutralLight { v[role] = Color(hexRGB: hex) }
        func family(_ seed: Color, _ prefix: String) {
            let argb = argbValue(seed)
            let tones = dark ? style.dark : style.light
            let roles = EDSSemanticColorRole.allCases.filter { $0.rawValue.hasPrefix(prefix) }
            let suffixTone: [String: Double] = ["Foreground":tones.foreground, "Surface":tones.surface, "SurfaceStrong":tones.strong, "Border":tones.border, "OnStrong":tones.onStrong]
            for role in roles {
                if let match = suffixTone.first(where: { role.rawValue == prefix + $0.key }) {
                    v[role] = color(argb: EDSColorPalette.tone(seedARGB: argb, tone: match.value))
                }
            }
        }
        family(seeds.brand, "brand"); family(seeds.information, "information"); family(seeds.success, "success")
        family(seeds.warning, "warning"); family(seeds.danger, "danger")
        v[.borderSelected] = v[.brandBorder]; v[.borderFocus] = v[.brandForeground]; v[.borderDanger] = v[.dangerBorder]
        if let contentColors = style.contentColors {
            for role in EDSContentColorRole.allCases {
                if let color = contentColors.color(for: role, brightness: brightness) {
                    v[role.semanticRole] = color
                }
            }
        }
        for role in EDSSemanticColorRole.allCases { if let override = overrides.color(for: role, brightness: brightness) { v[role] = override } }
        return EDSSemanticColors(values: v)
    }

    private static func argbValue(_ color: Color) -> Int {
        let hex = color.toHex().dropFirst(); return Int("FF" + hex, radix: 16) ?? 0xFF000000
    }
    private static func color(argb: Int) -> Color {
        Color(hexRGB: String(format: "#%06X", argb & 0xFFFFFF))
    }
}

public enum EDSInteractionState: Sendable { case rest, hovered, pressed }
public enum EDSInteractionColorFamily: Sendable { case brand, information, success, warning, danger }

public enum EDSInteractionResolver {
    public static func strongSurface(family: EDSInteractionColorFamily, seeds: EDSColorSeeds, style: EDSColorStyle = .default, brightness: EDSBrightness, state: EDSInteractionState) -> Color {
        resolve(family: family, seeds: seeds, brightness: brightness, state: state, style: style.strongInteraction)
    }
    public static func softSurface(family: EDSInteractionColorFamily, seeds: EDSColorSeeds, style: EDSColorStyle = .default, brightness: EDSBrightness, state: EDSInteractionState) -> Color {
        resolve(family: family, seeds: seeds, brightness: brightness, state: state, style: style.softInteraction)
    }
    public static func mediumSurface(family: EDSInteractionColorFamily, seeds: EDSColorSeeds, style: EDSColorStyle = .default, brightness: EDSBrightness, state: EDSInteractionState) -> Color {
        resolve(family: family, seeds: seeds, brightness: brightness, state: state, style: style.mediumInteraction)
    }
    public static func neutralStrongSurface(brightness: EDSBrightness, state: EDSInteractionState) -> Color {
        let light = ["#333338", "#29292D", "#202024"], dark = ["#E4E4E7", "#D8D8DC", "#CBCBD0"]
        return Color(hexRGB: (brightness == .dark ? dark : light)[state.index])
    }
    public static func neutralSurface(brightness: EDSBrightness, state: EDSInteractionState) -> Color {
        let light = ["#FFFFFF", "#F2F2F3", "#EAEAEC"], dark = ["#242426", "#2D2D30", "#35353A"]
        return Color(hexRGB: (brightness == .dark ? dark : light)[state.index])
    }
    private static func resolve(family: EDSInteractionColorFamily, seeds: EDSColorSeeds, brightness: EDSBrightness, state: EDSInteractionState, style: EDSInteractionToneStyle) -> Color {
        let seed: Color = switch family { case .brand: seeds.brand; case .information: seeds.information; case .success: seeds.success; case .warning: seeds.warning; case .danger: seeds.danger }
        let base = brightness == .dark ? style.darkBase : style.lightBase
        let delta = switch state { case .rest: 0.0; case .hovered: brightness == .dark ? style.darkHoveredDelta : style.lightHoveredDelta; case .pressed: brightness == .dark ? style.darkPressedDelta : style.lightPressedDelta }
        let hex = seed.toHex().dropFirst(); let argb = Int("FF" + hex, radix: 16) ?? 0xFF000000
        return Color(hexRGB: String(format: "#%06X", EDSColorPalette.tone(seedARGB: argb, tone: min(100, max(0, base + delta))) & 0xFFFFFF))
    }
}

private extension EDSInteractionState { var index: Int { switch self { case .rest: 0; case .hovered: 1; case .pressed: 2 } } }

public enum EDSLayer: Sendable { case base, raised, nested, overlay }
public enum EDSLayerResolver {
    public static func surface(_ layer: EDSLayer, colors: EDSSemanticColors) -> Color { switch layer { case .base: colors.surfacePage; case .raised: colors.surfaceRaised; case .nested: colors.surfaceSunken; case .overlay: colors.surfaceOverlay } }
    public static func fieldSurface(_ layer: EDSLayer, colors: EDSSemanticColors) -> Color { switch layer { case .raised: colors.surfaceSunken; default: colors.surfaceBase } }
    public static func border(_ layer: EDSLayer, colors: EDSSemanticColors) -> Color { switch layer { case .base: colors.borderSubtle; case .overlay: colors.borderStrong; default: colors.borderDefault } }
    public static func nestedChild(of layer: EDSLayer) -> EDSLayer { switch layer { case .base: .raised; case .raised, .nested: .nested; case .overlay: .overlay } }
}

private struct EDSLayerEnvironmentKey: EnvironmentKey { static let defaultValue: EDSLayer = .base }
public extension EnvironmentValues {
    var edsLayer: EDSLayer {
        get { self[EDSLayerEnvironmentKey.self] }
        set { self[EDSLayerEnvironmentKey.self] = newValue }
    }
}
public extension View {
    func edsLayer(_ layer: EDSLayer) -> some View { environment(\.edsLayer, layer) }
}

public enum EDSColorContrast {
    /// WCAG 2.x contrast ratio in the range 1...21.
    public static func ratio(_ foreground: Color, _ background: Color) -> Double {
        let a = luminance(foreground), b = luminance(background)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
    private static func luminance(_ color: Color) -> Double {
        let hex = color.toHex().dropFirst()
        guard let value = Int(hex, radix: 16) else { return 0 }
        func channel(_ shift: Int) -> Double {
            let raw = Double((value >> shift) & 0xFF) / 255
            return raw <= 0.04045 ? raw / 12.92 : pow((raw + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }
}
