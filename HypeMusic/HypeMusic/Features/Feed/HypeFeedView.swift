import SwiftUI

struct HypeFeedView: View {
    @ObservedObject var networkManager: NetworkManager

    private var items: [FriendNowPlaying] { networkManager.friendFeed }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if items.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    verticalReelScroll(geo: geo)
                }

                Text("Friends now playing")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await networkManager.fetchFriendFeed()
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
                                await networkManager.toggleFireReaction(forFriendId: entry.id)
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
                                await networkManager.toggleFireReaction(forFriendId: entry.id)
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
        Color(hexString: "#0F0F10").ignoresSafeArea()
        HypeFeedView(networkManager: NetworkManager())
    }
}
