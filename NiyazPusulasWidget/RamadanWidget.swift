import WidgetKit
import SwiftUI

// MARK: - Provider

struct RamadanProvider: TimelineProvider {
    func placeholder(in context: Context) -> RamadanWidgetEntry {
        RamadanWidgetEntry(
            date: Date(),
            imsak: Date().addingTimeInterval(-3600),
            iftar: Date().addingTimeInterval(3600),
            locationName: "İstanbul",
            isRamadan: true,
            widgetTheme: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RamadanWidgetEntry) -> Void) {
        let entry = makeEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RamadanWidgetEntry>) -> Void) {
        let entry = makeEntry()

        // Create entries for key transition points
        var entries = [entry]

        if let imsak = entry.imsak, imsak > Date() {
            entries.append(RamadanWidgetEntry(
                date: imsak,
                imsak: imsak, iftar: entry.iftar,
                locationName: entry.locationName,
                isRamadan: entry.isRamadan,
                widgetTheme: entry.widgetTheme
            ))
        }

        if let iftar = entry.iftar, iftar > Date() {
            entries.append(RamadanWidgetEntry(
                date: iftar,
                imsak: entry.imsak, iftar: iftar,
                locationName: entry.locationName,
                isRamadan: entry.isRamadan,
                widgetTheme: entry.widgetTheme
            ))
        }

        // Refresh after iftar or in 6 hours
        let refreshDate = entry.iftar.map { Calendar.current.date(byAdding: .hour, value: 1, to: $0) ?? Date().addingTimeInterval(6 * 3600) }
            ?? Date().addingTimeInterval(6 * 3600)

        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    private func makeEntry() -> RamadanWidgetEntry {
        let payload = loadWidgetPayload()
        return RamadanWidgetEntry(
            date: Date(),
            imsak: payload?.todayImsak,
            iftar: payload?.todayIftar,
            locationName: payload?.locationName ?? "—",
            isRamadan: payload?.isRamadan ?? false,
            widgetTheme: payload?.widgetTheme
        )
    }
}

// MARK: - Entry

struct RamadanWidgetEntry: TimelineEntry {
    let date: Date
    let imsak: Date?
    let iftar: Date?
    let locationName: String
    let isRamadan: Bool
    let widgetTheme: WidgetTheme?
}

// MARK: - Widget

struct RamadanWidget: Widget {
    let kind = "RamadanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RamadanProvider()) { entry in
            RamadanWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Ramazan")
        .description("Bugünün imsak ve iftar vakitlerini gösterir.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - View

struct RamadanWidgetView: View {
    let entry: RamadanWidgetEntry

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        if entry.isRamadan, let imsak = entry.imsak, let iftar = entry.iftar {
            ramadanContent(imsak: imsak, iftar: iftar)
        } else {
            notRamadanContent
        }
    }

    private func ramadanContent(imsak: Date, iftar: Date) -> some View {
        ZStack {
            // Background gradient if theme exists
            if let theme = entry.widgetTheme {
                LinearGradient(
                    colors: theme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 10) {
                // Location
                HStack {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 10))
                    Text(entry.locationName)
                        .font(.system(size: 11))
                    Spacer()
                }
                .foregroundStyle(.secondary)

                Spacer()

                // Imsak
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("İmsak")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(timeFormatter.string(from: imsak))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.widgetTheme?.accentColor ?? .indigo)
                    }
                    Spacer()
                }

                // Iftar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("İftar")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(timeFormatter.string(from: iftar))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.widgetTheme?.accentColor ?? .orange)
                    }
                    Spacer()
                }

                // Countdown to nearest
                let now = Date()
                if now < imsak {
                    Text(imsak, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(entry.widgetTheme?.accentColor ?? .indigo)
                } else if now < iftar {
                    Text(iftar, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(entry.widgetTheme?.accentColor ?? .orange)
                }
            }
            .padding(4)
        }
    }

    private var notRamadanContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Ramazan\nDışında")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview(as: .systemSmall) {
    RamadanWidget()
} timeline: {
    RamadanWidgetEntry(
        date: Date(),
        imsak: Calendar.current.date(bySettingHour: 5, minute: 32, second: 0, of: Date()),
        iftar: Calendar.current.date(bySettingHour: 17, minute: 55, second: 0, of: Date()),
        locationName: "İstanbul",
        isRamadan: true,
        widgetTheme: nil
    )
}
