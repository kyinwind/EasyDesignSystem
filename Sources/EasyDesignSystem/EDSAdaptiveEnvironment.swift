import SwiftUI

/// Describes the primary interaction model used to resolve adaptive metrics.
///
/// Most applications should keep the default `.automatic` value. Explicit
/// values are useful for previews, tests, and unusual host environments.
public enum EDSInteractionProfile: String, Codable, CaseIterable, Sendable {
    case automatic
    case touch
    case pointer
    case hybrid

    var resolved: EDSInteractionProfile {
        guard self == .automatic else { return self }

        #if targetEnvironment(macCatalyst)
        return .hybrid
        #elseif os(macOS)
        return .pointer
        #else
        return .touch
        #endif
    }
}

private struct EDSInteractionProfileKey: EnvironmentKey {
    static let defaultValue: EDSInteractionProfile = .automatic
}

public extension EnvironmentValues {
    var edsInteractionProfile: EDSInteractionProfile {
        get { self[EDSInteractionProfileKey.self] }
        set { self[EDSInteractionProfileKey.self] = newValue }
    }
}

public extension View {
    /// Overrides automatic interaction adaptation for this view subtree.
    func easyDesignInteractionProfile(_ profile: EDSInteractionProfile) -> some View {
        environment(\.edsInteractionProfile, profile)
    }
}

struct EDSResolvedMetrics: Equatable {
    let pagePadding: CGFloat
    let readableContentMaxWidth: CGFloat
    let minimumInteractiveDimension: CGFloat
    let supportsHoverEnhancement: Bool
    let showsPersistentAuxiliaryActions: Bool

    static func resolve(
        tokens: EDSDesignTokens,
        profile: EDSInteractionProfile,
        horizontalSizeClass: UserInterfaceSizeClass?
    ) -> EDSResolvedMetrics {
        let resolvedProfile = profile.resolved
        let isCompact = horizontalSizeClass == .compact
        let adaptive = tokens.adaptiveLayout
        let adaptiveDefaults = EDSAdaptiveLayoutTokens()
        let compactPagePadding = adaptive.compactPagePadding == adaptiveDefaults.compactPagePadding
            ? tokens.spacing.md
            : adaptive.compactPagePadding
        let regularPagePadding = adaptive.regularPagePadding == adaptiveDefaults.regularPagePadding
            ? tokens.spacing.xxl
            : adaptive.regularPagePadding

        let minimumInteractiveDimension: CGFloat
        switch resolvedProfile {
        case .touch:
            minimumInteractiveDimension = adaptive.minimumTouchTarget
        case .hybrid:
            minimumInteractiveDimension = adaptive.minimumHybridTarget
        case .pointer, .automatic:
            minimumInteractiveDimension = 0
        }

        return EDSResolvedMetrics(
            pagePadding: isCompact
                ? compactPagePadding
                : regularPagePadding,
            readableContentMaxWidth: adaptive.readableContentMaxWidth,
            minimumInteractiveDimension: minimumInteractiveDimension,
            supportsHoverEnhancement: resolvedProfile != .touch,
            showsPersistentAuxiliaryActions: resolvedProfile != .pointer
        )
    }

    func interactiveHeight(for visualHeight: CGFloat) -> CGFloat {
        max(visualHeight, minimumInteractiveDimension)
    }
}
