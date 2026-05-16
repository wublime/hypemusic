import Foundation

/// UI model for a Hype Feed row (Spotify now playing from the backend).
struct FriendNowPlaying: Identifiable, Equatable {
    let id: String
    var username: String
    var songTitle: String
    var artistName: String
    /// Album / track artwork; shown on the spinning vinyl (HTTPS URL from API).
    var artworkURL: String
    var isPlaying: Bool
    var fireCount: Int
    var didReact: Bool
    var progressMs: Int?
    var durationMs: Int?
    var progressSnapshotMs: Int64?

    /// Smooth progress ring: extrapolates from Spotify snapshot when playing.
    func progressFraction(at date: Date) -> Double? {
        guard let d = durationMs, d > 0,
              let snap = progressSnapshotMs,
              let p0 = progressMs else { return nil }
        let snapDate = Date(timeIntervalSince1970: Double(snap) / 1000.0)
        let deltaMs = isPlaying ? Int(date.timeIntervalSince(snapDate) * 1000) : 0
        let pos = min(d, max(0, p0 + deltaMs))
        return Double(pos) / Double(d)
    }

    /// Fire only for real track rows (connect / idle placeholders omit duration).
    var allowsHypeFire: Bool {
        (durationMs ?? 0) > 0
    }
}

extension FriendNowPlaying {
    init(dto: FriendNowPlayingDTO) {
        id = dto.user_id
        username = dto.username
        songTitle = dto.song_title
        artistName = dto.artist_name
        artworkURL = dto.artwork_url
        isPlaying = dto.is_playing
        fireCount = dto.fire_count
        didReact = dto.viewer_reacted
        progressMs = dto.progress_ms
        durationMs = dto.duration_ms
        progressSnapshotMs = dto.progress_snapshot_ms
    }
}

#if DEBUG
extension FriendNowPlaying {
    static let previewPlaying = FriendNowPlaying(
        id: "preview-user",
        username: "@you",
        songTitle: "FE!N",
        artistName: "Travis Scott",
        artworkURL: "https://picsum.photos/seed/hypepreview/600/600",
        isPlaying: true,
        fireCount: 12,
        didReact: false,
        progressMs: 45_000,
        durationMs: 220_000,
        progressSnapshotMs: Int64(Date().timeIntervalSince1970 * 1000)
    )
}
#endif
