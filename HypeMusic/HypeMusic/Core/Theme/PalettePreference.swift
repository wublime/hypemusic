import SwiftUI

/// Persisted accent/surface palette layered under ``ThemePreference`` (light/dark/system).
enum PalettePreference: String, CaseIterable, Identifiable {
    /// Original Hype chrome; mirrors ``HypePalette``.
    case hype
    /// Violet-tinted dark UI with a soft lavender accent.
    case nocturne
    /// Teal-forward coastal palette with cool neutrals.
    case coastal

    static let storageKey = "palettePreference"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hype: return "Hype"
        case .nocturne: return "Nocturne"
        case .coastal: return "Coastal"
        }
    }
}
