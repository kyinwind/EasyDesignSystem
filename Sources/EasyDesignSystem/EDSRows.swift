import SwiftUI

// MARK: - EDSSettingRow

public struct EDSSettingRow<Trailing: View>: View {
    @Environment(\.edsTheme) private var theme
    let title: LocalizedStringKey
    let subtitle: String?
    let trailing: Trailing

    public init(
        _ title: LocalizedStringKey,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.md) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.bodyStrong)
                    .foregroundStyle(theme.colors.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: theme.spacing.md)
            trailing
        }
        .frame(minHeight: theme.controlSize.rowMinHeight)
    }
}

// MARK: - EDSValueRow

public struct EDSValueRow: View {
    @Environment(\.edsTheme) private var theme
    let title: LocalizedStringKey
    let value: String
    let tone: Color?

    public init(_ title: LocalizedStringKey, value: String, tone: Color? = nil) {
        self.title = title
        self.value = value
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: theme.spacing.md) {
            Text(title)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)

            Spacer()

            Text(value)
                .font(theme.typography.bodyStrong)
                .foregroundStyle(tone ?? theme.colors.textPrimary)
        }
        .frame(minHeight: 28)
    }
}

// MARK: - EDSInlineField

public struct EDSInlineField<Content: View>: View {
    @Environment(\.edsTheme) private var theme
    let label: LocalizedStringKey
    let content: Content

    public init(_ label: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            EDSLabelText(label)
            content
        }
    }
}
