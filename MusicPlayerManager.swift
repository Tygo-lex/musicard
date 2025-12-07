import Foundation
import MusicKit

@MainActor
final class MusicPlayerManager: ObservableObject {
    static let shared = MusicPlayerManager()

    @Published private(set) var currentEntry: SongEntry?
    @Published private(set) var statusMessage: String = ""

    private let player = ApplicationMusicPlayer.shared

    private init() {}

    func play(entry: SongEntry) async {
        do {
            statusMessage = "Preparing Apple Music playback..."
            try await ensureAuthorization()
            try await loadAndPlay(entry: entry)
            currentEntry = entry
            statusMessage = "Playing \(entry.title)"
        } catch {
            statusMessage = "Playback failed: \(error.localizedDescription)"
        }
    }

    private func ensureAuthorization() async throws {
        let status = MusicAuthorization.currentStatus
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let newStatus = await MusicAuthorization.request()
            guard newStatus == .authorized else {
                throw PlaybackError.authorizationDenied
            }
        default:
            throw PlaybackError.authorizationDenied
        }
    }

    private func loadAndPlay(entry: SongEntry) async throws {
        let request = MusicCatalogSearchRequest(term: "\(entry.artist) \(entry.title)", categories: [.songs])
        request.limit = 1
        let response = try await request.response()

        guard let song = response.songs.first else {
            throw PlaybackError.songNotFound
        }

        player.queue = ApplicationMusicPlayer.Queue(for: [song])
        try await player.play()
    }
}

extension MusicPlayerManager {
    enum PlaybackError: LocalizedError {
        case authorizationDenied
        case songNotFound

        var errorDescription: String? {
            switch self {
            case .authorizationDenied:
                return "Apple Music access is required."
            case .songNotFound:
                return "Couldn't find this track in Apple Music."
            }
        }
    }
}
