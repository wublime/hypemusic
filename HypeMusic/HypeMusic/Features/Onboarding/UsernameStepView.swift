import SwiftUI

/// Status of the username uniqueness check.
enum UsernameStatus: Equatable {
    case idle
    case invalid
    case checking
    case taken
    case available
}

struct UsernameStepView: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
    @Binding var username: String
    @Binding var status: UsernameStatus

    /// Debounce token; bumped on every keystroke. The debounced task aborts early
    /// if `token` no longer matches its captured value.
    @State private var debounceToken: UUID = UUID()

    private let usernameRegex = #"^[a-z0-9_]{3,20}$"#

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick your @username")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                Text("This is also your display name. 3-20 lowercase letters, numbers, or underscores.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
            }

            HStack(spacing: 8) {
                Text("@")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(palette.accent)
                TextField("", text: $username, prompt: Text("yourhandle").foregroundColor(palette.secondaryText(for: colorScheme)))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.done)
                    .onChange(of: username) { _, newValue in
                        let normalized = sanitize(newValue)
                        if normalized != newValue { username = normalized }
                        scheduleCheck(for: normalized)
                    }

                statusGlyph
            }
            .padding(14)
            .background(palette.card(for: colorScheme))
            .cornerRadius(12)

            statusLabel

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    // MARK: - UI bits

    @ViewBuilder
    private var statusGlyph: some View {
        switch status {
        case .checking:
            ProgressView().tint(palette.secondaryText(for: colorScheme))
        case .available:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .taken, .invalid:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch status {
        case .invalid:
            Text("Use 3-20 lowercase letters, numbers, or underscores.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.red)
        case .taken:
            Text("That handle is already taken.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.red)
        case .available:
            Text("Nice — @\(username) is available.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.green)
        case .checking:
            Text("Checking availability…")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(palette.secondaryText(for: colorScheme))
        case .idle:
            Text(" ")
                .font(.system(size: 13))
        }
    }

    // MARK: - Validation

    private func sanitize(_ s: String) -> String {
        s.lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
            .prefix(20)
            .description
    }

    private func scheduleCheck(for candidate: String) {
        guard candidate.range(of: usernameRegex, options: .regularExpression) != nil else {
            status = candidate.isEmpty ? .idle : .invalid
            return
        }
        status = .checking
        let token = UUID()
        debounceToken = token
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard token == debounceToken else { return }
            let available = await auth.checkUsername(candidate)
            guard token == debounceToken else { return }
            await MainActor.run {
                status = available ? .available : .taken
            }
        }
    }
}

#Preview {
    @Previewable @State var u = ""
    @Previewable @State var s: UsernameStatus = .idle
    UsernameStepView(username: $u, status: $s)
        .environmentObject(AuthManager())
        .background(AppPalette(preference: .hype).background(for: .dark))
}
