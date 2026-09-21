import SwiftUI

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

enum EDSPlatformColorBridge {
    static func hexString(for color: Color) -> String? {
        guard let c = sRGBComponents(for: color) else { return nil }
        return makeHex(red: c.red, green: c.green, blue: c.blue)
    }

    /// 取 sRGB 分量。macOS 侧固定在浅色外观解析，保证结果确定性（供测试对齐）。
    static func sRGBComponents(for color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var resolvedColor: NSColor?
        NSAppearance(named: .aqua)?.performAsCurrentDrawingAppearance {
            resolvedColor = NSColor(color).usingColorSpace(.sRGB)
        }
        guard let resolvedColor = resolvedColor ?? NSColor(color).usingColorSpace(.sRGB) else {
            return nil
        }
        return (
            resolvedColor.redComponent,
            resolvedColor.greenComponent,
            resolvedColor.blueComponent,
            resolvedColor.alphaComponent
        )
    }

    /// 向黑色等比压缩 RGB（multiplier ∈ 0…1，1 = 原色）。
    /// 用于按钮 medium 档"比 tone 更深一档"的文字色。
    /// 注意：按浅色外观解析，深色外观下仍是深色——与 tone 静态 hex 的现状一致。
    static func darkened(_ color: Color, by multiplier: CGFloat) -> Color? {
        guard let c = sRGBComponents(for: color) else { return nil }
        return Color(
            red: c.red * multiplier,
            green: c.green * multiplier,
            blue: c.blue * multiplier,
            opacity: c.alpha
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
        guard let c = sRGBComponents(for: color) else { return nil }
        return makeHex(red: c.red, green: c.green, blue: c.blue)
    }

    /// 取 sRGB 分量。UIKit 侧固定按浅色外观解析，保证结果确定性（供测试对齐）。
    static func sRGBComponents(for color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
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
        return (red, green, blue, alpha)
    }

    /// 向黑色等比压缩 RGB（multiplier ∈ 0…1，1 = 原色）。
    /// 用于按钮 medium 档"比 tone 更深一档"的文字色。
    /// 注意：按浅色外观解析，深色外观下仍是深色——与 tone 静态 hex 的现状一致。
    static func darkened(_ color: Color, by multiplier: CGFloat) -> Color? {
        guard let c = sRGBComponents(for: color) else { return nil }
        return Color(
            red: c.red * multiplier,
            green: c.green * multiplier,
            blue: c.blue * multiplier,
            opacity: c.alpha
        )
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
