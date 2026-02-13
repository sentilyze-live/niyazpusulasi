import XCTest
@testable import NiyazPusulasi

final class PrayerTimesTests: XCTestCase {

    let provider = AdhanPrayerTimesProvider()
    let istanbulLocation = LocationSelection.istanbul
    let turkeySettings = CalcSettings.turkeyDefault

    // MARK: - Basic Calculation Tests

    func testIstanbulPrayerTimesNotNil() async throws {
        let result = try await provider.fetchPrayerTimes(
            for: Date(),
            location: istanbulLocation,
            settings: turkeySettings
        )

        XCTAssertNotNil(result)
        XCTAssertTrue(result.fajr < result.sunrise)
        XCTAssertTrue(result.sunrise < result.dhuhr)
        XCTAssertTrue(result.dhuhr < result.asr)
        XCTAssertTrue(result.asr < result.maghrib)
        XCTAssertTrue(result.maghrib < result.isha)
    }

    func testImsakIsFajrMinus10Minutes() async throws {
        let result = try await provider.fetchPrayerTimes(
            for: Date(),
            location: istanbulLocation,
            settings: turkeySettings
        )

        let expectedImsak = result.fajr.addingTimeInterval(-10 * 60)
        let diff = abs(result.imsak.timeIntervalSince(expectedImsak))
        XCTAssertLessThan(diff, 1, "Imsak should be exactly Fajr - 10 minutes")
    }

    func testSourceIsAdhanLocal() async throws {
        let result = try await provider.fetchPrayerTimes(
            for: Date(),
            location: istanbulLocation,
            settings: turkeySettings
        )

        XCTAssertEqual(result.source, .adhanLocal)
    }

    // MARK: - Date Range Tests

    func testDateRangeFetchesMultipleDays() async throws {
        let today = Date()
        guard let endDate = Calendar.current.date(byAdding: .day, value: 6, to: today) else {
            XCTFail("Could not create end date")
            return
        }

        let results = try await provider.fetchPrayerTimes(
            dateRange: today...endDate,
            location: istanbulLocation,
            settings: turkeySettings
        )

        XCTAssertEqual(results.count, 7, "Should return 7 days of prayer times")
    }

    // MARK: - Different Cities

    func testAnkaraPrayerTimesValid() async throws {
        let ankara = LocationSelection(
            mode: .manual,
            country: "Türkiye",
            city: "Ankara",
            latitude: 39.9334,
            longitude: 32.8597,
            timezone: "Europe/Istanbul"
        )

        let result = try await provider.fetchPrayerTimes(
            for: Date(),
            location: ankara,
            settings: turkeySettings
        )

        XCTAssertTrue(result.fajr < result.sunrise)
        XCTAssertTrue(result.maghrib < result.isha)
    }

    func testDifferentCitiesHaveDifferentTimes() async throws {
        let istanbul = try await provider.fetchPrayerTimes(
            for: Date(), location: istanbulLocation, settings: turkeySettings
        )

        let vanLocation = LocationSelection(
            mode: .manual, country: "Türkiye", city: "Van",
            latitude: 38.4891, longitude: 43.4089, timezone: "Europe/Istanbul"
        )
        let van = try await provider.fetchPrayerTimes(
            for: Date(), location: vanLocation, settings: turkeySettings
        )

        // Van is ~14° east of Istanbul, so times should differ
        let fajrDiff = abs(istanbul.fajr.timeIntervalSince(van.fajr))
        XCTAssertGreaterThan(fajrDiff, 30 * 60, "Fajr should differ by >30 min between Istanbul and Van")
    }

    // MARK: - Madhab Tests

    func testHanafiAsrLaterThanShafi() async throws {
        let hanafiSettings = CalcSettings(method: .turkey, madhab: .hanafi, highLatitudeRule: nil)
        let shafiSettings = CalcSettings(method: .turkey, madhab: .shafi, highLatitudeRule: nil)

        let hanafi = try await provider.fetchPrayerTimes(
            for: Date(), location: istanbulLocation, settings: hanafiSettings
        )
        let shafi = try await provider.fetchPrayerTimes(
            for: Date(), location: istanbulLocation, settings: shafiSettings
        )

        XCTAssertTrue(hanafi.asr > shafi.asr, "Hanafi Asr should be later than Shafi Asr")
    }

    // MARK: - Known Value Tests (Istanbul, approximate)

    func testIstanbulFajrReasonableHour() async throws {
        let result = try await provider.fetchPrayerTimes(
            for: Date(), location: istanbulLocation, settings: turkeySettings
        )

        let calendar = Calendar.current
        let tz = TimeZone(identifier: "Europe/Istanbul")!
        var cal = calendar
        cal.timeZone = tz

        let fajrHour = cal.component(.hour, from: result.fajr)
        // Fajr in Istanbul should be between 3:00 and 7:00 depending on season
        XCTAssertTrue(fajrHour >= 3 && fajrHour <= 7, "Fajr hour \(fajrHour) is outside expected range")
    }

    func testIstanbulDhuhrAroundNoon() async throws {
        let result = try await provider.fetchPrayerTimes(
            for: Date(), location: istanbulLocation, settings: turkeySettings
        )

        let tz = TimeZone(identifier: "Europe/Istanbul")!
        var cal = Calendar.current
        cal.timeZone = tz

        let dhuhrHour = cal.component(.hour, from: result.dhuhr)
        // Dhuhr should be between 12:00 and 13:30
        XCTAssertTrue(dhuhrHour >= 12 && dhuhrHour <= 13, "Dhuhr hour \(dhuhrHour) is outside expected range")
    }
}
