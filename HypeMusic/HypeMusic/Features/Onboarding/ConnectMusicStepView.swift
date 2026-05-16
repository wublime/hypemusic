import AuthenticationServices
import CryptoKit
import SwiftUI
import UIKit

/// Final onboarding step: connect Spotify (PKCE) and/or Apple Music (MusicKit).
/// Both are skippable — the parent flow exposes a "Skip" button.
struct ConnectMusicStepView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
    @State private var isWorking = false
    @State private var connectError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect a music service")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(palette.primaryText(for: colorScheme))
                    Text("Optional. Connecting lets friends see what you're playing on the Hype Feed. You can do this later from Profile.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                serviceCard(
                    title: "Spotify",
                    body: "OAuth 2 + PKCE. We store a refresh token server-side and read your currently-playing track.",
                    badge: auth.currentUser?.spotify_connected == true ? "Connected" : nil,
                    accent: Color(hexString: "#1DB954")
                ) {
                    SpotifyOAuth.start(auth: auth) { result in
                        switch result {
                        case .success: connectError = nil
                        case .failure(let err): connectError = err.localizedDescription
                        }
                    }
                }

                serviceCard(
                    title: "Apple Music",
                    body: "Uses MusicKit on this device. Tap connect once you've granted permission.",
                    badge: auth.currentUser?.apple_music_connected == true ? "Connected" : nil,
                    accent: Color(hexString: "#FA243C"),
                    disabled: true
                ) {
                    // TODO: wire MusicKit.requestAuthorization once MusicKit capability is added.
                }

                if let connectError {
                    Text(connectError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func serviceCard(
        title: String,
        body: String,
        badge: String? = nil,
        accent: Color,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(palette.accent)
                        .cornerRadius(6)
                }
            }
            Text(body)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(palette.secondaryText(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Text(badge == "Connected" ? "Re-connect" : "Connect \(title)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent)
                    .cornerRadius(10)
                    .opacity(disabled ? 0.4 : 1)
            }
            .disabled(disabled)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card(for: colorScheme))
        .cornerRadius(14)
    }
}

// MARK: - Spotify PKCE helper

/// Stateless Spotify Authorization Code with PKCE flow runner.
///
/// Drops the user into Spotify's web auth via `ASWebAuthenticationSession`, captures
/// the returned `code`, and asks the backend to exchange it (so the refresh token
/// stays server-side). Replace `APIConfig.spotifyClientID` before shipping.
enum SpotifyOAuth {
    private static var sessionRef: ASWebAuthenticationSession?
    private static let presentationDelegate = PresentationDelegate()

    static func start(auth: AuthManager, completion: @escaping (Result<Void, Error>) -> Void) {
        let verifier = randomCodeVerifier()
        let challenge = codeChallenge(for: verifier)

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: APIConfig.spotifyClientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: APIConfig.spotifyRedirectURI),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "scope", value: APIConfig.spotifyScopes),
        ]
        guard let authURL = components.url else {
            completion(.failure(NSError(domain: "spotify", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad URL"])))
            return
        }

        let callbackScheme = URL(string: APIConfig.spotifyRedirectURI)?.scheme ?? "hypemusic"
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { url, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let url else {
                completion(.failure(NSError(domain: "spotify", code: 2, userInfo: [NSLocalizedDescriptionKey: "No callback URL"])))
                return
            }
            guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "code" })?
                .value else {
                completion(.failure(NSError(domain: "spotify", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing code"])))
                return
            }
            Task {
                do {
                    try await auth.exchangeSpotifyCode(
                        code: code,
                        verifier: verifier,
                        redirectURI: APIConfig.spotifyRedirectURI
                    )
                    await MainActor.run { completion(.success(())) }
                } catch {
                    await MainActor.run { completion(.failure(error)) }
                }
            }
        }
        session.presentationContextProvider = presentationDelegate
        session.prefersEphemeralWebBrowserSession = true
        sessionRef = session
        session.start()
    }

    // MARK: PKCE primitives

    private static func randomCodeVerifier(length: Int = 64) -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    private static func codeChallenge(for verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64URLEncodedString()
    }

    private final class PresentationDelegate: NSObject, ASWebAuthenticationPresentationContextProviding {
        @MainActor
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
            if let window = activeScene?.windows.first(where: { $0.isKeyWindow }) ?? activeScene?.windows.first {
                return window
            }
            return ASPresentationAnchor()
        }
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

#Preview {
    ConnectMusicStepView().environmentObject(AuthManager())
        .background(AppPalette(preference: .hype).background(for: .dark))
}
