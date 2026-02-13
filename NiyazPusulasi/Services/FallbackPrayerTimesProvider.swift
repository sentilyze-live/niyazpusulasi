import Foundation

/// Orchestrates the fallback chain: Cache → Adhan Local → AlAdhan API.
/// The primary data path for all prayer time requests.
final class FallbackPrayerTimesProvider: PrayerTimesProvider {
    let providerName = "Fallback Chain"
    let isOfflineCapable = true

    static let shared = FallbackPrayerTimesProvider()

    private let localProvider = AdhanPrayerTimesProvider()
    private let apiProvider = AlAdhanAPIProvider()
    private let cache = PrayerTimesCache.shared

    private init() {}

    func fetchPrayerTimes(
        for date: Date,
        location: LocationSelection,
        settings: CalcSettings
    ) async throws -> PrayerTimeDay {
        // 1. Check cache
        let key = await cache.cacheKey(date: date, location: location, method: settings.method)
        if let cached = await cache.get(key: key) {
            return cached
        }

        // 2. Local calculation (always available, offline-first)
        do {
            let result = try await localProvider.fetchPrayerTimes(
                for: date, location: location, settings: settings
            )
            await cache.set(key: key, data: result)

            // 3. Background cross-validate with API (non-blocking)
            Task.detached(priority: .utility) { [weak self] in
                await self?.crossValidateWithAPI(
                    localResult: result, date: date, location: location, settings: settings
                )
            }

            return result
        } catch {
            // 4. Fallback to API if local somehow fails
            let apiResult = try await apiProvider.fetchPrayerTimes(
                for: date, location: location, settings: settings
            )
            await cache.set(key: key, data: apiResult)
            return apiResult
        }
    }

    /// Fetch prayer times for multiple days (optimized batch).
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

    /// Fetch Hijri date (delegates to API, with caching).
    func fetchHijriDate(for date: Date) async -> HijriDateInfo? {
        // Use Umm Al-Qura calendar as offline fallback
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let components = hijriCalendar.dateComponents([.day, .month, .year], from: date)

        let monthNames = [
            1: "Muharram", 2: "Safar", 3: "Rabi al-Awwal", 4: "Rabi al-Thani",
            5: "Jumada al-Ula", 6: "Jumada al-Thani", 7: "Rajab", 8: "Sha'ban",
            9: "Ramadan", 10: "Shawwal", 11: "Dhul Qi'dah", 12: "Dhul Hijjah"
        ]

        let monthName = monthNames[components.month ?? 1] ?? "Unknown"

        return HijriDateInfo(
            day: String(components.day ?? 1),
            month: monthName,
            monthArabic: "",
            year: String(components.year ?? 1),
            designation: "AH"
        )
    }

    // MARK: - Cross-Validation

    /// Compares local calculation with API result and logs discrepancies.
    private func crossValidateWithAPI(
        localResult: PrayerTimeDay,
        date: Date,
        location: LocationSelection,
        settings: CalcSettings
    ) async {
        do {
            let apiResult = try await apiProvider.fetchPrayerTimes(
                for: date, location: location, settings: settings
            )

            let maxDrift: TimeInterval = 5 * 60 // 5 minutes acceptable
            let prayers: [(String, Date, Date)] = [
                ("Fajr", localResult.fajr, apiResult.fajr),
                ("Dhuhr", localResult.dhuhr, apiResult.dhuhr),
                ("Asr", localResult.asr, apiResult.asr),
                ("Maghrib", localResult.maghrib, apiResult.maghrib),
                ("Isha", localResult.isha, apiResult.isha),
            ]

            for (name, local, api) in prayers {
                let diff = abs(local.timeIntervalSince(api))
                if diff > maxDrift {
                    print("[CrossValidation] \(name) drift: \(Int(diff/60)) min (local vs API)")
                }
            }
        } catch {
            // API unavailable — silent, local is authoritative
        }
    }
}
