import SwiftUI

struct ReleaseCard: View {
    let title: String
    let artist: String
    let hypeCount: Int
    let artworkURL: String
    /// `yyyy-MM-dd` from API; countdown / OUT NOW copy is derived on-device.
    let releaseDateYYYYMMDD: String?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    private var accent: Color { palette.accent }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Artwork Section
            AsyncImage(url: URL(string: artworkURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    Color.gray.opacity(0.3)
                        .overlay(Image(systemName: "music.note").foregroundColor(.gray))
                case .empty:
                    ProgressView()
                        .tint(palette.accent)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .overlay(alignment: .topTrailing) {
                Text("\(hypeCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(6)
                    .background(accent)
                    .clipShape(Circle())
                    .padding(8)
            }
            .overlay(alignment: .bottomLeading) {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let text = ReleaseSchedule.badgeText(
                        releaseDateYYYYMMDD: releaseDateYYYYMMDD,
                        now: context.date
                    )
                    Text(text)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(8)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                    .lineLimit(1)

                Text(artist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .lineLimit(1)
            }
            .padding(10)
        }
        .frame(width: 150)
        .background(palette.card(for: colorScheme))
        .cornerRadius(16)
    }
}
