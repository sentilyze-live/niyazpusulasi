import SwiftUI

/// Semantic color extensions for consistent theming.
extension Color {
    // Prayer-related colors
    static let prayerFajr = Color(red: 0.15, green: 0.1, blue: 0.3)
    static let prayerSunrise = Color(red: 0.9, green: 0.55, blue: 0.25)
    static let prayerDhuhr = Color(red: 0.25, green: 0.55, blue: 0.85)
    static let prayerAsr = Color(red: 0.35, green: 0.65, blue: 0.55)
    static let prayerMaghrib = Color(red: 0.75, green: 0.35, blue: 0.25)
    static let prayerIsha = Color(red: 0.2, green: 0.12, blue: 0.3)

    // Ramadan colors
    static let ramadanImsak = Color.indigo
    static let ramadanIftar = Color.orange

    // Habit colors
    static let habitDone = Color.green
    static let habitStreak = Color.orange

    /// Returns the theme color for a given prayer.
    static func forPrayer(_ prayer: PrayerName) -> Color {
        switch prayer {
        case .fajr:    return .prayerFajr
        case .sunrise: return .prayerSunrise
        case .dhuhr:   return .prayerDhuhr
        case .asr:     return .prayerAsr
        case .maghrib: return .prayerMaghrib
        case .isha:    return .prayerIsha
        }
    }
}
