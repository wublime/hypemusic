#if DEBUG
import SwiftUI
import Foundation

// Standalone mock model used only for previews/debug builds
struct PreviewMockRelease: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let imageName: String
    let daysUntil: Int
    let hoursUntil: Int
}

// Local mock data for previewing UI components
let previewMockReleases: [PreviewMockRelease] = [
    PreviewMockRelease(title: "CHROMAKOPIA", artist: "Tyler, The Creator", imageName: "tyler", daysUntil: 2, hoursUntil: 14),
    PreviewMockRelease(title: "Haram", artist: "Armand Hammer", imageName: "alchemist", daysUntil: 0, hoursUntil: 5),
    PreviewMockRelease(title: "Pray for Paris", artist: "Westside Gunn", imageName: "gunn", daysUntil: 4, hoursUntil: 12),
    PreviewMockRelease(title: "Vultures 2", artist: "¥$", imageName: "kanye", daysUntil: 1, hoursUntil: 3)
]

// Helper to format the mock countdown similarly to server-provided strings
private func formattedCountdown(days: Int, hours: Int) -> String {
    String(format: "%02dD %02dH", days, hours)
}

#Preview("ReleaseCard - Mock") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            ForEach(previewMockReleases) { r in
                ReleaseCard(
                    title: r.title,
                    artist: r.artist,
                    hype_score: 90, // stand-in value for previews
                    countdown: formattedCountdown(days: r.daysUntil, hours: r.hoursUntil)
                )
            }
        }
        .padding()
        .background(Color(hex: "#0F0F10"))
    }
}
#endif
