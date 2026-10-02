import XCTest
import SwiftUI
@testable import EasyDesignSystem

final class EDSColorSchemeTests: XCTestCase {
    func testDefaultSeedsMatchFlutterColorScheme2() {
        let seeds = EDSColorSeeds()
        XCTAssertEqual(seeds.brand.toHex(), "#3185FF")
        XCTAssertEqual(seeds.information.toHex(), "#3185FF")
        XCTAssertEqual(seeds.success.toHex(), "#27B15A")
        XCTAssertEqual(seeds.warning.toHex(), "#F9B135")
        XCTAssertEqual(seeds.danger.toHex(), "#E54444")
    }

    func testChangingBrandSeedDoesNotChangeOtherFamilies() {
        let original = EDSColorResolver.resolve(brightness: .light)
        let changed = EDSColorResolver.resolve(
            seeds: EDSColorSeeds(brand: Color(hexRGB: "#FF6B00")),
            brightness: .light
        )
        XCTAssertNotEqual(changed.brandForeground.toHex(), original.brandForeground.toHex())
        XCTAssertEqual(changed.successForeground.toHex(), original.successForeground.toHex())
        XCTAssertEqual(changed.warningSurface.toHex(), original.warningSurface.toHex())
        XCTAssertEqual(changed.dangerBorder.toHex(), original.dangerBorder.toHex())
    }

    func testBrightnessSpecificOverrideOnlyAffectsRequestedRole() {
        let overrides = EDSSemanticColorOverrides(
            light: [.borderFocus: "#123456"],
            dark: [.borderFocus: "#ABCDEF"]
        )
        let light = EDSColorResolver.resolve(overrides: overrides, brightness: .light)
        let dark = EDSColorResolver.resolve(overrides: overrides, brightness: .dark)
        XCTAssertEqual(light.borderFocus.toHex(), "#123456")
        XCTAssertEqual(dark.borderFocus.toHex(), "#ABCDEF")
        XCTAssertEqual(light.borderSelected.toHex(), light.brandBorder.toHex())
    }

    func testThemeJSONRoundTripUsesSeedsSchema() throws {
        let theme = EDSThemeData(
            seeds: EDSColorSeeds(brand: Color(hexRGB: "#FF6B00")),
            semanticOverrides: EDSSemanticColorOverrides(light: [.surfacePage: "#FAFAFA"]),
            colorStyle: .vivid
        )
        let data = try JSONEncoder().encode(theme)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let colors = try XCTUnwrap(object["colors"] as? [String: Any])
        XCTAssertNotNil(colors["seeds"])
        XCTAssertEqual(colors["style"] as? String, "vivid")
        XCTAssertNil(colors["primary"])
        let decoded = try JSONDecoder().decode(EDSThemeData.self, from: data)
        XCTAssertEqual(decoded.seeds.brand.toHex(), "#FF6B00")
        XCTAssertEqual(decoded.colorStyle.id, "vivid")
        XCTAssertEqual(decoded.resolvedColors(for: .light).surfacePage.toHex(), "#FAFAFA")
    }

    func testBuiltInStylesProduceDifferentOrangeStrongSurfaces() {
        let seeds = EDSColorSeeds(brand: Color(hexRGB: "#FF6B00"))
        let vivid = EDSColorResolver.resolve(seeds: seeds, style: .vivid, brightness: .dark)
        let balanced = EDSColorResolver.resolve(seeds: seeds, style: .default, brightness: .dark)
        let elegant = EDSColorResolver.resolve(seeds: seeds, style: .elegant, brightness: .dark)
        XCTAssertNotEqual(vivid.brandSurfaceStrong.toHex(), balanced.brandSurfaceStrong.toHex())
        XCTAssertNotEqual(balanced.brandSurfaceStrong.toHex(), elegant.brandSurfaceStrong.toHex())
    }

    func testCustomStyleLoadsFromJSON() throws {
        let data = try JSONEncoder().encode(EDSColorStyle.vivid)
        let style = try EDSColorStyle.load(jsonData: data)
        XCTAssertEqual(style, .vivid)
    }

