import SwiftUI

/// Lets a signed-in user suggest an upcoming album for the curated releases feed.
struct RequestDropSheet: View {
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
    @State private var albumTitle = ""
    @State private var artistName = ""
    @State private var note = ""
    @State private var isSubmitting = false
    @State private var alertMessage: String?
    @State private var alertWasSuccess = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case album, artist, note
    }

    private var accent: Color { palette.accent }

    private var canSubmit: Bool {
        !albumTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Tell us what we should add to the drop list. You’ll see it in the app if it gets picked.")
                            .font(.system(size: 14))
                            .foregroundColor(palette.secondaryText(for: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Album")
                            TextField("Album title", text: $albumTitle)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(palette.textFieldFill(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(palette.primaryText(for: colorScheme))
                                .focused($focusedField, equals: .album)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .artist }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Artist")
                            TextField("Artist name", text: $artistName)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(palette.textFieldFill(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(palette.primaryText(for: colorScheme))
                                .focused($focusedField, equals: .artist)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .note }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Note (optional)")
                            TextField("Release date, link, or why it should be here", text: $note, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3 ... 6)
                                .padding(14)
                                .background(palette.textFieldFill(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(palette.primaryText(for: colorScheme))
                                .focused($focusedField, equals: .note)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Request a drop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.background(for: colorScheme), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { Task { await submit() } }
                        .fontWeight(.bold)
                        .foregroundColor(
                            canSubmit
                                ? accent
                                : palette.secondaryText(for: colorScheme)
                        )
                        .disabled(!canSubmit)
                }
            }
            .alert("Request a drop", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil; alertWasSuccess = false } }
            )) {
                Button("OK") {
                    if alertWasSuccess {
                        dismiss()
                    }
                    alertWasSuccess = false
                    alertMessage = nil
                }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black))
            .tracking(1.2)
            .foregroundColor(palette.secondaryText(for: colorScheme))
    }

    private func submit() async {
        guard let token = auth.accessToken else {
            alertMessage = "You need to be signed in to send a request."
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response = try await API.shared.submitDropRequest(
                token: token,
                albumTitle: albumTitle,
                artistName: artistName,
                note: note
            )
            alertWasSuccess = true
            alertMessage = response.message
        } catch APIError.unauthorized {
            alertWasSuccess = false
            alertMessage = "Your session expired. Sign in again from the profile tab."
        } catch {
            alertWasSuccess = false
            alertMessage = error.localizedDescription
        }
    }
}

#Preview {
    RequestDropSheet()
        .environmentObject(AuthManager())
}
