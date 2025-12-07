//
//  ContentView.swift
//  musicard
//
//  Created by Lex Leenders on 11/11/2025.
//

import AVFoundation
import SwiftUI
import UIKit

struct ContentView: View {
    private enum Constants {
        static let scanPrompt = "Scan een Hitster kaart om te beginnen"
        static let cameraDeniedPrompt = "Camera-toegang is nodig. Ga naar Instellingen > Privacy > Camera en sta musicard toe."
    }

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var isHandlingScan = false
    @State private var message: String = Constants.scanPrompt
    @State private var cameraAuthorized = false
    @State private var didCheckCamera = false

    @StateObject private var library = SongLibrary.shared
    @StateObject private var player = MusicPlayerManager.shared
    
    @State private var scanAnimation = false

    var body: some View {
        ZStack {
            if cameraAuthorized {
                QRScannerView(handleDetectedValue: handleScan)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Top section
                VStack(spacing: 12) {
                    Text(message)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.3), value: message)

                    if !cameraAuthorized {
                        Button(action: openSettings) {
                            Label("Open instellingen", systemImage: "gear")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(.blue.gradient)
                                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                                )
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal)

                Spacer()

                // Playback Controls at bottom
                if player.currentEntry != nil {
                    GlassEffectContainer {
                        VStack(spacing: 20) {
                            // Progress Slider
                            VStack(spacing: 8) {
                                Slider(value: Binding(
                                    get: { player.currentTime },
                                    set: { newValue in
                                        Task { await player.seek(to: newValue) }
                                    }
                                ), in: 0...player.duration)
                                    .tint(.white)
                                
                                HStack {
                                    Text(player.formattedCurrentTime)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Spacer()
                                    Text(player.formattedDuration)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, 24)

                            // Control Buttons
                            HStack(spacing: 40) {
                                Button(action: { Task { await player.previous() } }) {
                                    Image(systemName: "backward.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.glass)

                                Button(action: { Task { await player.togglePlayPause() } }) {
                                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.glass)
                                .scaleEffect(player.isPlaying ? 1.0 : 1.1)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: player.isPlaying)

                                AirPlayButton()
                                    .frame(width: 50, height: 50)
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.4), radius: 30, y: 15)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .scaleEffect(player.currentEntry != nil ? 1.0 : 0.9)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: player.currentEntry != nil)
                }
            }
        }
        .task {
            guard !didCheckCamera else { return }
            didCheckCamera = true
            
            // Check camera status without blocking UI
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .authorized {
                await MainActor.run {
                    cameraAuthorized = true
                    message = Constants.scanPrompt
                }
            } else if status == .notDetermined {
                await evaluateCameraAuthorization()
            } else {
                await MainActor.run {
                    cameraAuthorized = false
                    message = Constants.cameraDeniedPrompt
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .authorized && !cameraAuthorized {
                cameraAuthorized = true
                message = Constants.scanPrompt
            }
        }
    }

    private func handleScan(_ code: String) {
        guard !isHandlingScan else { return }
        isHandlingScan = true

        guard let entry = library.song(for: code) else {
            message = "Geen nummer gevonden"
            isHandlingScan = false
            return
        }

        message = "Nummer laden..."

        Task {
            await player.play(entry: entry)
            await MainActor.run {
                message = "Nu afspelen"
                isHandlingScan = false
            }
        }
    }

    private func resetScan() {
        message = cameraAuthorized ? Constants.scanPrompt : Constants.cameraDeniedPrompt
        isHandlingScan = false
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func evaluateCameraAuthorization() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            await MainActor.run {
                cameraAuthorized = true
                if message == Constants.cameraDeniedPrompt {
                    message = Constants.scanPrompt
                }
            }
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                cameraAuthorized = granted
                message = granted ? Constants.scanPrompt : Constants.cameraDeniedPrompt
            }
        case .denied, .restricted:
            await MainActor.run {
                cameraAuthorized = false
                message = Constants.cameraDeniedPrompt
            }
        @unknown default:
            await MainActor.run {
                cameraAuthorized = false
                message = Constants.cameraDeniedPrompt
            }
        }
    }
}

#Preview {
    ContentView()
}
