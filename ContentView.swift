import SwiftUI

struct ContentView: View {
    @State private var isHandlingScan = false
    @State private var lastCode: String = ""
    @State private var message: String = "Scan a Hitster card to begin"

    @StateObject private var library = SongLibrary.shared
    @StateObject private var player = MusicPlayerManager.shared

    var body: some View {
        ZStack {
            QRScannerView(handleDetectedValue: handle(code:))
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(message)
                    .font(.headline)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let current = player.currentEntry {
                    Text("Now playing: \(current.artist) - \(current.title)")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !player.statusMessage.isEmpty {
                    Text(player.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: resetScan) {
                    Label("Scan Again", systemImage: "qrcode.viewfinder")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 24)
            }
            .padding()
        }
    }

    private func handle(code: String) {
        guard !isHandlingScan else { return }
        isHandlingScan = true
        lastCode = code

        guard let identifier = extractIdentifier(from: code) else {
            message = "Unsupported QR code"
            isHandlingScan = false
            return
        }

        guard let entry = library.song(for: identifier) else {
            message = "No song at number \(identifier)"
            isHandlingScan = false
            return
        }

    message = "Found #\(identifier): \(entry.artist) - \(entry.title)"

        Task {
            await player.play(entry: entry)
            await MainActor.run {
                isHandlingScan = false
            }
        }
    }

    private func resetScan() {
        message = "Scan a Hitster card to begin"
        isHandlingScan = false
        lastCode = ""
    }

    private func extractIdentifier(from code: String) -> Int? {
        if let range = code.range(of: "[0-9]+$", options: .regularExpression) {
            return Int(code[range])
        }

        let fallback = code.components(separatedBy: CharacterSet.decimalDigits.inverted).last { !$0.isEmpty }
        return fallback.flatMap(Int.init)
    }
}

#Preview {
    ContentView()
}
