import Foundation

/// User preferences for prayer and Ramadan notifications.
struct ReminderSettings: Codable, Equatable {

    /// Per-prayer notification toggle. Key = PrayerName.rawValue
    var prayerEnabled: [String: Bool]

    /// Per-prayer offset in minutes before the prayer time.
    /// Negative = before, 0 = at time. Key = PrayerName.rawValue
    var prayerOffsetMinutes: [String: Int]

    /// Imsak (Suhoor) reminder toggle.
    var imsakEnabled: Bool

    /// Minutes before Imsak to send reminder (positive value, applied as negative offset).
    var imsakOffsetMinutes: Int

    /// Iftar reminder toggle.
    var iftarEnabled: Bool

    /// Minutes before Iftar to send reminder.
    var iftarOffsetMinutes: Int

    /// Whether to show full-screen alarm overlay when app is open.
    var alarmModeEnabled: Bool

    /// Selected adhan sound for notifications.
    var adhanSound: AdhanSound = .default

    /// Default settings: all obligatory prayers enabled at prayer time, Ramadan reminders at 15 min.
    static let `default` = ReminderSettings(
        prayerEnabled: Dictionary(
            uniqueKeysWithValues: PrayerName.obligatory.map { ($0.rawValue, true) }
        ),
        prayerOffsetMinutes: Dictionary(
            uniqueKeysWithValues: PrayerName.obligatory.map { ($0.rawValue, 0) }
        ),
        imsakEnabled: true,
        imsakOffsetMinutes: 15,
        iftarEnabled: true,
        iftarOffsetMinutes: 15,
        alarmModeEnabled: false,
        adhanSound: .default
    )

    /// Count of enabled notification slots per day for budget calculation.
    var enabledSlotsPerDay: Int {
        let prayerSlots = prayerEnabled.values.filter { $0 }.count
        let imsakSlot = imsakEnabled ? 1 : 0
        let iftarSlot = iftarEnabled ? 1 : 0
        return prayerSlots + imsakSlot + iftarSlot
    }

    /// Maximum days of notification coverage given the 60-slot budget.
    var coverageDays: Int {
        let slots = enabledSlotsPerDay
        guard slots > 0 else { return 0 }
        return 60 / slots
    }
}
