import Foundation
import SwiftUI

public struct EDSToneSet: Codable, Equatable, Sendable {
    public var foreground: Double
    public var surface: Double
    public var strong: Double
    public var border: Double
    public var onStrong: Double
}

public struct EDSInteractionToneStyle: Codable, Equatable, Sendable {
    public var lightBase: Double
    public var darkBase: Double
    public var lightHoveredDelta: Double
    public var darkHoveredDelta: Double
    public var lightPressedDelta: Double
    public var darkPressedDelta: Double
}

/// Text/icon foreground roles that a color style may override.
public enum EDSContentColorRole: String, Codable, CaseIterable, Sendable {
    case foregroundPrimary, foregroundSecondary, foregroundTertiary, foregroundDisabled, foregroundInverse
    case brandOnStrong, informationOnStrong, successOnStrong, warningOnStrong, dangerOnStrong

    var semanticRole: EDSSemanticColorRole { EDSSemanticColorRole(rawValue: rawValue)! }
}

/// Optional fixed content colors supplied by a style. Missing roles keep using
/// colors generated from the seed and tonal palette.
public struct EDSContentColorOverrides: Codable, Equatable, Sendable {
    public var light: [EDSContentColorRole: String]
    public var dark: [EDSContentColorRole: String]

    public init(light: [EDSContentColorRole: String] = [:], dark: [EDSContentColorRole: String] = [:]) {
        self.light = light
        self.dark = dark
    }

    public func color(for role: EDSContentColorRole, brightness: EDSBrightness) -> Color? {
        (brightness == .light ? light : dark)[role].map(Color.init(hexRGB:))
    }

    private enum CodingKeys: String, CodingKey { case light, dark }
    private struct RoleKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func decode(_ key: CodingKeys) throws -> [EDSContentColorRole: String] {
            guard container.contains(key) else { return [:] }
            let values = try container.nestedContainer(keyedBy: RoleKey.self, forKey: key)
            var result: [EDSContentColorRole: String] = [:]
            for key in values.allKeys {
                guard let role = EDSContentColorRole(rawValue: key.stringValue) else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: values, debugDescription: "Unsupported content color role: \(key.stringValue)")
                }
                let value = try values.decode(String.self, forKey: key)
                guard value.range(of: #"^#[0-9A-Fa-f]{6}$"#, options: .regularExpression) != nil else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: values, debugDescription: "Expected #RRGGBB for \(key.stringValue).")
                }
                result[role] = value.uppercased()
            }
            return result
        }
        light = try decode(.light)
        dark = try decode(.dark)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        func encode(_ values: [EDSContentColorRole: String], for key: CodingKeys) throws {
            guard !values.isEmpty else { return }
            var nested = container.nestedContainer(keyedBy: RoleKey.self, forKey: key)
            for (role, value) in values {
                try nested.encode(value, forKey: RoleKey(stringValue: role.rawValue)!)
            }
        }
        try encode(light, for: .light)
        try encode(dark, for: .dark)
    }
}

/// JSON-backed visual personality applied to the same perceptual tonal palettes.
public struct EDSColorStyle: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var light: EDSToneSet
    public var dark: EDSToneSet
    public var strongInteraction: EDSInteractionToneStyle
    public var softInteraction: EDSInteractionToneStyle
    public var mediumInteraction: EDSInteractionToneStyle
    public var contentColors: EDSContentColorOverrides?

    public static let `default` = loadBuiltIn("EDSDefaultColorStyle")
    public static let vivid = loadBuiltIn("EDSVividColorStyle")
    public static let elegant = loadBuiltIn("EDSElegantColorStyle")
    public static let allBuiltIn: [EDSColorStyle] = [.default, .vivid, .elegant]

    public static func builtIn(id: String) throws -> EDSColorStyle {
        guard let style = allBuiltIn.first(where: { $0.id == id }) else {
            throw EDSColorStyleError.unknownStyle(id)
        }
        return style
    }

    public static func load(jsonData: Data) throws -> EDSColorStyle {
        try JSONDecoder().decode(EDSColorStyle.self, from: jsonData)
    }

    public static func load(jsonFileURL url: URL) throws -> EDSColorStyle {
        try load(jsonData: Data(contentsOf: url))
    }

    public static func load(jsonResource name: String, bundle: Bundle = .main) throws -> EDSColorStyle {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw EDSColorStyleError.resourceNotFound(name)
        }
        return try load(jsonFileURL: url)
    }

    private static func loadBuiltIn(_ name: String) -> EDSColorStyle {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let style = try? JSONDecoder().decode(EDSColorStyle.self, from: data) else {
            preconditionFailure("Missing or invalid built-in color style: \(name).json")
        }
        return style
    }
}

public enum EDSColorStyleError: LocalizedError {
    case unknownStyle(String)
    case resourceNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .unknownStyle(let id): "Unknown EDS color style: \(id)"
        case .resourceNotFound(let name): "Color style resource not found: \(name).json"
        }
    }
}
