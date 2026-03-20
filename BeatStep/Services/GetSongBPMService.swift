import Foundation

final class GetSongBPMService {
    static let shared = GetSongBPMService()

    private let baseURL = "https://api.getsongbpm.com"
    // Replace with actual API key before testing with live API
    private static let apiKey = "GETSONGBPM_API_KEY"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Title Sanitization

    /// Strips common Spotify suffixes that interfere with GetSongBPM search matching
    func sanitizeTitle(_ title: String) -> String {
        var cleaned = title
        // Remove patterns like " - Remastered", " - Remastered 2024", " - Live", " - Live Version"
        let dashPatterns = [
            #"\s*-\s*Remastered(\s+\d{4})?"#,
            #"\s*-\s*Live(\s+Version)?"#,
            #"\s*-\s*Radio\s+Edit"#,
            #"\s*-\s*Bonus\s+Track"#,
            #"\s*-\s*Deluxe(\s+Edition)?"#,
            #"\s*-\s*Acoustic(\s+Version)?"#,
        ]
        // Remove patterns like " (feat. Artist)", " [Deluxe]", " [Deluxe Edition]"
        let bracketPatterns = [
            #"\s*\(feat\.\s*[^)]+\)"#,
            #"\s*\[feat\.\s*[^\]]+\]"#,
            #"\s*\[Deluxe(\s+Edition)?\]"#,
            #"\s*\(Deluxe(\s+Edition)?\)"#,
            #"\s*\[Bonus\s+Track\]"#,
        ]

        for pattern in dashPatterns + bracketPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    range: NSRange(cleaned.startIndex..., in: cleaned),
                    withTemplate: ""
                )
            }
        }

        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - BPM Lookup (Two-Step)

    /// Performs two-step BPM lookup: search for song, then fetch song details for tempo
    func fetchBPM(title: String, artist: String) async throws -> Int? {
        let cleanTitle = sanitizeTitle(title)
        let query = "\(cleanTitle) \(artist)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchURL = URL(string: "\(baseURL)/search/?api_key=\(Self.apiKey)&type=song&lookup=\(encodedQuery)") else {
            return nil
        }

        // Step 1: Search
        let (searchData, _) = try await session.data(from: searchURL)
        let searchResponse = try JSONDecoder().decode(GetSongBPMSearchResponse.self, from: searchData)

        guard let firstResult = searchResponse.search.first else { return nil }

        // Rate limit delay (300ms between API calls)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Step 2: Get song details
        guard let songURL = URL(string: "\(baseURL)/song/?api_key=\(Self.apiKey)&id=\(firstResult.id)") else {
            return nil
        }

        let (songData, _) = try await session.data(from: songURL)
        let songResponse = try JSONDecoder().decode(GetSongBPMSongResponse.self, from: songData)

        guard let tempoString = songResponse.song.tempo,
              !tempoString.isEmpty,
              let tempo = Int(tempoString) else {
            return nil
        }

        return tempo
    }

    // MARK: - Songs by BPM (Discovery)

    /// Fetches songs at a specific BPM from GetSongBPM tempo endpoint
    func fetchSongsByBPM(_ bpm: Int) async throws -> [GetSongBPMSong] {
        guard let url = URL(string: "\(baseURL)/tempo/?api_key=\(Self.apiKey)&bpm=\(bpm)") else {
            return []
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(GetSongBPMTempoResponse.self, from: data)
        return response.tempo
    }
}
