import SwiftUI
internal import Combine

/// The three result kinds the search sheet can show. Matches Apple Music's
/// search scope filters.
enum SearchScope: String, CaseIterable, Identifiable, Hashable {
    case artists
    case albums
    case songs

    var id: String { rawValue }

    var label: String {
        switch self {
        case .artists: return "Artists"
        case .albums: return "Albums"
        case .songs: return "Songs"
        }
    }
}

/// Drives the Spotify-backed search sheet. The view model owns the debounce
/// timer so the view stays declarative — keystrokes/scope-changes just mutate
/// state and the model coalesces them into one API call.
@MainActor
final class SpotifySearchViewModel: ObservableObject {

    @Published var query: String = ""
    @Published var scope: SearchScope = .artists
    @Published private(set) var artists: [Artist] = []
    @Published private(set) var albums: [Album] = []
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    /// True iff the currently selected scope has no results to render.
    var currentScopeIsEmpty: Bool {
        switch scope {
        case .artists: return artists.isEmpty
        case .albums: return albums.isEmpty
        case .songs: return songs.isEmpty
        }
    }

    /// Kick off a search. When `debounce` is true (the typical case for
    /// keystrokes), we wait 300ms and let any newer call cancel us; when
    /// false (tab-tap), we fire immediately so the new tab feels responsive.
    func scheduleSearch(debounce: Bool = true) {
        searchTask?.cancel()
        let snapshotQuery = query
        let snapshotScope = scope
        searchTask = Task { [weak self] in
            if debounce {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if Task.isCancelled { return }
            }
            await self?.runSearch(snapshotQuery, scope: snapshotScope)
        }
    }

    func runSearch(_ q: String, scope: SearchScope) async {
        let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            artists = []
            albums = []
            songs = []
            errorMessage = nil
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            switch scope {
            case .artists:
                let result = try await API.shared.searchArtists(query: trimmed)
                if Task.isCancelled { return }
                artists = result
            case .albums:
                let result = try await API.shared.searchAlbums(query: trimmed)
                if Task.isCancelled { return }
                albums = result
            case .songs:
                let result = try await API.shared.searchSongs(query: trimmed)
                if Task.isCancelled { return }
                songs = result
            }
            errorMessage = nil
        } catch {
            // Cancellation is part of the normal debounce flow (the user typed
            // another character or switched scopes mid-request) — silently drop
            // it instead of flashing an error to the UI.
            if Task.isCancelled || Self.isCancellation(error) {
                return
            }
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let ns: NSError
        if let apiError = error as? APIError, case .transport(let underlying) = apiError {
            ns = underlying as NSError
        } else {
            ns = error as NSError
        }
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }

    func clear() {
        searchTask?.cancel()
        query = ""
        artists = []
        albums = []
        songs = []
        errorMessage = nil
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SpotifySearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette
    @FocusState private var queryFocused: Bool

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                scopePicker
                content
            }
            .background(palette.searchChromeBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.searchChromeBackground(for: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close") { dismiss() }
                        .foregroundColor(palette.accent)
                }
            }
            .onAppear { queryFocused = true }
        }
    }

    // MARK: - Header

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(palette.secondaryText(for: colorScheme))
            TextField("artist, album, or song", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundColor(palette.primaryText(for: colorScheme))
                .focused($queryFocused)
                .submitLabel(.search)
                .onChange(of: viewModel.query) { _, _ in
                    viewModel.scheduleSearch()
                }
            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clear()
                    queryFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(palette.secondaryText(for: colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(palette.card(for: colorScheme))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var scopePicker: some View {
        HStack(spacing: 8) {
            ForEach(SearchScope.allCases) { scope in
                scopeButton(for: scope)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func scopeButton(for scope: SearchScope) -> some View {
        let isActive = viewModel.scope == scope
        return Button {
            guard viewModel.scope != scope else { return }
            viewModel.scope = scope
            // Tab tap is intentional — skip the debounce so the new pane
            // populates immediately.
            viewModel.scheduleSearch(debounce: false)
        } label: {
            Text(scope.label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isActive ? .black : palette.secondaryText(for: colorScheme))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(isActive
                              ? palette.accent
                              : palette.card(for: colorScheme))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: viewModel.scope)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.currentScopeIsEmpty {
            ProgressView()
                .tint(palette.accent)
                .scaleEffect(1.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            errorState(error)
        } else if viewModel.currentScopeIsEmpty {
            emptyState
        } else {
            switch viewModel.scope {
            case .artists: artistList
            case .albums: albumGrid
            case .songs: songList
            }
        }
    }

    private var artistList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.artists) { artist in
                    ArtistRow(artist: artist)
                    Divider().background(palette.listDivider(for: colorScheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var albumGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(viewModel.albums) { album in
                    AlbumSearchResultCard(album: album)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var songList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.songs) { song in
                    SongRow(song: song)
                    Divider().background(palette.listDivider(for: colorScheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.query.isEmpty ? "magnifyingglass" : noResultsIcon)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(palette.secondaryText(for: colorScheme))
            Text(emptyStateMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(palette.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsIcon: String {
        switch viewModel.scope {
        case .artists: return "person.2"
        case .albums: return "square.stack"
        case .songs: return "music.note.list"
        }
    }

    private var emptyStateMessage: String {
        if viewModel.query.isEmpty {
            return "search for an artist, album, or song"
        }
        switch viewModel.scope {
        case .artists: return "no artists found"
        case .albums: return "no albums found"
        case .songs: return "no songs found"
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(palette.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Result rows

/// Circular avatar + name + (optional) follower count. Mirrors the look of
/// Apple Music's artist rows.
struct ArtistRow: View {
    let artist: Artist
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: artist.image_url.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Color.gray.opacity(0.3)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                case .empty:
                    Color.gray.opacity(0.15)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                    .lineLimit(1)
                Text(artist.formattedFollowers ?? "Artist")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

/// Square cover + name/artist/year. Matches the visual style of
/// `ReleaseCard` so the rest of the app feels consistent.
struct AlbumSearchResultCard: View {
    let album: Album
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            artwork
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                    .lineLimit(1)
                Text(album.artist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .lineLimit(1)
                if !album.releaseYear.isEmpty {
                    Text(album.releaseYear)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(palette.accent)
                        .padding(.top, 2)
                }
            }
            .padding(10)
        }
        .background(palette.card(for: colorScheme))
        .cornerRadius(16)
    }

    @ViewBuilder
    private var artwork: some View {
        AsyncImage(url: album.image_url.flatMap { URL(string: $0) }) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                Color.gray.opacity(0.3)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            case .empty:
                Color.gray.opacity(0.15)
                    .overlay(ProgressView().tint(palette.accent))
            @unknown default:
                EmptyView()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}

/// Small square cover + title + artist/album subtitle + duration. Mirrors
/// Apple Music's song rows.
struct SongRow: View {
    let song: Song
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appPalette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: song.image_url.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Color.gray.opacity(0.3)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                case .empty:
                    Color.gray.opacity(0.15)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(song.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(palette.primaryText(for: colorScheme))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.secondaryText(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(song.formattedDuration)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.secondaryText(for: colorScheme))
                .monospacedDigit()
        }
        .padding(.vertical, 8)
    }

    /// "Artist • Album" if both are present, else whichever is non-empty.
    private var subtitle: String {
        if song.album.isEmpty { return song.artist }
        return "\(song.artist) • \(song.album)"
    }
}

#Preview {
    SearchView()
}
