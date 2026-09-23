import SwiftUI

/// A compact visual container for commands that belong to the same task.
///
/// `EDSCommandGroup` does not change the behavior of its child controls. It
/// only gives adjacent commands a shared background, outline, spacing, and
/// clipping shape so a toolbar can communicate their relationship without
/// introducing another navigation level.
public struct EDSCommandGroup<Content: View>: View {
    private let spacing: CGFloat
    private let content: Content

    @Environment(\.edsTheme) private var theme

    public init(
        spacing: CGFloat = 2,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .padding(2)
        .background(theme.colors.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                .stroke(theme.colors.border, lineWidth: theme.stroke.hairline)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// A primary command paired with a menu of closely related alternatives.
///
/// The leading segment always runs `action`; the trailing chevron opens the
/// supplied SwiftUI menu. This keeps the default operation one click away
/// while avoiding a row of equally prominent export or creation buttons.
public struct EDSSplitButton<MenuContent: View>: View {
    private let appearance: EDSButtonAppearance
    private let action: () -> Void
    private let label: AnyView
    private let menuAccessibilityLabel: String
    private let isPrimaryDisabled: Bool
    private let isMenuDisabled: Bool
    private let menuContent: MenuContent

    public init(
        _ title: LocalizedStringKey,
        role: EDSButton.Role = .primary,
        systemImage: String? = nil,
        menuAccessibilityLabel: String = "More actions",
        isPrimaryDisabled: Bool = false,
        isMenuDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder menu: () -> MenuContent
    ) {
        self.appearance = role.appearance
        self.action = action
        self.label = AnyView(Self.makeLabel(title, systemImage: systemImage))
        self.menuAccessibilityLabel = menuAccessibilityLabel
        self.isPrimaryDisabled = isPrimaryDisabled
        self.isMenuDisabled = isMenuDisabled
        self.menuContent = menu()
    }

    public init(
        _ title: String,
        role: EDSButton.Role = .primary,
        systemImage: String? = nil,
        menuAccessibilityLabel: String = "More actions",
        isPrimaryDisabled: Bool = false,
        isMenuDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder menu: () -> MenuContent
    ) {
        self.init(
            LocalizedStringKey(title),
            role: role,
            systemImage: systemImage,
            menuAccessibilityLabel: menuAccessibilityLabel,
            isPrimaryDisabled: isPrimaryDisabled,
            isMenuDisabled: isMenuDisabled,
            action: action,
            menu: menu
        )
    }

    public init(
        _ title: LocalizedStringKey,
        emphasis: EDSButton.Emphasis,
        tone: EDSButton.Tone = .accent,
        size: EDSButton.Size = .regular,
        systemImage: String? = nil,
        menuAccessibilityLabel: String = "More actions",
        isPrimaryDisabled: Bool = false,
        isMenuDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder menu: () -> MenuContent
    ) {
        self.appearance = EDSButtonAppearance(emphasis: emphasis, tone: tone, size: size)
        self.action = action
        self.label = AnyView(Self.makeLabel(title, systemImage: systemImage))
        self.menuAccessibilityLabel = menuAccessibilityLabel
        self.isPrimaryDisabled = isPrimaryDisabled
        self.isMenuDisabled = isMenuDisabled
        self.menuContent = menu()
    }

    public init(
        _ title: String,
        emphasis: EDSButton.Emphasis,
        tone: EDSButton.Tone = .accent,
        size: EDSButton.Size = .regular,
        systemImage: String? = nil,
        menuAccessibilityLabel: String = "More actions",
        isPrimaryDisabled: Bool = false,
        isMenuDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder menu: () -> MenuContent
    ) {
        self.init(
            LocalizedStringKey(title),
            emphasis: emphasis,
            tone: tone,
            size: size,
            systemImage: systemImage,
            menuAccessibilityLabel: menuAccessibilityLabel,
            isPrimaryDisabled: isPrimaryDisabled,
            isMenuDisabled: isMenuDisabled,
            action: action,
            menu: menu
        )
    }

    public var body: some View {
        EDSCommandGroup(spacing: 1) {
            Button(action: action) {
                label
            }
            .buttonStyle(EDSButtonStyleCanvas(appearance: appearance))
            .disabled(isPrimaryDisabled)

            Menu {
                menuContent
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .accessibilityLabel(menuAccessibilityLabel)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .buttonStyle(EDSButtonStyleCanvas(appearance: appearance))
            .disabled(isMenuDisabled)
        }
    }

    private static func makeLabel(
        _ title: LocalizedStringKey,
        systemImage: String?
    ) -> some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
    }
}

/// A named command button that presents a structured popover.
///
/// Prefer this to an ambiguous ellipsis when the commands form a recognizable
/// domain such as “Page Actions”. The caller owns `isPresented`, allowing each
/// command to close the popover after it completes.
public struct EDSCommandPopover<PopoverContent: View>: View {
    @Binding private var isPresented: Bool

    private let appearance: EDSButtonAppearance
    private let label: AnyView
    private let arrowEdge: Edge
    private let popoverContent: PopoverContent

    public init(
        _ title: LocalizedStringKey,
        isPresented: Binding<Bool>,
        emphasis: EDSButton.Emphasis = .soft,
        tone: EDSButton.Tone = .accent,
        size: EDSButton.Size = .regular,
        systemImage: String? = nil,
        arrowEdge: Edge = .bottom,
        @ViewBuilder content: () -> PopoverContent
    ) {
        self._isPresented = isPresented
        self.appearance = EDSButtonAppearance(emphasis: emphasis, tone: tone, size: size)
        self.label = AnyView(Self.makeLabel(title, systemImage: systemImage))
        self.arrowEdge = arrowEdge
        self.popoverContent = content()
    }

    public init(
        _ title: String,
        isPresented: Binding<Bool>,
        emphasis: EDSButton.Emphasis = .soft,
        tone: EDSButton.Tone = .accent,
        size: EDSButton.Size = .regular,
        systemImage: String? = nil,
        arrowEdge: Edge = .bottom,
        @ViewBuilder content: () -> PopoverContent
    ) {
        self.init(
            LocalizedStringKey(title),
            isPresented: isPresented,
            emphasis: emphasis,
            tone: tone,
            size: size,
            systemImage: systemImage,
            arrowEdge: arrowEdge,
            content: content
        )
    }

    public var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            label
        }
        .buttonStyle(EDSButtonStyleCanvas(appearance: appearance))
        .popover(isPresented: $isPresented, arrowEdge: arrowEdge) {
            popoverContent
        }
    }

    private static func makeLabel(
        _ title: LocalizedStringKey,
        systemImage: String?
    ) -> some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.semibold))
        }
    }
}
