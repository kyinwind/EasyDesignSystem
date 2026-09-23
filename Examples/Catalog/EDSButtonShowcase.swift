import SwiftUI
import EasyDesignSystem

// MARK: - EDSButtonShowcase
//
// 按钮三维模型的展示与验收视图。覆盖四件事：
//
// 1. 预设入口（`Role`）—— 老写法，行为不变
// 2. `Emphasis` × `Tone` 组合矩阵 —— 展示正交模型的实际能力
// 3. 尺寸档位 `Size`
// 4. 可点击性验收：`.done` 与 `EDSBadge(.success)` 并列，检验体量区分是否足够
// 5. 别名等价性：`Role` 与等价三维组合应逐像素一致

public struct EDSButtonShowcase: View {
    @Environment(\.edsTheme) private var theme
    @State private var showsPageActions = false

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
            presetSection
            emphasisToneMatrix
            sizeSection
            doneVsBadgeSection
            aliasEquivalenceSection
            newCapabilitySection
            commandControlsSection
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("按钮三维模型")
                .edsFont(.bodyStrong, tokens: theme.typography)
                .foregroundColor(theme.colors.textPrimary)

            Text("底层实现由 emphasis × tone × size 三个正交维度驱动；Role 是一张预设别名表，两者汇入同一份渲染实现。")
                .edsFont(.caption, tokens: theme.typography)
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    // MARK: 预设入口

    private var presetSection: some View {
        section(
            "预设入口 · Role",
            subtitle: "一个角色 = 一组固定的三维组合。老代码写法与行为完全不变。"
        ) {
            HStack(spacing: theme.spacing.sm) {
                EDSButton("主要操作", role: .primary) {}
                EDSButton("次要操作", role: .secondary) {}
                EDSButton("常规灰底", role: .normal) {}
                EDSButton("轻量操作", role: .soft) {}
                EDSButton("危险操作", role: .danger) {}
                EDSButton("已完成", role: .done) {}
                EDSButton("零参数默认") {}
            }

            Text("最后一个未指定 role，走默认 .primary。这行能编译即证明三维初始化未产生重载歧义。")
                .edsFont(.caption, tokens: theme.typography)
                .foregroundColor(theme.colors.textTertiary)
        }
    }

    // MARK: 组合矩阵

