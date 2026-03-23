import Foundation

struct GetSongBPMSearchResponse: Codable {
    let search: [GetSongBPMSearchResult]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // API returns array on success, dictionary on "no result"
        if let results = try? container.decode([GetSongBPMSearchResult].self, forKey: .search) {
            search = results
        } else {
            search = []
        }
    }

    enum CodingKeys: String, CodingKey {
        case search
    }
}

struct GetSongBPMSearchResult: Codable {
    let id: String
    let title: String?
    let artist: GetSongBPMArtist?
}

struct GetSongBPMSongResponse: Codable {
    let song: GetSongBPMSong
}

struct GetSongBPMSong: Codable {
    let id: String
    let title: String?
    let tempo: String?
    let artist: GetSongBPMArtist?
    let album: GetSongBPMAlbum?
    let danceability: Int?
}

struct GetSongBPMArtist: Codable {
    let id: String?
    let name: String?
}

struct GetSongBPMAlbum: Codable {
    let title: String?
}

struct GetSongBPMTempoResponse: Codable {
    let tempo: [GetSongBPMSong]
}
