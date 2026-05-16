import SwiftUI

/// Three-step onboarding shown after Apple sign-in when `onboarding_complete == false`.
///
/// Step 1: Username (which is also display name).
/// Step 2: Favorite genres (multi-select chips).
/// Step 3: Connect a music service (skippable).
struct OnboardingFlowView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
    @State private var step: Int = 0

    // Step 1 state
    @State private var username: String = ""
    @State private var usernameStatus: UsernameStatus = .idle

    // Step 2 state
    @State private var selectedGenres: Set<String> = []

    // Misc
    @State private var isSaving = false
    @State private var saveError: String?

    private let totalSteps = 3

    var body: some View {
        ZStack {
            palette.background(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader

                Group {
                    switch step {
                    case 0:
                        UsernameStepView(
                            username: $username,
                            status: $usernameStatus
                        )
                    case 1:
                        GenresStepView(selectedGenres: $selectedGenres)
                    default:
                        ConnectMusicStepView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let saveError {
                    Text(saveError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                footer
            }
        }
        .task {
            if let user = auth.currentUser {
                username = user.username ?? ""
                selectedGenres = Set(user.favorite_genres)
            }
        }
    }

    // MARK: - Layout pieces

    private var progressHeader: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? palette.accent : Color.primary.opacity(0.12))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") { withAnimation { step -= 1; saveError = nil } }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)
            }

            if step == 2 {
                Button("Skip") { Task { await finish() } }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)
                    .disabled(isSaving)
            }

            Spacer()

            Button(action: { Task { await advance() } }) {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView().tint(.black).scaleEffect(0.8)
                    }
                    Text(primaryLabel)
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(minWidth: 140)
                .padding(.vertical, 14)
                .padding(.horizontal, 22)
                .background(palette.accent)
                .opacity(primaryDisabled ? 0.45 : 1)
                .cornerRadius(12)
            }
            .disabled(primaryDisabled || isSaving)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private var primaryLabel: String {
        switch step {
        case 0, 1: return "Continue"
        default: return "Finish"
        }
    }

    private var primaryDisabled: Bool {
        switch step {
        case 0:
            return usernameStatus != .available
        case 1:
            return selectedGenres.isEmpty
        default:
            return false
        }
    }

    // MARK: - Actions

    private func advance() async {
        saveError = nil
        switch step {
        case 0:
            await save(username: username.lowercased())
            if saveError == nil { withAnimation { step = 1 } }
        case 1:
            await save(genres: Array(selectedGenres))
            if saveError == nil { withAnimation { step = 2 } }
        default:
            await finish()
        }
    }

    private func save(username: String? = nil, genres: [String]? = nil) async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await auth.updateMe(username: username, favoriteGenres: genres)
        } catch {
            saveError = (error as? LocalizedError)?.errorDescription ?? "Could not save."
        }
    }

    private func finish() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await auth.updateMe(onboardingComplete: true)
        } catch {
            saveError = (error as? LocalizedError)?.errorDescription ?? "Could not finish onboarding."
        }
    }
}

#Preview {
    OnboardingFlowView().environmentObject(AuthManager())
}
