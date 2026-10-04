import SwiftUI

public enum EDSFontRole {
    case hero
    case pageTitle
    case sectionTitle
    case body15
    case body15Strong
    case body
    case bodyStrong
    case caption
    case captionStrong
    case monoCaption
}

struct EDSFontSpecification {
    let size: CGFloat
    let weight: Font.Weight
    let textStyle: Font.TextStyle
    let design: Font.Design
}

private struct EDSScaledFontModifier: ViewModifier {
    let specification: EDSFontSpecification
    @ScaledMetric private var scaledSize: CGFloat

    init(specification: EDSFontSpecification) {
        self.specification = specification
        self._scaledSize = ScaledMetric(
            wrappedValue: specification.size,
            relativeTo: specification.textStyle
        )
    }

    func body(content: Content) -> some View {
        content
            .font(.system(
                size: scaledSize,
                weight: specification.weight,
                design: specification.design
            ))
    }
}

private struct EDSThemedFontModifier: ViewModifier {
    @Environment(\.edsTheme) private var theme
    let role: EDSFontRole

    func body(content: Content) -> some View {
        content.modifier(EDSScaledFontModifier(specification: theme.typography.specification(for: role)))
    }
}

public extension View {
    func edsFont(_ role: EDSFontRole, tokens: EDSTypographyTokens) -> some View {
        modifier(EDSScaledFontModifier(specification: tokens.specification(for: role)))
    }

    /// Applies the font role using the current EasyDesignSystem theme.
    func edsFont(_ role: EDSFontRole) -> some View {
        modifier(EDSThemedFontModifier(role: role))
    }
}

extension EDSTypographyTokens {
    func specification(for role: EDSFontRole) -> EDSFontSpecification {
        switch role {
        case .hero:
            EDSFontSpecification(size: heroSize, weight: fontWeight(heroWeight), textStyle: .largeTitle, design: .rounded)
        case .pageTitle:
            EDSFontSpecification(size: pageTitleSize, weight: fontWeight(pageTitleWeight), textStyle: .headline, design: .rounded)
        case .sectionTitle:
            EDSFontSpecification(size: sectionTitleSize, weight: fontWeight(sectionTitleWeight), textStyle: .subheadline, design: .default)
        case .body15:
            EDSFontSpecification(size: body15Size, weight: fontWeight(body15Weight), textStyle: .body, design: .default)
        case .body15Strong:
            EDSFontSpecification(size: body15StrongSize, weight: fontWeight(body15StrongWeight), textStyle: .body, design: .default)
        case .body:
            EDSFontSpecification(size: bodySize, weight: fontWeight(bodyWeight), textStyle: .body, design: .default)
        case .bodyStrong:
            EDSFontSpecification(size: bodyStrongSize, weight: fontWeight(bodyStrongWeight), textStyle: .body, design: .default)
        case .caption:
            EDSFontSpecification(size: captionSize, weight: fontWeight(captionWeight), textStyle: .caption, design: .default)
        case .captionStrong:
            EDSFontSpecification(size: captionStrongSize, weight: fontWeight(captionStrongWeight), textStyle: .caption, design: .default)
        case .monoCaption:
            EDSFontSpecification(size: monoCaptionSize, weight: fontWeight(monoCaptionWeight), textStyle: .caption2, design: .monospaced)
        }
    }

    func fontWeight(_ value: String) -> Font.Weight {
        switch value {
        case "bold": .bold
        case "semibold": .semibold
        case "medium": .medium
        case "light": .light
        case "thin": .thin
        default: .regular
        }
    }
}
