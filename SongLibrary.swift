import Foundation

final class SongLibrary: ObservableObject {
    static let shared = SongLibrary()

    @Published private(set) var entries: [SongEntry] = []

    private init() {
        loadSongs()
    }

    private func loadSongs() {
        guard let url = Bundle.main.url(forResource: "list", withExtension: "txt") else {
            assertionFailure("Missing list.txt in bundle")
            entries = []
            return
        }

        do {
            let rawContent = try String(contentsOf: url)
            let lines = rawContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            entries = lines.enumerated().map { index, line in
                SongEntry(id: index + 1, rawLine: line)
            }
        } catch {
            assertionFailure("Failed to load list.txt: \(error.localizedDescription)")
            entries = []
        }
    }

    func song(for identifier: Int) -> SongEntry? {
        guard identifier > 0, identifier <= entries.count else {
            return nil
        }
        return entries[identifier - 1]
    }
}
