import SwiftUI

struct PlaylistListView: View {
    @State private var playlists: [SpotifyPlaylist] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var offset = 0
    @State private var error: String?

    private let limit = 50

    var body: some View {
        Group {
            if isLoading && playlists.isEmpty {
                ProgressView("Loading playlists...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error, playlists.isEmpty {
                errorView(message: error)
            } else {
                playlistList
            }
        }
        .navigationTitle("Your Library")
        .task {
            if playlists.isEmpty {
                await loadPlaylists()
            }
        }
        .refreshable {
            await refresh()
        }
    }

    // MARK: - Subviews

    private var playlistList: some View {
        List {
            ForEach(playlists) { playlist in
                NavigationLink(value: playlist) {
                    PlaylistRow(playlist: playlist)
                }
                .onAppear {
                    if playlist.id == playlists.last?.id && hasMore && !isLoading {
                        Task { await loadPlaylists() }
                    }
                }
            }

            if isLoading && !playlists.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: SpotifyPlaylist.self) { playlist in
            PlaylistDetailView(playlist: playlist)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await loadPlaylists() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadPlaylists() async {
        isLoading = true
        error = nil

        do {
            let response = try await SpotifyAPIService.shared.fetchPlaylists(offset: offset, limit: limit)
            playlists.append(contentsOf: response.items)
            hasMore = response.hasMore
            offset = response.nextOffset
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func refresh() async {
        playlists = []
        offset = 0
        hasMore = true
        await loadPlaylists()
    }
}

// MARK: - Playlist Row

private struct PlaylistRow: View {
    let playlist: SpotifyPlaylist

    var body: some View {
        HStack(spacing: 12) {
            // Cover art
            if let imageURL = playlist.images?.first?.url,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "music.note.list")
                            .foregroundStyle(.gray)
                    }
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text("\(playlist.tracks.total) tracks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 50)
    }
}
