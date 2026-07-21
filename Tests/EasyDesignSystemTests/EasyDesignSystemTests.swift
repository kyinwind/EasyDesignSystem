import SwiftUI
import XCTest
@testable import EasyDesignSystem

@MainActor
final class EasyDesignSystemTests: XCTestCase {
    func testPublicEntrypointsCompile() throws {
        try EDSTheme.shared.applyDefaultThemeFromPackage()
        EDSTheme.shared.applyPreset(.orange)
        EDSTheme.shared.configure { tokens in
            tokens.colors.primary = Color(hexRGB: "#3185FF")
            tokens.spacing.md = 16
        }

        _ = EDSButton("保存", role: .primary, systemImage: "checkmark") {}
        _ = EDSBadge("Pro", style: .accent)
        _ = EDSToggle(isOn: .constant(true), localizedLabel: "自动更新")
        _ = EDSCard { Text("Card") }
        _ = EDSPage("设置", subtitle: "管理应用偏好") {
            EDSPageSection("通用") {
                EDSGroup { Text("Content") }
            }
        }
        _ = EDSSettingRow("标题", subtitle: "说明") { Text("Value") }
        _ = EDSPill("标签", tone: EDSPillTone.defaultPalette[0], action: {})
        _ = EDSEmptyState(systemImage: "tray", title: "暂无内容")
        _ = EDSHeroPanel { Text("Hero") }
        _ = EDSComparisonSection(features: [("Feature", true, false)])
        _ = EDSMultilineSubtitleRow(title: "Title") { EmptyView() }
        _ = EDSCollapsibleSection("Details") { Text("Content") }

        _ = Text("Page").easyDesign()
        _ = Text("Content").easyDesign(.content)
        _ = Text("Section").easyDesign(
            .section,
            options: EDSEasyOptions(
                padding: .xl,
                maxContentWidth: .fixed(960),
                background: .visible
            )
        )
        _ = Text("Preset").easyDesign(.card, theme: .orange)
        _ = Text("Tokens").easyDesign(.group, tokens: EDSDesignTokens())
        _ = Text("Theme only").easyDesignTheme(.purple)
    }

    func testPartialJSONUsesTokenDefaults() throws {
        let data = try XCTUnwrap("""
        {
          "colors": { "primary": "#FF6B00" },
          "shadow": { "opacity": 0.08 }
        }
        """.data(using: .utf8))

        try EDSTheme.shared.configure(jsonData: data)

        XCTAssertEqual(EDSTheme.shared.colors.primary.toHex(), "#FF6B00")
        XCTAssertEqual(EDSTheme.shared.spacing.md, 16)
        XCTAssertEqual(EDSTheme.shared.shadow.opacity, 0.08)
    }

    func testColorHexFormatsKeepEightDigitSemanticsExplicit() {
        XCTAssertEqual(Color(hexRGB: "#FF0000").toHex(), "#FF0000")
        XCTAssertEqual(Color(hexARGB: "#FF0000FF").toHex(), "#0000FF")
        XCTAssertEqual(Color(hexRGBA: "#FF0000FF").toHex(), "#FF0000")
        XCTAssertEqual(Color(hex: "#FF0000FF", format: .rgba).toHex(), "#FF0000")
    }

    func testGenericPresets() {
        XCTAssertEqual(EDSPresetTheme.allPresets.map(\.id), ["default", "orange", "purple"])
    }

    func testEnvironmentUsesLocalTokensBeforeGlobalTokens() {
        let original = EDSTheme.shared.tokens
        defer { EDSTheme.shared.tokens = original }

        var global = EDSDesignTokens()
        global.spacing.md = 17
        EDSTheme.shared.tokens = global

        var environment = EnvironmentValues()
        XCTAssertEqual(environment.edsTheme.spacing.md, 17)

        var local = global
        local.spacing.md = 29
        environment.edsTheme = local

        XCTAssertEqual(environment.edsTheme.spacing.md, 29)
        XCTAssertEqual(EDSTheme.shared.tokens.spacing.md, 17)
    }

    func testEasyRecipeMapsAllSemanticScenes() {
        var tokens = EDSDesignTokens()
        tokens.spacing.xs = 7
        tokens.spacing.md = 15
        tokens.spacing.lg = 21
        tokens.spacing.xxl = 35
        tokens.radius.md = 13

        let page = EDSEasyRecipe.resolve(style: .page, tokens: tokens)
        XCTAssertEqual(page.padding, 35)
        XCTAssertEqual(page.width, .fixed(880))
        XCTAssertEqual(page.background, .inherited)

        let content = EDSEasyRecipe.resolve(style: .content, tokens: tokens)
        XCTAssertEqual(content.padding, 15)
        XCTAssertEqual(content.width, .fill)

        let section = EDSEasyRecipe.resolve(style: .section, tokens: tokens)
        XCTAssertEqual(section.padding, 7)
        XCTAssertEqual(section.paddingAxis, .vertical)

        let group = EDSEasyRecipe.resolve(style: .group, tokens: tokens)
        XCTAssertEqual(group.padding, 21)
        XCTAssertEqual(group.background, .subtle)
        XCTAssertEqual(group.cornerRadius, 13)
        XCTAssertFalse(group.showsShadow)

        let card = EDSEasyRecipe.resolve(style: .card, tokens: tokens)
        XCTAssertEqual(card.background, .card)
        XCTAssertTrue(card.showsBorder)
        XCTAssertTrue(card.showsShadow)

        let plain = EDSEasyRecipe.resolve(style: .plain, tokens: tokens)
        XCTAssertEqual(plain.padding, 0)
        XCTAssertEqual(plain.width, .unchanged)
        XCTAssertEqual(plain.background, .inherited)
    }

    func testEasyOptionsOverrideRecipeWithoutAmbiguousNil() {
        let tokens = EDSDesignTokens()
        let recipe = EDSEasyRecipe.resolve(
            style: .card,
            options: EDSEasyOptions(
                padding: .none,
                maxContentWidth: .fixed(-10),
                background: .hidden
            ),
            tokens: tokens
        )

        XCTAssertEqual(recipe.padding, 0)
        XCTAssertEqual(recipe.paddingAxis, .all)
        XCTAssertEqual(recipe.width, .fixed(0))
        XCTAssertEqual(recipe.background, .inherited)
    }
}
