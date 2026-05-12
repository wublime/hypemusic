import SwiftUI

/// Placeholder + roadmap for Spotify / Apple Music linking (OAuth PKCE, MusicKit, listening snapshots).
struct MusicServicesConnectSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Link a music account so friends can see what you are playing on the Hype Feed. Playback is read from the service you connect; Hype stores only snapshots you allow.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Spotify", systemImage: "waveform")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Text("Use OAuth 2 with PKCE in the app, send the refresh token to your backend, then poll Spotify’s currently-playing endpoint or accept POST /users/me/listening updates from the app.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hexString: "#1A1A1C"))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Apple Music", systemImage: "music.note.list")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        Text("Use MusicKit for the subscriber on this device. Observe ApplicationMusicPlayer (or system music) and publish now-playing to your backend with POST /users/me/listening—Apple does not expose friends’ playback server-side like Spotify.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hexString: "#1A1A1C"))
                    .cornerRadius(12)

                    Button {
                        // Wire ASWebAuthenticationSession + Spotify client ID when ready.
                    } label: {
                        Text("Connect Spotify")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hexString: "#1DB954"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(true)
                    .opacity(0.45)

                    Button {
                        // Wire MusicKit.requestAuthorization + developer token flow when ready.
                    } label: {
                        Text("Connect Apple Music")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hexString: "#FA243C"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(true)
                    .opacity(0.45)
                }
                .padding(20)
            }
            .background(Color(hexString: "#0F0F10"))
            .navigationTitle("Music services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hexString: "#FFB300"))
                }
            }
            .toolbarBackground(Color(hexString: "#0F0F10"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
