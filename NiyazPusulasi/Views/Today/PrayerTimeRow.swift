import SwiftUI

/// A single row in the prayer times list.
struct PrayerTimeRow: View {
    let prayer: PrayerName
    let time: Date
    let isCurrent: Bool
    let isNext: Bool
    let formattedTime: String

    var body: some View {
        HStack(spacing: 12) {
            // Prayer icon
            Image(systemName: prayer.symbolName)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            // Prayer name
            Text(prayer.turkishName)
                .font(.body)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundStyle(textColor)

            Spacer()

            // Time
            Text(formattedTime)
                .font(.system(.body, design: .monospaced))
                .fontWeight(isHighlighted ? .semibold : .regular)
                .foregroundStyle(textColor)

            // Status indicator
            if isCurrent {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.green)
            } else if isNext {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHighlighted ? highlightBackground : Color.clear)
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
