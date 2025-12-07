import Foundation

enum SongListType: String {
    case standard
    case xmas
    case movies
    case schlager
    case guiltyPleasure
}

struct SongEntry: Identifiable, Hashable {
    let id: Int
    let listType: SongListType
    let artist: String
    let title: String

    init(id: Int, listType: SongListType = .standard, rawLine: String) {
        self.id = id
        self.listType = listType

        let components = rawLine.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        if let first = components.first {
            artist = first.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            artist = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if components.count > 1 {
            title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            title = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    // Hashable implementation to distinguish between same IDs in different lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(listType)
    }
    
    static func == (lhs: SongEntry, rhs: SongEntry) -> Bool {
        return lhs.id == rhs.id && lhs.listType == rhs.listType
    }
}
