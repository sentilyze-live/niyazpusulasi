import Foundation

/// Data contract between the main app and WidgetKit extensions.
/// Serialized to App Group UserDefaults as JSON.
struct WidgetPayload: Codable {
    let updatedAt: Date
    let locationName: String
    let todayPrayers: PrayerTimeDay
    let nextPrayerName: String
    let nextPrayerTime: Date
    let isRamadan: Bool
    let todayImsak: Date?
    let todayIftar: Date?

    /// UserDefaults key for the payload.
    static let userDefaultsKey = "widget_payload"

    /// App Group suite name shared between app and widget.
    static let appGroupId = "group.com.niyazpusulasi.shared"
}
