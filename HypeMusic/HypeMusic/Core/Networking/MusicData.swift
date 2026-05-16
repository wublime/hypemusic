
import Foundation
internal import Combine

// MARK: - Configuration

enum APIConfig {
    /// Read from Info.plist (`APIBaseURL`). Must be reachable from wherever the app runs:
    /// simulator → `http://127.0.0.1:8000`; physical device → `http://<your-mac-lan-ip>:8000`,
    /// or a deployed HTTPS host.
    static let baseURL: URL = Self.resolveAPIBaseURL()

    #if targetEnvironment(simulator)
    static let isSimulator = true
    #else
    static let isSimulator = false
    #endif

    /// Spotify configuration. Replace the client ID in your config before shipping;
    /// the redirect URI must match what's registered in the Spotify dashboard AND
    /// what's listed under `CFBundleURLTypes` in `Info.plist`.
    static let spotifyClientID = "ee492ad025c34c1bae0ccf5975d17a78"
    static let spotifyRedirectURI = "tap-in-login://callback"
    static let spotifyScopes = "user-read-currently-playing user-read-recently-played user-read-playback-state"

    private static func resolveAPIBaseURL() -> URL {
        let key = "APIBaseURL"
        if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           let url = Self.normalizedHTTPURL(raw) {
            return url
        }
        #if targetEnvironment(simulator)
        return URL(string: "http://127.0.0.1:8000")!
        #else
        print(
            "[APIConfig] Missing or invalid \(key) in Info.plist. " +
                "Set it to http://<your-mac-ip>:8000 so a device can reach your local API."
        )
        return URL(string: "http://127.0.0.1:8000")!
        #endif
    }

    private static func normalizedHTTPURL(_ raw: String) -> URL? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasSuffix("/") { s.removeLast() }
        guard !s.isEmpty, let url = URL(string: s), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        guard scheme == "http" || scheme == "https" else { return nil }
        return url
    }
}

// MARK: - DTOs

/// Matches `/releases` JSON keys (aligned with Postgres column names).
struct ReleaseResponse: Codable, Identifiable {
    var id: String { "\(title)-\(artist)-\(release_date ?? "")" }
    let title: String
    let artist: String
    let artwork_url: String
    let hype_count: Int
    /// `yyyy-MM-dd` (Eastern drop is midnight on this calendar day in New York).
    let release_date: String?
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
    let progress_ms: Int?
    let duration_ms: Int?
    let progress_snapshot_ms: Int64?
}

struct FireReactResponse: Codable {
    let fire_count: Int
    let viewer_reacted: Bool
}

struct AppUser: Codable, Equatable {
    let id: String
    let email: String?
    let username: String?
    let avatar_url: String?
    let favorite_genres: [String]
    let onboarding_complete: Bool
    let spotify_connected: Bool
    let apple_music_connected: Bool
}

struct AppleAuthRequest: Codable {
    let identity_token: String
    let nonce: String?
    let email: String?
}

struct AppleAuthResponse: Codable {
    let access_token: String
    let user: AppUser
}

struct UpdateUserRequest: Codable {
    var username: String?
    var favorite_genres: [String]?
    var onboarding_complete: Bool?
}

struct CheckUsernameResponse: Codable {
    let available: Bool
}

struct SpotifyExchangeRequest: Codable {
    let code: String
    let code_verifier: String
    let redirect_uri: String
}

struct SpotifyExchangeResponse: Codable {
    let connected: Bool
}

struct DropRequestCreateBody: Codable {
    let album_title: String
    let artist_name: String
    let note: String?
}

struct DropRequestCreatedResponse: Codable {
    let id: Int
    let message: String
}

/// Matches `/api/search/albums` JSON. Keyed off `spotify_id` so SwiftUI
/// `ForEach` / `Identifiable` works without us inventing a UUID per row.
struct Album: Codable, Identifiable, Equatable, Hashable {
    let name: String
    let artist: String
    let release_date: String
    let spotify_id: String
    let image_url: String?

    var id: String { spotify_id }

