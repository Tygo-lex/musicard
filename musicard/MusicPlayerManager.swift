import Combine
import Foundation
import MusicKit

@MainActor
final class MusicPlayerManager: ObservableObject {
    static let shared = MusicPlayerManager()

    @Published private(set) var currentEntry: SongEntry?
    @Published private(set) var statusMessage: String = ""
    @Published private(set) var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1

    private let player = ApplicationMusicPlayer.shared
    private var cache: [SongEntry: Song] = [:]
    private var playbackObserver: AnyCancellable?
    private var timeObserver: AnyCancellable?

    private init() {
        observePlaybackState()
        observePlaybackTime()
    }

    private func resolveSong(for entry: SongEntry) async throws -> Song {
        if let cached = cache[entry] {
            return cached
        }

        var searchRequest = MusicCatalogSearchRequest(
            term: "\(entry.artist) \(entry.title)",
            types: [Song.self]
        )
        searchRequest.limit = 1  // Only need the first result
        let response = try await searchRequest.response()

        guard let match = response.songs.first else {
            throw PlaybackError.songNotFound
        }

        cache[entry] = match
        return match
    }

    func play(entry: SongEntry) async {
        statusMessage = "Laden..."
        print("🎵 Starting playback for: \(entry.artist) - \(entry.title)")

        do {
            // Run authorization and token fetch in parallel
            async let authTask: Void = ensureAuthorization()
            async let tokenTask = MusicTokenManager.shared.ensureTokens()
            
            try await authTask
            _ = try await tokenTask
            
            let song = try await resolveSong(for: entry)
            print("  ↳ Found song: \(song.title)")
            try await queueAndPlay(song)
            currentEntry = entry
            statusMessage = ""
        } catch {
            print("❌ MusicPlayerManager error: \(error)")
            print("   Error type: \(type(of: error))")
            if let tokenError = error as? MusicTokenManager.TokenError {
                statusMessage = tokenError.localizedDescription
            } else if let playbackError = error as? PlaybackError {
                statusMessage = playbackError.localizedDescription
            } else if let localized = error as? LocalizedError, let description = localized.errorDescription {
                statusMessage = description
            } else {
                statusMessage = "Fout: \(error.localizedDescription)"
            }
        }
    }

    private func ensureAuthorization() async throws {
        switch MusicAuthorization.currentStatus {
        case .authorized:
            return
        case .notDetermined:
            let status = await MusicAuthorization.request()
            guard status == .authorized else {
                throw PlaybackError.authorizationDenied
            }
        default:
            throw PlaybackError.authorizationDenied
        }
    }

    private func queueAndPlay(_ song: Song) async throws {
        player.queue = ApplicationMusicPlayer.Queue(for: [song])
        try await player.prepareToPlay()
        
        // Start at the most important part (chorus ~40% into song)
        if let durationSeconds = song.duration {
            let startTime = durationSeconds * 0.4
            player.playbackTime = startTime
        }
        
        try await player.play()
    }

    private func observePlaybackState() {
        playbackObserver = player.state.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isPlaying = self?.player.state.playbackStatus == .playing
                }
            }
    }

    private func observePlaybackTime() {
        timeObserver = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.currentTime = self.player.playbackTime
                
                // Get duration from current entry if available
                if let entry = self.player.queue.currentEntry,
                   case .song(let song) = entry.item,
                   let songDuration = song.duration {
                    self.duration = songDuration
                }
            }
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func seek(to time: Double) async {
        player.playbackTime = time
    }

    func showAirPlayMenu() {
        // This will be handled via AVRoutePickerView in SwiftUI
    }

    func togglePlayPause() async {
        do {
            if player.state.playbackStatus == .playing {
                player.pause()
            } else {
                try await player.play()
            }
        } catch {
            print("❌ Toggle play/pause error: \(error)")
        }
    }

    func previous() async {
        do {
            try await player.skipToPreviousEntry()
        } catch {
            print("❌ Skip previous error: \(error)")
        }
    }
}

extension MusicPlayerManager {
    enum PlaybackError: LocalizedError {
        case authorizationDenied
        case songNotFound

        var errorDescription: String? {
            switch self {
            case .authorizationDenied:
                return "Apple Music-toegang is vereist."
            case .songNotFound:
                return "Geen catalogusresultaat gevonden voor dit nummer."
            }
        }
    }
}
