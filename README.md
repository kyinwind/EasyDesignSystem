# EasyDesignSystem

An opinionated SwiftUI design system for building consistent macOS applications.

EasyDesignSystem provides configurable design tokens, standard layouts, reusable components, and UI patterns. The first release is extracted from MySwiftAppTools and uses the `EDS` API prefix.

```swift
import EasyDesignSystem

EDSTheme.shared.applyPreset(.orange)

struct SettingsView: View {
    var body: some View {
        EDSPage("Settings") {
            EDSGroup {
                EDSSettingRow("Automatic updates") {
                    EDSToggle(isOn: .constant(true), label: "Enabled")
                }
            }
        }
    }
}
```

The package currently supports macOS 14 and later with Swift 6.
