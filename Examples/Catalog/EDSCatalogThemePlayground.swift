import SwiftUI
import EasyDesignSystem

// MARK: - EDSCatalogThemeEntry

/// 预览用主题条目：把「一个可切换的颜色风格」封装成可枚举的值。
///
/// 只服务于 Examples 层，不属于 EasyDesignSystem 的公共 API。
public struct EDSCatalogThemeEntry: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let detail: String
    /// `true` 表示直接引用包内预设；`false` 表示在 Examples 层构造的自定义主题。
    public let isBuiltIn: Bool
    public let preset: EDSPresetTheme

    public init(
        id: String,
        name: String,
        detail: String,
        isBuiltIn: Bool,
        preset: EDSPresetTheme
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.isBuiltIn = isBuiltIn
        self.preset = preset
    }

    /// 5 个语义色，供顶部栏色块预览。顺序固定：primary / accent / success / warning / danger。
    public var swatchColors: [Color] {
        let colors = preset.tokens.colors
        return [
            colors.primary,
            colors.accent,
            colors.success,
            colors.warning,
            colors.danger
        ]
    }
}

// MARK: - EDSCatalogThemeCatalog

/// 预览候选主题清单。
///
/// 分两组：
/// - `builtIn`：直接引用包内 `EDSPresetTheme` 预设，验证现状
/// - `custom`：在 Examples 层用 `EDSPresetTheme(id:name:tokens:)` 现场构造，
///   演示「包外 App 换主色」的真实写法，不需要改动包内任何代码
public enum EDSCatalogThemeCatalog {

    /// 默认主题 ID，与 `EDSPlatformCatalogApp` 的启动配置保持一致。
    public static let defaultThemeID = "builtin.default"

    // MARK: 包内预设

    public static let builtIn: [EDSCatalogThemeEntry] = [
        EDSCatalogThemeEntry(
            id: defaultThemeID,
            name: "默认蓝",
            detail: "包内预设 · #3185FF",
            isBuiltIn: true,
            preset: .default
        ),
        EDSCatalogThemeEntry(
            id: "builtin.orange",
            name: "橙",
            detail: "包内预设 · #FF6B00",
            isBuiltIn: true,
            preset: .orange
        ),
        EDSCatalogThemeEntry(
            id: "builtin.purple",
            name: "紫",
            detail: "包内预设 · #8B5CF6",
            isBuiltIn: true,
            preset: .purple
        )
    ]

    // MARK: 包外自定义示例

    public static let custom: [EDSCatalogThemeEntry] = [
        makeCustom(
            id: "custom.businessBlue",
            name: "商务深蓝",
            primaryHex: "#1D4ED8",
            endHex: "#123A9E"
        ),
        makeCustom(
            id: "custom.teal",
            name: "青",
            primaryHex: "#0E9E9E",
            endHex: "#0A7373"
        ),
        makeCustom(
            id: "custom.green",
            name: "绿",
            primaryHex: "#27B15A",
            endHex: "#1B8342"
        ),
        makeCustom(
            id: "custom.rose",
            name: "玫红",
            primaryHex: "#E0457B",
            endHex: "#B32B5C"
        )
    ]

    /// 全部候选主题（包内预设 + 包外自定义）。
    public static var all: [EDSCatalogThemeEntry] { builtIn + custom }

    // MARK: 查找

    public static func entry(id: String) -> EDSCatalogThemeEntry? {
        all.first { $0.id == id }
    }

    public static func preset(id: String) -> EDSPresetTheme? {
        entry(id: id)?.preset
    }

    // MARK: - 构造自定义主题

    /// 演示「包外换主色」的正确写法。
    ///
    /// 关键点：**显式设全 5 个语义色**。包内 `EDSPresetTheme.default` 只设了
    /// primary + accent + heroGradient，success / warning / danger 会落到
    /// `EDSDesignTokens()` 的默认值（系统 `.green` / `.orange` / `.red`），
    /// 与 `.orange` / `.purple` 预设的 hex 取值并不一致。自定义主题显式设全，
    /// 对比才公平。
    private static func makeCustom(
        id: String,
        name: String,
        primaryHex: String,
        endHex: String
    ) -> EDSCatalogThemeEntry {
        var tokens = EDSDesignTokens()
        let primary = Color(hexRGB: primaryHex)

        tokens.colors.primary = primary
        tokens.colors.accent  = primary
        tokens.colors.success = Color(hexRGB: "#27B15A")
        tokens.colors.warning = Color(hexRGB: "#F9B135")
        tokens.colors.danger  = Color(hexRGB: "#E54444")
        tokens.heroGradient = EDSHeroGradient(
            startColor: primary,
            endColor: Color(hexRGB: endHex)
        )

        return EDSCatalogThemeEntry(
            id: id,
            name: name,
            detail: "包外自定义 · \(primaryHex)",
            isBuiltIn: false,
            preset: EDSPresetTheme(id: id, name: name, tokens: tokens)
        )
    }
}

