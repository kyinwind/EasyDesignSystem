import XCTest
import SwiftUI
@testable import EasyDesignSystem

// MARK: - EDSActionBarTests

/// 命令编排层的纯逻辑验收。
///
/// 只覆盖不依赖渲染的部分：快捷键模型、语义默认值、id 唯一性。
/// 视觉与自适应降级在 Catalog 的「命令编排」页人工验收。
///
/// - Note: 标 `@MainActor` 是因为 SwiftUI `View` 的构造已被隔离到主线程，
///   Swift 6 严格并发下在同步非隔离上下文构造 `EDSActionBar` 会报错。
@MainActor
final class EDSActionBarTests: XCTestCase {

    // MARK: 快捷键模型

    func testShortcutisValidRejectsBlankKey() {
        // 旧实现用空格作哨兵值，靠 `displayString != " "` 判断；这里改为显式语义。
        XCTAssertTrue(EDSActionShortcut.commandS.isValid)
        XCTAssertFalse(EDSActionShortcut(key: " ", modifiers: []).isValid)
    }

    func testShortcutisValidAcceptsModifierWithoutKey() {
        // 带修饰键即视为有效，即便没有主键。
        XCTAssertTrue(EDSActionShortcut(key: " ", modifiers: [.command]).isValid)
    }

    func testShortcutDisplayString() {
        XCTAssertEqual(EDSActionShortcut.commandS.displayString, "⌘S")
        XCTAssertEqual(EDSActionShortcut.delete.displayString, "⌫")
        XCTAssertEqual(EDSActionShortcut.escape.displayString, "Esc")
    }

    /// 修饰键按 macOS 惯例顺序拼接（⌃ ⌥ ⇧ ⌘），而非旧的逆序写法。
    func testShortcutDisplayStringFollowsMacOSOrder() {
        XCTAssertEqual(
            EDSActionShortcut(key: "n", modifiers: [.command, .shift]).displayString,
            "⇧⌘N"
        )
        XCTAssertEqual(
            EDSActionShortcut(key: "s", modifiers: [.command, .option, .control]).displayString,
            "⌃⌥⌘S"
        )
    }

    func testCommandFactoryEquality() {
        XCTAssertEqual(EDSActionShortcut.command("s"), EDSActionShortcut.commandS)
    }

    // MARK: 语义默认值

    func testSemanticRoles() {
        XCTAssertEqual(item(.add {}).resolvedRole, .secondary)
        XCTAssertEqual(item(.edit {}).resolvedRole, .normal)
        XCTAssertEqual(item(.delete {}).resolvedRole, .danger)
        XCTAssertEqual(item(.save {}).resolvedRole, .primary)
        // cancel 刻意不再是破坏性：退出/取消不是危险操作。
        XCTAssertEqual(item(.cancel {}).resolvedRole, .normal)
        XCTAssertEqual(item(.custom(title: "导出") {}).resolvedRole, .secondary)
    }

    func testCustomSupportsDirectButtonDimensions() {
        let item = EDSActionItem.custom(
            title: "警告操作",
            emphasis: .outline,
            tone: .warning,
            size: .large
        ) {}

        let appearance = item.resolvedAppearance(defaultSize: .small)
        XCTAssertEqual(appearance.emphasis, .outline)
        XCTAssertEqual(appearance.tone, .warning)
        XCTAssertEqual(appearance.size, .large)
    }

    func testCustomDimensionSizeFallsBackToActionBarSize() {
        let item = EDSActionItem.custom(
            title: "稍后处理",
            emphasis: .plain,
            tone: .neutral
        ) {}

        XCTAssertEqual(item.resolvedAppearance(defaultSize: .small).size, .small)
    }

    func testRoleCustomKeepsPresetStyleAndUsesActionBarSize() {
        let item = EDSActionItem.custom(title: "移除", role: .dangerSoft) {}
        let appearance = item.resolvedAppearance(defaultSize: .large)

        XCTAssertEqual(appearance.emphasis, .soft)
        XCTAssertEqual(appearance.tone, .danger)
        XCTAssertEqual(appearance.size, .large)
    }

    func testSemanticSystemImages() {
        XCTAssertEqual(item(.add {}).resolvedSystemImage, "plus")
        XCTAssertEqual(item(.edit {}).resolvedSystemImage, "pencil")
        XCTAssertEqual(item(.delete {}).resolvedSystemImage, "trash")
        XCTAssertEqual(item(.save {}).resolvedSystemImage, "square.and.arrow.down")
        XCTAssertEqual(item(.cancel {}).resolvedSystemImage, "xmark")
        XCTAssertNil(item(.custom(title: "纯文字") {}).resolvedSystemImage)
    }

    func testCustomTitleOverridesBuiltin() {
        XCTAssertEqual(item(.save(title: "保存并继续") {}).resolvedTitle, "保存并继续")
        // 未传 title 时回退到 EDS 资源包内的文案。
        XCTAssertFalse(item(.save {}).resolvedTitle.isEmpty)
    }

    func testDeleteSupportsShortcut() {
        // 旧实现的 delete case 缺 shortcut 参数，这里补齐后应可读出。
        let item = EDSActionItem.delete(shortcut: .delete) {}
        XCTAssertEqual(item.resolvedShortcut?.displayString, "⌫")
    }

    // MARK: id 唯一性

    func testIdsAreUniqueAcrossSameCase() {
        let first = EDSActionItem.custom(title: "导出") {}
        let second = EDSActionItem.custom(title: "导出") {}
        // 旧实现从 title 拼 id，同名两次会碰撞导致 SwiftUI diff 错乱。
        XCTAssertNotEqual(first.id, second.id)
    }

    func testIdsAreUniqueAcrossAllCases() {
        let all: [EDSActionItem] = [
            .add {}, .edit {}, .delete {}, .save {}, .cancel {}, .custom(title: "导出") {}
        ]
        let ids = Set(all.map(\.id))
        XCTAssertEqual(ids.count, all.count)
    }

    // MARK: 启用状态与动作

    func testEnabledFlag() {
        XCTAssertFalse(EDSActionItem.save(enabled: false) {}.isEnabled)
        XCTAssertTrue(EDSActionItem.save(enabled: true) {}.isEnabled)
    }

    func testAccessibilityHintCarriesShortcut() {
        let withShortcut = EDSActionItem.save(shortcut: .commandS) {}
        XCTAssertTrue(withShortcut.accessibilityHintText.contains("⌘S"))

        let withoutShortcut = EDSActionItem.save {}
        XCTAssertTrue(withoutShortcut.accessibilityHintText.isEmpty)
    }

    func testHoverHelpShowsShortcutWhenConfigured() {
        let withShortcut = EDSActionItem.save(title: "保存", shortcut: .commandS) {}
        XCTAssertEqual(withShortcut.helpText, "保存（⌘S）")

        let withoutShortcut = EDSActionItem.cancel(title: "取消") {}
        XCTAssertEqual(withoutShortcut.helpText, "取消")
    }

    // MARK: 便捷工具

    /// 把一次性构造收敛到一处，避免每个断言都写一长串。
    private func item(_ value: EDSActionItem) -> EDSActionItem { value }
}
