
import Foundation
internal import Combine

/// Matches `/releases` JSON keys (aligned with Postgres column names).
struct ReleaseResponse: Codable, Identifiable {
    var id: String { title }
    let title: String
    let artist: String
    let artwork_url: String
    let hype_count: Int
    let status: String
    let countdown: String
}

struct FriendNowPlayingDTO: Codable {
    let user_id: String
    let username: String
    let song_title: String
    let artist_name: String
    let artwork_url: String
    let is_playing: Bool
    let updated_at: String
    let fire_count: Int
    let viewer_reacted: Bool
}

struct FireReactResponse: Codable {
    let fire_count: Int
    let viewer_reacted: Bool
}

@MainActor
class NetworkManager: ObservableObject {
    @Published var releases: [ReleaseResponse] = []
    @Published var friendFeed: [FriendNowPlaying] = mockFriendFeed

    func fetchReleases() async {
        // "127.0.0.1" works for the simulator to talk to your Mac
        guard let url = URL(string: "http://127.0.0.1:8000/releases") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode([ReleaseResponse].self, from: data)
            self.releases = decodedData
        } catch {
            print("❌ Error fetching data: \(error)")
        }
    }

    func fetchFriendFeed() async {
        guard let url = URL(string: "http://127.0.0.1:8000/feed/now-playing") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([FriendNowPlayingDTO].self, from: data)
            friendFeed = decoded.map { FriendNowPlaying(dto: $0) }
        } catch {
            print("❌ Error fetching friend feed: \(error)")
            friendFeed = mockFriendFeed
        }
    }

    func toggleFireReaction(forFriendId id: String) async {
        guard let url = URL(string: "http://127.0.0.1:8000/feed/now-playing/\(id)/react") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(FireReactResponse.self, from: data)
            guard let idx = friendFeed.firstIndex(where: { $0.id == id }) else { return }
            friendFeed[idx].fireCount = response.fire_count
            friendFeed[idx].didReact = response.viewer_reacted
        } catch {
            print("❌ Error toggling fire reaction: \(error)")
            guard let idx = friendFeed.firstIndex(where: { $0.id == id }) else { return }
            var row = friendFeed[idx]
            let was = row.didReact
            row.didReact = !was
            row.fireCount = max(0, row.fireCount + (row.didReact ? 1 : -1))
            friendFeed[idx] = row
        }
    }
}
