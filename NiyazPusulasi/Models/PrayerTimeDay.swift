import Foundation

/// All prayer times for a single day.
struct PrayerTimeDay: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date          // Start of day (midnight) in local timezone
    let fajr: Date
    let sunrise: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    let imsak: Date         // Fajr - 10 minutes (Turkish convention)

    /// Source of this calculation.
    enum Source: String, Codable {
        case adhanLocal
        case aladhanAPI
        case cached
    }
    let source: Source

    /// Get the Date for a specific prayer.
    func time(for prayer: PrayerName) -> Date {
        switch prayer {
        case .fajr:    return fajr
        case .sunrise: return sunrise
        case .dhuhr:   return dhuhr
        case .asr:     return asr
        case .maghrib: return maghrib
        case .isha:    return isha
        }
    }

    /// All prayer times as an ordered array of (name, time) pairs.
    var allPrayers: [(PrayerName, Date)] {
        PrayerName.allCases.map { ($0, time(for: $0)) }
    }

    /// Only the five obligatory prayers.
    var obligatoryPrayers: [(PrayerName, Date)] {
        PrayerName.obligatory.map { ($0, time(for: $0)) }
    }
}
