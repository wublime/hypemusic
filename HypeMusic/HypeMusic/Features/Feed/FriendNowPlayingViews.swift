import SwiftUI

private let accent = Color(hexString: "#FFB300")

struct SpinningRecordView: View {
    var isPlaying: Bool
    /// HTTPS URL for album or track artwork (shown on the spinning label).
    var artworkURL: String
    private let diameter: CGFloat = 240
    private var labelDiameter: CGFloat { diameter * 0.58 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: !isPlaying)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let cycle: Double = 12
            let degrees = (t.truncatingRemainder(dividingBy: cycle) / cycle) * 360

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hexString: "#2A2A2C"),
                                Color(hexString: "#0A0A0B")
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: diameter / 2
                        )
                    )
                    .frame(width: diameter, height: diameter)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.5), lineWidth: 2)
                    )

                ForEach(0..<28, id: \.self) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                        .frame(width: diameter * CGFloat(i) / 28, height: diameter * CGFloat(i) / 28)
                }

                ZStack {
                    Circle()
                        .fill(Color(hexString: "#1C1C1E"))

                    artworkDiskLayer
                        .frame(width: labelDiameter, height: labelDiameter)
                        .clipShape(Circle())
                }
                .frame(width: labelDiameter, height: labelDiameter)
                .overlay(
                    Circle()
                        .stroke(accent.opacity(0.35), lineWidth: 1)
                )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.25), Color.black.opacity(0.6)],
                            center: .center,
                            startRadius: 2,
                            endRadius: diameter * 0.12
                        )
                    )
                    .frame(width: diameter * 0.14, height: diameter * 0.14)
            }
            .rotationEffect(.degrees(degrees))
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isPlaying ? "Now playing, spinning record" : "Paused record")
    }

    @ViewBuilder
    private var artworkDiskLayer: some View {
        if let url = validArtworkURL(artworkURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    artworkPlaceholder
                case .empty:
                    ZStack {
                        artworkPlaceholder
                        ProgressView()
                            .tint(.white)
                    }
                @unknown default:
                    artworkPlaceholder
                }
            }
        } else {
            artworkPlaceholder
        }
    }

    private var artworkPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hexString: "#2C2C2E"), Color(hexString: "#1A1A1C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.gray.opacity(0.6))
        }
    }

    private func validArtworkURL(_ string: String) -> URL? {
        guard let url = URL(string: string), !string.isEmpty else { return nil }
        let scheme = url.scheme?.lowercased() ?? ""
        guard scheme == "https" || scheme == "http" else { return nil }
        return url
    }
}

#Preview("SpinningRecord") {
    ZStack {
        Color(hexString: "#0F0F10").ignoresSafeArea()
        SpinningRecordView(
            isPlaying: true,
            artworkURL: "https://picsum.photos/seed/previewvinyl/600/600"
        )
    }
}

