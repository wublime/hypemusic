import SwiftUI

/// Switches between the install/onboarding/in-app states based on the
/// shared `AuthManager`.
struct RootView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        ZStack {
            palette.background(for: colorScheme).ignoresSafeArea()

            switch auth.phase {
            case .loading:
                SplashView()
                    .transition(.opacity)
            case .signedOut:
                WelcomeView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingFlowView()
                    .transition(.opacity)
            case .signedIn:
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: phaseKey)
    }

    /// Stable identifier so SwiftUI re-runs `transition`/`animation` on phase
    /// changes without comparing the whole `AppUser` payload.
    private var phaseKey: String {
        switch auth.phase {
        case .loading: return "loading"
        case .signedOut: return "signedOut"
        case .onboarding: return "onboarding"
        case .signedIn: return "signedIn"
        }
    }
}

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "flame.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(palette.accent)
            ProgressView()
                .tint(palette.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background(for: colorScheme))
    }
}

#Preview {
    RootView().environmentObject(AuthManager())
}
