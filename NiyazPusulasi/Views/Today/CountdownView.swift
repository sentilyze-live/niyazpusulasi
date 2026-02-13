import SwiftUI

/// Displays the next prayer name and a live countdown timer.
struct CountdownView: View {
    let prayerName: PrayerName
    let prayerTime: Date

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: prayerName.symbolName)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Sıradaki: \(prayerName.turkishName)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Live countdown — SwiftUI handles the animation
            Text(prayerTime, style: .relative)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            // Prayer time
            Text(prayerTime, style: .time)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(
            LinearGradient(
                colors: gradientColors(for: prayerName),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: gradientColors(for: prayerName).first?.opacity(0.3) ?? .clear, radius: 12, y: 4)
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
}
