import SwiftUI

enum EDSFontRole {
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

private struct EDSFontSpecification {
    let weight: Font.Weight
    let textStyle: Font.TextStyle
    let design: Font.Design
}

private struct EDSScaledFontModifier: ViewModifier {
    let specification: EDSFontSpecification

    func body(content: Content) -> some View {
        content
            .font(semanticFont(for: specification.textStyle))
            .fontDesign(specification.design)
            .fontWeight(specification.weight)
    }

    private func semanticFont(for style: Font.TextStyle) -> Font {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .caption: .caption
        case .caption2: .caption2
        case .footnote: .footnote
        default: .body
        }
    }
}

extension View {
    func edsFont(_ role: EDSFontRole, tokens: EDSTypographyTokens) -> some View {
        modifier(EDSScaledFontModifier(specification: tokens.specification(for: role)))
    }
}

private extension EDSTypographyTokens {
    func specification(for role: EDSFontRole) -> EDSFontSpecification {
        switch role {
        case .hero:
            EDSFontSpecification(weight: fontWeight(heroWeight), textStyle: .largeTitle, design: .rounded)
        case .pageTitle:
            EDSFontSpecification(weight: fontWeight(pageTitleWeight), textStyle: .headline, design: .rounded)
        case .sectionTitle:
            EDSFontSpecification(weight: fontWeight(sectionTitleWeight), textStyle: .subheadline, design: .default)
        case .body15:
            EDSFontSpecification(weight: fontWeight(body15Weight), textStyle: .body, design: .default)
        case .body15Strong:
            EDSFontSpecification(weight: fontWeight(body15StrongWeight), textStyle: .body, design: .default)
        case .body:
            EDSFontSpecification(weight: fontWeight(bodyWeight), textStyle: .body, design: .default)
        case .bodyStrong:
            EDSFontSpecification(weight: fontWeight(bodyStrongWeight), textStyle: .body, design: .default)
        case .caption:
            EDSFontSpecification(weight: fontWeight(captionWeight), textStyle: .caption, design: .default)
        case .captionStrong:
            EDSFontSpecification(weight: fontWeight(captionStrongWeight), textStyle: .caption, design: .default)
        case .monoCaption:
            EDSFontSpecification(weight: fontWeight(monoCaptionWeight), textStyle: .caption2, design: .monospaced)
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
