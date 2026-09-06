import SwiftUI

// MARK: - EDSSettingRow

public struct EDSSettingRow<Trailing: View>: View {
    @Environment(\.edsTheme) private var theme
    @Environment(\.edsInteractionProfile) private var interactionProfile
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        let metrics = EDSResolvedMetrics.resolve(
            tokens: theme,
            profile: interactionProfile,
            horizontalSizeClass: horizontalSizeClass
        )

        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    labels
                    trailing.frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(alignment: .center, spacing: theme.spacing.md) {
                    labels
                    Spacer(minLength: theme.spacing.md)
                    trailing
                }
            }
        }
        .frame(minHeight: metrics.interactiveHeight(for: theme.controlSize.rowMinHeight))
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(title)
                .edsFont(.bodyStrong, tokens: theme.typography)
                .foregroundStyle(theme.colors.textPrimary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .edsFont(.caption, tokens: theme.typography)
                    .foregroundStyle(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - EDSValueRow

public struct EDSValueRow: View {
    @Environment(\.edsTheme) private var theme
    @Environment(\.edsInteractionProfile) private var interactionProfile
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: LocalizedStringKey
    let value: String
    let tone: Color?

    public init(_ title: LocalizedStringKey, value: String, tone: Color? = nil) {
        self.title = title
        self.value = value
        self.tone = tone
    }

    public var body: some View {
        let metrics = EDSResolvedMetrics.resolve(
            tokens: theme,
            profile: interactionProfile,
            horizontalSizeClass: horizontalSizeClass
        )

        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    titleText
                    valueText
                }
            } else {
                HStack(spacing: theme.spacing.md) {
                    titleText
                    Spacer()
                    valueText
                }
            }
        }
        .frame(minHeight: metrics.interactiveHeight(for: 28))
    }

    private var titleText: some View {
        Text(title)
            .edsFont(.body, tokens: theme.typography)
            .foregroundStyle(theme.colors.textSecondary)
    }

    private var valueText: some View {
        Text(value)
            .edsFont(.bodyStrong, tokens: theme.typography)
            .foregroundStyle(tone ?? theme.colors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
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
