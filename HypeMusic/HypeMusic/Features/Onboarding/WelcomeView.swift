import AuthenticationServices
import SwiftUI

/// Splash/landing screen shown when no JWT exists in the Keychain.
/// The only call-to-action is Sign in with Apple.
struct WelcomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            palette.background(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(palette.accent)

                    Text("hype")
                        .font(.system(size: 56, weight: .black))
                        .foregroundColor(palette.primaryText(for: colorScheme))

                    Text("Letterboxd for music.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                }

                Spacer()

                VStack(spacing: 12) {
                    if let signInError = auth.signInError {
                        Text(signInError)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            isAuthenticating = true
                            Task {
                                await auth.handleAppleAuthorization(authorization)
                                isAuthenticating = false
                            }
                        case .failure(let error):
                            auth.reportSignInFailure(error.localizedDescription)
                            print("Apple sign-in failed: \(error)")
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .cornerRadius(12)
                    .disabled(isAuthenticating)

                    #if DEBUG
                    if APIConfig.isSimulator {
                        Button("Continue without Apple (dev)") {
                            isAuthenticating = true
                            Task {
                                await auth.devSignIn()
                                isAuthenticating = false
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                        .disabled(isAuthenticating)
                    }
                    #endif

                    Text("Sign in to track releases, rate albums, and tap in with friends.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }

            if isAuthenticating {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(palette.accent)
                    .scaleEffect(1.4)
            }
        }
    }
}

#Preview {
    WelcomeView().environmentObject(AuthManager())
}
