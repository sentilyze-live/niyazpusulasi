import SwiftUI

/// Displays the next prayer name and a live countdown timer.
struct CountdownView: View {
    let prayerName: PrayerName
    let prayerTime: Date

    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timeRemaining: TimeInterval {
        max(0, prayerTime.timeIntervalSince(now))
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Sıradaki Vakit")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(Color.themeCyan)
                .textCase(.uppercase)

            Text(prayerName.localizedName)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .glowingText(color: Color.themeGold, intensity: 15)

            // Animated Countdown Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)

                Circle()
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .padding(8)

                VStack(spacing: 4) {
                    Text(timeRemainingString(from: timeRemaining))
                        .font(.system(size: 44, weight: .light, design: .default))
                        .monospacedDigit()
                        .tracking(-1)
                        .foregroundStyle(.white)

                    Text("Kaldı")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .tracking(2)
                        .foregroundStyle(.gray)
                        .textCase(.uppercase)
                }
            }
            .frame(width: 200, height: 200)
            .padding(.vertical, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassPanel(cornerRadius: 32, opacity: 0.6)
        .onReceive(timer) { tick in
            now = tick
        }
    }

    // MARK: - Helpers

    private func timeRemainingString(from interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func gradientColors(for prayer: PrayerName) -> [Color] {
        switch prayer {
        case .fajr:    return [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.2, green: 0.15, blue: 0.4)]
        case .sunrise: return [Color(red: 0.9, green: 0.5, blue: 0.2), Color(red: 0.95, green: 0.6, blue: 0.3)]
        case .dhuhr:   return [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.3, green: 0.6, blue: 0.9)]
        case .asr:     return [Color(red: 0.3, green: 0.6, blue: 0.5), Color(red: 0.4, green: 0.7, blue: 0.6)]
        case .maghrib: return [Color(red: 0.7, green: 0.3, blue: 0.2), Color(red: 0.8, green: 0.4, blue: 0.3)]
        case .isha:    return [Color(red: 0.15, green: 0.1, blue: 0.25), Color(red: 0.25, green: 0.15, blue: 0.35)]
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CountdownView(
            prayerName: .asr,
            prayerTime: Date().addingTimeInterval(3600)
        )
        CountdownView(
            prayerName: .fajr,
            prayerTime: Date().addingTimeInterval(7200)
        )
    }
    .padding()
    .appBackground()
}
