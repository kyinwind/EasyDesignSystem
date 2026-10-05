import SwiftUI
import EasyDesignSystem

// MARK: - EDSActionBarShowcase

/// 命令编排层的展示与验收视图。覆盖六件事：
///
/// 1. 六个语义 case 的默认图标与默认角色
/// 2. 内建双语标题 vs 调用方自定义标题
/// 3. 三种对齐
/// 4. 三种尺寸
/// 5. 四种布局风格
/// 6. 宽度自适应：同一组命令在窄容器里应自动收成 `EDSCommandGroup`
///
/// 验收要点：切换主题种子色后，所有按钮必须跟着变色——这是本组件存在的首要理由。

public struct EDSActionBarShowcase: View {
    @Environment(\.edsTheme) private var theme
    @State private var lastAction = "（未点击）"

    private let embedsScrollView: Bool

    /// - Parameter embedsScrollView: 独立预览时为 `true`（自带滚动）；嵌入到已有滚动
    ///   容器的页面（如 Gallery 的 `EDSPage`）时传 `false`，避免嵌套滚动。
    public init(embedsScrollView: Bool = true) {
        self.embedsScrollView = embedsScrollView
    }

    public var body: some View {
        if embedsScrollView {
            ScrollView { content }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxl) {
            header
            semanticSection
            customAppearanceSection
            titleSection
            alignmentSection
            sizeSection
            layoutStyleSection
            adaptiveSection
            stateSection
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 自定义按钮外观

    private var customAppearanceSection: some View {
        section(
            "Custom · 三维按钮样式",
            subtitle: "可继续使用 role 预设，也可直接组合 Emphasis / Tone / Size；单项 size 可覆盖 ActionBar 的统一尺寸。"
        ) {
            EDSActionBar([
                .custom(title: "角色预设", systemImage: "square.and.arrow.up", role: .secondary) {
                    lastAction = "roleCustom"
                },
                .custom(
                    title: "直接指定",
                    systemImage: "exclamationmark.triangle",
                    emphasis: .outline,
                    tone: .warning,
                    size: .large
                ) {
                    lastAction = "dimensionCustom"
                },
            ], alignment: .leading, size: .small, layoutStyle: .horizontal)
        }
    }

    // MARK: 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("命令编排层")
                .edsFont(.bodyStrong, tokens: theme.typography)
                .foregroundColor(theme.colors.textPrimary)

            Text("调用方给的是意图，由组件翻译成按钮、决定图标与角色、排好队，并在拥挤时自己降级。")
                .edsFont(.caption, tokens: theme.typography)
                .foregroundColor(theme.colors.textSecondary)

            Text("最近点击：\(lastAction)")
                .edsFont(.caption, tokens: theme.typography)
                .foregroundColor(theme.colors.accentSoft)
        }
    }

    // MARK: 语义 case

    private var semanticSection: some View {
        section(
            "语义 case · 默认图标与默认角色",
            subtitle: "add=secondary / edit=normal / delete=danger / save=primary / cancel=normal / custom=secondary"
        ) {
            EDSActionBar([
                .add(title: nil) { lastAction = "add" },
                .edit { lastAction = "edit" },
                .delete { lastAction = "delete" },
                .save { lastAction = "save" },
                .cancel { lastAction = "cancel" },
                .custom(title: "导出", systemImage: "square.and.arrow.up") { lastAction = "custom" },
            ], alignment: .leading)
        }
    }

    // MARK: 标题策略

