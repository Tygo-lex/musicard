import Foundation

struct SongEntry: Identifiable {
    let id: Int
    let artist: String
    let title: String

    init(id: Int, rawLine: String) {
        self.id = id

        let components = rawLine.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        if let artistPart = components.first {
            artist = artistPart.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            artist = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if components.count > 1 {
            title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            title = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