    func testStyleContentColorsOverrideGeneratedForegrounds() throws {
        var style = EDSColorStyle.default
        style.contentColors = EDSContentColorOverrides(
            light: [.foregroundPrimary: "#123456", .brandOnStrong: "#FEDCBA"],
            dark: [.foregroundPrimary: "#ABCDEF"]
        )

        let light = EDSColorResolver.resolve(style: style, brightness: .light)
        let dark = EDSColorResolver.resolve(style: style, brightness: .dark)
        XCTAssertEqual(light.foregroundPrimary.toHex(), "#123456")
        XCTAssertEqual(light.brandOnStrong.toHex(), "#FEDCBA")
        XCTAssertEqual(dark.foregroundPrimary.toHex(), "#ABCDEF")
        XCTAssertEqual(dark.brandOnStrong.toHex(), EDSColorResolver.resolve(brightness: .dark).brandOnStrong.toHex())
    }

    func testThemeSemanticOverrideHasPriorityOverStyleContentColor() {
        var style = EDSColorStyle.default
        style.contentColors = EDSContentColorOverrides(light: [.foregroundPrimary: "#123456"])
        let colors = EDSColorResolver.resolve(
            overrides: EDSSemanticColorOverrides(light: [.foregroundPrimary: "#654321"]),
            style: style,
            brightness: .light
        )
        XCTAssertEqual(colors.foregroundPrimary.toHex(), "#654321")
    }

    func testStyleRejectsNonContentColorRole() throws {
        let encoded = try JSONEncoder().encode(EDSColorStyle.default)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["contentColors"] = ["light": ["surfacePage": "#FFFFFF"], "dark": [:]]
        let invalid = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try EDSColorStyle.load(jsonData: invalid))
    }

    func testLegacyColorJSONIsRejectedWithMigrationMessage() throws {
        let data = Data("{\"colors\":{\"primary\":\"#3185FF\"}}".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(EDSThemeData.self, from: data)) { error in
            XCTAssertTrue(String(describing: error).contains("colors.seeds"))
        }
    }

    func testLayerAndInteractionResolversMatchSpecification() {
        let colors = EDSColorResolver.resolve(brightness: .light)
        XCTAssertEqual(EDSLayerResolver.surface(.base, colors: colors), colors.surfacePage)
        XCTAssertEqual(EDSLayerResolver.fieldSurface(.raised, colors: colors), colors.surfaceSunken)
        XCTAssertEqual(EDSLayerResolver.border(.overlay, colors: colors), colors.borderStrong)
        XCTAssertEqual(EDSLayerResolver.nestedChild(of: .base), .raised)

        let rest = EDSInteractionResolver.strongSurface(family: .brand, seeds: EDSColorSeeds(), brightness: .light, state: .rest)
        let hover = EDSInteractionResolver.strongSurface(family: .brand, seeds: EDSColorSeeds(), brightness: .light, state: .hovered)
        let pressed = EDSInteractionResolver.strongSurface(family: .brand, seeds: EDSColorSeeds(), brightness: .light, state: .pressed)
        XCTAssertNotEqual(rest.toHex(), hover.toHex())
        XCTAssertNotEqual(hover.toHex(), pressed.toHex())
    }

    func testCoreTextContrastMeetsWCAGAA() {
        for style in EDSColorStyle.allBuiltIn {
            for brightness in [EDSBrightness.light, .dark] {
                let colors = EDSColorResolver.resolve(style: style, brightness: brightness)
                XCTAssertGreaterThanOrEqual(EDSColorContrast.ratio(colors.foregroundPrimary, colors.surfacePage), 4.5, style.id)
                XCTAssertGreaterThanOrEqual(EDSColorContrast.ratio(colors.brandOnStrong, colors.brandSurfaceStrong), 4.5, style.id)
                XCTAssertGreaterThanOrEqual(EDSColorContrast.ratio(colors.dangerOnStrong, colors.dangerSurfaceStrong), 4.5, style.id)
            }
        }
    }
}
