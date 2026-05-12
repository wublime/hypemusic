import SwiftUI

struct ReleaseCard: View {
    let title: String
    let artist: String
    let hypeCount: Int
    let countdown: String
    let status: String
    let artworkURL: String

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
                    // Fallback if link is broken
                    Color.gray.opacity(0.3)
                        .overlay(Image(systemName: "music.note").foregroundColor(.gray))
                case .empty:
                    // Loading state
                    ProgressView()
                        .tint(.yellow)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 150, height: 150) // Keeps it a perfect square
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                // Keep your gradient so the badges/text are readable
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .overlay(alignment: .topTrailing) {
                // Hype Score Badge
                Text("\(hypeCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(6)
                    .background(Color(hexString: "#FFB300"))
                    .clipShape(Circle())
                    .padding(8)
            }
            .overlay(alignment: .bottomLeading) {
                // Timer Badge
                Text(countdown)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hexString: "#FFB300"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(8)
            }
            
            // Text Surface
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(artist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(10)
        }
        .frame(width: 150)
        .background(Color(hexString: "#1A1A1C"))
        .cornerRadius(16)
    }
}
