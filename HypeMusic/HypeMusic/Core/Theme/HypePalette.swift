import SwiftUI
import UIKit

/// Semantic colors that track the current ``ColorScheme`` so “Light” in Settings
/// looks like a real light UI, not just dark chrome with a light status bar.
enum HypePalette {
    static let accent = Color(hexString: "#FFB300")

    static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hexString: "#0F0F10") : Color(hexString: "#F2F2F7")
    }

    static func card(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hexString: "#1A1A1C") : Color(UIColor.secondarySystemGroupedBackground)
    }

    static func toggleTrack(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(hexString: "#E5E5EA")
    }

    static func togglePill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hexString: "#2C2C2E") : Color.white
    }

    static func avatarPlaceholder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hexString: "#2C2C2E") : Color(hexString: "#D1D1D6")
    }

    static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(hexString: "#1C1C1E")
    }

    static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.6) : Color(hexString: "#6C6C70")
    }

    static func tabBarSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hexString: "#1A1A1C") : Color(UIColor.secondarySystemBackground)
    }

    static func tabBarTopHairline(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.08)
    }

    static func searchChromeBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hexString: "#0F0F10") : Color(hexString: "#F2F2F7")
    }

    static func textFieldFill(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    static func listDivider(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.1)
    }
}
