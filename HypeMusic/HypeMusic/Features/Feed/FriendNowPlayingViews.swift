import SwiftUI

struct SpinningRecordView: View {
    var isPlaying: Bool
    /// HTTPS URL for album or track artwork (shown on the spinning label).
    var artworkURL: String
    /// 0...1 fraction through the track; drawn as a static ring around the vinyl (does not spin).
    var progressFraction: Double?
    private let diameter: CGFloat = 240
    @Environment(\.appPalette) private var palette
    private var labelDiameter: CGFloat { diameter * 0.58 }
    /// Outer ring sits slightly outside the vinyl groove area.
    private var ringDiameter: CGFloat { diameter + 14 }

    var body: some View {
        ZStack {
            // Progress track + arc (never rotates with the platter)
            if let frac = progressFraction {
                Circle()
                    .stroke(palette.accent.opacity(0.2), lineWidth: 3)
                    .frame(width: ringDiameter, height: ringDiameter)

                Circle()
                    .trim(from: 0, to: min(1, max(0, CGFloat(frac))))
                    .stroke(
                        palette.accent,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: ringDiameter, height: ringDiameter)
                    .rotationEffect(.degrees(-90))
            }

            TimelineView(.animation(minimumInterval: isPlaying ? 1 / 60 : 1, paused: false)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let cycle: Double = 12
                let degrees = isPlaying ? (t.truncatingRemainder(dividingBy: cycle) / cycle) * 360 : 0

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
                            .stroke(palette.accent.opacity(0.35), lineWidth: 1)
                    )

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [palette.accent.opacity(0.25), Color.black.opacity(0.6)],
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
        }
        .frame(width: ringDiameter, height: ringDiameter)
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
            artworkURL: "https://picsum.photos/seed/previewvinyl/600/600",
            progressFraction: 0.42
        )
    }
}
