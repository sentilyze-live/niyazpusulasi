import Foundation

/// Errors that can occur during prayer time fetching.
enum PrayerTimesError: Error, LocalizedError {
    case calculationFailed(String)
    case networkError(Error)
    case decodingError(Error)
    case invalidLocation
    case noDataAvailable

    var errorDescription: String? {
        switch self {
        case .calculationFailed(let reason): return "Hesaplama hatası: \(reason)"
        case .networkError(let error):       return "Ağ hatası: \(error.localizedDescription)"
        case .decodingError(let error):      return "Veri hatası: \(error.localizedDescription)"
        case .invalidLocation:               return "Geçersiz konum"
        case .noDataAvailable:               return "Veri bulunamadı"
        }
    }
}

/// Abstract interface for prayer time data sources.
/// Implementations: AdhanPrayerTimesProvider (local), AlAdhanAPIProvider (remote).
protocol PrayerTimesProvider {
    /// Human-readable name for logging/debugging.
    var providerName: String { get }

    /// Whether this provider works without network access.
    var isOfflineCapable: Bool { get }

    /// Fetch prayer times for a single date.
    func fetchPrayerTimes(
        for date: Date,
        location: LocationSelection,
        settings: CalcSettings
    ) async throws -> PrayerTimeDay

    /// Fetch prayer times for a date range (inclusive).
    func fetchPrayerTimes(
        dateRange: ClosedRange<Date>,
        location: LocationSelection,
        settings: CalcSettings
    ) async throws -> [PrayerTimeDay]
}

/// Default implementation: fetch range by iterating days.
extension PrayerTimesProvider {
    func fetchPrayerTimes(
        dateRange: ClosedRange<Date>,
        location: LocationSelection,
        settings: CalcSettings
    ) async throws -> [PrayerTimeDay] {
        let calendar = Calendar.current
        var results: [PrayerTimeDay] = []
        var current = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)

        while current <= end {
            let day = try await fetchPrayerTimes(for: current, location: location, settings: settings)
            results.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return results
    }
}
