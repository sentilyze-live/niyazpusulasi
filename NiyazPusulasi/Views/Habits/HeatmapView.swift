import SwiftUI

/// Monthly heatmap grid showing habit completion intensity.
struct HeatmapView: View {
    let data: [Int: Double]  // day -> completion percentage (0.0-1.0)
    let currentDate: Date

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let calendar = Calendar.current
    private let dayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30
    }

    /// Day of week the month starts on (0 = Monday in our grid).
    private var startOffset: Int {
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.day = 1
        guard let firstDay = calendar.date(from: components) else { return 0 }
        // Convert to Monday-based (1=Sun,2=Mon,...,7=Sat) → (0=Mon,...,6=Sun)
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday + 5) % 7
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthName.capitalized)
                .font(.subheadline.weight(.medium))

            // Day labels
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                // Empty cells for offset
                ForEach(0..<startOffset, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .aspectRatio(1, contentMode: .fit)
                }

                // Day cells
                ForEach(1...daysInMonth, id: \.self) { day in
                    let percentage = data[day] ?? 0
                    let isToday = day == calendar.component(.day, from: currentDate)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(cellColor(for: percentage))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if isToday {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.primary, lineWidth: 1.5)
                            }
                        }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Az")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cellColor(for: level))
                        .frame(width: 12, height: 12)
                }
                Text("Çok")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func cellColor(for percentage: Double) -> Color {
        if percentage <= 0 {
            return Color(.tertiarySystemFill)
        }
        return .green.opacity(0.2 + percentage * 0.8)
    }
}

#Preview {
    HeatmapView(
        data: [1: 0.8, 2: 0.6, 3: 1.0, 5: 0.4, 7: 0.2, 10: 1.0, 12: 0.6, 13: 0.8],
        currentDate: Date()
    )
    .padding()
}
