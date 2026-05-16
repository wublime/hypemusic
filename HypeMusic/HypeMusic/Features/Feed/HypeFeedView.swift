import SwiftUI

struct HypeFeedView: View {
    @ObservedObject var networkManager: NetworkManager
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    private var items: [FriendNowPlaying] { networkManager.friendFeed }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if items.isEmpty {
                    emptyState(width: geo.size.width, height: geo.size.height)
                } else {
                    verticalReelScroll(geo: geo)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("HYPE FEED")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                    Text("You’re live — friends land here next")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.secondaryText(for: colorScheme).opacity(0.85))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: auth.accessToken) {
            await networkManager.fetchFriendFeed(accessToken: auth.accessToken)
            await pollFeedWhileVisible()
        }
    }

    private func emptyState(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "waveform.path")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(palette.accent.opacity(0.7))
            Text("Sign in and connect Spotify\nto see your live playback.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(width: width, height: height)
    }

    /// Refreshes Spotify-backed rows every few seconds while this view’s task runs.
    private func pollFeedWhileVisible() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await networkManager.fetchFriendFeed(accessToken: auth.accessToken)
        }
    }

    @ViewBuilder
    private func verticalReelScroll(geo: GeometryProxy) -> some View {
        let pageHeight = geo.size.height
        let pageWidth = geo.size.width

        if #available(iOS 17.0, *) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(items) { entry in
                        FriendNowPlayingCard(entry: entry) {
                            Task {
                                await networkManager.toggleFireReaction(
                                    forFriendId: entry.id,
                                    accessToken: auth.accessToken
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(width: pageWidth, height: pageHeight)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(items) { entry in
                        FriendNowPlayingCard(entry: entry) {
                            Task {
                                await networkManager.toggleFireReaction(
                                    forFriendId: entry.id,
                                    accessToken: auth.accessToken
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(width: pageWidth)
                        .frame(minHeight: pageHeight)
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppPalette(preference: .hype).background(for: .dark).ignoresSafeArea()
        HypeFeedView(networkManager: NetworkManager())
            .environmentObject(AuthManager())
    }
}