// MARK: - EDSThemeBar

/// 顶部主题选择栏：一个下拉选择器 + 当前主题的 5 色色块。
@MainActor
public struct EDSThemeBar: View {
    @Binding private var selectionID: String

    public init(selectionID: Binding<String>) {
        self._selectionID = selectionID
    }

    public var body: some View {
        HStack(spacing: 12) {
            Text("预览主题")
                .font(EDSTheme.shared.typography.captionStrong)
                .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                .fixedSize()

            Picker("预览主题", selection: $selectionID) {
                Section("包内预设") {
                    ForEach(EDSCatalogThemeCatalog.builtIn) { entry in
                        Text(entry.name).tag(entry.id)
                    }
                }
                Section("包外自定义示例") {
                    ForEach(EDSCatalogThemeCatalog.custom) { entry in
                        Text(entry.name).tag(entry.id)
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
            .accessibilityIdentifier("catalog.theme.picker")

            swatches

            Spacer(minLength: 8)

            if let entry = EDSCatalogThemeCatalog.entry(id: selectionID) {
                Text(entry.detail)
                    .font(EDSTheme.shared.typography.monoCaption)
                    .foregroundStyle(EDSTheme.shared.colors.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, EDSTheme.shared.spacing.md)
        .padding(.vertical, EDSTheme.shared.spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EDSTheme.shared.colors.cardBackground)
    }

    /// 当前主题的 5 个语义色，一眼看出语义色是否协调。
    private var swatches: some View {
        let colors = EDSCatalogThemeCatalog.entry(id: selectionID)?.swatchColors ?? []
        return HStack(spacing: 4) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(EDSTheme.shared.colors.border, lineWidth: 0.5)
                    )
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - EDSThemePlayground

/// 给预览内容套一层可切换的主题外壳。
///
/// 两个机制必须配合，缺一不可：
///
/// 1. **改全局单例**：两个 Gallery 里大量代码直读 `EDSTheme.shared.xxx`，
///    不走 `@Environment(\.edsTheme)`，所以只能改单例才能生效。
/// 2. **`.id()` 强制重建**：`EDSTheme` 是普通 class，不是 `ObservableObject`，
///    改它不会让 SwiftUI 重绘（`EDSTheme.swift` 注释亦写明「运行时动态切换主题
///    暂不承诺自动刷新 UI」）。因此由 `.id` 变化触发 SwiftUI 销毁并重建子树，
///    重建时才会重新求值全部 token。
///
/// 顺序要求：**先 applyPreset，再改驱动 `.id` 的 state**。反过来会慢一拍
/// （body 先重算读到旧单例，之后改单例又不会触发第二次渲染）。
@MainActor
public struct EDSThemePlayground<Content: View>: View {
    @State private var selectedID: String
    @State private var appliedRevision: Int = 0
    private let content: () -> Content

    public init(
        initialThemeID: String = EDSCatalogThemeCatalog.defaultThemeID,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._selectedID = State(initialValue: initialThemeID)
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            EDSThemeBar(selectionID: selectionBinding)
            Divider()
            content()
                .id(appliedRevision)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var selectionBinding: Binding<String> {
        Binding(
            get: { selectedID },
            set: { newValue in
                // Binding 的 set 由 SwiftUI 在主线程调用；Picker 交互必然在主线程。
                MainActor.assumeIsolated {
                    applyTheme(withID: newValue)   // ① 先落全局单例
                    selectedID = newValue          // ② 再改 state
                    appliedRevision += 1           // ③ 触发 `.id` 变化 → 重建子树
                }
            }
        )
    }

    @MainActor
    private func applyTheme(withID id: String) {
        guard let preset = EDSCatalogThemeCatalog.preset(id: id) else { return }
        EDSTheme.shared.applyPreset(preset)
    }
}
