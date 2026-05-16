//
//  HypeMusicApp.swift
//  HypeMusic
//
//  Created by jacob hancock on 3/8/26.
//

import SwiftUI

@main
struct HypeMusicApp: App {
    @StateObject private var auth = AuthManager()
    @AppStorage(ThemePreference.storageKey) private var themePreferenceRaw = ThemePreference.dark.rawValue
    @AppStorage(PalettePreference.storageKey) private var paletteRaw = PalettePreference.hype.rawValue

    private var preferredColorScheme: ColorScheme? {
        (ThemePreference(rawValue: themePreferenceRaw) ?? .dark).resolvedColorScheme
    }

    private var appPalette: AppPalette {
        AppPalette(preference: PalettePreference(rawValue: paletteRaw) ?? .hype)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environment(\.appPalette, appPalette)
                .preferredColorScheme(preferredColorScheme)
                .task { await auth.bootstrap() }
        }
    }
}
