import SwiftUI
import EasyDesignSystem

/// Easy API 的效果预览与最短调用参考。
///
/// 左侧按语义分类导航，右侧只展示当前场景。容器的 Token、背景、
/// padding、圆角和阴影全部由 `easyDesign` 决定。
public struct EDSEasyAPIDesignSystemGallery: View {
    @State private var selection = EasyGallerySection.overview.id
    @State private var notificationsEnabled = true

    public init() {}

    public var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)

            selectedContent
                .frame(minWidth: 600)
        }
        .frame(minWidth: 920, minHeight: 680)
    }

    private var sidebar: some View {
        VStack(alignment: .leading) {
            EDSPageTitle("Easy API", subtitle: "场景化最佳实践")

            EDSSidebarGroupView(
                title: "示例",
                items: EasyGallerySection.allCases.map(\.menuItem),
                selection: $selection
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .easyDesign(.group)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch EasyGallerySection(id: selection) {
        case .overview:
            overviewPage
        case .layout:
            layoutPage
        case .surfaces:
            surfacesPage
        case .themes:
            themesPage
        case .stress:
            stressPage
        }
    }

    private var overviewPage: some View {
        detailPage(
            "Easy API 概览",
            subtitle: "调用方只描述这是什么，设计系统决定如何呈现。"
        ) {
            EasyAPIExample(
                "一行启用页面最佳实践",
                usage: "ContentView().easyDesign()"
            ) {
                VStack(alignment: .leading) {
                    Text("默认等价于 .easyDesign(.page)")
                    EDSBadge("最大内容宽度", style: .accent)
                    EDSBadge("页面 padding", style: .success)
                    EDSBadge("主题前景色与 tint", style: .neutral)
                }
                .easyDesign(.group)
            }

            EasyAPIExample(
                "层次是语义化的",
                usage: "Page -> Section -> Group / Card -> 业务组件"
            ) {
                VStack(alignment: .leading) {
                    Text("容器使用 Easy API，按钮继续提供业务语义。")
                    HStack {
                        EDSButton("确定", role: .primary) {}
                        EDSButton("删除", role: .danger) {}
                    }
                }
                .easyDesign(.card)
            }
        }
    }

    private var layoutPage: some View {
        detailPage(
            "布局场景",
            subtitle: "Page、Content、Section 和 Plain 负责从页面到内容区的结构。"
        ) {
            EasyAPIExample(
                "Page",
                usage: ".easyDesign()"
            ) {
                Text("右侧整个详情页就是 Page：内容限宽、居中并应用标准外边距。")
            }

            EasyAPIExample(
                "Content",
                usage: ".easyDesign(.content)"
            ) {
                VStack(alignment: .leading) {
                    Text("适合已位于导航或滚动容器内的内容。")
                    Text("默认填满可用宽度，不额外制造视觉表面。")
                }
                .easyDesign(.content)
            }

            EasyAPIExample(
                "Section",
                usage: ".easyDesign(.section)"
            ) {
                VStack(alignment: .leading) {
                    EDSSectionTitle("通知", subtitle: "Section 负责信息结构和垂直节奏。")
                    EDSToggle(isOn: $notificationsEnabled, label: "接收更新通知")
                }
                .easyDesign(.section)
            }

            EasyAPIExample(
                "Plain",
                usage: ".easyDesign(.plain)"
            ) {
                Text("Plain 只传递主题、tint 和默认文本样式，不改变几何尺寸。")
                    .easyDesign(.plain)
            }
        }
    }

    private var surfacesPage: some View {
        detailPage(
            "视觉表面",
            subtitle: "Group 表达同一功能集合，Card 表达独立视觉层级。"
        ) {
            EasyAPIExample(
                "Group",
                usage: ".easyDesign(.group)"
            ) {
                VStack(alignment: .leading) {
                    EDSSectionTitle("通用设置", subtitle: "自适应 subtle 表面、标准 padding 和圆角。")
                    EDSSettingRow("自动更新", subtitle: "定期检查新版本。") {
                        EDSToggle(isOn: $notificationsEnabled, label: "启用")
                    }
                }
                .easyDesign(.group)
            }

            EasyAPIExample(
                "Card",
                usage: ".easyDesign(.card)"
            ) {
                VStack(alignment: .leading) {
                    EDSSectionTitle("专业版", subtitle: "语义卡片背景、边框和轻量阴影建立独立层级。")
                    HStack {
                        EDSBadge("已解锁", style: .success)
                        Spacer()
                        EDSButton("管理", role: .soft) {}
                    }
                }
                .easyDesign(.card)
            }
        }
    }

    private var themesPage: some View {
        detailPage(
            "局部主题",
            subtitle: "Environment 保存值类型 Token，局部主题不会修改全局状态。"
        ) {
            EasyAPIExample(
                "Preset 主题",
                usage: ".easyDesign(.card, theme: .orange)"
            ) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("继承当前主题")
                        EDSButton("继续", role: .primary) {}
                    }
                    .easyDesign(.card)

                    VStack(alignment: .leading) {
                        Text("仅这个子树使用橙色主题")
                        EDSButton("继续", role: .primary) {}
                    }
                    .easyDesign(.card, theme: .orange)
                }
            }

            EasyAPIExample(
                "仅传递主题",
                usage: ".easyDesignTheme(.purple)"
            ) {
                EDSButton("紫色主题按钮", role: .primary) {}
                    .easyDesignTheme(.purple)
            }
        }
    }

    private var stressPage: some View {
        detailPage(
            "嵌套与性能",
            subtitle: "正常页面保持 Page -> Section -> Group/Card 两到四层语义嵌套。"
        ) {
            ForEach(0..<4, id: \.self) { section in
                VStack(alignment: .leading) {
                    EDSSectionTitle("功能区 \(section + 1)")

                    HStack(alignment: .top) {
                        ForEach(0..<3, id: \.self) { item in
                            VStack(alignment: .leading) {
                                Text("项目 \(item + 1)")
                                EDSBadge("正常", style: .success)
                            }
                            .easyDesign(item.isMultiple(of: 2) ? .group : .card)
                        }
                    }
                }
                .easyDesign(.section)
            }
        }
    }

    private func detailPage<Content: View>(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                EDSPageTitle(title, subtitle: subtitle)
                content()
            }
            .easyDesign()
        }
    }
}

private struct EasyAPIExample<Content: View>: View {
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
        VStack(alignment: .leading) {
            EDSSectionTitle(title, subtitle: LocalizedStringKey(usage))
            content
        }
        .easyDesign(.section)
    }
}

private enum EasyGallerySection: String, CaseIterable, Identifiable {
    case overview
    case layout
    case surfaces
    case themes
    case stress

    var id: String { rawValue }

    init(id: String) {
        self = EasyGallerySection(rawValue: id) ?? .overview
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
        case .overview: "Easy API 概览"
        case .layout: "布局场景"
        case .surfaces: "视觉表面"
        case .themes: "局部主题"
        case .stress: "嵌套与性能"
        }
    }

    private var icon: String {
        switch self {
        case .overview: "sparkles"
        case .layout: "rectangle.3.group"
        case .surfaces: "square.stack.3d.up"
        case .themes: "paintpalette"
        case .stress: "square.grid.3x3"
        }
    }

    private var tint: Color {
        switch self {
        case .overview: .blue
        case .layout: .indigo
        case .surfaces: .teal
        case .themes: .orange
        case .stress: .purple
        }
    }
}

#Preview("Easy API Gallery") {
    EDSEasyAPIDesignSystemGallery()
}
