import SwiftUI


// MARK: - EDSThemeBuilder：用于闭包配置的 builder

@resultBuilder
public struct EDSThemeBuilder {
    public static func buildBlock(_ components: Void...) -> Void {}
    public static func buildEither<T>(truthy: T) -> T { truthy }
    public static func buildEither<T>(falsey: T) -> T { falsey }
}


// MARK: - EDSThemeError

public enum EDSThemeError: LocalizedError {
    case jsonDecodingFailed(Error)
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .jsonDecodingFailed(let error):
            return "JSON 解码失败: \(error.localizedDescription)"
        case .fileNotFound(let path):
            return "文件未找到: \(path)"
        }
    }
}


// MARK: - EDSTheme

/// Design System 统一配置入口
///
/// 使用方式：
/// ```swift
/// // App 初始化时配置主题
/// EDSTheme.shared.configure { tokens in
///     tokens.colors.primary = "#FF6B00"
/// }
/// ```
public final class EDSTheme: @unchecked Sendable {

    /// 全局单例。建议在 App 启动阶段完成配置，运行时动态切换主题暂不承诺自动刷新 UI。
    public static let shared = EDSTheme()

    /// 当前生效的设计 Token
    public var tokens: EDSDesignTokens = EDSDesignTokens()

    private init() {}

    // MARK: - 配置方法

    /// 通过闭包配置 Token（链式配置）
    ///
    /// ```swift
    /// EDSTheme.shared.configure { tokens in
    ///     tokens.colors.primary = "#FF6B00"
    ///     tokens.spacing.lg = 24
    /// }
    /// ```
    @MainActor
    public func configure(_ block: (inout EDSDesignTokens) -> Void) {
        block(&tokens)
    }

    /// 通过 JSON Data 配置 Token
    ///
    /// ```swift
    /// let data = try Data(contentsOf: url)
    /// try EDSTheme.shared.configure(jsonData: data)
    /// ```
    @MainActor
    public func configure(jsonData: Data) throws {
        do {
            tokens = try JSONDecoder().decode(EDSDesignTokens.self, from: jsonData)
        } catch {
            throw EDSThemeError.jsonDecodingFailed(error)
        }
    }

    /// 通过文件 URL 加载 JSON 配置
    ///
    /// ```swift
    /// let url = Bundle.main.url(forResource: "theme", withExtension: "json")!
    /// try EDSTheme.shared.configure(jsonFileURL: url)
    /// ```
    @MainActor
    public func configure(jsonFileURL url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw EDSThemeError.fileNotFound(url.path)
        }
        let data = try Data(contentsOf: url)
        try configure(jsonData: data)
    }

    /// 从 Bundle 内的 JSON 资源文件加载配置
    ///
    /// ```swift
    /// // 从 MyAppTheme.json 加载（扩展名自动追加）
    /// try EDSTheme.shared.configure(jsonResource: "MyAppTheme")
    /// ```
    @MainActor
    public func configure(jsonResource name: String, bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw EDSThemeError.fileNotFound("'\(name).json' in bundle")
        }
        try configure(jsonFileURL: url)
    }

    /// 加载包内自带的默认主题 JSON。
    ///
    /// 外部 App 无法直接访问 Swift Package 的 `Bundle.module`，因此读取包内默认主题时请使用这个入口：
    ///
    /// ```swift
    /// try EDSTheme.shared.applyDefaultThemeFromPackage()
    /// ```
    @MainActor
    public func applyDefaultThemeFromPackage() throws {
        try configure(jsonResource: "EDSDefaultTheme", bundle: .module)
    }

    /// 应用预设主题
    ///
    /// ```swift
    /// EDSTheme.shared.applyPreset(.orange)
    /// ```
    @MainActor
    public func applyPreset(_ preset: EDSPresetTheme) {
        tokens = preset.tokens
    }

    // MARK: - 便捷访问别名

    /// 颜色 Token 快捷访问
    public var colors: EDSColorTokens { tokens.colors }

    /// 间距 Token 快捷访问
    public var spacing: EDSSpacingTokens { tokens.spacing }

    /// 圆角 Token 快捷访问
    public var radius: EDSRadiusTokens { tokens.radius }

    /// 字体 Token 快捷访问
    public var typography: EDSTypographyTokens { tokens.typography }

    /// 控件尺寸 Token 快捷访问
    public var controlSize: EDSControlSizeTokens { tokens.controlSize }

    /// Hero 渐变 Token 快捷访问
    public var heroGradient: EDSHeroGradient { tokens.heroGradient }

    /// stroke Token 快捷访问
    public var stroke: EDSStrokeTokens { tokens.stroke }

    /// 阴影 Token 快捷访问
    public var shadow: EDSShadowTokens { tokens.shadow }

    // MARK: - 导出 JSON

    /// 将当前 Token 导出为 JSON Data
    public func exportJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(tokens)
    }

    /// 将当前 Token 导出为格式化 JSON 字符串
    public func exportJSONString() throws -> String {
        let data = try exportJSON()
        guard let string = String(data: data, encoding: .utf8) else {
            throw EDSThemeError.jsonDecodingFailed(
                NSError(domain: "EDSTheme", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法将 JSON Data 转换为字符串"])
            )
        }
        return string
    }
}


// MARK: - EDSPresetTheme：预设主题

public struct EDSPresetTheme: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let tokens: EDSDesignTokens

    public init(id: String, name: String, tokens: EDSDesignTokens) {
        self.id = id
        self.name = name
        self.tokens = tokens
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: EDSPresetTheme, rhs: EDSPresetTheme) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - 内置预设

    /// 默认蓝色主题
    public static let `default` = EDSPresetTheme(
        id: "default",
        name: "默认蓝色",
        tokens: {
            var t = EDSDesignTokens()
            t.colors.primary = Color(hexRGB: "#3185FF")
            t.colors.accent  = Color(hexRGB: "#3185FF")
            t.heroGradient   = EDSDesignTokens.heroGradientBlue
            return t
        }()
    )

    /// 通用蓝色主题（`.default` 的别名）
    public static let blue = EDSPresetTheme.default

    /// 通用橙色主题
    public static let orange = EDSPresetTheme(
        id: "orange",
        name: "橙色",
        tokens: {
            var t = EDSDesignTokens()
            t.colors.primary = Color(hexRGB: "#FF6B00")
            t.colors.accent  = Color(hexRGB: "#FF6B00")
            t.colors.success = Color(hexRGB: "#27B15A")
            t.colors.warning = Color(hexRGB: "#F9B135")
            t.colors.danger  = Color(hexRGB: "#E54444")
            t.heroGradient   = EDSDesignTokens.heroGradientOrange
            return t
        }()
    )

    /// 通用紫色主题
    public static let purple = EDSPresetTheme(
        id: "purple",
        name: "紫色",
        tokens: {
            var t = EDSDesignTokens()
            t.colors.primary = Color(hexRGB: "#8B5CF6")
            t.colors.accent  = Color(hexRGB: "#8B5CF6")
            t.colors.success = Color(hexRGB: "#10B981")
            t.colors.warning = Color(hexRGB: "#F59E0B")
            t.colors.danger  = Color(hexRGB: "#EF4444")
            t.heroGradient   = EDSDesignTokens.heroGradientPurple
            return t
        }()
    )

    /// 所有内置预设
    public static let allPresets: [EDSPresetTheme] = [
        .default,
        .orange,
        .purple
    ]
}
