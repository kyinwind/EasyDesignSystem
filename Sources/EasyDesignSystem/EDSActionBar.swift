import SwiftUI

// MARK: - 本地化

/// 读取 EDS 资源包内的文案。
///
/// 与 `EDSComparisonSection` 的取法一致（`Bundle.module`）。EDS 的 l10n
/// 资源位于 `Sources/EasyDesignSystem/Resources/{zh-Hans,en}.lproj`。
private func edsActionLocalized(_ key: String) -> String {
    Bundle.module.localizedString(forKey: key, value: nil, table: nil)
}

// MARK: - EDSActionShortcut

/// 动作的键盘快捷键。
///
/// 与旧版 `MySwiftAppTools.ActionShortcut` 的关键差别：
/// - 用 `isValid` 显式表达"是否存在快捷键"，取代原来用空格作哨兵值的写法。
/// - 保留常用静态值，其余通过 `command(_:)` 工厂构造，不再手写 26 个常量。
public struct EDSActionShortcut: Equatable, Sendable {

    public let key: KeyEquivalent
    public let modifiers: EventModifiers

    public init(key: KeyEquivalent, modifiers: EventModifiers) {
        self.key = key
        self.modifiers = modifiers
    }

    /// ⌘ + 任意键的快捷构造。
    public static func command(_ key: KeyEquivalent) -> EDSActionShortcut {
        EDSActionShortcut(key: key, modifiers: [.command])
    }

    // MARK: 常用静态值

    public static let commandN = EDSActionShortcut.command("n")
    public static let commandS = EDSActionShortcut.command("s")
    public static let commandD = EDSActionShortcut.command("d")
    public static let commandO = EDSActionShortcut.command("o")
    public static let commandE = EDSActionShortcut.command("e")
    public static let delete = EDSActionShortcut(key: .delete, modifiers: [])
    public static let escape = EDSActionShortcut(key: .escape, modifiers: [])

    /// 是否存在有效快捷键。
    ///
    /// 旧实现用 `displayString != " "` 判断——一个空格既是哨兵值又是魔法字符串。
    /// 这里改为显式语义：有任何修饰键即为有效；无修饰键时排除空白字符。
    public var isValid: Bool {
        if !modifiers.isEmpty { return true }
        return !String(key.character).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 用于无障碍提示的显示文本，如 `⌘S`、`⇧⌘N`、`⌫`。
    public var displayString: String {
        var result = ""

        // macOS 惯例顺序：⌃ ⌥ ⇧ ⌘。
        // 旧实现按 command → shift → option → control 拼接，正好是惯例的逆序，
        // 拼出「⌘⇧N」而非系统菜单显示的「⇧⌘N」，这里修正。
        if modifiers.contains(.control) { result += "⌃" }
        if modifiers.contains(.option) { result += "⌥" }
        if modifiers.contains(.shift) { result += "⇧" }
        if modifiers.contains(.command) { result += "⌘" }

        switch key {
        case .delete:
            result += "⌫"
        case .escape:
            result += "Esc"
        default:
            result += String(key.character).uppercased()
        }

        return result
    }
}

// MARK: - EDSActionItem

/// 一条命令的语义描述。
///
/// 设计原则：**EDS 只负责"长什么样"，不负责"业务叫什么"**。
/// 语义 case 自带默认图标与默认按钮角色（属视觉决策），标题走 EDS 内置双语
/// 且调用方可覆盖；`.custom` 既可使用 `EDSButton.Role` 预设，也可直接指定
/// `Emphasis / Tone / Size` 三个正交维度，但**不接受 `Color`**——旧版
/// `ActionBarButtonDisplayStyle` 允许传任意颜色，正是橙色硬编码的入口。
///
/// ```swift
/// EDSActionBar([
///     .add(title: L(L10n.newProject)) { newProject() },
///     .delete(title: L(L10n.delete), enabled: !selected.isEmpty) { delete() },
/// ])
/// ```
public enum EDSActionItem: Identifiable {

    case add(
        title: String? = nil,
        enabled: Bool = true,
        shortcut: EDSActionShortcut? = nil,
        id: String = UUID().uuidString,
        action: () -> Void
    )

