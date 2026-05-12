import SwiftUI

struct ContentView: View {
    @StateObject private var networkManager = NetworkManager()
    @State private var selectedTab = 0
    @State private var discoveryFriendsMode = 0
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexString: "#0F0F10").ignoresSafeArea()

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
                BottomTabBar(selectedTab: $selectedTab, plusAction: {
                    showCreateSheet = true
                })
            }
            .task {
                await networkManager.fetchReleases()
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateOptionsSheet()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "calendar").foregroundColor(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text(principalTitle)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "gearshape").foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

struct CreateOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    dismiss()
                } label: {
                    Label("Create Post", systemImage: "square.and.pencil")
                }

                Button {
                    dismiss()
                } label: {
                    Label("Track Release", systemImage: "music.note.list")
                }

                Button {
                    dismiss()
                } label: {
                    Label("Add to Hype List", systemImage: "star")
                }
            }
            .navigationTitle("create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: Int
    var plusAction: () -> Void

    private let accent = Color(hexString: "#FFB300")
    private let plusDiameter: CGFloat = 56

    var body: some View {
        ZStack(alignment: .top) {
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

            HStack(alignment: .center, spacing: 0) {
                TabButton(index: 0, title: "Home", system: "house", selectedTab: $selectedTab, accent: accent)
                TabButton(index: 1, title: "Hype Feed", system: "flame", selectedTab: $selectedTab, accent: accent)
                Spacer().frame(width: plusDiameter + 16)
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
