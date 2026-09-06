import SwiftUI

// MARK: - State Patterns

public struct EDSEmptyState: View {
    @Environment(\.edsTheme) private var theme
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let action: (() -> Void)?

    public init(
        systemImage: String = "tray",
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        actionTitle: LocalizedStringKey? = nil,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
    }

    public var body: some View {
        EDSStateContent(
            systemImage: systemImage,
            iconColor: theme.colors.textTertiary,
            title: title,
            message: message,
            actionTitle: actionTitle,
            actionSystemImage: actionSystemImage,
            actionRole: .soft,
            action: action
        )
    }
}

public struct EDSErrorState: View {
    @Environment(\.edsTheme) private var theme
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let action: (() -> Void)?

    public init(
        systemImage: String = "exclamationmark.triangle",
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        actionTitle: LocalizedStringKey? = nil,
        actionSystemImage: String? = "arrow.clockwise",
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
    }

    public var body: some View {
        EDSStateContent(
            systemImage: systemImage,
            iconColor: theme.colors.danger,
            title: title,
            message: message,
            actionTitle: actionTitle,
            actionSystemImage: actionSystemImage,
            actionRole: .secondary,
            action: action
        )
    }
}

public struct EDSLoadingState: View {
    @Environment(\.edsTheme) private var theme
    let title: LocalizedStringKey
    let message: LocalizedStringKey?

    public init(
        _ title: LocalizedStringKey = "正在处理",
        message: LocalizedStringKey? = nil
    ) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            ProgressView()
                .controlSize(.regular)

            VStack(spacing: theme.spacing.xs) {
                Text(title)
                    .edsFont(.bodyStrong, tokens: theme.typography)
                    .foregroundStyle(theme.colors.textPrimary)

                if let message {
                    Text(message)
                        .edsFont(.caption, tokens: theme.typography)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.xxl)
    }
}

public struct EDSProgressPanel: View {
    @Environment(\.edsTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let fractionCompleted: Double
    let statusText: LocalizedStringKey?
    let systemImage: String
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let action: (() -> Void)?

    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        fractionCompleted: Double,
        statusText: LocalizedStringKey? = nil,
        systemImage: String = "arrow.down.circle",
        actionTitle: LocalizedStringKey? = nil,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.fractionCompleted = fractionCompleted
        self.statusText = statusText
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
    }

    public var body: some View {
        EDSGroup {
            HStack(alignment: .top, spacing: theme.spacing.md) {
                EDSSidebarIcon(
                    systemName: systemImage,
                    tint: theme.colors.primary,
                    size: .medium
                )

                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    header
                    ProgressView(value: clampedFraction)
                        .progressViewStyle(.linear)

                    if let statusText {
                        Text(statusText)
                            .edsFont(.caption, tokens: theme.typography)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
            }
        }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    headerText
                    actionButton
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: theme.spacing.md) {
                    headerText
                    Spacer(minLength: theme.spacing.md)
                    actionButton
                }
            }
        }
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(title)
                .edsFont(.bodyStrong, tokens: theme.typography)
                .foregroundStyle(theme.colors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .edsFont(.caption, tokens: theme.typography)
                    .foregroundStyle(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if let actionTitle, let action {
            EDSButton(actionTitle, role: .soft, systemImage: actionSystemImage, action: action)
        }
    }

    private var clampedFraction: Double {
        max(0, min(1, fractionCompleted))
    }
}

private struct EDSStateContent: View {
    @Environment(\.edsTheme) private var theme
    let systemImage: String
    let iconColor: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let actionRole: EDSButton.Role
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.12))
                )

            VStack(spacing: theme.spacing.xs) {
                Text(title)
                    .edsFont(.sectionTitle, tokens: theme.typography)
                    .foregroundStyle(theme.colors.textPrimary)

                if let message {
                    Text(message)
                        .edsFont(.caption, tokens: theme.typography)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionTitle, let action {
                EDSButton(actionTitle, role: actionRole, systemImage: actionSystemImage, action: action)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.xxl)
    }
}
