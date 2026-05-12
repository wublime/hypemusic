import Foundation

/// UI model for a friend’s now-playing row on the Hype Feed.
struct FriendNowPlaying: Identifiable, Equatable {
    let id: String
    var username: String
    var songTitle: String
    var artistName: String
    /// Album / track artwork; shown on the spinning vinyl (HTTPS URL from API in production).
    var artworkURL: String
    var isPlaying: Bool
    var fireCount: Int
    var didReact: Bool
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
    }
}

let mockFriendFeed: [FriendNowPlaying] = [
    FriendNowPlaying(
        id: "user_alex",
        username: "@alexm",
        songTitle: "FE!N",
        artistName: "Travis Scott",
        artworkURL: "https://picsum.photos/seed/hypealex/600/600",
        isPlaying: true,
        fireCount: 14,
        didReact: false
    ),
    FriendNowPlaying(
        id: "user_nina",
        username: "@ninab",
        songTitle: "Vampire",
        artistName: "Olivia Rodrigo",
        artworkURL: "https://picsum.photos/seed/hypenina/600/600",
        isPlaying: true,
        fireCount: 31,
        didReact: true
    ),
    FriendNowPlaying(
        id: "user_jo",
        username: "@jothekid",
        songTitle: "SICKO MODE",
        artistName: "Travis Scott",
        artworkURL: "https://picsum.photos/seed/hypejo/600/600",
        isPlaying: false,
        fireCount: 8,
        didReact: false
    ),
    FriendNowPlaying(
        id: "user_maya",
        username: "@mayacodes",
        songTitle: "After Hours",
        artistName: "The Weeknd",
        artworkURL: "https://picsum.photos/seed/hypemaya/600/600",
        isPlaying: true,
        fireCount: 22,
        didReact: false
    )
]
