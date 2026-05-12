import SwiftUI

struct ProfileView: View {
    @State private var showMusicServices = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Profile")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)

                HStack(spacing: 16) {
                    Circle()
                        .fill(Color(hexString: "#2C2C2E"))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("You")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Stats, hype lists, and settings shortcuts—placeholder.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 10) {
                    profileRowButton(title: "Music services", systemImage: "music.note") {
                        showMusicServices = true
                    }
                    profileRow(title: "Your stats", systemImage: "chart.bar.fill")
                    profileRow(title: "Settings", systemImage: "gearshape.fill")
                    profileRow(title: "Hype lists", systemImage: "list.star")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showMusicServices) {
            MusicServicesConnectSheet()
        }
    }

    private func profileRow(title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hexString: "#FFB300"))
                .frame(width: 28)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(Color(hexString: "#1A1A1C"))
        .cornerRadius(12)
    }

    private func profileRowButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hexString: "#FFB300"))
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(Color(hexString: "#1A1A1C"))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
