import SwiftUI

// MARK: - EDSSettingRow

public struct EDSSettingRow<Trailing: View>: View {
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
        HStack(alignment: .center, spacing: EDSTheme.shared.spacing.md) {
            VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.xxs) {
                Text(title)
                    .font(EDSTheme.shared.typography.bodyStrong)
                    .foregroundStyle(EDSTheme.shared.colors.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(EDSTheme.shared.typography.caption)
                        .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: EDSTheme.shared.spacing.md)
            trailing
        }
        .frame(minHeight: EDSTheme.shared.controlSize.rowMinHeight)
    }
}

// MARK: - EDSValueRow

public struct EDSValueRow: View {
    let title: LocalizedStringKey
    let value: String
    let tone: Color

    public init(_ title: LocalizedStringKey, value: String, tone: Color = EDSTheme.shared.colors.textPrimary) {
        self.title = title
        self.value = value
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: EDSTheme.shared.spacing.md) {
            Text(title)
                .font(EDSTheme.shared.typography.body)
                .foregroundStyle(EDSTheme.shared.colors.textSecondary)

            Spacer()

            Text(value)
                .font(EDSTheme.shared.typography.bodyStrong)
                .foregroundStyle(tone)
        }
        .frame(minHeight: 28)
    }
}

// MARK: - EDSInlineField

public struct EDSInlineField<Content: View>: View {
    let label: LocalizedStringKey
    let content: Content

    public init(_ label: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.xs) {
            EDSLabelText(label)
            content
        }
    }
}
