import SwiftUI
import XCTest
#if canImport(AppKit)
import AppKit
#endif
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
        _ = EDSMultilineSubtitleRow(
            icon: Image(systemName: "book"),
            title: "Image"
        ) { EmptyView() }
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
        _ = Text("Touch preview").easyDesignInteractionProfile(.touch)
    }

    func testReadmeMultiplatformExampleCompiles() {
        _ = ReadmeAccountPage()
    }

    #if canImport(AppKit)
    func testLegacyNSImageInitializerStillCompilesOnMacOS() {
        _ = EDSMultilineSubtitleRow(
            iconImage: NSImage(size: NSSize(width: 16, height: 16)),
            title: "Legacy"
        ) { EmptyView() }
    }
    #endif

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
        XCTAssertEqual(EDSTheme.shared.adaptiveLayout.minimumTouchTarget, 44)
    }

    func testColorHexFormatsKeepEightDigitSemanticsExplicit() {
        XCTAssertEqual(Color(hexRGB: "#FF0000").toHex(), "#FF0000")
        XCTAssertEqual(Color(hexARGB: "#FF0000FF").toHex(), "#0000FF")
        XCTAssertEqual(Color(hexRGBA: "#FF0000FF").toHex(), "#FF0000")
        XCTAssertEqual(Color(hex: "#FF0000FF", format: .rgba).toHex(), "#FF0000")
    }

    func testThemeColorsRoundTripWithoutSilentBlackFallback() throws {
        var tokens = EDSDesignTokens()
        tokens.colors = EDSColorTokens(
            primary: Color(hexRGB: "#123456"),
            accent: Color(hexRGB: "#654321"),
            success: Color(hexRGB: "#238636"),
            warning: Color(hexRGB: "#D29922"),
            danger: Color(hexRGB: "#CF222E")
        )

        let data = try JSONEncoder().encode(tokens)
        let decoded = try JSONDecoder().decode(EDSDesignTokens.self, from: data)

        XCTAssertEqual(decoded.colors.primary.toHex(), "#123456")
        XCTAssertEqual(decoded.colors.accent.toHex(), "#654321")
        XCTAssertEqual(decoded.colors.success.toHex(), "#238636")
        XCTAssertEqual(decoded.colors.warning.toHex(), "#D29922")
        XCTAssertEqual(decoded.colors.danger.toHex(), "#CF222E")
    }

    func testDynamicBackgroundColorsResolveUsingLightAppearance() {
        let colors = EDSColorTokens()

        XCTAssertNotEqual(colors.pageBackground.toHex(), "#000000")
        XCTAssertNotEqual(colors.cardBackground.toHex(), "#000000")
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

    func testLegacyThemeFixtureUsesAdaptiveDefaults() throws {
        let tokens = try decodeFixture("LegacyTheme")

        XCTAssertEqual(tokens.colors.primary.toHex(), "#3185FF")
        XCTAssertEqual(tokens.controlSize.buttonHeight, 34)
        XCTAssertEqual(tokens.adaptiveLayout.compactPagePadding, 16)
        XCTAssertEqual(tokens.adaptiveLayout.minimumTouchTarget, 44)
    }

    func testPartialLegacyThemeFixtureUsesDefaults() throws {
        let tokens = try decodeFixture("PartialLegacyTheme")

        XCTAssertEqual(tokens.colors.primary.toHex(), "#FF6B00")
        XCTAssertEqual(tokens.spacing.md, 16)
        XCTAssertEqual(tokens.adaptiveLayout.readableContentMaxWidth, 880)
    }

    func testMultiplatformThemeRoundTrip() throws {
        let tokens = try decodeFixture("MultiplatformTheme")
        let data = try JSONEncoder().encode(tokens)
        let decoded = try JSONDecoder().decode(EDSDesignTokens.self, from: data)

        XCTAssertEqual(decoded.colors.primary.toHex(), "#2196F3")
        XCTAssertEqual(decoded.adaptiveLayout.compactPagePadding, 18)
        XCTAssertEqual(decoded.adaptiveLayout.regularPagePadding, 30)
        XCTAssertEqual(decoded.adaptiveLayout.readableContentMaxWidth, 920)
        XCTAssertEqual(decoded.adaptiveLayout.minimumTouchTarget, 46)
        XCTAssertEqual(decoded.adaptiveLayout.minimumHybridTarget, 42)
    }

    func testAdaptiveMetricsResolveInteractionProfiles() {
        var tokens = EDSDesignTokens()
        tokens.spacing.md = 17
        tokens.spacing.xxl = 33

        let touchCompact = EDSResolvedMetrics.resolve(
            tokens: tokens,
            profile: .touch,
            horizontalSizeClass: .compact
        )
        XCTAssertEqual(touchCompact.pagePadding, 17)
        XCTAssertEqual(touchCompact.minimumInteractiveDimension, 44)
        XCTAssertTrue(touchCompact.showsPersistentAuxiliaryActions)
        XCTAssertFalse(touchCompact.supportsHoverEnhancement)

        let pointerRegular = EDSResolvedMetrics.resolve(
            tokens: tokens,
            profile: .pointer,
            horizontalSizeClass: .regular
        )
        XCTAssertEqual(pointerRegular.pagePadding, 33)
        XCTAssertEqual(pointerRegular.minimumInteractiveDimension, 0)
        XCTAssertFalse(pointerRegular.showsPersistentAuxiliaryActions)
        XCTAssertTrue(pointerRegular.supportsHoverEnhancement)

        let hybrid = EDSResolvedMetrics.resolve(
            tokens: tokens,
            profile: .hybrid,
            horizontalSizeClass: .regular
        )
        XCTAssertEqual(hybrid.minimumInteractiveDimension, 44)
        XCTAssertTrue(hybrid.showsPersistentAuxiliaryActions)
        XCTAssertTrue(hybrid.supportsHoverEnhancement)
    }

    func testExplicitAdaptivePaddingOverridesSpacingCompatibilityFallback() {
        var tokens = EDSDesignTokens()
        tokens.spacing.md = 17
        tokens.spacing.xxl = 33
        tokens.adaptiveLayout.compactPagePadding = 20
        tokens.adaptiveLayout.regularPagePadding = 36

        XCTAssertEqual(
            EDSResolvedMetrics.resolve(
                tokens: tokens,
                profile: .touch,
                horizontalSizeClass: .compact
            ).pagePadding,
            20
        )
        XCTAssertEqual(
            EDSResolvedMetrics.resolve(
                tokens: tokens,
                profile: .pointer,
                horizontalSizeClass: .regular
            ).pagePadding,
            36
        )
    }

    private func decodeFixture(_ name: String) throws -> EDSDesignTokens {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json")
        )
        return try JSONDecoder().decode(
            EDSDesignTokens.self,
            from: Data(contentsOf: url)
        )
    }
}

private struct ReadmeAccountPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                EDSPageTitle("账户")
                EDSSettingRow("自动同步") {
                    EDSToggle(isOn: .constant(true), label: "启用")
                }
                .easyDesign(.group)
            }
            .easyDesign(.page)
        }
    }
}
