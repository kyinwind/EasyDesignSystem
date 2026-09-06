import SwiftUI

/// 标准的 Free / Pro 功能对比区域。
public struct EDSComparisonSection: View {
    @Environment(\.edsTheme) private var theme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    public let features: [(String, Bool, Bool)]

    public init(features: [(String, Bool, Bool)]) {
        self.features = features
    }

    public var body: some View {
        EDSSection(header: {
            EDSSectionTitle(title: localized("EDSComparisonSection.features.title"))
                .padding(.vertical, 10)
        }) {
            if horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize {
                compactContent
            } else {
                tableContent
            }
        }
    }

    private var tableContent: some View {
            VStack(spacing: theme.spacing.sm) {
                HStack {
                    header("EDSComparisonSection.features.features", width: 55)
                    Spacer()
                    header("EDSComparisonSection.features.free", width: 72)
                    header("EDSComparisonSection.features.pro", width: 72)
                }

                Divider()

                ForEach(features.indices, id: \.self) { index in
                    HStack(spacing: theme.spacing.md) {
                        Text("\(index + 1).")
                        Text(features[index].0)
                            .edsFont(.body, tokens: theme.typography)
                            .foregroundStyle(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        EDSIconMark(isOn: features[index].1)
                            .frame(width: 72)
                        EDSIconMark(isOn: features[index].2)
                            .frame(width: 72)
                    }
                }
            }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            ForEach(features.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("\(index + 1). \(features[index].0)")
                        .edsFont(.body, tokens: theme.typography)
                        .foregroundStyle(theme.colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: theme.spacing.lg) {
                        compactValue(
                            "EDSComparisonSection.features.free",
                            isOn: features[index].1
                        )
                        compactValue(
                            "EDSComparisonSection.features.pro",
                            isOn: features[index].2
                        )
                    }
                }

                if index != features.indices.last {
                    Divider()
                }
            }
        }
    }

    private func compactValue(_ key: String, isOn: Bool) -> some View {
        HStack(spacing: theme.spacing.xs) {
            Text(localized(key))
                .edsFont(.captionStrong, tokens: theme.typography)
                .foregroundStyle(theme.colors.textSecondary)
            EDSIconMark(isOn: isOn)
        }
        .accessibilityElement(children: .combine)
    }

    private func header(_ key: String, width: CGFloat) -> some View {
        Text(localized(key))
            .edsFont(.captionStrong, tokens: theme.typography)
            .foregroundStyle(theme.colors.textSecondary)
            .frame(width: width)
    }

    private func localized(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: nil, table: nil)
    }
}

public struct EDSIconMark: View {
    @Environment(\.edsTheme) private var theme
    public let isOn: Bool

    public init(isOn: Bool) {
        self.isOn = isOn
    }

    public var body: some View {
        Image(systemName: isOn ? "checkmark.circle.fill" : "minus.circle")
            .foregroundStyle(isOn ? theme.colors.success : theme.colors.textTertiary)
            .font(.system(size: 18, weight: .semibold))
    }
}
