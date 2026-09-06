import SwiftUI
import EasyDesignSystem

@main
struct EDSPlatformCatalogApp: App {
    init() {
        EDSTheme.shared.applyPreset(.default)
    }

    var body: some Scene {
        WindowGroup {
            PlatformCatalogContentView()
        }
    }
}