    /// Spotify `release_date` is one of `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`
    /// depending on the album's `release_date_precision`. We only need the
    /// year for the card UI.
    var releaseYear: String {
        String(release_date.prefix(4))
    }
}

/// Matches `/api/search/artists` JSON.
struct Artist: Codable, Identifiable, Equatable, Hashable {
    let name: String
    let spotify_id: String
    let image_url: String?
    let genres: [String]
    let follower_count: Int?

    var id: String { spotify_id }

    /// `1,234,567` style number for the row subtitle. Avoids a full
    /// `NumberFormatter` instance — search results render at 60fps and we
    /// don't want to allocate per cell.
    var formattedFollowers: String? {
        guard let count = follower_count else { return nil }
        if count >= 1_000_000 {
            return String(format: "%.1fM followers", Double(count) / 1_000_000)
        }
        if count >= 1_000 {
            return String(format: "%.1fK followers", Double(count) / 1_000)
        }
        return "\(count) followers"
    }
}

/// Matches `/api/search/songs` JSON. Spotify calls these "tracks"; we
/// expose them as "songs" to match the Apple Music vocabulary used in our UI.
struct Song: Codable, Identifiable, Equatable, Hashable {
    let name: String
    let artist: String
    let album: String
    let release_date: String
    let spotify_id: String
    let image_url: String?
    let preview_url: String?
    let duration_ms: Int

    var id: String { spotify_id }

    /// `mm:ss` formatting for row subtitle.
    var formattedDuration: String {
        let totalSeconds = duration_ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case badStatus(Int, String)
    case decoding(Error)
    case transport(Error)
    case unauthorized(String)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code, let body): return Self.friendlyHTTPMessage(code: code, body: body)
        case .decoding(let e): return "Decoding error: \(e)"
        case .transport(let e): return "Transport error: \(e)"
        case .unauthorized(let body): return Self.friendlyHTTPMessage(code: 401, body: body)
        }
    }

    private static func friendlyHTTPMessage(code: Int, body: String) -> String {
        if let data = body.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let detail = json["detail"] as? String {
            return detail
        }
        return "HTTP \(code): \(body)"
    }
}

// MARK: - API client

/// All authenticated and unauthenticated API calls funnel through here.
/// Routing through one helper keeps `Authorization` header injection consistent.
struct API {
    static let shared = API()

    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    // MARK: Unauthenticated

    func appleAuth(identityToken: String, email: String?, nonce: String? = nil) async throws -> AppleAuthResponse {
        let body = AppleAuthRequest(identity_token: identityToken, nonce: nonce, email: email)
        return try await request(
            method: "POST",
            path: "/auth/apple",
            token: nil,
            body: body
        )
    }

    /// Local backend only (`DEV_AUTH_ENABLED=1`). Used in the simulator when Apple token
    /// verification is not configured yet.
    func devAuth(email: String? = nil) async throws -> AppleAuthResponse {
        struct DevAuthRequest: Codable { let email: String? }
        return try await request(
            method: "POST",
            path: "/auth/dev",
            token: nil,
            body: DevAuthRequest(email: email)
        )
    }

