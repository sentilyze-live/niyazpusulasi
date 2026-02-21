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
        HStack {
            // Day badge
            VStack(spacing: 2) {
                Text("\(day.dayNumber) Ram")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isToday ? .white : .gray)
                Text(dateFormatter.string(from: day.date))
                    .font(.system(size: 10))
                    .foregroundStyle(isToday ? Color.themeCyan : .gray.opacity(0.7))
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            // Imsak time
            Text(formatTime(day.imsak))
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(isToday ? .bold : .medium)
                .foregroundStyle(isToday ? .white : .gray)
                .frame(width: 60)
            
            Spacer()
            
            // Iftar time
            Text(formatTime(day.iftar))
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(isToday ? .bold : .medium)
                .foregroundStyle(isToday ? Color.themeGold : .gray)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            if isToday {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeCyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.themeCyan.opacity(0.5), lineWidth: 1)
                    )
            } else {
                Color.clear
            }
        }
        .opacity(day.date < Calendar.current.startOfDay(for: Date()) ? 0.4 : 1.0)
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
