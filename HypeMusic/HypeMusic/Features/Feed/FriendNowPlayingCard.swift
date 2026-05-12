import SwiftUI

private let feedAccent = Color(hexString: "#FFB300")

// MARK: - Fire reaction (shared by reel + compact layouts)

struct FireButton: View {
    let didReact: Bool
    let fireCount: Int
    /// Larger tap target and typography for the full-screen feed card.
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if prominent {
                fireLabel
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hexString: "#1A1A1C"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(didReact ? feedAccent : Color.clear, lineWidth: 2)
                    )
            } else {
                fireLabel
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(didReact ? "Remove fire reaction" : "React with fire")
        .accessibilityHint("Double tap to toggle your reaction")
    }

    private var fireLabel: some View {
        HStack(spacing: prominent ? 8 : 6) {
            Image(systemName: didReact ? "flame.fill" : "flame")
                .font(.system(size: prominent ? 22 : 16, weight: .semibold))
                .foregroundColor(didReact ? feedAccent : .gray)
            Text("\(fireCount)")
                .font(prominent ? .system(size: 16, weight: .bold) : .system(size: 12, weight: .semibold))
                .foregroundColor(didReact ? feedAccent : .gray)
        }
    }
}

// MARK: - Full-screen reel card (used by HypeFeedView)

struct FriendNowPlayingCard: View {
    let entry: FriendNowPlaying
    var onFireTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Text(entry.username)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(feedAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hexString: "#1A1A1C"))
                .clipShape(Capsule())

            SpinningRecordView(isPlaying: entry.isPlaying, artworkURL: entry.artworkURL)

            VStack(spacing: 6) {
                Text(entry.songTitle)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(entry.artistName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)

            if !entry.isPlaying {
                Text("Paused")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.gray.opacity(0.8))
            }

            FireButton(didReact: entry.didReact, fireCount: entry.fireCount, prominent: true, action: onFireTapped)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Compact card (optional layouts)

struct FriendNowPlayingCompact: View {
    let entry: FriendNowPlaying
    let onFireTapped: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hexString: "#1A1A1C"))
                .overlay(
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.songTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(entry.artistName) • \(entry.username)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(16)
                )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FireButton(didReact: entry.didReact, fireCount: entry.fireCount, prominent: false, action: onFireTapped)
                }
                .padding(16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Reel card") {
    ZStack {
        Color(hexString: "#0F0F10").ignoresSafeArea()
        FriendNowPlayingCard(entry: mockFriendFeed.first!) {}
            .padding(.horizontal, 20)
    }
}

#Preview("Compact") {
    ZStack {
        Color(hexString: "#0F0F10").ignoresSafeArea()
        FriendNowPlayingCompact(entry: mockFriendFeed.first!) {}
            .padding(20)
    }
}
