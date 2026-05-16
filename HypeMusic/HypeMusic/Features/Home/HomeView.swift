import SwiftUI

struct HomeView: View {
    @ObservedObject var networkManager: NetworkManager
    @Binding var discoveryFriendsMode: Int
    @EnvironmentObject private var auth: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
    @State private var showRequestDropSheet = false

    private var accent: Color { palette.accent }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("DROPPING THIS WEEK")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
                    .foregroundColor(palette.secondaryText(for: colorScheme))

                Spacer(minLength: 8)

                Button {
                    showRequestDropSheet = true
                } label: {
                    Text("Request a drop")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.3)
                        .foregroundColor(accent)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Suggest an upcoming album for the feed")
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if networkManager.releases.isEmpty {
                        ProgressView()
                            .tint(palette.accent)
                            .frame(width: 150, height: 200)
                    } else {
                        ForEach(networkManager.releases) { release in
                            ReleaseCard(
                                title: release.title,
                                artist: release.artist,
                                hypeCount: release.hype_count,
                                artworkURL: release.artwork_url,
                                releaseDateYYYYMMDD: release.release_date
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                await networkManager.fetchReleases()
            }

            Text("RECENT REVIEWS")
                .font(.system(size: 11, weight: .black))
                .tracking(1.5)
                .foregroundColor(palette.secondaryText(for: colorScheme))
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 2)
            
            HypeToggle(discoveryFriendsMode: $discoveryFriendsMode)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(mockReviewPosts) { post in
                        ReviewCard(post: post)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(.top, 20)
        .sheet(isPresented: $showRequestDropSheet) {
            RequestDropSheet()
                .environmentObject(auth)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
