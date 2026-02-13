import XCTest
@testable import NiyazPusulasi

final class NotificationTests: XCTestCase {

    // MARK: - Coverage Calculation Tests

    func testDefaultSettingsCoverageDays() {
        let settings = ReminderSettings.default
        // 5 prayers + imsak + iftar = 7 slots per day
        // 60 / 7 = 8 days
        XCTAssertEqual(settings.enabledSlotsPerDay, 7)
        XCTAssertEqual(settings.coverageDays, 8)
    }

    func testPrayerOnlyCoverage() {
        let settings = ReminderSettings(
            prayerEnabled: Dictionary(
                uniqueKeysWithValues: PrayerName.obligatory.map { ($0.rawValue, true) }
            ),
            prayerOffsetMinutes: [:],
            imsakEnabled: false,
            imsakOffsetMinutes: 15,
            iftarEnabled: false,
            iftarOffsetMinutes: 15,
            alarmModeEnabled: false
        )

        XCTAssertEqual(settings.enabledSlotsPerDay, 5)
        XCTAssertEqual(settings.coverageDays, 12) // 60 / 5 = 12
    }

    func testSinglePrayerCoverage() {
        let settings = ReminderSettings(
            prayerEnabled: [PrayerName.fajr.rawValue: true],
            prayerOffsetMinutes: [:],
            imsakEnabled: false,
            imsakOffsetMinutes: 15,
            iftarEnabled: false,
            iftarOffsetMinutes: 15,
            alarmModeEnabled: false
        )

        XCTAssertEqual(settings.enabledSlotsPerDay, 1)
        XCTAssertEqual(settings.coverageDays, 60)
    }

    func testAllDisabledCoverage() {
        let settings = ReminderSettings(
            prayerEnabled: [:],
            prayerOffsetMinutes: [:],
            imsakEnabled: false,
            imsakOffsetMinutes: 15,
            iftarEnabled: false,
            iftarOffsetMinutes: 15,
            alarmModeEnabled: false
        )

        XCTAssertEqual(settings.enabledSlotsPerDay, 0)
        XCTAssertEqual(settings.coverageDays, 0)
    }

    // MARK: - Notification ID Format Tests

    func testNotificationIDsAreUnique() {
        let engine = TimeEngine.shared
        let cal = Calendar.current

        let days = (0..<3).map { offset -> PrayerTimeDay in
            let date = cal.date(byAdding: .day, value: offset, to: Date())!
            return makeMockDay(baseDate: date)
        }

        let schedule = engine.buildNotificationSchedule(
            days: days,
            settings: .default,
            maxCount: 60
        )

        let ids = Set(schedule.map(\.id))
        XCTAssertEqual(ids.count, schedule.count, "All notification IDs must be unique")
    }

    func testNotificationIDContainsPrayerName() {
        let engine = TimeEngine.shared
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let day = makeMockDay(baseDate: tomorrow)

        let settings = ReminderSettings(
            prayerEnabled: [PrayerName.fajr.rawValue: true],
            prayerOffsetMinutes: [PrayerName.fajr.rawValue: 0],
            imsakEnabled: false,
            imsakOffsetMinutes: 15,
            iftarEnabled: false,
            iftarOffsetMinutes: 15,
            alarmModeEnabled: false
        )

        let schedule = engine.buildNotificationSchedule(
            days: [day],
            settings: settings,
            maxCount: 60
        )

        guard let first = schedule.first else {
            XCTFail("Expected at least one notification")
            return
        }

        XCTAssertTrue(first.id.contains("fajr"), "ID should contain prayer name: \(first.id)")
    }

    // MARK: - Budget Guard Tests

    func testBudgetNeverExceeds64() {
        let engine = TimeEngine.shared

        // Max settings: all prayers + imsak + iftar
        let maxSettings = ReminderSettings.default

        // 30 days of data
        let days = (0..<30).map { offset -> PrayerTimeDay in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
            return makeMockDay(baseDate: date)
        }

        let schedule = engine.buildNotificationSchedule(
            days: days,
            settings: maxSettings,
            maxCount: 60
        )

        // Hard limit: never more than 60 (leaving 4 for housekeeping)
        XCTAssertLessThanOrEqual(schedule.count, 60)
    }

    // MARK: - Helper

    private func makeMockDay(baseDate: Date = Date()) -> PrayerTimeDay {
        let cal = Calendar.current
        let today = cal.startOfDay(for: baseDate)

        return PrayerTimeDay(
            id: UUID(),
            date: today,
            fajr: cal.date(bySettingHour: 5, minute: 42, second: 0, of: today)!,
            sunrise: cal.date(bySettingHour: 7, minute: 10, second: 0, of: today)!,
            dhuhr: cal.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
            asr: cal.date(bySettingHour: 15, minute: 32, second: 0, of: today)!,
            maghrib: cal.date(bySettingHour: 17, minute: 55, second: 0, of: today)!,
            isha: cal.date(bySettingHour: 19, minute: 22, second: 0, of: today)!,
            imsak: cal.date(bySettingHour: 5, minute: 32, second: 0, of: today)!,
            source: .adhanLocal
        )
    }
}
