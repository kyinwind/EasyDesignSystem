import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

enum EDSPlatformColorBridge {
    static func hexString(for color: Color) -> String? {
        var resolvedColor: NSColor?
        NSAppearance(named: .aqua)?.performAsCurrentDrawingAppearance {
            resolvedColor = NSColor(color).usingColorSpace(.sRGB)
        }
        guard let resolvedColor = resolvedColor ?? NSColor(color).usingColorSpace(.sRGB) else {
            return nil
        }
        return makeHex(
            red: resolvedColor.redComponent,
            green: resolvedColor.greenComponent,
            blue: resolvedColor.blueComponent
        )
    }
}

extension EDSMultilineSubtitleRow {
    /// 保留现有 macOS API。新代码优先使用接受 SwiftUI Image 的统一初始化方法。
    public init(
        systemIcon: String? = nil,
        iconImage: NSImage? = nil,
        iconColor: Color? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.systemIcon = systemIcon
        self.customIcon = iconImage.map(Image.init(nsImage:))
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
}

#elseif canImport(UIKit)
import UIKit

enum EDSPlatformColorBridge {
    static func hexString(for color: Color) -> String? {
        let resolvedColor = UIColor(color).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light)
        )
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        return makeHex(red: red, green: green, blue: blue)
    }
}

extension EDSMultilineSubtitleRow {
    /// 使用 SF Symbol 的跨平台初始化方法。
    public init(
        systemIcon: String? = nil,
        iconColor: Color? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.systemIcon = systemIcon
        self.customIcon = nil
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
}
#endif

private func makeHex(red: CGFloat, green: CGFloat, blue: CGFloat) -> String {
    let red = Int((red * 255).rounded()).clamped(to: 0...255)
    let green = Int((green * 255).rounded()).clamped(to: 0...255)
    let blue = Int((blue * 255).rounded()).clamped(to: 0...255)
    return String(format: "#%02X%02X%02X", red, green, blue)
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
