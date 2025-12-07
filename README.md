# Musicard 🎵

A beautiful, modern SwiftUI companion app for the **Hitster** music card game. Musicard scans the QR codes on your cards and instantly plays the corresponding song via Apple Music, designed with a stunning "Liquid Glass" aesthetic.

## ✨ Features

- **🎨 Liquid Glass UI**: A timeless, transparent interface that feels native to iOS.
- **🚀 Instant Chorus**: Smart playback logic starts songs at **40% duration**, so you hear the recognizable part immediately.
- **📷 Fast Scanning**: Built-in QR code scanner optimized for Hitster cards.
- **💿 Multi-Edition Support**: Automatically detects and switches between different game editions:
  - Original / Standard
  - Christmas Party (`aaaa0037`)
  - Movies (`aaaa0027`)
  - Schlager (`aaaa0007`)
  - Guilty Pleasures (`aaaa0006`)
- **📡 AirPlay Integration**: Stream the music directly to your Sonos or HomePod.
- **⚡️ High Performance**: Optimized startup and authentication for a snappy experience.

## 🛠 Requirements

- iOS 16.0+
- Xcode 14.0+
- **Apple Music Subscription** (Required for playback)
- Apple Music Developer Token

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/musicard.git
cd musicard
```

### 2. Configure API Keys
To protect your API keys, the `Info.plist` containing the Developer Token is ignored by git.

1. Locate `musicard/Info.example.plist`.
2. Duplicate it and rename the copy to `Info.plist`.
3. Open `Info.plist` and replace `YOUR_DEVELOPER_TOKEN_HERE` with your actual Apple Music Developer Token.

> **Note:** You can generate a developer token in the Apple Developer Portal.

### 3. Build and Run
Open `musicard.xcodeproj` in Xcode and run the app on your physical device (Camera access is required for scanning).

## 📂 Project Structure

- **ContentView.swift**: Main UI with Liquid Glass styling and scanner integration.
- **MusicPlayerManager.swift**: Handles Apple Music playback, authentication, and state.
- **SongLibrary.swift**: Manages the song databases and edition logic.
- **Resources/**: Contains the text files mapping IDs to songs (`list.txt`, `xmas.txt`, etc.).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Disclaimer: This is an unofficial companion app. Hitster is a trademark of its respective owners.*
