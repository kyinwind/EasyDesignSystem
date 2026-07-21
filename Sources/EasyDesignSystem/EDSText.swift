import SwiftUI

// macOS SwiftUI 中会自动切换的系统颜色：
//
// 背景色：
// Color(.textBackgroundColor) / .controlBackgroundColor / .windowBackgroundColor
// .secondarySystemBackground / .tertiarySystemBackground
// .underPageBackground / .underWindowBackground
//
// 文字色：
// .labelColor / .secondaryLabelColor / .tertiaryLabelColor
// .quaternaryLabelColor
//
// 其他：
// .separatorColor / .opaqueSeparatorColor - 分隔线
// .selectionColor - 选中色
// .controlColor - 控件色
//
// macOS 特有：
// .alternatingContentBackgroundColors
//
// 建议使用 Color(.controlBackgroundColor) 作为卡片背景，Color(.labelColor) 作为文字色，
// 这样在亮色/暗色模式下都会自动适配。

// MARK: - EDSPageTitle

/// 页面的大标题（用于页面顶部的标题区域）
public struct EDSPageTitle: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?

    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.xs) {
            Text(title)
                .font(EDSTheme.shared.typography.pageTitle)
                .foregroundStyle(EDSTheme.shared.colors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(EDSTheme.shared.typography.body)
                    .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - EDSSectionTitle

/// 章节标题（用于页面内每个区块的标题）
public struct EDSSectionTitle: View {
    let titleText: Text
    let subtitleText: Text?

    // 1. 支持 LocalizedStringKey（SwiftUI原生方式）
    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.titleText = Text(title)
        self.subtitleText = subtitle.map { Text($0) }
    }

    // 2. 支持 String
    public init(title: String, subtitle: String? = nil) {
        self.titleText = Text(title)
        self.subtitleText = subtitle.map { Text($0) }
    }

    // 3. 支持直接传 Text（最灵活）
    public init(title: Text, subtitle: Text? = nil) {
        self.titleText = title
        self.subtitleText = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.xxs) {
            titleText
                .font(EDSTheme.shared.typography.sectionTitle)
                .foregroundStyle(EDSTheme.shared.colors.textPrimary)

            if let subtitleText {
                subtitleText
                    .font(EDSTheme.shared.typography.caption)
                    .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - EDSLabelText

/// 表单标签文字（次要层级，用于 label）
public struct EDSLabelText: View {
    let text: LocalizedStringKey

    public init(_ text: LocalizedStringKey) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(EDSTheme.shared.typography.captionStrong)
            .foregroundStyle(EDSTheme.shared.colors.textSecondary)
            .textCase(nil)
    }
}

// MARK: - EDSCaptionText

/// 说明文字（最次要层级，用于 caption）
public struct EDSCaptionText: View {
    let text: LocalizedStringKey

    public init(_ text: LocalizedStringKey) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(EDSTheme.shared.typography.caption)
            .foregroundStyle(EDSTheme.shared.colors.textSecondary)
    }
}

// MARK: - EDSMonoText

/// 等宽文字（用于路径、代码等）
public struct EDSMonoText: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(EDSTheme.shared.typography.monoCaption)
            .foregroundStyle(EDSTheme.shared.colors.textSecondary)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}