    private var emphasisToneMatrix: some View {
        section(
            "组合矩阵 · Emphasis × Tone",
            subtitle: "改造前 4 种按钮只覆盖其中 4 格，其余格子旧模型无法表达。"
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.sm) {
                    Text("")
                        .frame(width: 56, alignment: .leading)
                    ForEach(EDSButton.Tone.allCases, id: \.self) { tone in
                        Text(tone.rawValue)
                            .edsFont(.caption, tokens: theme.typography)
                            .foregroundColor(theme.colors.textSecondary)
                            .frame(width: 84, alignment: .leading)
                    }
                }

                ForEach(EDSButton.Emphasis.allCases, id: \.self) { emphasis in
                    HStack(spacing: theme.spacing.sm) {
                        // outline 自 0.4.2 恢复为 M3 浅描边档，行标加注说明配方。
                        Text(emphasis.rawValue == "outline" ? "outline·浅描边" : emphasis.rawValue)
                            .edsFont(.caption, tokens: theme.typography)
                            .foregroundColor(theme.colors.textSecondary)
                            .frame(width: 56, alignment: .leading)

                        ForEach(EDSButton.Tone.allCases, id: \.self) { tone in
                            EDSButton("按钮", emphasis: emphasis, tone: tone) {}
                                .frame(width: 84, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    // MARK: 尺寸档位

    private var sizeSection: some View {
        section(
            "尺寸档位 · Size",
            subtitle: "regular 读取 controlSize.buttonHeight，与改造前完全一致；触屏档案下会自动放大到最小触控目标。"
        ) {
            HStack(alignment: .center, spacing: theme.spacing.md) {
                ForEach(EDSButton.Size.allCases, id: \.self) { size in
                    EDSButton(LocalizedStringKey(size.rawValue), emphasis: .filled, size: size) {}
                }
            }
        }
    }

    // MARK: .done 与 Badge 的可点击性验收

    private var doneVsBadgeSection: some View {
        section(
            "可点击性验收 · .done vs EDSBadge",
            subtitle: "按钮是实心绿 + ✓ + 34pt 高；徽章是浅绿胶囊且无交互。体量与色彩双重区分，不应再有误判。"
        ) {
            HStack(alignment: .bottom, spacing: theme.spacing.xxl) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("按钮 · 可点击")
                        .edsFont(.caption, tokens: theme.typography)
                        .foregroundColor(theme.colors.textSecondary)
                    EDSButton("已完成", role: .done) {}
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("徽章 · 不可点击")
                        .edsFont(.caption, tokens: theme.typography)
                        .foregroundColor(theme.colors.textSecondary)
                    EDSBadge("已完成", style: .success)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("按钮 · 无图标对照")
                        .edsFont(.caption, tokens: theme.typography)
                        .foregroundColor(theme.colors.textSecondary)
                    EDSButton("已完成", emphasis: .filled, tone: .success) {}
                }
            }
        }
    }

    // MARK: 别名等价性

    private var aliasEquivalenceSection: some View {
        section(
            "别名等价性 · Role ↔ 三维",
            subtitle: "每一行左右两侧应逐像素一致，用来证明别名表只是快捷方式，不是另一套实现。"
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                equivalenceRow(
                    "primary",
                    EDSButton("确定", role: .primary) {},
                    EDSButton("确定", emphasis: .filled, tone: .accent, size: .regular) {}
                )
                equivalenceRow(
                    "secondary",
                    EDSButton("取消", role: .secondary) {},
                    EDSButton("取消", emphasis: .medium, tone: .accent, size: .regular) {}
                )
                equivalenceRow(
                    "soft",
                    EDSButton("管理", role: .soft) {},
                    EDSButton("管理", emphasis: .soft, tone: .accent, size: .regular) {}
                )
                equivalenceRow(
                    "danger",
                    EDSButton("删除", role: .danger) {},
                    EDSButton("删除", emphasis: .filled, tone: .danger, size: .regular) {}
                )
                equivalenceRow(
                    "done",
                    EDSButton("已完成", role: .done) {},
                    EDSButton("已完成", emphasis: .filled, tone: .success, size: .regular, systemImage: "checkmark") {}
                )
            }
        }
    }

    // MARK: 新解锁的能力

    private var newCapabilitySection: some View {
        section(
            "改造解锁的典型场景",
            subtitle: "这些组合在旧的一维模型里无解——不是设计上不需要，是模型说不出。"
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                capabilityRow(
                    "对话框「忽略并删除」",
                    "次要但危险，不抢主操作视觉",
                    EDSButton("忽略并删除", emphasis: .soft, tone: .danger) {}
                )
                capabilityRow(
                    "卡片「更多」",
                    "纯文字，最轻一档",
                    EDSButton("更多", emphasis: .plain, tone: .accent, systemImage: "ellipsis") {}
                )
                capabilityRow(
                    "工具栏密集操作",
                    "28pt 小尺寸",
                    EDSButton("刷新", emphasis: .medium, tone: .accent, size: .small) {}
                )
                capabilityRow(
                    "主行动区 CTA",
                    "44pt 大尺寸",
                    EDSButton("开始处理", emphasis: .filled, tone: .accent, size: .large) {}
                )
                capabilityRow(
                    "中性次要操作",
                    "灰色实心，不抢主题色",
                    EDSButton("跳过", emphasis: .filled, tone: .neutral) {}
                )
            }
        }
    }

    // MARK: 命令组合组件

    private var commandControlsSection: some View {
        section(
            "命令组合",
            subtitle: "用明确的任务名称和分组关系收纳密集工具栏，避免把所有操作都降级为“更多”。"
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                EDSCommandGroup {
                    EDSButton("叠加元素", emphasis: .soft, size: .small, systemImage: "square.3.layers.3d") {}
                    EDSButton("背景音乐", emphasis: .soft, size: .small, systemImage: "music.note") {}
                }

                EDSSplitButton(
                    "导出视频",
                    role: .primary,
                    systemImage: "square.and.arrow.up",
                    menuAccessibilityLabel: "导出选项"
                ) {
                } menu: {
                    Button("导出 Word") {}
                    Button("导出讲解词") {}
                }

                EDSCommandPopover(
                    "页面操作",
                    isPresented: $showsPageActions,
                    size: .small,
                    systemImage: "slider.horizontal.3"
                ) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Button("隐藏当前页") { showsPageActions = false }
                        Button("插入视频") { showsPageActions = false }
                        Divider()
                        Button("删除页面", role: .destructive) { showsPageActions = false }
                    }
                    .padding(theme.spacing.md)
                    .frame(minWidth: 220, alignment: .leading)
                }
            }
        }
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
    private func equivalenceRow<LHS: View, RHS: View>(
        _ label: String,
        _ lhs: LHS,
        _ rhs: RHS
    ) -> some View {
        HStack(spacing: theme.spacing.lg) {
            Text(label)
                .edsFont(.caption, tokens: theme.typography)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 72, alignment: .leading)
            lhs
            rhs
        }
    }

    @ViewBuilder
    private func capabilityRow<Action: View>(
        _ title: String,
        _ note: String,
        _ action: Action
    ) -> some View {
        HStack(spacing: theme.spacing.lg) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .edsFont(.caption, tokens: theme.typography)
                    .foregroundColor(theme.colors.textPrimary)
                Text(note)
                    .edsFont(.caption, tokens: theme.typography)
                    .foregroundColor(theme.colors.textTertiary)
            }
            .frame(width: 220, alignment: .leading)

            action
            Spacer()
        }
    }
}

#Preview("按钮三维模型 · 主题可切换") {
    EDSThemePlayground {
        EDSButtonShowcase()
    }
    .frame(width: 1_020, height: 760)
}