    case edit(
        title: String? = nil,
        enabled: Bool = true,
        shortcut: EDSActionShortcut? = nil,
        id: String = UUID().uuidString,
        action: () -> Void
    )

    case delete(
        title: String? = nil,
        enabled: Bool = true,
        shortcut: EDSActionShortcut? = nil,
        id: String = UUID().uuidString,
        action: () -> Void
    )

    case save(
        title: String? = nil,
        enabled: Bool = true,
        shortcut: EDSActionShortcut? = nil,
        id: String = UUID().uuidString,
        action: () -> Void
    )

    case cancel(
        title: String? = nil,
        enabled: Bool = true,
        shortcut: EDSActionShortcut? = nil,
        id: String = UUID().uuidString,
        action: () -> Void
    )

    case custom(
        title: String,
        systemImage: String? = nil,
        role: EDSButton.Role = .secondary,
        enabled: Bool = true,
        shortcut: EDSActionShortcut? = nil,
        id: String = UUID().uuidString,
        action: () -> Void
    )

    /// 使用按钮三维原语描述自定义动作。
    ///
    /// `emphasis` 刻意不提供默认值，使只传标题的旧调用稳定匹配 `role` 重载。
    /// `size` 省略时跟随 `EDSActionBar(size:)`，显式传入时只覆盖当前按钮。
    /// 三维 `custom(...)` 工厂的内部存储，不作为调用方直接使用的语义 case。
    @_spi(EDSActionItemImplementation)
    case styledCustom(
        title: String,
        systemImage: String? = nil,
        emphasis: EDSButton.Emphasis,
        tone: EDSButton.Tone = .accent,
        size: EDSButton.Size? = nil,
        enabled: Bool = true,
        shortcut: EDSActionShortcut? = nil,
        id: String = UUID().uuidString,
        action: () -> Void
    )

    /// 稳定且唯一的 id。
    ///
    /// 旧实现从 title 拼字符串，同名的两个 `.custom` 会碰撞，导致 SwiftUI diff 错乱。
    /// 这里每个 case 自带 UUID（`action` 之前的隐藏参数，调用方无需传）。
    public var id: String {
        switch self {
        case .add(_, _, _, let id, _),
             .edit(_, _, _, let id, _),
             .delete(_, _, _, let id, _),
             .save(_, _, _, let id, _),
             .cancel(_, _, _, let id, _):
            return id
        case .custom(_, _, _, _, _, let id, _),
             .styledCustom(_, _, _, _, _, _, _, let id, _):
            return id
        }
    }
}

// MARK: - EDSActionItem 解析

extension EDSActionItem {

    /// 创建可直接指定按钮三维样式的自定义动作。
    ///
    /// 保留原有 `custom(... role:)` enum case，因此既有源码与公开 API 不变；
    /// 这个重载要求显式传 `emphasis`，避免只传标题时产生重载歧义。
    public static func custom(
        title: String,
        systemImage: String? = nil,
        emphasis: EDSButton.Emphasis,
        tone: EDSButton.Tone = .accent,
        size: EDSButton.Size? = nil,
        enabled: Bool = true,
        shortcut: EDSActionShortcut? = nil,
        id: String = UUID().uuidString,
        action: @escaping () -> Void
    ) -> EDSActionItem {
        .styledCustom(
            title: title,
            systemImage: systemImage,
            emphasis: emphasis,
            tone: tone,
            size: size,
            enabled: enabled,
            shortcut: shortcut,
            id: id,
            action: action
        )
    }

    var resolvedTitle: String {
        switch self {
        case .add(let title, _, _, _, _):
            return title ?? edsActionLocalized("EDSActionBar.add.title")
        case .edit(let title, _, _, _, _):
            return title ?? edsActionLocalized("EDSActionBar.edit.title")
        case .delete(let title, _, _, _, _):
            return title ?? edsActionLocalized("EDSActionBar.delete.title")
        case .save(let title, _, _, _, _):
            return title ?? edsActionLocalized("EDSActionBar.save.title")
        case .cancel(let title, _, _, _, _):
            return title ?? edsActionLocalized("EDSActionBar.cancel.title")
        case .custom(let title, _, _, _, _, _, _),
             .styledCustom(let title, _, _, _, _, _, _, _, _):
            return title
        }
    }

