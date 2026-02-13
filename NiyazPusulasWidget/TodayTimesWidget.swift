import WidgetKit
import SwiftUI

// MARK: - Provider

struct TodayTimesProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayTimesEntry {
        TodayTimesEntry(date: Date(), payload: placeholderPayload)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayTimesEntry) -> Void) {
        let payload = loadWidgetPayload() ?? placeholderPayload
        completion(TodayTimesEntry(date: Date(), payload: payload))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayTimesEntry>) -> Void) {
        let payload = loadWidgetPayload() ?? placeholderPayload
        let entry = TodayTimesEntry(date: Date(), payload: payload)

        // Refresh after isha + 1 hour (new day's data)
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: payload.todayPrayers.isha)
            ?? Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Entry

struct TodayTimesEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload
}

// MARK: - Widget

struct TodayTimesWidget: Widget {
    let kind = "TodayTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayTimesProvider()) { entry in
            TodayTimesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Günün Vakitleri")
        .description("Bugünün tüm namaz vakitlerini gösterir.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - View

struct TodayTimesWidgetView: View {
    let entry: TodayTimesEntry

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var prayers: [(String, String, Date)] {
        let p = entry.payload.todayPrayers
        return [
            ("İmsak", "moon.haze.fill", p.fajr),
            ("Güneş", "sunrise.fill", p.sunrise),
            ("Öğle", "sun.max.fill", p.dhuhr),
            ("İkindi", "sun.haze.fill", p.asr),
            ("Akşam", "sunset.fill", p.maghrib),
            ("Yatsı", "moon.stars.fill", p.isha),
        ]
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text(entry.payload.locationName)
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)

                Spacer()

                Text(entry.date, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            // Prayer times grid (2 rows × 3 columns)
            let rows = [prayers.prefix(3), prayers.suffix(3)]

            ForEach(0..<2, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(Array(rows[rowIndex].enumerated()), id: \.offset) { _, prayer in
                        let isNext = prayer.0 == entry.payload.nextPrayerName
                        VStack(spacing: 4) {
                            Image(systemName: prayer.1)
                                .font(.system(size: 14))
                                .foregroundStyle(isNext ? .blue : .secondary)

                            Text(prayer.0)
                                .font(.system(size: 10, weight: isNext ? .bold : .regular))
                                .foregroundStyle(isNext ? .primary : .secondary)

                            Text(timeFormatter.string(from: prayer.2))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(isNext ? .blue : .primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(4)
    }
}

#Preview(as: .systemMedium) {
    TodayTimesWidget()
} timeline: {
    TodayTimesEntry(date: Date(), payload: placeholderPayload)
}
