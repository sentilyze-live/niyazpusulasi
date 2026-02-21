import SwiftUI

/// Semantic color extensions for consistent theming.
extension Color {
    // MARK: - New Theme Colors
    static let themeDarkBg = Color(red: 11/255, green: 17/255, blue: 32/255) // #0b1120
    static let themeGold = Color(red: 212/255, green: 175/255, blue: 55/255) // #D4AF37
    static let themeCyan = Color(red: 6/255, green: 182/255, blue: 212/255) // #06b6d4
    
    // Prayer-related colors (Updated to new theme)
    static let prayerFajr = Color.themeCyan.opacity(0.8)
    static let prayerSunrise = Color.themeGold.opacity(0.8)
    static let prayerDhuhr = Color.yellow.opacity(0.8)
    static let prayerAsr = Color.themeGold
    static let prayerMaghrib = Color.themeCyan
    static let prayerIsha = Color.gray.opacity(0.8)

    // Ramadan colors
    static let ramadanImsak = Color.themeCyan
    static let ramadanIftar = Color.themeGold

    // Habit colors
    static let habitDone = Color.themeGold
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
