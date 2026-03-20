import Foundation

struct GetSongBPMSearchResponse: Codable {
    let search: [GetSongBPMSearchResult]
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
