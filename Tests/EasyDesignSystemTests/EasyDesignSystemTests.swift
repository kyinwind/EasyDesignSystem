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

    /// `.done` 的默认外观契约：实心成功色 + 标准尺寸。
    ///
    /// 固化于 2026-09-20 目视验收之后。当时 `.done` 由 `.soft` 改为 `.filled`，
    /// 但磁盘改动被编辑器缓冲区覆盖，Preview 仍显示浅绿底，只靠肉眼才发现。
    /// 这条断言让"档位被静默改回去"在 `swift test` 阶段就暴露。
    func testDoneRoleResolvesToFilledSuccess() {
        let appearance = EDSButton.Role.done.appearance
        XCTAssertEqual(appearance.emphasis, .filled)
        XCTAssertEqual(appearance.tone, .success)
        XCTAssertEqual(appearance.size, .regular)
    }

    /// `.done` 的改档不波及四个既有 role。
    func testLegacyRolesKeepTheirAppearance() {
        XCTAssertEqual(
            EDSButton.Role.primary.appearance,
            EDSButtonAppearance(emphasis: .filled, tone: .accent, size: .regular)
        )
        XCTAssertEqual(
            EDSButton.Role.secondary.appearance,
            EDSButtonAppearance(emphasis: .medium, tone: .accent, size: .regular)
        )
        XCTAssertEqual(
            EDSButton.Role.soft.appearance,
            EDSButtonAppearance(emphasis: .soft, tone: .accent, size: .regular)
        )
        XCTAssertEqual(
            EDSButton.Role.danger.appearance,
            EDSButtonAppearance(emphasis: .filled, tone: .danger, size: .regular)
        )
    }

    /// `.normal` 的默认外观契约：浅灰底 + 深字 + 标准尺寸。
    ///
    /// 杨哥定版 2026-09-22：灰底次级按钮是最常见的重复场景（工具栏
    /// "检测对话/导出/打开目录"一类），收进 Role 快捷方式表。
    func testNormalRoleResolvesToSoftNeutral() {
        let appearance = EDSButton.Role.normal.appearance
        XCTAssertEqual(appearance.emphasis, .soft)
        XCTAssertEqual(appearance.tone, .neutral)
        XCTAssertEqual(appearance.size, .regular)
    }

    /// allCases 必须包含 normal（Role 表 6 条）。
    func testRoleAllCasesIncludeNormal() {
        XCTAssertEqual(
            Set(EDSButton.Role.allCases.map(\.rawValue)),
            ["primary", "secondary", "soft", "danger", "done", "normal"]
        )
    }

    // MARK: - 0.3.1 · A1 主题色单一来源

    /// 只改 `primary` 时，所有"跟随主题色"的读取点都必须跟着变。
    ///
    /// 固化 2026-09-21 的 A1 修复。修复前包内读取是分裂的：浅底档按钮的
    /// **底色**读 `accentSoft`（→ `accent`），**文字**读 `primary`，
    /// 于是 VideoHero 只设 `primary = .orange` 时渲染成"12% 蓝底 + 橙字"；
    /// 侧边栏选中态与全局 `.tint()` 也停留在蓝色。
    ///
    /// 这条断言用"primary 与 accent 取**不同**颜色"来区分两条读取路径——
    /// 若哪天有人把 `accentSoft` 改回读 `accent`，本测试立刻失败。
    func testThemeColorReadsFollowPrimaryNotAccent() {
        let orange = Color(hexRGB: "#FF6B00")
        let blue = Color(hexRGB: "#3185FF")

        var tokens = EDSDesignTokens()
        tokens.colors.primary = orange
        tokens.colors.accent = blue          // 保持默认蓝，模拟"只改了 primary"

        // 派生浅底色跟随 primary
        XCTAssertEqual(tokens.colors.primarySoft, orange.opacity(0.12))
        XCTAssertEqual(tokens.colors.accentSoft, tokens.colors.primarySoft)
        XCTAssertEqual(tokens.colors.accentSoft.toHex(), "#FF6B00")

        // 浅底档按钮：底色与文字必须同源，否则就是那个"蓝底橙字"的历史 bug
        let soft = EDSButtonAppearance(emphasis: .soft, tone: .accent, size: .regular)
        let visual = soft.resolved(tokens: tokens)
        XCTAssertEqual(visual.background, orange.opacity(0.12))
        XCTAssertEqual(visual.foreground, orange)
    }

    /// 预设路径不受 A1 影响：三个内置预设的 primary 与 accent 取值仍然相同。
    ///
    /// 这是"用 `applyPreset` 的 App 零视觉变化"这一承诺的可执行版本。
    func testBuiltInPresetsKeepPrimaryAndAccentInSync() {
        for preset in EDSPresetTheme.allPresets {
            XCTAssertEqual(
                preset.tokens.colors.primary.toHex(),
                preset.tokens.colors.accent.toHex(),
                "预设 \(preset.id) 的 primary 与 accent 不再同值，A1 修复会改变其视觉"
            )
        }
    }

    // MARK: - 0.3.1 · A2 String 标题重载

    /// `String` 标题重载可编译，且解析出的外观与对应 `Role` 一致。
    ///
    /// 背景：App 自有本地化函数（如 VideoHero 的 `L(_:_:)`）返回 `String`，
    /// 0.3.1 之前 `EDSButton(L("x"), role: .secondary) {}` 直接编译失败
    /// （`cannot convert value of type 'String' to expected argument type 'LocalizedStringKey'`）。
    /// 本测试的存在即"该写法可编译"的证据。
    func testStringTitleInitializersCompile() {
        let title: String = "取消"

        _ = EDSButton(title, role: .secondary) {}
        _ = EDSButton(title, role: .primary, systemImage: "xmark") {}
        _ = EDSButton(title, emphasis: .soft, tone: .danger, size: .small) {}
        _ = EDSButton(title, emphasis: .medium, size: .large, systemImage: "arrow.clockwise") {}

        // 字面量调用仍走 LocalizedStringKey 重载，行为不变
        _ = EDSButton("确定", role: .primary) {}
    }

    // MARK: - 0.4.0 · medium 档取代 outline（描边退役）

    /// 废弃的 `outline` 与 `medium` 渲染视觉必须完全相等（内部转发保证）。
    ///
    /// outline 经 rawValue 构造，避免测试源码直接引用废弃符号触发告警。
    func testOutlineRendersIdenticallyToMedium() {
        guard let outline = EDSButton.Emphasis(rawValue: "outline") else {
            return XCTFail("outline case 应保留（废弃别名），rawValue 构造不应失败")
        }
        let tokens = EDSDesignTokens()

        for tone in EDSButton.Tone.allCases {
            let medium = EDSButtonAppearance(
                emphasis: .medium, tone: tone, size: .regular
            ).resolved(tokens: tokens)
            let legacy = EDSButtonAppearance(
                emphasis: outline, tone: tone, size: .regular
            ).resolved(tokens: tokens)

            XCTAssertEqual(medium.foreground, legacy.foreground, "tone=\(tone.rawValue) 文字色不一致")
            XCTAssertEqual(medium.background, legacy.background, "tone=\(tone.rawValue) 底色不一致")
            XCTAssertNil(legacy.borderColor, "描边已退役，borderColor 必须为 nil")
        }
    }

    /// medium 档视觉规则：25% 色底 + "深一档的同色系"文字（neutral 除外）+ 无描边。
    ///
    /// 25% 是杨哥定版（2026-09-22；50% 目视偏重，试算 22% 与 soft 12% 区分不开）；
    /// 文字同色系且压深 30% 是杨哥定版（2026-09-22；纯黑字丢失色彩身份，
    /// 纯 tone 字则与 soft 拉不开文字层次）。neutral 无彩度，维持 textPrimary。
    func testMediumResolvesToQuarterToneFillWithDarkenedToneText() {
        let tokens = EDSDesignTokens()

        for tone in EDSButton.Tone.allCases {
            let visual = EDSButtonAppearance(
                emphasis: .medium, tone: tone, size: .regular
            ).resolved(tokens: tokens)

            let toneColor: Color
            switch tone {
            case .accent:  toneColor = tokens.colors.primary
            case .neutral: toneColor = Color.primary
            case .danger:  toneColor = tokens.colors.danger
            case .success: toneColor = tokens.colors.success
            case .warning: toneColor = tokens.colors.warning
            }

            XCTAssertEqual(visual.background, toneColor.opacity(0.25), "tone=\(tone.rawValue)")

            let expectedForeground: Color = tone == .neutral
                ? tokens.colors.textPrimary
                : EDSPlatformColorBridge.darkened(toneColor, by: 0.7) ?? tokens.colors.textPrimary
            XCTAssertEqual(visual.foreground, expectedForeground, "tone=\(tone.rawValue)")

            XCTAssertNil(visual.borderColor)
        }
    }

    /// medium 文字色必须真的比 tone 深一档（压深 ≠ 原色 ≠ 黑），防回归成纯 tone 或纯黑。
    func testMediumDarkenedTextIsBetweenToneAndBlack() throws {
        let tokens = EDSDesignTokens()
        let pureTone = try XCTUnwrap(
            EDSPlatformColorBridge.sRGBComponents(for: tokens.colors.primary)
        )
        let darkened = try XCTUnwrap(
            EDSPlatformColorBridge.sRGBComponents(
                for: EDSPlatformColorBridge.darkened(tokens.colors.primary, by: 0.7)!
            )
        )
        // 总亮度严格下降（逐通道比较不行：如纯蓝的 red 通道本来就是 0）
        let pureSum = pureTone.red + pureTone.green + pureTone.blue
        let darkenedSum = darkened.red + darkened.green + darkened.blue
        XCTAssertLessThan(darkenedSum, pureSum)
        // 但没有压成纯黑
        XCTAssertGreaterThan(darkenedSum, 0)
    }

    /// allCases 手动实现必须包含全部 5 个 case（含废弃 outline）。
    func testEmphasisAllCasesIncludeMediumAndDeprecatedOutline() {
        let all = EDSButton.Emphasis.allCases.map(\.rawValue)
        XCTAssertEqual(
            Set(all),
            ["filled", "medium", "soft", "plain", "outline"]
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
