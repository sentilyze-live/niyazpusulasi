import SwiftUI

/// A single row in the prayer times list.
struct PrayerTimeRow: View {
    let prayer: PrayerName
    let time: Date
    let isCurrent: Bool
    let isNext: Bool
    let formattedTime: String

    var body: some View {
        HStack {
            Image(systemName: prayer.symbolName) // Assuming prayer.symbolName is the correct property
                .font(.title2)
                .foregroundStyle(isCurrent ? Color.themeGold : (isNext ? Color.themeCyan : .gray.opacity(0.5)))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(prayer.localizedName)
                    .font(.subheadline)
                    .fontWeight(isCurrent || isNext ? .semibold : .medium)
                    .foregroundStyle(isCurrent || isNext ? .white : .gray)
                
                if isCurrent {
                    Text("Şu an")
                        .font(.caption2)
                        .foregroundStyle(Color.themeGold)
                } else if isNext {
                    Text("Sıradaki")
                        .font(.caption2)
                        .foregroundStyle(Color.themeCyan)
                }
            }

            Spacer()

            Text(formattedTime)
                .font(.headline)
                .foregroundStyle(isCurrent ? Color.themeGold : .white)
        }
        .padding()
        .background {
            if isCurrent {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.themeGold.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.themeGold.opacity(0.5), lineWidth: 1)
                    )
            } else if isNext {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.themeCyan.opacity(0.1))
            } else {
                Color.clear
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var isHighlighted: Bool {
        isCurrent || isNext
    }

    private var iconColor: Color {
        if isCurrent { return .green }
        if isNext { return .blue }
        if time < Date() { return .secondary }
        return .primary
    }

    private var textColor: Color {
        if isCurrent { return .primary }
        if isNext { return .primary }
        if time < Date() { return .secondary }
        return .primary
    }

    private var highlightBackground: Color {
        if isCurrent { return .green.opacity(0.08) }
        if isNext { return .blue.opacity(0.08) }
        return .clear
    }
}

#Preview {
    VStack(spacing: 0) {
        PrayerTimeRow(
            prayer: .fajr, time: Date().addingTimeInterval(-7200),
            isCurrent: false, isNext: false, formattedTime: "05:42"
        )
        PrayerTimeRow(
            prayer: .dhuhr, time: Date().addingTimeInterval(-3600),
            isCurrent: true, isNext: false, formattedTime: "12:30"
        )
        PrayerTimeRow(
            prayer: .asr, time: Date().addingTimeInterval(1800),
            isCurrent: false, isNext: true, formattedTime: "15:32"
        )
        PrayerTimeRow(
            prayer: .maghrib, time: Date().addingTimeInterval(3600),
            isCurrent: false, isNext: false, formattedTime: "18:05"
        )
        PrayerTimeRow(
            prayer: .isha, time: Date().addingTimeInterval(7200),
            isCurrent: false, isNext: false, formattedTime: "19:35"
        )
    }
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
}
