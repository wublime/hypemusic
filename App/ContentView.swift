import SwiftUI

struct ContentView: View {
    // 1. Initialize the Network Manager to talk to Python backend
    @StateObject var networkManager = NetworkManager()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexString: "#0F0F10").ignoresSafeArea()
                
                // Use a single vertical stack so sections appear in the intended order
                VStack(alignment: .leading, spacing: 24) {
                    // Section Label
                    Text("DROPPING THIS WEEK")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                    
                    // The Horizontal Carousel
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // 2. Loop through the REAL releases from Python server
                            if networkManager.releases.isEmpty {
                                // Optional: Show placeholders while loading
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 150, height: 200)
                            } else {
                                ForEach(networkManager.releases) { release in
                                    ReleaseCard(
                                        title: release.title,
                                        artist: release.artist,
                                        hype_score: release.hype_score,
                                        countdown: release.countdown
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .refreshable {
                        await networkManager.fetchReleases()
                    }
                    
                    // Place the toggle directly under the carousel as in the mock
                    HypeToggle(selectedTab: $selectedTab)
                    
                    // Reviews Section
                    Text("RECENT REVIEWS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)

                    // Vertical list of review cards from mock data
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
            // 3. This triggers the Python "ping" as soon as the app appears
            .safeAreaInset(edge: .bottom) {
                BottomTabBar(selectedTab: $selectedTab, plusAction: {
                    // TODO: Handle central plus action
                })
            }
            .task {
                await networkManager.fetchReleases()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "calendar").foregroundColor(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text("hype")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "gearshape").foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // Remove the default navigation bar background (white bar) so our dark background shows through
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }

    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: Int
    var plusAction: () -> Void

    private let accent = Color(hexString: "#FFB300")
    private let plusDiameter: CGFloat = 56

    var body: some View {
        ZStack(alignment: .top) {
            // Bar background
            Rectangle()
                .fill(Color(hexString: "#1A1A1C"))
                .overlay(
                    Rectangle()
                        .fill(Color.white)
                        .opacity(0.06)
                        .frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)

            // Tab items
            HStack(alignment: .center, spacing: 0) {
                TabButton(index: 0, title: "Home", system: "house", selectedTab: $selectedTab, accent: accent)
                TabButton(index: 1, title: "Hype Feed", system: "flame", selectedTab: $selectedTab, accent: accent)
                Spacer().frame(width: plusDiameter + 16) // gap reserved for the central plus button
                TabButton(index: 3, title: "Alerts", system: "bell", selectedTab: $selectedTab, accent: accent)
                TabButton(index: 4, title: "Profile", system: "person", selectedTab: $selectedTab, accent: accent)
            }
            .padding(.horizontal, 24)
            .frame(height: 64)
        }
        .frame(height: 80)
        .overlay(
            Button(action: plusAction) {
                ZStack {
                    Circle()
                        .fill(accent)
                        .frame(width: plusDiameter, height: plusDiameter)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.black)
                }
            }
            .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 6)
            .offset(y: -20)
        )
    }
}

struct TabButton: View {
    let index: Int
    let title: String
    let system: String
    @Binding var selectedTab: Int
    let accent: Color

    var body: some View {
        let isActive = selectedTab == index
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: system)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isActive ? accent : .gray)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isActive ? accent : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
