import SwiftUI
import EasyDesignSystem

// MARK: - EDSDesignSystemGallery

/// DesignSystem 组件与页面模式 Gallery。
///
/// `EDSDesignSystemPreview` 主要用于调整 token；`EDSDesignSystemGallery` 用来观察
/// DesignSystem 在真实页面结构里的默认效果。
public struct EDSDesignSystemGallery: View {
    @State private var selection: GallerySection.ID = GallerySection.page.id
    @State private var isEnabled = true
    @State private var progress = 0.42

    public init() {}

    public var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)

            selectedContent
                .frame(minWidth: 560)
        }
        .frame(minWidth: 900, minHeight: 640)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.lg) {
            EDSPageTitle("Gallery", subtitle: "DesignSystem 组件和页面模式")

            EDSSidebarGroupView(
                title: "页面",
                items: GallerySection.allCases.map(\.menuItem),
                selection: $selection
            )

            Spacer()
        }
        .padding(EDSTheme.shared.spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(EDSTheme.shared.colors.cardBackground)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch GallerySection(id: selection) {
        case .page:
            pageExample
        case .states:
            statesExample
        case .controls:
            controlsExample
        case .rows:
            rowsExample
        case .surfaces:
            surfacesExample
        }
    }

    private var pageExample: some View {
        EDSPage("标准设置页", subtitle: "推荐结构：EDSPage -> EDSPageSection -> EDSGroup -> Row / Control") {
            EDSPageSection("基础设置") {
                GalleryExample(
                    "EDSPageSection + EDSGroup + EDSSettingRow",
                    usage: "EDSPageSection { EDSGroup { EDSSettingRow(...) } }"
                ) {
                    EDSGroup("通用", subtitle: "常用偏好集中放在一个内容分组里。") {
                        EDSSettingRow("自动检查更新", subtitle: "启动后自动检查是否有新版本。") {
                            EDSToggle(isOn: $isEnabled, label: "启用")
                        }

                        EDSSettingRow("默认导出目录", subtitle: "/Users/name/Documents/Exports") {
                            EDSButton("更改", role: .soft, systemImage: "folder") {}
                        }
                    }
                }
            }

            EDSPageSection("状态反馈") {
                GalleryExample(
                    "EDSProgressPanel",
                    usage: "EDSProgressPanel(\"模型下载\", fractionCompleted: progress)"
                ) {
                    EDSProgressPanel(
                        "模型下载",
                        subtitle: "LaMa.mlpackage.zip",
                        fractionCompleted: progress,
                        statusText: "正在从最快的可用源下载...",
                        actionTitle: "取消",
                        actionSystemImage: "xmark"
                    ) {}
                }
            }

            EDSPageSection("操作") {
                GalleryExample(
                    "EDSButton",
                    usage: "EDSButton(\"保存设置\", role: .primary, systemImage: \"checkmark\")"
                ) {
                    EDSGroup(style: .plain) {
                        HStack(spacing: EDSTheme.shared.spacing.md) {
                            EDSButton("保存设置", role: .primary, systemImage: "checkmark") {}
                            EDSButton("恢复默认", role: .soft, systemImage: "arrow.counterclockwise") {}
                        }
                    }
                }
            }
        }
    }

    private var statesExample: some View {
        EDSPage("状态模式", subtitle: "空状态、错误状态、加载状态和进度面板是最常见的页面片段。") {
            EDSPageSection("空状态") {
                GalleryExample(
                    "EDSEmptyState",
                    usage: "EDSEmptyState(systemImage: \"tray\", title: \"暂无文件\")"
                ) {
                    EDSGroup {
                        EDSEmptyState(
                            systemImage: "tray",
                            title: "暂无文件",
                            message: "添加文件后会显示在这里。",
                            actionTitle: "添加文件",
                            actionSystemImage: "plus"
                        ) {}
                    }
                }
            }

            EDSPageSection("错误和加载") {
                HStack(alignment: .top, spacing: EDSTheme.shared.spacing.md) {
                    GalleryExample(
                        "EDSErrorState",
                        usage: "EDSErrorState(title: \"加载失败\", actionTitle: \"重试\")"
                    ) {
                        EDSGroup {
                            EDSErrorState(
                                title: "加载失败",
                                message: "请检查网络后重试。",
                                actionTitle: "重试"
                            ) {}
                        }
                    }

                    GalleryExample(
                        "EDSLoadingState",
                        usage: "EDSLoadingState(\"正在处理\", message: \"...\")"
                    ) {
                        EDSGroup {
                            EDSLoadingState("正在处理", message: "这通常只需要几秒。")
                        }
                    }
                }
            }
        }
    }

    private var controlsExample: some View {
        EDSPage("基础控件", subtitle: "按钮、徽章和开关默认跟随 EDSTheme。") {
            EDSPageSection("按钮") {
                GalleryExample(
                    "EDSButton",
                    usage: "EDSButton(\"主要操作\", role: .primary, systemImage: \"checkmark\")"
                ) {
                    EDSGroup {
                        HStack(spacing: EDSTheme.shared.spacing.md) {
                            EDSButton("主要操作", role: .primary, systemImage: "checkmark") {}
                            EDSButton("次要操作", role: .secondary, systemImage: "slider.horizontal.3") {}
                            EDSButton("轻量操作", role: .soft, systemImage: "sparkles") {}
                            EDSButton("危险操作", role: .danger, systemImage: "trash") {}
                        }
                    }
                }
            }

            EDSPageSection("徽章和开关") {
                GalleryExample(
                    "EDSBadge + EDSToggle",
                    usage: "EDSBadge(\"已完成\", style: .success) / EDSToggle(isOn: $value)"
                ) {
                    EDSGroup {
                        HStack(spacing: EDSTheme.shared.spacing.sm) {
                            EDSBadge("Pro", style: .accent)
                            EDSBadge("已完成", style: .success)
                            EDSBadge("待处理", style: .warning)
                            EDSBadge("失败", style: .danger)
                            EDSBadge(verbatim: "v1.0.0", style: .neutral)
                        }

                        EDSSettingRow("启用自动处理", subtitle: "适合二元开关型设置。") {
                            EDSToggle(isOn: $isEnabled, label: "启用")
                        }
                    }
                }
            }
        }
    }

    private var rowsExample: some View {
        EDSPage("行和标签", subtitle: "设置行、键值行、内联字段和流式标签。") {
            EDSPageSection("设置行") {
                GalleryExample(
                    "EDSSettingRow + EDSValueRow",
                    usage: "EDSSettingRow(\"标题\") { trailing } / EDSValueRow(\"标题\", value: \"值\")"
                ) {
                    EDSGroup {
                        EDSSettingRow("图片输出格式", subtitle: "用于批量处理后的默认格式。") {
                            EDSBadge("PNG", style: .accent)
                        }

                        EDSValueRow("今日处理", value: "128 张", tone: EDSTheme.shared.colors.success)
                        EDSValueRow("缓存占用", value: "240 MB", tone: EDSTheme.shared.colors.warning)
                    }
                }
            }

            EDSPageSection("流式标签") {
                GalleryExample(
                    "EDSPillFlow",
                    usage: "EDSPillFlow(items, sortOrder: .ascending, showsRemoveButton: true)"
                ) {
                    EDSGroup {
                        EDSPillFlow(
                            ["75%", "100%", "110%", "1280x720", "1920x1080", "2560x1600", "4K"],
                            sortOrder: .ascending,
                            minItemWidth: 88,
                            showsRemoveButton: true,
                            onTap: { _ in },
                            onRemove: { _ in }
                        )
                    }
                }
            }
        }
    }

    private var surfacesExample: some View {
        EDSPage("容器分层", subtitle: "PageSection 管章节，Group 管内容分组，Card 是底层视觉容器。") {
            EDSPageSection("分组") {
                GalleryExample(
                    "EDSGroup",
                    usage: "EDSGroup(\"默认分组\", subtitle: \"...\") { content }"
                ) {
                    EDSGroup("默认分组", subtitle: "默认浅背景，无边框。") {
                        EDSValueRow("语义", value: "内容分组")
                        EDSValueRow("默认背景", value: "浅色")
                    }
                }
            }

            EDSPageSection("强调面板") {
                GalleryExample(
                    "EDSHeroPanel",
                    usage: "EDSHeroPanel { content }"
                ) {
                    EDSHeroPanel {
                        VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.sm) {
                            Text("Hero Panel")
                                .font(EDSTheme.shared.typography.hero)
                                .foregroundStyle(.white)
                            Text("用于第一屏强调、关键状态或付费权益说明。")
                                .font(EDSTheme.shared.typography.body)
                                .foregroundStyle(.white.opacity(0.82))
                        }
                    }
                }
            }

            EDSPageSection("底层卡片") {
                GalleryExample(
                    "EDSCard",
                    usage: "EDSCard { ... } / EDSCard(background: ...) { ... }"
                ) {
                    HStack(alignment: .top, spacing: EDSTheme.shared.spacing.md) {
                        EDSCard {
                            Text("默认 EDSCard 只提供 padding，不绘制背景。")
                                .font(EDSTheme.shared.typography.body)
                        }

                        EDSCard(background: EDSTheme.shared.colors.accentSoft) {
                            Text("显式传入 background 时才绘制背景和圆角。")
                                .font(EDSTheme.shared.typography.body)
                        }
                    }
                }
            }
        }
    }
}

