import Foundation

/// All prayer times tracked by the app.
enum PrayerName: String, CaseIterable, Codable, Identifiable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    /// Display name in Turkish.
    var turkishName: String {
        switch self {
        case .fajr:    return "İmsak"
        case .sunrise: return "Güneş"
        case .dhuhr:   return "Öğle"
        case .asr:     return "İkindi"
        case .maghrib: return "Akşam"
        case .isha:    return "Yatsı"
        }
    }

    /// Display name in English.
    var englishName: String {
        switch self {
        case .fajr:    return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr:   return "Dhuhr"
        case .asr:     return "Asr"
        case .maghrib: return "Maghrib"
        case .isha:    return "Isha"
        }
    }

    /// SF Symbol name for the prayer.
    var symbolName: String {
        switch self {
        case .fajr:    return "moon.haze.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr:   return "sun.max.fill"
        case .asr:     return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha:    return "moon.stars.fill"
        }
    }

    /// The five daily obligatory prayers (excludes sunrise).
    static var obligatory: [PrayerName] {
        [.fajr, .dhuhr, .asr, .maghrib, .isha]
    }
}
