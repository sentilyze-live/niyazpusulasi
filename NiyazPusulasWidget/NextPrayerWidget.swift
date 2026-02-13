import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct NextPrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPrayerEntry {
        NextPrayerEntry(date: Date(), payload: placeholderPayload)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextPrayerEntry) -> Void) {
        let payload = loadWidgetPayload() ?? placeholderPayload
        completion(NextPrayerEntry(date: Date(), payload: payload))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextPrayerEntry>) -> Void) {
        let payload = loadWidgetPayload() ?? placeholderPayload

        // Create entries at each prayer transition point
        var entries: [NextPrayerEntry] = []
        let prayers = payload.todayPrayers

        let allTimes: [(String, Date)] = [
            ("İmsak", prayers.fajr),
            ("Güneş", prayers.sunrise),
            ("Öğle", prayers.dhuhr),
            ("İkindi", prayers.asr),
            ("Akşam", prayers.maghrib),
            ("Yatsı", prayers.isha),
        ]

        let now = Date()

        // Current entry
        entries.append(NextPrayerEntry(date: now, payload: payload))

        // Future prayer entries
        for (_, time) in allTimes where time > now {
            var updatedPayload = payload
            entries.append(NextPrayerEntry(date: time, payload: updatedPayload))
        }

        // Refresh after last prayer
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: prayers.isha) ?? prayers.isha
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Entry

struct NextPrayerEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload
}

// MARK: - Widget

struct NextPrayerWidget: Widget {
    let kind = "NextPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextPrayerProvider()) { entry in
            NextPrayerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sıradaki Namaz")
        .description("Bir sonraki namaz vaktini ve geri sayımı gösterir.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - Views

struct NextPrayerWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NextPrayerEntry

    var body: some View {
        switch family {
        case .systemSmall:
            systemSmallView
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryInline:
            accessoryInlineView
        default:
            systemSmallView
        }
    }

    // MARK: - System Small

    private var systemSmallView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
                Text(entry.payload.locationName)
                    .font(.system(size: 11))
                Spacer()
            }
            .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 4) {
                Text(entry.payload.nextPrayerName)
                    .font(.headline)

                Text(entry.payload.nextPrayerTime, style: .time)
                    .font(.system(.title2, design: .rounded).weight(.bold))

                // Live countdown
                Text(entry.payload.nextPrayerTime, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(4)
    }

    // MARK: - Lock Screen Widgets

    private var accessoryCircularView: some View {
        VStack(spacing: 2) {
            Text(entry.payload.nextPrayerName.prefix(3))
                .font(.system(size: 11, weight: .bold))
            Text(entry.payload.nextPrayerTime, style: .time)
                .font(.system(size: 12, design: .rounded))
        }
    }

    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.payload.nextPrayerName)
                .font(.headline)
            HStack {
                Text(entry.payload.nextPrayerTime, style: .time)
                    .font(.system(.body, design: .rounded))
                Spacer()
                Text(entry.payload.nextPrayerTime, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var accessoryInlineView: some View {
        Text("\(entry.payload.nextPrayerName) · \(entry.payload.nextPrayerTime, style: .time)")
    }
}

#Preview(as: .systemSmall) {
    NextPrayerWidget()
} timeline: {
    NextPrayerEntry(date: Date(), payload: placeholderPayload)
}
