import SwiftUI

struct ReleaseCard: View {
    let title: String
    let artist: String
    let hype_score: Int
    let countdown: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Artwork Section
            // We use .overlay here to fix the vertical stretching issue
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray)
                .opacity(0.3)
                .aspectRatio(1, contentMode: .fit) // This ensures the artwork stays a perfect square
                .overlay {
                    LinearGradient(
                        colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .overlay(alignment: .topTrailing) {
                    // Hype Score Badge - Pinned to Top Right
                    Text("\(hype_score)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(6)
                        .background(Color(hexString: "#FFB300"))
                        .clipShape(Circle())
                        .padding(8)
                }
                .overlay(alignment: .bottomLeading) {
                    // Timer Badge - Pinned to Bottom Left
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
        .frame(width: 150) // This keeps the card width consistent and prevents stretching
        .background(Color(hexString: "#1A1A1C"))
        .cornerRadius(16)
    }
}

