import WidgetKit
import SwiftUI

/// Bundle containing all Niyaz Pusulasi widgets.
@main
struct NiyazPusulasWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextPrayerWidget()
        TodayTimesWidget()
        RamadanWidget()
    }
}

// MARK: - Shared Widget Helpers

/// Reads the widget payload from App Group UserDefaults.
func loadWidgetPayload() -> WidgetPayload? {
    guard let defaults = UserDefaults(suiteName: WidgetPayload.appGroupId),
          let data = defaults.data(forKey: WidgetPayload.userDefaultsKey) else {
        return nil
    }
    return try? JSONDecoder().decode(WidgetPayload.self, from: data)
}

/// Placeholder payload for widget previews.
let placeholderPayload = WidgetPayload(
    updatedAt: Date(),
    locationName: "İstanbul",
    todayPrayers: PrayerTimeDay(
        id: UUID(),
        date: Date(),
        fajr: Calendar.current.date(bySettingHour: 5, minute: 42, second: 0, of: Date())!,
        sunrise: Calendar.current.date(bySettingHour: 7, minute: 10, second: 0, of: Date())!,
        dhuhr: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!,
        asr: Calendar.current.date(bySettingHour: 15, minute: 32, second: 0, of: Date())!,
        maghrib: Calendar.current.date(bySettingHour: 17, minute: 55, second: 0, of: Date())!,
        isha: Calendar.current.date(bySettingHour: 19, minute: 22, second: 0, of: Date())!,
        imsak: Calendar.current.date(bySettingHour: 5, minute: 32, second: 0, of: Date())!,
        source: .cached
    ),
    nextPrayerName: "İkindi",
    nextPrayerTime: Date().addingTimeInterval(3600),
    isRamadan: false,
    todayImsak: nil,
    todayIftar: nil,
    widgetTheme: nil
)
