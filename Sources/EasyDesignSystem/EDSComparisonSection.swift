import SwiftUI

/// 标准的 Free / Pro 功能对比区域。
public struct EDSComparisonSection: View {
    @Environment(\.edsTheme) private var theme
    public let features: [(String, Bool, Bool)]

    public init(features: [(String, Bool, Bool)]) {
        self.features = features
    }

    public var body: some View {
        EDSSection(header: {
            EDSSectionTitle(title: localized("EDSComparisonSection.features.title"))
                .padding(.vertical, 10)
        }) {
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
                            .font(theme.typography.body)
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
    }

    private func header(_ key: String, width: CGFloat) -> some View {
        Text(localized(key))
            .font(theme.typography.captionStrong)
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
