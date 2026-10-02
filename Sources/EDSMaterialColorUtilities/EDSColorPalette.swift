// Material Color Utilities adapter pinned from upstream commit
// 5b3618b16fdc3825e21d5679bafd144662088ea1.

/// Minimal adapter used by EasyDesignSystem so the vendored implementation does
/// not become part of EasyDesignSystem's public API.
public enum EDSColorPalette {
    public static func tone(seedARGB: Int, tone: Double) -> Int {
        TonalPalette.fromHct(Hct.fromInt(seedARGB)).tone(tone)
    }
}
