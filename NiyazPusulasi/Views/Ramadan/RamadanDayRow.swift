import SwiftUI

/// A single row in the Ramadan Imsakiye calendar.
struct RamadanDayRow: View {
    let day: RamadanDay
    let isToday: Bool
    let formatTime: (Date) -> String

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Day number badge
            Text("\(day.dayNumber)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isToday ? .white : .secondary)
                .frame(width: 32, height: 32)
                .background(isToday ? Color.orange : Color(.tertiarySystemFill))
                .clipShape(Circle())

            // Date info
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: day.date))
                    .font(.subheadline.weight(.medium))
                Text(dayFormatter.string(from: day.date).capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70, alignment: .leading)

            Spacer()

            // Imsak
            VStack(spacing: 2) {
                Text("İmsak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatTime(day.imsak))
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(.indigo)
            }

            Spacer()

            // Iftar
            VStack(spacing: 2) {
                Text("İftar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatTime(day.iftar))
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isToday ? Color.orange.opacity(0.08) : Color.clear)
    }
}

#Preview {
    VStack(spacing: 0) {
        RamadanDayRow(
            day: RamadanDay(
                id: UUID(),
                date: Date(),
                hijriDate: "1 Ramazan 1447",
                dayNumber: 1,
                imsak: Date().addingTimeInterval(-7200),
                iftar: Date().addingTimeInterval(3600)
            ),
            isToday: true,
            formatTime: { date in
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                return f.string(from: date)
            }
        )
        RamadanDayRow(
            day: RamadanDay(
                id: UUID(),
                date: Date().addingTimeInterval(86400),
                hijriDate: "2 Ramazan 1447",
                dayNumber: 2,
                imsak: Date().addingTimeInterval(86400 - 7200),
                iftar: Date().addingTimeInterval(86400 + 3600)
            ),
            isToday: false,
            formatTime: { date in
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                return f.string(from: date)
            }
        )
    }
}
