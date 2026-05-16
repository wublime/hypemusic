import AuthenticationServices
import Foundation
internal import Combine

/// Drives the entire install -> account -> in-app flow.
///
/// Phases:
///   - `.loading`  — Keychain check in flight (or `bootstrap()` not yet called).
///   - `.signedOut` — show `WelcomeView` with Sign in with Apple.
///   - `.onboarding(user)` — signed in, but `onboarding_complete == false`.
///   - `.signedIn(user)` — ready to use the app.
enum AuthPhase: Equatable {
    case loading
    case signedOut
    case onboarding(AppUser)
    case signedIn(AppUser)
}

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var phase: AuthPhase = .loading
    @Published private(set) var accessToken: String?
    @Published private(set) var signInError: String?

    var currentUser: AppUser? {
        switch phase {
        case .onboarding(let u), .signedIn(let u): return u
        case .loading, .signedOut: return nil
        }
    }

    /// Read Keychain on launch and try to hydrate the session from the backend.
    func bootstrap() async {
        guard let token = KeychainHelper.loadToken() else {
            phase = .signedOut
            return
        }
        accessToken = token
        do {
            let user = try await API.shared.fetchMe(token: token)
            applyUser(user)
        } catch {
            // Ignore stale bootstrap if sign-in completed while fetchMe was in flight.
            guard accessToken == token else { return }
            print("[AuthManager] bootstrap failed: \(error)")
            KeychainHelper.deleteToken()
            accessToken = nil
            phase = .signedOut
        }
    }

    /// Handle the credential from `SignInWithAppleButton`.
    func handleAppleAuthorization(_ authorization: ASAuthorization) async {
        signInError = nil
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            signInError = "Apple did not return a sign-in token. Try again."
            print("[AuthManager] Apple credential missing identity token")
            return
        }
        let email = credential.email
        do {
            let response = try await API.shared.appleAuth(
                identityToken: identityToken,
                email: email
            )
            persistSession(response)
        } catch {
            print("[AuthManager] Apple sign-in failed: \(error)")
            signInError = (error as? LocalizedError)?.errorDescription
                ?? "Sign in failed. Check that the backend is running."
            #if DEBUG
            if APIConfig.isSimulator {
                await devSignIn(suppressErrors: true)
            }
            #endif
        }
    }

    /// Simulator-only fallback when `DEV_AUTH_ENABLED=1` on the backend.
    func devSignIn(suppressErrors: Bool = false) async {
        if !suppressErrors { signInError = nil }
        do {
            let response = try await API.shared.devAuth()
            persistSession(response)
            signInError = nil
        } catch {
            print("[AuthManager] Dev sign-in failed: \(error)")
            signInError = (error as? LocalizedError)?.errorDescription
                ?? "Dev sign-in failed. Set DEV_AUTH_ENABLED=1 in backend/.env."
        }
    }

    func refreshMe() async {
        guard let token = accessToken else { return }
        do {
            let user = try await API.shared.fetchMe(token: token)
            applyUser(user)
        } catch {
            print("[AuthManager] refreshMe failed: \(error)")
        }
    }

    @discardableResult
    func updateMe(
        username: String? = nil,
        favoriteGenres: [String]? = nil,
        onboardingComplete: Bool? = nil
    ) async throws -> AppUser {
        guard let token = accessToken else {
            throw APIError.unauthorized("Not signed in")
        }
        let body = UpdateUserRequest(
            username: username,
            favorite_genres: favoriteGenres,
            onboarding_complete: onboardingComplete
        )
        let user = try await API.shared.updateMe(token: token, body: body)
        applyUser(user)
        return user
    }

    func checkUsername(_ candidate: String) async -> Bool {
        do {
            return try await API.shared.checkUsername(candidate)
        } catch {
            return false
        }
    }

    func exchangeSpotifyCode(code: String, verifier: String, redirectURI: String) async throws {
        guard let token = accessToken else { throw APIError.unauthorized("Not signed in") }
        _ = try await API.shared.exchangeSpotify(
            token: token,
            code: code,
            verifier: verifier,
            redirectURI: redirectURI
        )
        await refreshMe()
    }

    func signOut() {
        KeychainHelper.deleteToken()
        accessToken = nil
        signInError = nil
        phase = .signedOut
    }

    private func persistSession(_ response: AppleAuthResponse) {
        KeychainHelper.saveToken(response.access_token)
        accessToken = response.access_token
        applyUser(response.user)
    }

    func reportSignInFailure(_ message: String) {
        signInError = message
    }

    private func applyUser(_ user: AppUser) {
        phase = user.onboarding_complete ? .signedIn(user) : .onboarding(user)
    }
}
