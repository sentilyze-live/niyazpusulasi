import Foundation
import Adhan

/// Offline prayer time calculator using the Adhan library.
/// This is the primary provider — works without network.
final class AdhanPrayerTimesProvider: PrayerTimesProvider {
    let providerName = "Adhan (Offline)"
    let isOfflineCapable = true

    func fetchPrayerTimes(
        for date: Date,
        location: LocationSelection,
        settings: CalcSettings
    ) async throws -> PrayerTimeDay {
        let timeZone = TimeZone(identifier: location.timezone) ?? .current

        let coordinates = Coordinates(
            latitude: location.latitude,
            longitude: location.longitude
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        let params = mapCalculationParameters(settings: settings)

        guard let prayerTimes = PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: params
        ) else {
            throw PrayerTimesError.calculationFailed("Adhan library returned nil for \(components)")
        }

        let imsak = prayerTimes.fajr.addingTimeInterval(-10 * 60) // Turkish convention

        return PrayerTimeDay(
            id: UUID(),
            date: calendar.startOfDay(for: date),
            fajr: prayerTimes.fajr,
            sunrise: prayerTimes.sunrise,
            dhuhr: prayerTimes.dhuhr,
            asr: prayerTimes.asr,
            maghrib: prayerTimes.maghrib,
            isha: prayerTimes.isha,
            imsak: imsak,
            source: .adhanLocal
        )
    }

    // MARK: - Mapping

    /// Maps app CalcSettings to Adhan library CalculationParameters.
    private func mapCalculationParameters(settings: CalcSettings) -> CalculationParameters {
        var params = mapMethod(settings.method).params

        // Madhab
        switch settings.madhab {
        case .hanafi: params.madhab = .hanafi
        case .shafi:  params.madhab = .shafi
        }

        // High latitude rule
        if let rule = settings.highLatitudeRule {
            switch rule {
            case .middleOfTheNight:  params.highLatitudeRule = .middleOfTheNight
            case .seventhOfTheNight: params.highLatitudeRule = .seventhOfTheNight
            case .twilightAngle:     params.highLatitudeRule = .twilightAngle
            }
        }

        return params
    }

    /// Maps app Method enum to Adhan CalculationMethod.
    private func mapMethod(_ method: CalcSettings.Method) -> CalculationMethod {
        switch method {
        case .turkey:               return .turkey
        case .muslimWorldLeague:    return .muslimWorldLeague
        case .egyptian:             return .egyptian
        case .karachi:              return .karachi
        case .ummAlQura:            return .ummAlQura
        case .dubai:                return .dubai
        case .northAmerica:         return .northAmerica
        case .kuwait:               return .kuwait
        case .qatar:                return .qatar
        case .singapore:            return .singapore
        case .tehran:               return .tehran
        case .moonsightingCommittee: return .moonsightingCommittee
        }
    }
}
