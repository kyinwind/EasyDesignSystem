import SwiftUI

/// Shared surface renderer used by both fine-grained containers and Easy recipes.
struct EDSSurfaceConfiguration {
    var background: AnyShapeStyle?
    var cornerRadius: CGFloat
    var borderColor: Color?
    var borderWidth: CGFloat
    var shadow: EDSShadowTokens?

    init(
        background: AnyShapeStyle? = nil,
        cornerRadius: CGFloat = 0,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 0,
        shadow: EDSShadowTokens? = nil
    ) {
        self.background = background
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadow = shadow
    }
}

private struct EDSSurfacePrimitiveModifier: ViewModifier {
    let configuration: EDSSurfaceConfiguration

    @ViewBuilder
    func body(content: Content) -> some View {
        if let background = configuration.background {
            let shape = RoundedRectangle(
                cornerRadius: configuration.cornerRadius,
                style: .continuous
            )

            if let shadow = configuration.shadow {
                bordered(content: content, background: background, shape: shape)
                    .shadow(
                        color: shadow.shadowColor,
                        radius: shadow.radius,
                        x: shadow.x,
                        y: shadow.y
                    )
            } else {
                bordered(content: content, background: background, shape: shape)
            }
        } else {
            content
        }
    }

    @ViewBuilder
    private func bordered(
        content: Content,
        background: AnyShapeStyle,
        shape: RoundedRectangle
    ) -> some View {
        if let borderColor = configuration.borderColor, configuration.borderWidth > 0 {
            content
                .background(shape.fill(background))
                .overlay(shape.stroke(borderColor, lineWidth: configuration.borderWidth))
        } else {
            content.background(shape.fill(background))
        }
    }
}

extension View {
    func edsSurface(_ configuration: EDSSurfaceConfiguration) -> some View {
        modifier(EDSSurfacePrimitiveModifier(configuration: configuration))
    }
}
