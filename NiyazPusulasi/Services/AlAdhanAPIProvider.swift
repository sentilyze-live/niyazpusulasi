import Foundation

/// Remote prayer time provider using the AlAdhan REST API.
/// Used for cross-validation and Hijri date lookups.
final class AlAdhanAPIProvider: PrayerTimesProvider {
    let providerName = "AlAdhan API"
    let isOfflineCapable = false

    private let baseURL = "https://api.aladhan.com/v1"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPrayerTimes(
        for date: Date,
        location: LocationSelection,
        settings: CalcSettings
    ) async throws -> PrayerTimeDay {
        let dateString = Self.apiDateFormatter.string(from: date)
        let method = mapMethodToAPIId(settings.method)
        let school = settings.madhab == .hanafi ? 1 : 0

        var components = URLComponents(string: "\(baseURL)/timings/\(dateString)")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "method", value: String(method)),
            URLQueryItem(name: "school", value: String(school)),
            URLQueryItem(name: "timezonestring", value: location.timezone),
        ]

        guard let url = components.url else {
            throw PrayerTimesError.invalidLocation
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PrayerTimesError.networkError(
                NSError(domain: "AlAdhan", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid response"
                ])
            )
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 400:
            throw PrayerTimesError.invalidLocation
        case 403:
            throw PrayerTimesError.networkError(
                NSError(domain: "AlAdhan", code: 403, userInfo: [
                    NSLocalizedDescriptionKey: "API rate limit exceeded"
                ])
            )
        case 404:
            throw PrayerTimesError.networkError(
                NSError(domain: "AlAdhan", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: "Location not found"
                ])
            )
        case 500...599:
            throw PrayerTimesError.networkError(
                NSError(domain: "AlAdhan", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "Server error"
                ])
            )
        default:
            throw PrayerTimesError.networkError(
                NSError(domain: "AlAdhan", code: httpResponse.statusCode)
            )
        }

        let apiResponse = try JSONDecoder().decode(AlAdhanResponse.self, from: data)

        return try parsePrayerTimes(from: apiResponse, date: date, timezone: location.timezone)
    }

    /// Fetch Hijri date for a Gregorian date.
    func fetchHijriDate(for date: Date) async throws -> HijriDateInfo {
        let dateString = Self.apiDateFormatter.string(from: date)
        let url = URL(string: "\(baseURL)/gToH/\(dateString)")!

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(AlAdhanHijriResponse.self, from: data)

        return HijriDateInfo(
            day: response.data.hijri.day,
            month: response.data.hijri.month.en,
            monthArabic: response.data.hijri.month.ar,
            year: response.data.hijri.year,
            designation: response.data.hijri.designation.abbreviated
        )
    }

    // MARK: - Parsing

    private func parsePrayerTimes(
        from response: AlAdhanResponse,
        date: Date,
        timezone: String
    ) throws -> PrayerTimeDay {
        let timings = response.data.timings
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        guard let tz = TimeZone(identifier: timezone) else {
            throw PrayerTimesError.invalidLocation
        }

        func parseTime(_ timeString: String) throws -> Date {
            // AlAdhan returns "HH:mm (TZ)" — strip timezone suffix
            let clean = timeString.components(separatedBy: " ").first ?? timeString
            let parts = clean.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else {
                throw PrayerTimesError.decodingError(
                    NSError(domain: "AlAdhan", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid time format: \(timeString)"
                    ])
                )
            }
            var comps = calendar.dateComponents(in: tz, from: startOfDay)
            comps.hour = parts[0]
            comps.minute = parts[1]
            comps.second = 0
            guard let result = calendar.date(from: comps) else {
                throw PrayerTimesError.decodingError(
                    NSError(domain: "AlAdhan", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to construct date for \(timeString)"
                    ])
                )
            }
            return result
        }

        let fajr = try parseTime(timings.Fajr)

        return PrayerTimeDay(
            id: UUID(),
            date: startOfDay,
            fajr: fajr,
            sunrise: try parseTime(timings.Sunrise),
            dhuhr: try parseTime(timings.Dhuhr),
            asr: try parseTime(timings.Asr),
            maghrib: try parseTime(timings.Maghrib),
            isha: try parseTime(timings.Isha),
            imsak: try parseTime(timings.Imsak),
            source: .aladhanAPI
        )
    }

    // MARK: - API Method Mapping

    private func mapMethodToAPIId(_ method: CalcSettings.Method) -> Int {
        switch method {
        case .muslimWorldLeague:    return 3
        case .northAmerica:         return 2
        case .egyptian:             return 5
        case .ummAlQura:            return 4
        case .karachi:              return 1
        case .tehran:               return 7
        case .turkey:               return 13
        case .dubai:                return 8
        case .kuwait:               return 9
        case .qatar:                return 10
        case .singapore:            return 11
        case .moonsightingCommittee: return 3 // Closest available
        }
    }

    // MARK: - Date Formatting

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// MARK: - API Response Models

struct AlAdhanResponse: Codable {
    let code: Int
    let status: String
    let data: AlAdhanData
}

struct AlAdhanData: Codable {
    let timings: AlAdhanTimings
    let date: AlAdhanDateInfo
}

struct AlAdhanTimings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
    let Imsak: String
}

struct AlAdhanDateInfo: Codable {
    let hijri: AlAdhanHijri
}

struct AlAdhanHijri: Codable {
    let day: String
    let month: AlAdhanMonth
    let year: String
    let designation: AlAdhanDesignation
}

struct AlAdhanMonth: Codable {
    let number: Int
    let en: String
    let ar: String
}

struct AlAdhanDesignation: Codable {
    let abbreviated: String
}

// Hijri conversion response
struct AlAdhanHijriResponse: Codable {
    let data: AlAdhanHijriData
}

struct AlAdhanHijriData: Codable {
    let hijri: AlAdhanHijri
}

/// Parsed Hijri date info for display.
struct HijriDateInfo: Codable, Equatable {
    let day: String
    let month: String
    let monthArabic: String
    let year: String
    let designation: String

    var displayString: String {
        "\(day) \(month) \(year) \(designation)"
    }

    var turkishDisplayString: String {
        "\(day) \(turkishMonthName) \(year)"
    }

    private var turkishMonthName: String {
        let monthNames: [String: String] = [
            "Muharram": "Muharrem",
            "Safar": "Safer",
            "Rabi al-Awwal": "Rebiülevvel",
            "Rabi al-Thani": "Rebiülahir",
            "Jumada al-Ula": "Cemaziyelevvel",
            "Jumada al-Thani": "Cemaziyelahir",
            "Rajab": "Recep",
            "Sha'ban": "Şaban",
            "Ramadan": "Ramazan",
            "Shawwal": "Şevval",
            "Dhul Qi'dah": "Zilkade",
            "Dhul Hijjah": "Zilhicce",
        ]
        return monthNames[month] ?? month
    }
}