    var resolvedSystemImage: String? {
        switch self {
        case .add:      return "plus"
        case .edit:     return "pencil"
        case .delete:   return "trash"
        case .save:     return "square.and.arrow.down"
        case .cancel:   return "xmark"
        case .custom(_, let systemImage, _, _, _, _, _),
             .styledCustom(_, let systemImage, _, _, _, _, _, _, _):
            return systemImage
        }
    }

    var resolvedRole: EDSButton.Role {
        switch self {
        case .add:      return .secondary
        case .edit:     return .normal
        case .delete:   return .danger
        case .save:     return .primary
        case .cancel:   return .normal
        case .custom(_, _, let role, _, _, _, _):
            return role
        case .styledCustom:
            return .secondary
        }
    }

    /// 解析最终按钮外观。Role 是预设入口；三维重载则直接使用调用方的组合。
    func resolvedAppearance(defaultSize: EDSButton.Size) -> EDSButtonAppearance {
        switch self {
        case .styledCustom(_, _, let emphasis, let tone, let size, _, _, _, _):
            return EDSButtonAppearance(
                emphasis: emphasis,
                tone: tone,
                size: size ?? defaultSize
            )
        default:
            let appearance = resolvedRole.appearance
            return EDSButtonAppearance(
                emphasis: appearance.emphasis,
                tone: appearance.tone,
                size: defaultSize
            )
        }
    }

    var isEnabled: Bool {
        switch self {
        case .add(_, let enabled, _, _, _),
             .edit(_, let enabled, _, _, _),
             .delete(_, let enabled, _, _, _),
             .save(_, let enabled, _, _, _),
             .cancel(_, let enabled, _, _, _):
            return enabled
        case .custom(_, _, _, let enabled, _, _, _),
             .styledCustom(_, _, _, _, _, let enabled, _, _, _):
            return enabled
        }
    }

    var resolvedShortcut: EDSActionShortcut? {
        switch self {
        case .add(_, _, let shortcut, _, _),
             .edit(_, _, let shortcut, _, _),
             .delete(_, _, let shortcut, _, _),
             .save(_, _, let shortcut, _, _),
             .cancel(_, _, let shortcut, _, _):
            return shortcut
        case .custom(_, _, _, _, let shortcut, _, _),
             .styledCustom(_, _, _, _, _, _, let shortcut, _, _):
            return shortcut
        }
    }

    var perform: () -> Void {
        switch self {
        case .add(_, _, _, _, let action),
             .edit(_, _, _, _, let action),
             .delete(_, _, _, _, let action),
             .save(_, _, _, _, let action),
             .cancel(_, _, _, _, let action):
            return action
        case .custom(_, _, _, _, _, _, let action),
             .styledCustom(_, _, _, _, _, _, _, _, let action):
            return action
        }
    }

    /// 无障碍提示：有快捷键时补一句"快捷键 ⌘S"，无快捷键时为空字符串。
    var accessibilityHintText: String {
        guard let shortcut = resolvedShortcut, shortcut.isValid else { return "" }
        return "\(edsActionLocalized("EDSActionBar.hint.shortcut")) \(shortcut.displayString)"
    }

    /// 鼠标悬停提示：标题后附快捷键；未配置快捷键时只显示标题。
    var helpText: String {
        guard let shortcut = resolvedShortcut, shortcut.isValid else { return resolvedTitle }
        return "\(resolvedTitle)（\(shortcut.displayString)）"
    }
}

// MARK: - 布局参数

public enum EDSActionBarAlignment: Sendable {
    case leading
    case center
    case trailing
}

public enum EDSActionBarLayoutStyle: Sendable {
    /// 放得下排一行，放不下自动收成 `EDSCommandGroup`。默认值。
    case automatic
    /// 始终一行，宽度不够时不压缩（保持按钮固有宽度）。
    case horizontal
    /// 保持按钮固有尺寸，放不下时换行。
    case wrapping
    /// 始终收成 `EDSCommandGroup`。
    case compact
}

// MARK: - EDSActionBar

/// 一组命令的编排容器。
///
/// 与 `EDSCommandGroup` 的分工：
/// - `EDSCommandGroup`：调用方给的是**已建好的 View**，它只负责框起来。
/// - `EDSActionBar`：调用方给的是**意图**（`EDSActionItem`），由它翻译成按钮、
///   决定默认图标与角色、排布、并在拥挤时自己降级。
///
/// 视觉全部由 `EDSThemeData` 驱动，随色彩风格与种子色切换而变；
/// 相比 `MySwiftAppTools.ActionBar` 不再有任何硬编码颜色。
public struct EDSActionBar: View {

