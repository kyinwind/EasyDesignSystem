import XCTest

@MainActor
final class EDSPlatformCatalogUITests: XCTestCase {
    func testAdaptiveCatalogExposesCoreControls() {
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview"]
        app.launch()

        XCTAssertTrue(app.staticTexts["跨平台适配"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["预览环境"].exists)
        XCTAssertTrue(app.buttons["继续"].firstMatch.exists)
        XCTAssertTrue(app.switches.firstMatch.exists || app.checkBoxes.firstMatch.exists)
    }

    func testAccessibilityDarkScenarioLaunches() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--adaptive-preview",
            "--accessibility-preview",
            "--dark-preview"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["跨平台适配"].waitForExistence(timeout: 5))
        #if os(macOS) && !targetEnvironment(macCatalyst)
        XCTAssertTrue(app.popUpButtons["adaptive.dynamic-type"].exists)
        #else
        XCTAssertTrue(app.staticTexts["最大辅助字号"].exists)
        #endif
    }

    func testAccessibilityEnvironmentIsExposed() {
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "accessibility.increase-contrast.")
            ).firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "accessibility.differentiate-without-color.")
            ).firstMatch.exists
        )
        XCTAssertTrue(
            app.staticTexts.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "accessibility.reduce-motion.")
            ).firstMatch.exists
        )

        let environment = ProcessInfo.processInfo.environment
        if let expected = environment["EDS_EXPECT_INCREASE_CONTRAST"] {
            XCTAssertTrue(app.staticTexts["accessibility.increase-contrast.\(expected)"].exists)
        }
        if let expected = environment["EDS_EXPECT_DIFFERENTIATE_WITHOUT_COLOR"] {
            XCTAssertTrue(app.staticTexts["accessibility.differentiate-without-color.\(expected)"].exists)
        }
        if let expected = environment["EDS_EXPECT_REDUCE_MOTION"] {
            XCTAssertTrue(app.staticTexts["accessibility.reduce-motion.\(expected)"].exists)
        }
    }

    func testVoiceOverNamesCoreInteractiveElements() {
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview"]
        app.launch()

        XCTAssertTrue(app.staticTexts["跨平台适配"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["启用"].firstMatch.exists || app.checkBoxes["启用"].firstMatch.exists)
        XCTAssertTrue(app.buttons["继续"].firstMatch.exists)
        XCTAssertTrue(app.buttons["取消"].firstMatch.exists)
        XCTAssertTrue(app.buttons["删除 iPhone"].firstMatch.exists)
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    func testAdaptiveCatalogSurvivesOrientationChanges() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview"]
        app.launch()

        XCTAssertTrue(app.staticTexts["跨平台适配"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["跨平台适配"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["继续"].firstMatch.exists)
        XCUIDevice.shared.orientation = .portrait
    }

    func testIPadSplitWidthScenario() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview", "--split-width-preview"]
        app.launch()

        guard app.windows.firstMatch.frame.width >= 700 else {
            throw XCTSkip("iPad-only split-width verification")
        }

        let container = app.otherElements["split-width-preview"]
        XCTAssertTrue(container.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(container.frame.width, 440)
        XCTAssertTrue(app.staticTexts["跨平台适配"].exists)
        XCTAssertTrue(app.buttons["继续"].firstMatch.exists)
    }

    func testTouchAndPointerProfiles() {
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview", "--touch-profile"]
        app.launch()

        let toggle = app.switches.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let initialValue = String(describing: toggle.value)
        toggle.tap()
        XCTAssertNotEqual(String(describing: toggle.value), initialValue)

        app.terminate()
        app.launchArguments = ["--adaptive-preview", "--pointer-profile"]
        app.launch()
        let profilePicker = app.buttons["adaptive.profile"].exists
            ? app.buttons["adaptive.profile"]
            : app.popUpButtons["adaptive.profile"]
        XCTAssertTrue(profilePicker.waitForExistence(timeout: 5))
        let visiblePointerValue = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Pointer"))
            .firstMatch
        XCTAssertTrue(visiblePointerValue.waitForExistence(timeout: 5))
    }
    #endif

    #if os(macOS) && !targetEnvironment(macCatalyst)
    func testMacWindowSupportsNarrowAndWideLayouts() {
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview", "--narrow-window"]
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(window.frame.width, 650)
        XCTAssertTrue(app.staticTexts["跨平台适配"].exists)

        app.terminate()
        app.launchArguments = ["--adaptive-preview", "--wide-window"]
        app.launch()
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(window.frame.width, 1_050)
        XCTAssertTrue(app.buttons["继续"].firstMatch.exists)
    }

    func testMacPointerAndKeyboardInteraction() {
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview", "--wide-window"]
        app.launch()

        let toggle = app.switches.firstMatch.exists
            ? app.switches.firstMatch
            : app.checkBoxes.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let initialToggleValue = String(describing: toggle.value)
        toggle.click()
        XCTAssertNotEqual(String(describing: toggle.value), initialToggleValue)

        let profile = app.popUpButtons["adaptive.profile"]
        XCTAssertTrue(profile.exists)
        let initialProfileValue = String(describing: profile.value)
        profile.click()
        app.menuItems["Pointer"].click()
        XCTAssertNotEqual(String(describing: profile.value), initialProfileValue)

        app.typeKey(.tab, modifierFlags: [])
        let focusedElement = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasKeyboardFocus == true"))
            .firstMatch
        XCTAssertTrue(focusedElement.waitForExistence(timeout: 2))
    }
    #endif

    func testAdaptiveCatalogPassesSystemAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--adaptive-preview"]
        app.launch()

        XCTAssertTrue(app.staticTexts["跨平台适配"].waitForExistence(timeout: 5))
        #if os(macOS) && !targetEnvironment(macCatalyst)
        let auditTypes: XCUIAccessibilityAuditType = [
            .elementDetection,
            .hitRegion
        ]
        #else
        let isPad = app.windows.firstMatch.frame.width >= 700
        let auditTypes: XCUIAccessibilityAuditType = isPad
            ? [.textClipped, .hitRegion, .sufficientElementDescription, .trait]
            : [.dynamicType, .textClipped, .hitRegion, .sufficientElementDescription, .trait]
        #endif
        try app.performAccessibilityAudit(
            for: auditTypes
        )
    }
}
