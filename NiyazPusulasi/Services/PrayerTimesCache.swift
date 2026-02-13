import Foundation

/// Thread-safe, actor-based cache for prayer time data.
/// Stores data in App Group UserDefaults for widget access.
actor PrayerTimesCache {
    static let shared = PrayerTimesCache()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// TTL for cached entries: 24 hours.
    private let ttl: TimeInterval = 24 * 3600

    private init() {
        self.defaults = UserDefaults(suiteName: WidgetPayload.appGroupId) ?? .standard
    }

    // MARK: - Cache Key

    /// Generates a deterministic cache key from date, location, and method.
    func cacheKey(date: Date, location: LocationSelection, method: CalcSettings.Method) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let dateStr = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        let latRounded = String(format: "%.2f", location.latitude)
        let lonRounded = String(format: "%.2f", location.longitude)
        return "prayer_\(dateStr)_\(latRounded)_\(lonRounded)_\(method.rawValue)"
    }

    // MARK: - Get / Set

    func get(key: String) -> PrayerTimeDay? {
        guard let data = defaults.data(forKey: key) else { return nil }

        // Check TTL
        let timestampKey = "\(key)_ts"
        let timestamp = defaults.double(forKey: timestampKey)
        guard timestamp > 0, Date().timeIntervalSince1970 - timestamp < ttl else {
            // Expired — remove
            defaults.removeObject(forKey: key)
            defaults.removeObject(forKey: timestampKey)
            return nil
        }

        return try? decoder.decode(PrayerTimeDay.self, from: data)
    }

    func set(key: String, data: PrayerTimeDay) {
        guard let encoded = try? encoder.encode(data) else { return }
        defaults.set(encoded, forKey: key)
        defaults.set(Date().timeIntervalSince1970, forKey: "\(key)_ts")
    }

    // MARK: - Bulk Operations

    /// Cache an array of prayer days.
    func cacheMultipleDays(_ days: [PrayerTimeDay], location: LocationSelection, method: CalcSettings.Method) {
        for day in days {
            let key = cacheKey(date: day.date, location: location, method: method)
            set(key: key, data: day)
        }
    }

    /// Get cached days for a date range (returns what's available).
    func getCachedDays(
        dateRange: ClosedRange<Date>,
        location: LocationSelection,
        method: CalcSettings.Method
    ) -> [PrayerTimeDay] {
        let calendar = Calendar.current
        var results: [PrayerTimeDay] = []
        var current = calendar.startOfDay(for: dateRange.lowerBound)
        let end = calendar.startOfDay(for: dateRange.upperBound)

        while current <= end {
            let key = cacheKey(date: current, location: location, method: method)
            if let cached = get(key: key) {
                results.append(cached)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return results
    }

    /// Clear all prayer time cache entries.
    func clearAll() {
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix("prayer_") {
            defaults.removeObject(forKey: key)
        }
    }
}
