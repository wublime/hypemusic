import SwiftUI

struct RootView: View {
    @State private var selected = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selected) {
                ContentView()
                    .tabItem { Label("Home", systemImage: "house") }
                    .tag(0)

                // Placeholder tabs for now
                Text("Hype Feed")
                    .tabItem { Label("Hype Feed", systemImage: "flame") }
                    .tag(1)

                Text("Add")
                    .tabItem { Label("Add", systemImage: "plus.circle") }
                    .tag(2)

                Text("Alerts")
                    .tabItem { Label("Alerts", systemImage: "bell") }
                    .tag(3)

                Text("Profile")
                    .tabItem { Label("Profile", systemImage: "person") }
                    .tag(4)
            }

            // Floating action button overlay
            Button {
                // TODO: Present compose review sheet
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 56, height: 56)
                    .background(Color(red: 1.0, green: 0.7019608, blue: 0.0))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.bottom, 28)
        }
    }
}

#Preview {
    RootView()
}
