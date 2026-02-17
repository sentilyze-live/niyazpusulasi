import SwiftUI
import AVFoundation

struct NotificationSoundSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var showPaywall = false
    @StateObject private var audioPlayer = AudioPreviewPlayer()

    var allSounds: [AdhanSound] {
        AdhanSound.allCases
    }

    var body: some View {
        List(allSounds) { sound in
            HStack {
                // Flag emoji
                Text(sound.emoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(sound.displayName)
                        .font(.body)
                    Text(sound.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if sound.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                            Text("premium_only".localized)
                        }
                        .font(.caption2)
                        .foregroundColor(.orange)
                    }
                }

                Spacer()

                // Play/Stop button (only for non-default sounds)
                if let fileName = sound.fileName {
                    Button {
                        audioPlayer.play(fileName)
                    } label: {
                        Image(systemName: audioPlayer.isPlaying && audioPlayer.currentSound == fileName ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }

                // Checkmark for selected sound
                if settingsManager.settings.reminderSettings.adhanSound == sound {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.body.weight(.semibold))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectSound(sound)
            }
        }
        .navigationTitle("notification_sound_title".localized)
        .sheet(isPresented: $showPaywall) {
            PaywallView(trigger: .customNotificationSounds)
        }
    }

    private func selectSound(_ sound: AdhanSound) {
        guard !sound.isPremium || premiumManager.hasAccess(to: .customNotificationSounds) else {
            showPaywall = true
            return
        }

        settingsManager.settings.reminderSettings.adhanSound = sound
    }
}


@MainActor
final class AudioPreviewPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentSound: String?

    private var player: AVAudioPlayer?

    func play(_ soundName: String) {
        if isPlaying && currentSound == soundName {
            stop()
            return
        }

        stop()

        guard let url = Bundle.main.url(forResource: soundName, withExtension: "caf") else {
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
            currentSound = soundName
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    func stop() {
        player?.stop()
        isPlaying = false
        currentSound = nil
    }
}

extension AudioPreviewPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentSound = nil
        }
    }
}
