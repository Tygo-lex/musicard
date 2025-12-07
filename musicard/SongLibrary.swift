import Combine
import Foundation

final class SongLibrary: ObservableObject {
    static let shared = SongLibrary()

    @Published private(set) var entries: [SongEntry] = [] // Keep for compatibility if needed, or remove
    private var lists: [SongListType: [SongEntry]] = [:]

    private init() {
        loadSongs()
    }

    private func loadSongs() {
        lists[.standard] = loadList(filename: "list", type: .standard)
        lists[.xmas] = loadList(filename: "xmas", type: .xmas)
        lists[.movies] = loadList(filename: "movi", type: .movies)
        lists[.schlager] = loadList(filename: "schl", type: .schlager)
        lists[.guiltyPleasure] = loadList(filename: "gupl", type: .guiltyPleasure)
        
        // Populate default entries for backward compatibility or debugging
        entries = lists[.standard] ?? []
    }

    private func loadList(filename: String, type: SongListType) -> [SongEntry] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt") else {
            print("Missing \(filename).txt in bundle")
            return []
        }

        do {
            let raw = try String(contentsOf: url, encoding: .utf8)
            let lines = raw.components(separatedBy: .newlines).filter { !$0.isEmpty }
            return lines.enumerated().map { index, line in
                SongEntry(id: index + 1, listType: type, rawLine: line)
            }
        } catch {
            print("Failed to load \(filename).txt: \(error.localizedDescription)")
            return []
        }
    }

    func song(for code: String) -> SongEntry? {
        // Determine list type based on URL pattern
        let type: SongListType
        if code.contains("aaaa0037") {
            type = .xmas
        } else if code.contains("aaaa0027") {
            type = .movies
        } else if code.contains("aaaa0007") {
            type = .schlager
        } else if code.contains("aaaa0006") {
            type = .guiltyPleasure
        } else {
            type = .standard
        }
        
        guard let id = extractIdentifier(from: code) else { return nil }
        
        let list = lists[type] ?? []
        guard id > 0, id <= list.count else { return nil }
        
        return list[id - 1]
    }
    
    // Helper to extract ID from the code string
    private func extractIdentifier(from code: String) -> Int? {
        if let range = code.range(of: "[0-9]+$", options: .regularExpression) {
            return Int(code[range])
        }

        let fallback = code.components(separatedBy: CharacterSet.decimalDigits.inverted).last { !$0.isEmpty }
        return fallback.flatMap(Int.init)
    }
    
    // Deprecated: Old method for backward compatibility if needed, but better to switch to code-based
    func song(for identifier: Int) -> SongEntry? {
        let list = lists[.standard] ?? []
        guard identifier > 0, identifier <= list.count else { return nil }
        return list[identifier - 1]
    }
}
