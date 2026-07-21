import SwiftUI

// MARK: - State Patterns

public struct EDSEmptyState: View {
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
            iconColor: EDSTheme.shared.colors.textTertiary,
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
            iconColor: EDSTheme.shared.colors.danger,
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
        VStack(spacing: EDSTheme.shared.spacing.md) {
            ProgressView()
                .controlSize(.regular)

            VStack(spacing: EDSTheme.shared.spacing.xs) {
                Text(title)
                    .font(EDSTheme.shared.typography.bodyStrong)
                    .foregroundStyle(EDSTheme.shared.colors.textPrimary)

                if let message {
                    Text(message)
                        .font(EDSTheme.shared.typography.caption)
                        .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(EDSTheme.shared.spacing.xxl)
    }
}

public struct EDSProgressPanel: View {
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
            HStack(alignment: .top, spacing: EDSTheme.shared.spacing.md) {
                EDSSidebarIcon(
                    systemName: systemImage,
                    tint: EDSTheme.shared.colors.primary,
                    size: .medium
                )

                VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.sm) {
                    header
                    ProgressView(value: clampedFraction)
                        .progressViewStyle(.linear)

                    if let statusText {
                        Text(statusText)
                            .font(EDSTheme.shared.typography.caption)
                            .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: EDSTheme.shared.spacing.md) {
            VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.xxs) {
                Text(title)
                    .font(EDSTheme.shared.typography.bodyStrong)
                    .foregroundStyle(EDSTheme.shared.colors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(EDSTheme.shared.typography.caption)
                        .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: EDSTheme.shared.spacing.md)

            if let actionTitle, let action {
                EDSButton(actionTitle, role: .soft, systemImage: actionSystemImage, action: action)
            }
        }
    }

    private var clampedFraction: Double {
        max(0, min(1, fractionCompleted))
    }
}

private struct EDSStateContent: View {
    let systemImage: String
    let iconColor: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let actionRole: EDSButton.Role
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: EDSTheme.shared.spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.12))
                )

            VStack(spacing: EDSTheme.shared.spacing.xs) {
                Text(title)
                    .font(EDSTheme.shared.typography.sectionTitle)
                    .foregroundStyle(EDSTheme.shared.colors.textPrimary)

                if let message {
                    Text(message)
                        .font(EDSTheme.shared.typography.caption)
                        .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionTitle, let action {
                EDSButton(actionTitle, role: actionRole, systemImage: actionSystemImage, action: action)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(EDSTheme.shared.spacing.xxl)
    }
}
