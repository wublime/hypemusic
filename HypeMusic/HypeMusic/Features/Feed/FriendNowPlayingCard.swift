import SwiftUI

// MARK: - Fire reaction (shared by reel + compact layouts)

struct FireButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
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
                    .background(palette.card(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(didReact ? palette.accent : Color.clear, lineWidth: 2)
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
                .foregroundColor(didReact ? palette.accent : palette.secondaryText(for: colorScheme))
            Text("\(fireCount)")
                .font(prominent ? .system(size: 16, weight: .bold) : .system(size: 12, weight: .semibold))
                .foregroundColor(didReact ? palette.accent : palette.secondaryText(for: colorScheme))
        }
    }
}

// MARK: - Full-screen reel card (used by HypeFeedView)

struct FriendNowPlayingCard: View {
    let entry: FriendNowPlaying
    var onFireTapped: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    private var progressTimelineInterval: Double {
        entry.isPlaying && (entry.durationMs ?? 0) > 0 ? 1.0 / 30.0 : 1.0
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(palette.accent.opacity(0.9))
                Text(entry.username)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(palette.card(for: colorScheme))
            .clipShape(Capsule())

            TimelineView(.animation(minimumInterval: progressTimelineInterval, paused: false)) { context in
                SpinningRecordView(
                    isPlaying: entry.isPlaying,
                    artworkURL: entry.artworkURL,
                    progressFraction: entry.progressFraction(at: context.date)
                )
            }

            VStack(spacing: 6) {
                Text(entry.songTitle)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(entry.artistName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)

            if !entry.isPlaying, entry.allowsHypeFire {
                Text("Paused")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(palette.secondaryText(for: colorScheme).opacity(0.9))
            }

            if entry.allowsHypeFire {
                FireButton(didReact: entry.didReact, fireCount: entry.fireCount, prominent: true, action: onFireTapped)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Compact card (optional layouts)

struct FriendNowPlayingCompact: View {
    let entry: FriendNowPlaying
    let onFireTapped: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(palette.card(for: colorScheme))
                .overlay(
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.songTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(palette.primaryText(for: colorScheme))
                            .lineLimit(1)
                        Text("\(entry.artistName) • \(entry.username)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(palette.secondaryText(for: colorScheme))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(16)
                )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if entry.allowsHypeFire {
                        FireButton(didReact: entry.didReact, fireCount: entry.fireCount, prominent: false, action: onFireTapped)
                    }
                }
                .padding(16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Reel card") {
    ZStack {
        AppPalette(preference: .hype).background(for: .dark).ignoresSafeArea()
        FriendNowPlayingCard(entry: .previewPlaying) {}
            .padding(.horizontal, 20)
    }
}

#Preview("Compact") {
    ZStack {
        AppPalette(preference: .hype).background(for: .dark).ignoresSafeArea()
        FriendNowPlayingCompact(entry: .previewPlaying) {}
            .padding(20)
    }
}