    private var titleSection: some View {
        section(
            "标题策略 · 内建双语 vs 自定义",
            subtitle: "省略 title 时用 EDS 资源包内的文案；传 title 时按调用方的本地化系统走。"
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                EDSActionBar([
                    .add { lastAction = "add" },
                    .save { lastAction = "save" },
                ], alignment: .leading)

                EDSActionBar([
                    .save(title: "保存并继续") { lastAction = "saveContinue" },
                    .cancel(title: "放弃修改", shortcut: .escape) { lastAction = "cancel" },
                ], alignment: .leading)
            }
        }
    }

    // MARK: 对齐

    private var alignmentSection: some View {
        section("对齐方式 · Alignment", subtitle: "leading / center / trailing，默认 trailing。") {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                ForEach(alignmentCases, id: \.0) { label, value in
                    row(label) {
                        EDSActionBar([
                            .add { lastAction = "add" },
                            .edit { lastAction = "edit" },
                            .delete(enabled: false) { lastAction = "delete" },
                        ], alignment: value, layoutStyle: .horizontal)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: 尺寸

    private var sizeSection: some View {
        section("尺寸档位 · Size", subtitle: "small=28pt / regular=34pt / large=44pt，容器不预设高度，由内容决定。") {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                ForEach(EDSButton.Size.allCases, id: \.self) { size in
                    row(size.rawValue) {
                        EDSActionBar([
                            .add { lastAction = "add" },
                            .save(title: "保存", shortcut: .commandS) { lastAction = "save" },
                        ], alignment: .leading, size: size, layoutStyle: .horizontal)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: 布局风格

    private var layoutStyleSection: some View {
        section(
            "布局风格 · LayoutStyle",
            subtitle: "automatic 会按可用宽度在 regular 与 compact 之间自动切换，其余三档是固定行为。"
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                ForEach(layoutCases, id: \.0) { label, value in
                    row(label) {
                        EDSActionBar([
                            .add { lastAction = "add" },
                            .edit { lastAction = "edit" },
                            .delete(enabled: false) { lastAction = "delete" },
                            .save(title: "保存", shortcut: .commandS) { lastAction = "save" },
                        ], alignment: .leading, layoutStyle: value)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: 宽度自适应验收

    private var adaptiveSection: some View {
        section(
            "宽度自适应验收 · automatic",
            subtitle: "下面三条内容完全相同。拖动/缩放窗口或对照宽度：宽的一行排开，窄的应自动收成命令组，且不闪烁。"
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                row("520pt") {
                    EDSActionBar(sampleItems, size: .small)
                        .frame(width: 520)
                }
                row("260pt") {
                    EDSActionBar(sampleItems, size: .small)
                        .frame(width: 260)
                }
                row("150pt") {
                    EDSActionBar(sampleItems, size: .small)
                        .frame(width: 150)
                }
            }
        }
    }

    // MARK: 状态与快捷键

    private var stateSection: some View {
        section(
            "禁用状态与快捷键",
            subtitle: "快捷键不占用按钮标签；通过 keyboardShortcut 生效，鼠标悬停与无障碍提示会显示快捷键。"
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                row("全可用") {
                    EDSActionBar([
                        .save(title: "保存", shortcut: .commandS) { lastAction = "save" },
                        .cancel(title: "取消", shortcut: .escape) { lastAction = "cancel" },
                    ], alignment: .leading, layoutStyle: .horizontal)
                    .frame(maxWidth: .infinity)
                }

                row("全禁用") {
                    EDSActionBar([
                        .save(title: "保存", enabled: false, shortcut: .commandS) { lastAction = "save" },
                        .cancel(title: "取消", enabled: false) { lastAction = "cancel" },
                    ], alignment: .leading, layoutStyle: .horizontal)
                    .frame(maxWidth: .infinity)
                }

                row("收成命令组") {
                    EDSActionBar([
                        .save(title: "保存", enabled: false) { lastAction = "save" },
                        .cancel(title: "取消") { lastAction = "cancel" },
                    ], alignment: .leading, layoutStyle: .compact)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: 数据

    private var sampleItems: [EDSActionItem] {
        [
            .add { lastAction = "add" },
            .edit { lastAction = "edit" },
            .delete(enabled: false) { lastAction = "delete" },
            .save(title: "保存", shortcut: .commandS) { lastAction = "save" },
        ]
    }

    private var alignmentCases: [(String, EDSActionBarAlignment)] {
        [("leading", .leading), ("center", .center), ("trailing", .trailing)]
    }

    private var layoutCases: [(String, EDSActionBarLayoutStyle)] {
        [("automatic", .automatic), ("horizontal", .horizontal), ("wrapping", .wrapping), ("compact", .compact)]
    }

    // MARK: 布局工具

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .edsFont(.bodyStrong, tokens: theme.typography)
                    .foregroundColor(theme.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .edsFont(.caption, tokens: theme.typography)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            content()
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.lg)
                .fill(theme.colors.cardBackground)
        )
    }

    @ViewBuilder
    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: theme.spacing.lg) {
            Text(label)
                .edsFont(.caption, tokens: theme.typography)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 84, alignment: .leading)
            content()
        }
    }
}

#Preview("命令编排层 · 主题可切换") {
    EDSThemePlayground {
        EDSActionBarShowcase()
    }
    .frame(width: 1_020, height: 820)
}
