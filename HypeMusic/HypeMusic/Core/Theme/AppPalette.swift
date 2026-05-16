import SwiftUI
import UIKit

/// Resolved semantic chrome for the selected ``PalettePreference``. ``case hype`` forwards to ``HypePalette``.
struct AppPalette: Sendable {
    let preference: PalettePreference

    var accent: Color {
        switch preference {
        case .hype: HypePalette.accent
        case .nocturne: Color(hexString: "#B49CFF")
        case .coastal: Color(hexString: "#2EC4B6")
        }
    }

    func background(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.background(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#0E0B14") : Color(hexString: "#F4F0FF")
        case .coastal:
            scheme == .dark ? Color(hexString: "#0A1214") : Color(hexString: "#EFF8F6")
        }
    }

    func card(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.card(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#1B1626") : Color(UIColor.secondarySystemGroupedBackground)
        case .coastal:
            scheme == .dark ? Color(hexString: "#152022") : Color(UIColor.secondarySystemGroupedBackground)
        }
    }

    func toggleTrack(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.toggleTrack(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#08060C") : Color(hexString: "#E8E0F5")
        case .coastal:
            scheme == .dark ? Color(hexString: "#060B0D") : Color(hexString: "#DDECE9")
        }
    }

    func togglePill(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.togglePill(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#2E2740") : Color.white
        case .coastal:
            scheme == .dark ? Color(hexString: "#243032") : Color.white
        }
    }

    func avatarPlaceholder(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.avatarPlaceholder(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#342C48") : Color(hexString: "#D4C9EE")
        case .coastal:
            scheme == .dark ? Color(hexString: "#2A383A") : Color(hexString: "#B8D9D3")
        }
    }

    func primaryText(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.primaryText(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#F5F2FF") : Color(hexString: "#1C1C1E")
        case .coastal:
            scheme == .dark ? Color(hexString: "#ECF8F5") : Color(hexString: "#1C1C1E")
        }
    }

    func secondaryText(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.secondaryText(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#A69BBD") : Color(hexString: "#6C6C70")
        case .coastal:
            scheme == .dark ? Color(hexString: "#8BA9A4") : Color(hexString: "#5C706C")
        }
    }

    func tabBarSurface(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.tabBarSurface(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#1B1626") : Color(UIColor.secondarySystemBackground)
        case .coastal:
            scheme == .dark ? Color(hexString: "#152022") : Color(UIColor.secondarySystemBackground)
        }
    }

    func tabBarTopHairline(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.tabBarTopHairline(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#B49CFF").opacity(0.12) : Color.black.opacity(0.08)
        case .coastal:
            scheme == .dark ? Color(hexString: "#2EC4B6").opacity(0.14) : Color.black.opacity(0.08)
        }
    }

    func searchChromeBackground(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.searchChromeBackground(for: scheme)
        case .nocturne, .coastal:
            background(for: scheme)
        }
    }

    func textFieldFill(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.textFieldFill(for: scheme)
        case .nocturne:
            scheme == .dark ? Color(hexString: "#B49CFF").opacity(0.10) : Color.black.opacity(0.06)
        case .coastal:
            scheme == .dark ? Color(hexString: "#2EC4B6").opacity(0.10) : Color.black.opacity(0.06)
        }
    }

    func listDivider(for scheme: ColorScheme) -> Color {
        switch preference {
        case .hype: HypePalette.listDivider(for: scheme)
        case .nocturne:
            scheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.1)
        case .coastal:
            scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.09)
        }
    }
}

private struct AppPaletteKey: EnvironmentKey {
    static let defaultValue = AppPalette(preference: .hype)
}

extension EnvironmentValues {
    var appPalette: AppPalette {
        get { self[AppPaletteKey.self] }
        set { self[AppPaletteKey.self] = newValue }
    }
}