    func checkUsername(_ candidate: String) async throws -> Bool {
        var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent("/users/check-username"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "q", value: candidate)]
        let url = components.url!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let response: CheckUsernameResponse = try await send(req)
        return response.available
    }

    /// Hits `/api/search/albums?query=…` which proxies Spotify's search.
    /// Backend handles the Spotify auth and shape simplification, so the
    /// client only needs to know about `Album`.
    func searchAlbums(query: String) async throws -> [Album] {
        try await searchEntity(path: "/api/search/albums", query: query)
    }

    /// Hits `/api/search/artists?query=…`.
    func searchArtists(query: String) async throws -> [Artist] {
        try await searchEntity(path: "/api/search/artists", query: query)
    }

    /// Hits `/api/search/songs?query=…`.
    func searchSongs(query: String) async throws -> [Song] {
        try await searchEntity(path: "/api/search/songs", query: query)
    }

    /// Shared GET helper for the three search endpoints. Centralised so we
    /// only have one place to add caching, auth, telemetry, etc. later.
    private func searchEntity<R: Decodable>(path: String, query: String) async throws -> [R] {
        var components = URLComponents(
            url: APIConfig.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "query", value: query)]
        guard let url = components.url else { return [] }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        return try await send(req)
    }

    // MARK: Authenticated

    func fetchMe(token: String) async throws -> AppUser {
        try await request(method: "GET", path: "/users/me", token: token, body: Optional<EmptyBody>.none)
    }

    func updateMe(token: String, body: UpdateUserRequest) async throws -> AppUser {
        try await request(method: "PATCH", path: "/users/me", token: token, body: body)
    }

    func exchangeSpotify(token: String, code: String, verifier: String, redirectURI: String) async throws -> SpotifyExchangeResponse {
        let body = SpotifyExchangeRequest(code: code, code_verifier: verifier, redirect_uri: redirectURI)
        return try await request(
            method: "POST",
            path: "/auth/spotify/exchange",
            token: token,
            body: body
        )
    }

    func submitDropRequest(
        token: String,
        albumTitle: String,
        artistName: String,
        note: String?
    ) async throws -> DropRequestCreatedResponse {
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = DropRequestCreateBody(
            album_title: albumTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            artist_name: artistName.trimmingCharacters(in: .whitespacesAndNewlines),
            note: (trimmedNote?.isEmpty == false) ? trimmedNote : nil
        )
        return try await request(
            method: "POST",
            path: "/releases/drop-requests",
            token: token,
            body: body
        )
    }

    // MARK: Lower-level helpers

    private struct EmptyBody: Codable {}

    private func request<R: Decodable, B: Encodable>(
        method: String,
        path: String,
        token: String?,
        body: B?
    ) async throws -> R {
        let url = APIConfig.baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)
        }
        return try await send(req)
    }

    private func send<R: Decodable>(_ request: URLRequest) async throws -> R {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.badStatus(-1, "non-HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 401 {
                throw APIError.unauthorized(body)
            }
            throw APIError.badStatus(http.statusCode, body)
        }
        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

// MARK: - View-model used by the existing tab bar

@MainActor
class NetworkManager: ObservableObject {
    @Published var releases: [ReleaseResponse] = []
    @Published var friendFeed: [FriendNowPlaying] = []

    func fetchReleases() async {
        var req = URLRequest(url: APIConfig.baseURL.appendingPathComponent("/releases"))
        req.httpMethod = "GET"
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode([ReleaseResponse].self, from: data)
            self.releases = decoded
        } catch {
            print("Error fetching data: \(error)")
        }
    }

    func fetchFriendFeed(accessToken: String?) async {
        guard let token = accessToken, !token.isEmpty else {
            friendFeed = []
            return
        }
        var req = URLRequest(url: APIConfig.baseURL.appendingPathComponent("/feed/now-playing"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                friendFeed = []
                return
            }
            if http.statusCode == 401 {
                friendFeed = []
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                friendFeed = []
                return
            }
            let decoded = try JSONDecoder().decode([FriendNowPlayingDTO].self, from: data)
            friendFeed = decoded.map { FriendNowPlaying(dto: $0) }
        } catch {
            print("Error fetching friend feed: \(error)")
        }
    }

    func toggleFireReaction(forFriendId id: String, accessToken: String?) async {
        guard let token = accessToken, !token.isEmpty else { return }
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent("/feed/now-playing/\(id)/react"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(FireReactResponse.self, from: data)
            guard let idx = friendFeed.firstIndex(where: { $0.id == id }) else { return }
            friendFeed[idx].fireCount = response.fire_count
            friendFeed[idx].didReact = response.viewer_reacted
        } catch {
            print("Error toggling fire reaction: \(error)")
            guard let idx = friendFeed.firstIndex(where: { $0.id == id }) else { return }
            var row = friendFeed[idx]
            let was = row.didReact
            row.didReact = !was
            row.fireCount = max(0, row.fireCount + (row.didReact ? 1 : -1))
            friendFeed[idx] = row
        }
    }
}