private struct GalleryExample<Content: View>: View {
    let title: LocalizedStringKey
    let usage: String
    let content: Content

    init(
        _ title: LocalizedStringKey,
        usage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.usage = usage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.sm) {
            VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.xs) {
                Text(title)
                    .font(EDSTheme.shared.typography.bodyStrong)
                    .foregroundStyle(EDSTheme.shared.colors.primary)

                Text(verbatim: usage)
                    .font(EDSTheme.shared.typography.monoCaption)
                    .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, EDSTheme.shared.spacing.sm)
                    .padding(.vertical, EDSTheme.shared.spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: EDSTheme.shared.radius.sm, style: .continuous)
                            .fill(EDSTheme.shared.colors.subtleFill)
                    )
            }

            content
        }
    }
}

private enum GallerySection: String, CaseIterable, Identifiable {
    case page
    case states
    case controls
    case rows
    case surfaces

    var id: String { rawValue }

    init(id: String) {
        self = GallerySection(rawValue: id) ?? .page
    }

    var menuItem: EDSSidebarMenuItem {
        EDSSidebarMenuItem(
            id: id,
            label: label,
            icon: icon,
            tint: tint
        )
    }

    private var label: String {
        switch self {
        case .page: return "标准页面"
        case .states: return "状态模式"
        case .controls: return "基础控件"
        case .rows: return "行与标签"
        case .surfaces: return "容器分层"
        }
    }

    private var icon: String {
        switch self {
        case .page: return "rectangle.3.group"
        case .states: return "circle.dotted"
        case .controls: return "switch.2"
        case .rows: return "list.bullet.rectangle"
        case .surfaces: return "square.stack.3d.up"
        }
    }

    private var tint: Color {
        switch self {
        case .page: return EDSTheme.shared.colors.primary
        case .states: return EDSTheme.shared.colors.warning
        case .controls: return EDSTheme.shared.colors.success
        case .rows: return .purple
        case .surfaces: return .teal
        }
    }
}

#Preview{
    EDSDesignSystemGallery()
}
