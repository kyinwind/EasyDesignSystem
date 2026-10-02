import SwiftUI

private struct EDSLocalThemeKey: EnvironmentKey {
    static let defaultValue: EDSThemeData? = nil
}

public extension EnvironmentValues {
    /// The design tokens for the current SwiftUI subtree.
    ///
    /// A value explicitly injected into the environment takes precedence. When
    /// no local value exists, the current global `EDSTheme.shared.tokens` value
    /// is read lazily so app-start configuration is not frozen by a static key.
    var edsTheme: EDSThemeData {
        get { self[EDSLocalThemeKey.self] ?? EDSTheme.shared.themeData }
        set { self[EDSLocalThemeKey.self] = newValue }
    }
}

public extension View {
    /// Applies design tokens to this view subtree without changing its layout.
    func easyDesignTheme(_ theme: EDSThemeData) -> some View {
        environment(\.edsTheme, theme)
    }

    /// Compatibility overload for non-color tokens.
    func easyDesignTheme(_ tokens: EDSDesignTokens) -> some View {
        easyDesignTheme(EDSThemeData(tokens: tokens))
    }

    /// Applies a preset theme to this view subtree without changing its layout.
    func easyDesignTheme(_ theme: EDSPresetTheme) -> some View {
        easyDesignTheme(theme.themeData)
    }
}
