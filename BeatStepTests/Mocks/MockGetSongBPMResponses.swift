import Foundation

enum MockGetSongBPMResponses {

    // MARK: - Search Response

    static let searchSuccess = """
    {
        "search": [
            {
                "id": "abc123",
                "title": "Run Boy Run",
                "artist": {
                    "id": "artist_1",
                    "name": "Woodkid"
                }
            },
            {
                "id": "def456",
                "title": "Run Boy Run (Remix)",
                "artist": {
                    "id": "artist_2",
                    "name": "Woodkid"
                }
            }
        ]
    }
    """.data(using: .utf8)!

    static let searchEmpty = """
    {
        "search": []
    }
    """.data(using: .utf8)!

    // MARK: - Song Response

    static let songSuccess = """
    {
        "song": {
            "id": "abc123",
            "title": "Run Boy Run",
            "tempo": "172",
            "artist": {
                "id": "artist_1",
                "name": "Woodkid"
            },
            "album": {
                "title": "The Golden Age"
            }
        }
    }
    """.data(using: .utf8)!

    static let songNoTempo = """
    {
        "song": {
            "id": "xyz789",
            "title": "Ambient Soundscape",
            "tempo": "",
            "artist": {
                "id": "artist_3",
                "name": "Unknown"
            },
            "album": {
                "title": "Ambient Collection"
            }
        }
    }
    """.data(using: .utf8)!

    // MARK: - Tempo Response

    static let tempoSuccess = """
    {
        "tempo": [
            {
                "id": "song_1",
                "title": "Fast Track",
                "tempo": "170",
                "artist": {
                    "id": "a1",
                    "name": "Artist One"
                },
                "album": {
                    "title": "Album One"
                }
            },
            {
                "id": "song_2",
                "title": "Quick Beat",
                "tempo": "170",
                "artist": {
                    "id": "a2",
                    "name": "Artist Two"
                },
                "album": {
                    "title": "Album Two"
                }
            },
            {
                "id": "song_3",
                "title": "Speed Demon",
                "tempo": "170",
                "artist": {
                    "id": "a3",
                    "name": "Artist Three"
                },
                "album": {
                    "title": "Album Three"
                }
            }
        ]
    }
    """.data(using: .utf8)!
}
