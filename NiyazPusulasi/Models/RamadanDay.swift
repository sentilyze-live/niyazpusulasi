import Foundation

/// A single day's Ramadan fasting times.
struct RamadanDay: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date              // Gregorian date
    let hijriDate: String       // e.g., "1 Ramazan 1447"
    let dayNumber: Int          // 1-30
    let imsak: Date             // Suhoor end time (Fajr - 10 min)
    let iftar: Date             // = Maghrib time

    /// Whether this day is today.
    func isToday(in calendar: Calendar = .current) -> Bool {
        calendar.isDateInToday(date)
    }
}

/// Fasting state at a given moment during Ramadan.
enum RamadanState: Equatable {
    case beforeSuhoor(imsakTime: Date)      // Before imsak — can still eat
    case fasting(iftarTime: Date)           // Between imsak and iftar
    case afterIftar                         // After iftar — fasting complete
    case notRamadan                         // Outside Ramadan season
}
