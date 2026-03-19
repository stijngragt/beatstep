import Foundation

enum MockSpotifyResponses {

    // MARK: - User Profiles

    static let premiumUser = """
    {
        "id": "test_user_123",
        "display_name": "Test Runner",
        "product": "premium",
        "images": [
            {
                "url": "https://example.com/avatar.jpg",
                "width": 300,
                "height": 300
            }
        ]
    }
    """

    static let freeUser = """
    {
        "id": "free_user_456",
        "display_name": "Free User",
        "product": "free",
        "images": []
    }
    """

    // MARK: - Playlists

    static let playlistList = """
    {
        "items": [
            {
                "id": "playlist_1",
                "name": "Running Hits",
                "description": "High energy running tracks",
                "images": [
                    {
                        "url": "https://example.com/playlist1.jpg",
                        "width": 300,
                        "height": 300
                    }
                ],
                "tracks": { "total": 50 },
                "owner": { "display_name": "Test Runner" }
            },
            {
                "id": "playlist_2",
                "name": "Chill Jog",
                "description": "Easy pace playlist",
                "images": [],
                "tracks": { "total": 25 },
                "owner": { "display_name": "Test Runner" }
            },
            {
                "id": "playlist_3",
                "name": "Sprint Interval",
                "description": null,
                "images": [],
                "tracks": { "total": 15 },
                "owner": { "display_name": "Other User" }
            }
        ],
        "total": 3,
        "limit": 50,
        "offset": 0,
        "next": null
    }
    """

    // MARK: - Tracks

    static let playlistTracks = """
    {
        "items": [
            {
                "track": {
                    "id": "track_1",
                    "name": "Run Boy Run",
                    "uri": "spotify:track:track_1",
                    "duration_ms": 232000,
                    "artists": [{ "name": "Woodkid" }],
                    "album": {
                        "name": "The Golden Age",
                        "images": [{ "url": "https://example.com/album1.jpg", "width": 300, "height": 300 }]
                    }
                }
            },
            {
                "track": {
                    "id": "track_2",
                    "name": "Stronger",
                    "uri": "spotify:track:track_2",
                    "duration_ms": 312000,
                    "artists": [{ "name": "Kanye West" }],
                    "album": {
                        "name": "Graduation",
                        "images": [{ "url": "https://example.com/album2.jpg", "width": 300, "height": 300 }]
                    }
                }
            },
            {
                "track": {
                    "id": "track_3",
                    "name": "Till I Collapse",
                    "uri": "spotify:track:track_3",
                    "duration_ms": 298000,
                    "artists": [{ "name": "Eminem" }, { "name": "Nate Dogg" }],
                    "album": {
                        "name": "The Eminem Show",
                        "images": [{ "url": "https://example.com/album3.jpg", "width": 300, "height": 300 }]
                    }
                }
            },
            {
                "track": {
                    "id": "track_4",
                    "name": "Eye of the Tiger",
                    "uri": "spotify:track:track_4",
                    "duration_ms": 246000,
                    "artists": [{ "name": "Survivor" }],
                    "album": {
                        "name": "Eye of the Tiger",
                        "images": []
                    }
                }
            }
        ],
        "total": 4,
        "limit": 100,
        "offset": 0,
        "next": null
    }
    """

    // MARK: - Errors

    static let unauthorizedError = """
    {
        "error": {
            "status": 401,
            "message": "The access token expired"
        }
    }
    """
}
