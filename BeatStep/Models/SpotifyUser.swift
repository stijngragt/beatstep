import Foundation

struct SpotifyImage: Codable, Hashable {
    let url: String
    let width: Int?
    let height: Int?
}

struct SpotifyUser: Codable {
    let id: String
    let displayName: String?
    let product: String?
    let images: [SpotifyImage]?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case product
        case images
    }

    // Dev Mode (Feb 2026+) requires Premium; product field no longer returned
    var isPremium: Bool {
        product == "premium" || product == nil
    }
}
