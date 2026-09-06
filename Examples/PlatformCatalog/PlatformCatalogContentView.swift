import SwiftUI
import Foundation
import EasyDesignSystem
import EasyDesignSystemCatalog
#if os(macOS)
import AppKit
#endif

struct PlatformCatalogContentView: View {
    @State private var selectedTab = ProcessInfo.processInfo.arguments.contains("--adaptive-preview") ? 3 : 0

    var body: some View {
        TabView(selection: $selectedTab) {
            EDSDesignSystemGallery()
                .accessibilityIdentifier("catalog.components")
                .tag(0)
                .tabItem {
                    Label("组件", systemImage: "square.grid.2x2")
                }

            EDSEasyAPIDesignSystemGallery()
                .accessibilityIdentifier("catalog.easy-api")
                .tag(1)
                .tabItem {
                    Label("Easy API", systemImage: "wand.and.stars")
                }

            EDSDesignSystemPreview()
                .accessibilityIdentifier("catalog.theme")
                .tag(2)
                .tabItem {
                    Label("主题", systemImage: "paintpalette")
                }

            AdaptiveCatalogView()
                .tag(3)
                .tabItem {
                    Label("适配", systemImage: "rectangle.3.group")
                }
        }
        .modifier(CatalogWindowSizeModifier())
        .modifier(CatalogSplitWidthModifier())
    }
}

private struct CatalogSplitWidthModifier: ViewModifier {
    private let usesSplitWidth = ProcessInfo.processInfo.arguments.contains("--split-width-preview")

    @ViewBuilder
    func body(content: Content) -> some View {
        if usesSplitWidth {
            content
                .frame(maxWidth: 440, maxHeight: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("split-width-preview")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            content
        }
    }
}

private struct CatalogWindowSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            let width: CGFloat?
            if arguments.contains("--narrow-window") {
                width = 620
            } else if arguments.contains("--wide-window") {
                width = 1_100
            } else {
                width = nil
            }

            guard let width else { return }
            DispatchQueue.main.async {
                NSApplication.shared.windows.first?.setContentSize(
                    NSSize(width: width, height: 720)
                )
            }
        }
        #else
        content
        #endif
    }
}

private struct AdaptiveCatalogView: View {
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedProfile = CatalogProfile.launchValue
    @State private var synchronizationEnabled = true
    @State private var colorScheme = ProcessInfo.processInfo.arguments.contains("--dark-preview")
        ? ColorScheme.dark
        : ColorScheme.light
    @State private var dynamicTypeSize: DynamicTypeSize? = ProcessInfo.processInfo.arguments.contains("--accessibility-preview")
        ? .accessibility5
        : nil

    var body: some View {
        EDSPage(
            "跨平台适配",
            subtitle: "使用同一套 API 检查布局、交互档案、外观和辅助字号。",
            showsBackground: true
        ) {
            EDSPageSection("预览环境") {
                VStack(alignment: .leading) {
                    Picker("交互档案", selection: $selectedProfile) {
                        ForEach(CatalogProfile.allCases) { profile in
                            Text(profile.title).tag(profile)
                        }
                    }
                    .accessibilityIdentifier("adaptive.profile")

                    Picker("外观", selection: $colorScheme) {
                        Text("浅色").tag(ColorScheme.light)
                        Text("深色").tag(ColorScheme.dark)
                    }
                    .accessibilityIdentifier("adaptive.color-scheme")

                    Picker("字体", selection: $dynamicTypeSize) {
                        Text("跟随系统").tag(nil as DynamicTypeSize?)
                        Text("最大辅助字号").tag(DynamicTypeSize.accessibility5 as DynamicTypeSize?)
                    }
                    .accessibilityIdentifier("adaptive.dynamic-type")
                }
                .easyDesign(.group)
            }

            EDSPageSection(
                "紧凑与常规宽度",
                subtitle: "两个预览分别强制 compact 和 regular size class。"
            ) {
                #if os(macOS) || targetEnvironment(macCatalyst)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top) {
                        previewCard(title: "Compact", sizeClass: .compact)
                            .frame(width: 320)
                        previewCard(title: "Regular", sizeClass: .regular)
                            .frame(width: 520)
                    }

                    previewCardsVertically
                }
                #else
                previewCardsVertically
                #endif
            }

            EDSPageSection(
                "辅助功能状态",
                subtitle: "验证增强对比度、无需颜色区分与减少动态效果。"
            ) {
                VStack(alignment: .leading) {
                    HStack {
                        EDSBadge("已完成", style: .success)
                        EDSBadge("请注意", style: .warning)
                        EDSBadge("失败", style: .danger)
                    }

                    Text(colorSchemeContrast == .increased ? "提高对比度：开启" : "提高对比度：关闭")
                        .accessibilityIdentifier("accessibility.increase-contrast.\(colorSchemeContrast == .increased ? "enabled" : "disabled")")
                    Text(differentiateWithoutColor ? "无需颜色区分：开启" : "无需颜色区分：关闭")
                        .accessibilityIdentifier("accessibility.differentiate-without-color.\(differentiateWithoutColor ? "enabled" : "disabled")")
                    Text(reduceMotion ? "减少动态效果：开启" : "减少动态效果：关闭")
                        .accessibilityIdentifier("accessibility.reduce-motion.\(reduceMotion ? "enabled" : "disabled")")
                }
                .easyDesign(.group)
            }
        }
        .easyDesignInteractionProfile(selectedProfile.value)
        .environment(\.colorScheme, colorScheme)
        .environment(\.dynamicTypeSize, dynamicTypeSize ?? systemDynamicTypeSize)
    }

    private var previewCardsVertically: some View {
                VStack(alignment: .leading) {
                    previewCard(title: "Compact", sizeClass: .compact)
                    previewCard(title: "Regular", sizeClass: .regular)
                }
    }

    private func previewCard(
        title: String,
        sizeClass: UserInterfaceSizeClass
    ) -> some View {
        VStack(alignment: .leading) {
            EDSSectionTitle(
                title: title,
                subtitle: "这是一段用于验证中英文混排、较长说明文字与自动换行效果的内容。EasyDesignSystem keeps the same semantic API on every supported platform."
            )

            EDSSettingRow(
                "跨设备同步",
                subtitle: "辅助字号下，说明与尾随控件会改为纵向布局，避免内容被截断。"
            ) {
                EDSToggle(isOn: $synchronizationEnabled, label: "启用")
            }

            EDSPillFlow(
                ["iPhone", "iPadOS", "macOS", "Mac Catalyst"],
                showsRemoveButton: true,
                onTap: { _ in },
                onRemove: { _ in }
            )

            HStack {
                EDSButton("继续", role: .primary) {}
                EDSButton("取消", role: .secondary) {}
            }
        }
        .easyDesign(.card)
        .environment(\.horizontalSizeClass, sizeClass)
    }
}

private enum CatalogProfile: String, CaseIterable, Identifiable {
    case automatic
    case touch
    case pointer
    case hybrid

    var id: Self { self }

    static var launchValue: CatalogProfile {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--touch-profile") { return .touch }
        if arguments.contains("--pointer-profile") { return .pointer }
        if arguments.contains("--hybrid-profile") { return .hybrid }
        return .automatic
    }

    var title: String {
        switch self {
        case .automatic: "自动"
        case .touch: "Touch"
        case .pointer: "Pointer"
        case .hybrid: "Hybrid"
        }
    }

    var value: EDSInteractionProfile {
        switch self {
        case .automatic: .automatic
        case .touch: .touch
        case .pointer: .pointer
        case .hybrid: .hybrid
        }
    }
}
