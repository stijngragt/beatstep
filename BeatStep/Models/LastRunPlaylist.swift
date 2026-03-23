import Foundation

enum LastRunPlaylist {
    private static let nameKey = "beatstep_last_run_playlist_name"
    private static let idKey = "beatstep_last_run_playlist_id"
    private static let imageURLKey = "beatstep_last_run_playlist_image"

    static var name: String? {
        get { UserDefaults.standard.string(forKey: nameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    static var id: String? {
        get { UserDefaults.standard.string(forKey: idKey) }
        set { UserDefaults.standard.set(newValue, forKey: idKey) }
    }

    static var imageURL: String? {
        get { UserDefaults.standard.string(forKey: imageURLKey) }
        set { UserDefaults.standard.set(newValue, forKey: imageURLKey) }
    }
}
