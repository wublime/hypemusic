import SwiftUI

struct ThemeSettingsSheet: View {
    @AppStorage(ThemePreference.storageKey) private var themeRaw = ThemePreference.dark.rawValue
    @AppStorage(PalettePreference.storageKey) private var paletteRaw = PalettePreference.hype.rawValue
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    private var appearanceSelection: ThemePreference {
        ThemePreference(rawValue: themeRaw) ?? .dark
    }

    private var paletteSelection: PalettePreference {
        PalettePreference(rawValue: paletteRaw) ?? .hype
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(ThemePreference.allCases) { option in
                        Button {
                            themeRaw = option.rawValue
                        } label: {
                            HStack {
                                Text(option.displayName)
                                    .foregroundColor(palette.primaryText(for: colorScheme))
                                Spacer()
                                if option == appearanceSelection {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(palette.accent)
                                }
                            }
                        }
                    }
                }

                Section("Palette") {
                    ForEach(PalettePreference.allCases) { option in
                        Button {
                            paletteRaw = option.rawValue
                        } label: {
                            HStack {
                                Text(option.displayName)
                                    .foregroundColor(palette.primaryText(for: colorScheme))
                                Spacer()
                                if option == paletteSelection {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(palette.accent)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background(for: colorScheme))
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.background(for: colorScheme), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(palette.accent)
                }
            }
        }
    }
}

#Preview {
    ThemeSettingsSheet()
}
