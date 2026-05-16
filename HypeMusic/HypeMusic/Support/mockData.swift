#if DEBUG
import SwiftUI
import Foundation

struct PreviewMockRelease: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let artwork_url: String
    let hype_count: Int
    let release_date: String?
}

let previewMockReleases: [PreviewMockRelease] = [
    PreviewMockRelease(title: "CHROMAKOPIA", artist: "Tyler, The Creator", artwork_url: "https://news.artnet.com/app/news-upload/2024/10/tyler-creator-chromakopia-album-1024x1024.jpg", hype_count: 98, release_date: "2030-01-15"),
    PreviewMockRelease(title: "Haram", artist: "Armand Hammer", artwork_url: "https://picsum.photos/seed/haram/600/600", hype_count: 88, release_date: "2020-06-01"),
    PreviewMockRelease(title: "Pray for Paris", artist: "Westside Gunn", artwork_url: "https://upload.wikimedia.org/wikipedia/en/3/36/Prayers_for_paris.jpg", hype_count: 92, release_date: "2031-12-01")
]

#Preview("ReleaseCard - Mock") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            ForEach(previewMockReleases) { r in
                ReleaseCard(
                    title: r.title,
                    artist: r.artist,
                    hypeCount: r.hype_count,
                    artworkURL: r.artwork_url,
                    releaseDateYYYYMMDD: r.release_date
                )
            }
        }
        .padding()
        .background(Color(red: 0.05, green: 0.05, blue: 0.06)) // Matching your dark theme
    }
}
#endif