    private let items: [EDSActionItem]
    private let alignment: EDSActionBarAlignment
    private let size: EDSButton.Size
    private let layoutStyle: EDSActionBarLayoutStyle

    @Environment(\.edsTheme) private var theme

    public init(
        _ items: [EDSActionItem],
        alignment: EDSActionBarAlignment = .trailing,
        size: EDSButton.Size = .regular,
        layoutStyle: EDSActionBarLayoutStyle = .automatic
    ) {
        self.items = items
        self.alignment = alignment
        self.size = size
        self.layoutStyle = layoutStyle
    }

    public var body: some View {
        switch layoutStyle {
        case .automatic:
            adaptiveBar
        case .horizontal:
            aligned { regularRow }
        case .wrapping:
            wrappingBar
        case .compact:
            aligned { compactRow }
        }
    }

    // MARK: 布局变体

    /// `ViewThatFits` 取代旧实现的双 `GeometryReader` 测量。
    ///
    /// 旧写法要维护两个 `@State`、渲染两遍 regularBar，且初值都是 0 导致
    /// `0 >= 0` 恒真——窄窗口第一帧必闪一下再收起。这里一次性全部消除。
    private var adaptiveBar: some View {
        aligned {
            ViewThatFits(in: .horizontal) {
                regularRow
                compactRow
            }
        }
    }

    private var wrappingBar: some View {
        EDSFlowLayout(
            horizontalSpacing: theme.spacing.xs,
            verticalSpacing: theme.spacing.xs,
            alignment: flowAlignment
        ) {
            ForEach(items) { item in
                button(for: item)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var regularRow: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(items) { item in
                button(for: item)
            }
        }
        .fixedSize()
    }

    private var compactRow: some View {
        EDSCommandGroup(spacing: theme.spacing.xxs) {
            ForEach(items) { item in
                // 收进命令组时统一降为纯文字，避免实心色块叠色块的沉重感；
                // tone 保留，危险操作仍是红字。
                button(for: item, forcePlain: true)
            }
        }
    }

    // MARK: 辅助

    /// 外层 Spacer 负责对齐，`content` 只管自己的固有宽度。
    private func aligned<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 0) {
            if alignment != .leading { Spacer(minLength: 0) }
            content()
            if alignment != .trailing { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity)
    }

    private func button(for item: EDSActionItem, forcePlain: Bool = false) -> some View {
        let appearance = item.resolvedAppearance(defaultSize: size)
        let emphasis = forcePlain ? EDSButton.Emphasis.plain : appearance.emphasis

        return AnyView(
            EDSButton(
                item.resolvedTitle,
                emphasis: emphasis,
                tone: appearance.tone,
                size: appearance.size,
                systemImage: item.resolvedSystemImage
            ) {
                item.perform()
            }
            .disabled(!item.isEnabled)
            .help(item.helpText)
            .accessibilityLabel(item.resolvedTitle)
            .accessibilityHint(item.accessibilityHintText)
            .edsShortcut(item.resolvedShortcut)
        )
    }

    private var flowAlignment: EDSFlowAlignment {
        switch alignment {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - 快捷键挂载

extension View {
    /// 挂载键盘快捷键。无快捷键时原样返回。
    func edsShortcut(_ shortcut: EDSActionShortcut?) -> some View {
        modifier(EDSShortcutModifier(shortcut: shortcut))
    }
}

private struct EDSShortcutModifier: ViewModifier {
    let shortcut: EDSActionShortcut?

    func body(content: Content) -> some View {
        if let shortcut, shortcut.isValid {
            content.keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
        } else {
            content
        }
    }
}
