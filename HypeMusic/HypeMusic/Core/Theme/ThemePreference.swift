import SwiftUI

/// Persisted appearance choice for the main app chrome. Applied at the window via
/// ``HypeMusicApp`` using ``SwiftUI/View/preferredColorScheme(_:)``.
enum ThemePreference: String, CaseIterable, Identifiable {
    /// Original Hype design (dark chrome) regardless of device setting.
    case dark
    case light
    /// Follow the device light/dark mode.
    case system

    static let storageKey = "themePreference"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "Match System"
        }
    }

    /// `nil` means follow the device (``case system``).
    var resolvedColorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}
