import SwiftUI

/// Preset genre list shown as togglable chips during onboarding.
enum GenreCatalog {
    static let all: [(id: String, label: String)] = [
        ("hiphop", "Hip-Hop"),
        ("rnb", "R&B"),
        ("pop", "Pop"),
        ("indie", "Indie"),
        ("rock", "Rock"),
        ("alternative", "Alternative"),
        ("electronic", "Electronic"),
        ("house", "House"),
        ("techno", "Techno"),
        ("country", "Country"),
        ("latin", "Latin"),
        ("jazz", "Jazz"),
        ("soul", "Soul"),
        ("classical", "Classical"),
        ("metal", "Metal"),
        ("kpop", "K-Pop"),
    ]
}

struct GenresStepView: View {
    @Binding var selectedGenres: Set<String>
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you listen to?")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                Text("Pick at least one. We use this to surface releases you'll actually care about.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(GenreCatalog.all, id: \.id) { genre in
                        chip(id: genre.id, label: genre.label)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func chip(id: String, label: String) -> some View {
        let isSelected = selectedGenres.contains(id)
        return Button {
            if isSelected { selectedGenres.remove(id) } else { selectedGenres.insert(id) }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .black : palette.primaryText(for: colorScheme))
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(isSelected ? palette.accent : palette.card(for: colorScheme))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["hiphop"]
    return GenresStepView(selectedGenres: $selection)
        .background(AppPalette(preference: .hype).background(for: .dark))
}
