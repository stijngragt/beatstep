import Foundation

struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let total: Int
    let limit: Int
    let offset: Int
    let next: String?

    var hasMore: Bool {
        next != nil
    }

    var nextOffset: Int {
        offset + limit
    }
}
