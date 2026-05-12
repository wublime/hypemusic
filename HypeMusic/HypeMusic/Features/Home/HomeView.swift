import SwiftUI

struct HomeView: View {
    @ObservedObject var networkManager: NetworkManager
    @Binding var discoveryFriendsMode: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("DROPPING THIS WEEK")
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if networkManager.releases.isEmpty {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 150, height: 200)
                    } else {
                        ForEach(networkManager.releases) { release in
                            ReleaseCard(
                                title: release.title,
                                artist: release.artist,
                                hypeCount: release.hype_count,
                                countdown: release.countdown,
                                status: release.status,
                                artworkURL: release.artwork_url
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                await networkManager.fetchReleases()
            }

            HypeToggle(discoveryFriendsMode: $discoveryFriendsMode)

            Text("RECENT REVIEWS")
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(mockReviewPosts) { post in
                        ReviewCard(post: post)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.top, 20)
    }
}
