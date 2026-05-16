import SwiftUI

struct ContentView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var selectedTab = 0
    @State private var discoveryFriendsMode = 0
    @State private var showSearchSheet = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background(for: colorScheme).ignoresSafeArea()

                Group {
                    switch selectedTab {
                    case 0:
                        HomeView(
                            networkManager: networkManager,
                            discoveryFriendsMode: $discoveryFriendsMode
                        )
                    case 1:
                        HypeFeedView(networkManager: networkManager)
                    case 3:
                        AlertsView()
                    case 4:
                        ProfileView()
                    default:
                        HomeView(
                            networkManager: networkManager,
                            discoveryFriendsMode: $discoveryFriendsMode
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                BottomTabBar(
                    selectedTab: $selectedTab,
                    colorScheme: colorScheme,
                    searchAction: {
                        showSearchSheet = true
                    }
                )
            }
            .task {
                await networkManager.fetchReleases()
            }
            .sheet(isPresented: $showSearchSheet) {
                SearchView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "calendar")
                        .foregroundColor(palette.primaryText(for: colorScheme))
                }
                ToolbarItem(placement: .principal) {
                    Text(principalTitle)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(palette.primaryText(for: colorScheme))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "gearshape")
                        .foregroundColor(palette.primaryText(for: colorScheme))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
        }
    }

    private var principalTitle: String {
        switch selectedTab {
        case 1: return "hype feed"
        case 3: return "alerts"
        case 4: return "profile"
        default: return "hype"
        }
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: Int
    var colorScheme: ColorScheme
    var searchAction: () -> Void
    @Environment(\.appPalette) private var palette

    private var accent: Color { palette.accent }
    private let centerButtonDiameter: CGFloat = 56

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(palette.tabBarSurface(for: colorScheme))
                .overlay(
                    Rectangle()
                        .fill(palette.tabBarTopHairline(for: colorScheme))
                        .frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)

            HStack(alignment: .center, spacing: 0) {
                TabButton(index: 0, title: "Home", system: "house", selectedTab: $selectedTab, accent: accent, colorScheme: colorScheme)
                TabButton(index: 1, title: "Hype Feed", system: "flame", selectedTab: $selectedTab, accent: accent, colorScheme: colorScheme)
                Spacer().frame(width: centerButtonDiameter + 16)
                TabButton(index: 3, title: "Alerts", system: "bell", selectedTab: $selectedTab, accent: accent, colorScheme: colorScheme)
                TabButton(index: 4, title: "Profile", system: "person", selectedTab: $selectedTab, accent: accent, colorScheme: colorScheme)
            }
            .padding(.horizontal, 24)
            .frame(height: 64)
        }
        .frame(height: 80)
        .overlay(
            Button(action: searchAction) {
                ZStack {
                    Circle()
                        .fill(accent)
                        .frame(width: centerButtonDiameter, height: centerButtonDiameter)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.black)
                }
            }
            .accessibilityLabel("Search albums")
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
    var colorScheme: ColorScheme
    @Environment(\.appPalette) private var palette

    private var muted: Color { palette.secondaryText(for: colorScheme) }

    var body: some View {
        let isActive = selectedTab == index
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: system)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isActive ? accent : muted)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isActive ? accent : muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
