import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
    @State private var showMusicServices = false
    @State private var showThemes = false
    @State private var showSignOutConfirm = false

    private var user: AppUser? { auth.currentUser }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Profile")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(palette.primaryText(for: colorScheme))

                profileHeader

                if let genres = user?.favorite_genres, !genres.isEmpty {
                    genresRow(genres)
                }

                VStack(spacing: 10) {
                    profileRowButton(title: "Music services", systemImage: "music.note") {
                        showMusicServices = true
                    }
                    profileRowButton(title: "Themes", systemImage: "paintpalette") {
                        showThemes = true
                    }
                    profileRow(title: "Your stats", systemImage: "chart.bar.fill")
                    profileRow(title: "Settings", systemImage: "gearshape.fill")
                    profileRow(title: "Hype lists", systemImage: "list.star")

                    Button {
                        showSignOutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(width: 28)
                            Text("Sign out")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(14)
                        .background(palette.card(for: colorScheme))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showMusicServices) {
            MusicServicesConnectSheet()
        }
        .sheet(isPresented: $showThemes) {
            ThemeSettingsSheet()
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { auth.signOut() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Subviews

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(palette.avatarPlaceholder(for: colorScheme))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(user?.username.map { "@\($0)" } ?? "@you")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                if let email = user?.email {
                    Text(email)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                }
                HStack(spacing: 6) {
                    badge(label: "Spotify", connected: user?.spotify_connected ?? false)
                    badge(label: "Apple Music", connected: user?.apple_music_connected ?? false)
                }
                .padding(.top, 2)
            }
            Spacer()
        }
    }

    private func badge(label: String, connected: Bool) -> some View {
        Text(connected ? "\(label) ✓" : label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(connected ? .black : palette.secondaryText(for: colorScheme))
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(connected ? palette.accent : palette.card(for: colorScheme))
            .cornerRadius(6)
    }

    private func genresRow(_ genres: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your genres")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.secondaryText(for: colorScheme))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(genres, id: \.self) { g in
                        Text(labelFor(genre: g))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(palette.primaryText(for: colorScheme))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(palette.card(for: colorScheme))
                            .cornerRadius(14)
                    }
                }
            }
        }
    }

    private func labelFor(genre id: String) -> String {
        GenreCatalog.all.first(where: { $0.id == id })?.label ?? id.capitalized
    }

    private func profileRow(title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(palette.accent)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(palette.primaryText(for: colorScheme))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.secondaryText(for: colorScheme))
        }
        .padding(14)
        .background(palette.card(for: colorScheme))
        .cornerRadius(12)
    }

    private func profileRowButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.accent)
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
            }
            .padding(14)
            .background(palette.card(for: colorScheme))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView().environmentObject(AuthManager())
}
