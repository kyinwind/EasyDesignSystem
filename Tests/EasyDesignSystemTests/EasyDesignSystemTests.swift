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
}
