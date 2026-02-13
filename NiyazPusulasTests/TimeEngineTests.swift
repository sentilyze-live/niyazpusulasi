import XCTest
@testable import NiyazPusulasi

final class TimeEngineTests: XCTestCase {

    let engine = TimeEngine.shared

    /// Creates a PrayerTimeDay with predictable times for testing.
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

    // MARK: - Current Prayer Tests

    func testCurrentPrayerAtNoon() {
        let day = makeMockDay()
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 13, minute: 0, second: 0, of: day.date)!

        let current = engine.currentPrayer(from: day, at: noon)
        XCTAssertEqual(current, .dhuhr)
    }

    func testCurrentPrayerBeforeFajr() {
        let day = makeMockDay()
        let cal = Calendar.current
        let earlyMorning = cal.date(bySettingHour: 3, minute: 0, second: 0, of: day.date)!

        let current = engine.currentPrayer(from: day, at: earlyMorning)
        XCTAssertNil(current, "No prayer should be active before Fajr")
    }

    func testCurrentPrayerAfterIsha() {
        let day = makeMockDay()
        let cal = Calendar.current
        let lateNight = cal.date(bySettingHour: 22, minute: 0, second: 0, of: day.date)!

        let current = engine.currentPrayer(from: day, at: lateNight)
        XCTAssertEqual(current, .isha)
    }

    // MARK: - Next Prayer Tests

    func testNextPrayerAtNoon() {
        let day = makeMockDay()
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 13, minute: 0, second: 0, of: day.date)!

        let next = engine.nextPrayer(from: day, at: noon)
        XCTAssertNotNil(next)
        XCTAssertEqual(next?.0, .asr)
    }

    func testNextPrayerBeforeFajr() {
        let day = makeMockDay()
        let cal = Calendar.current
        let earlyMorning = cal.date(bySettingHour: 3, minute: 0, second: 0, of: day.date)!

        let next = engine.nextPrayer(from: day, at: earlyMorning)
        XCTAssertNotNil(next)
        XCTAssertEqual(next?.0, .fajr)
    }

    func testNextPrayerAfterIsha() {
        let day = makeMockDay()
        let cal = Calendar.current
        let lateNight = cal.date(bySettingHour: 22, minute: 0, second: 0, of: day.date)!

        let next = engine.nextPrayer(from: day, at: lateNight)
        XCTAssertNil(next, "Should return nil when all prayers passed")
    }

    func testNextPrayerCrossDayFallsToTomorrow() {
        let cal = Calendar.current
        let today = makeMockDay()
        let tomorrowDate = cal.date(byAdding: .day, value: 1, to: today.date)!
        let tomorrow = makeMockDay(baseDate: tomorrowDate)
        let lateNight = cal.date(bySettingHour: 22, minute: 0, second: 0, of: today.date)!

        let next = engine.nextPrayer(today: today, tomorrow: tomorrow, at: lateNight)
        XCTAssertNotNil(next)
        XCTAssertEqual(next?.0, .fajr)
    }

    // MARK: - Ramadan State Tests

    func testRamadanStateBeforeSuhoor() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let imsak = cal.date(bySettingHour: 5, minute: 32, second: 0, of: today)!
        let iftar = cal.date(bySettingHour: 17, minute: 55, second: 0, of: today)!
        let now = cal.date(bySettingHour: 4, minute: 0, second: 0, of: today)!

        let state = engine.ramadanState(imsak: imsak, iftar: iftar, at: now)
        if case .beforeSuhoor = state {
            // Expected
        } else {
            XCTFail("Expected .beforeSuhoor, got \(state)")
        }
    }

    func testRamadanStateFasting() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let imsak = cal.date(bySettingHour: 5, minute: 32, second: 0, of: today)!
        let iftar = cal.date(bySettingHour: 17, minute: 55, second: 0, of: today)!
        let now = cal.date(bySettingHour: 12, minute: 0, second: 0, of: today)!

        let state = engine.ramadanState(imsak: imsak, iftar: iftar, at: now)
        if case .fasting = state {
            // Expected
        } else {
            XCTFail("Expected .fasting, got \(state)")
        }
    }

    func testRamadanStateAfterIftar() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let imsak = cal.date(bySettingHour: 5, minute: 32, second: 0, of: today)!
        let iftar = cal.date(bySettingHour: 17, minute: 55, second: 0, of: today)!
        let now = cal.date(bySettingHour: 20, minute: 0, second: 0, of: today)!

        let state = engine.ramadanState(imsak: imsak, iftar: iftar, at: now)
        XCTAssertEqual(state, .afterIftar)
    }

    // MARK: - Notification Schedule Tests

    func testNotificationScheduleRespectsMaxCount() {
        let days = (0..<30).map { offset -> PrayerTimeDay in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
            return makeMockDay(baseDate: date)
        }

        let schedule = engine.buildNotificationSchedule(
            days: days,
            settings: .default,
            maxCount: 60
        )

        XCTAssertLessThanOrEqual(schedule.count, 60, "Schedule must not exceed 60 notifications")
    }

    func testNotificationScheduleOnlyFutureNotifications() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let day = makeMockDay(baseDate: yesterday)

        let schedule = engine.buildNotificationSchedule(
            days: [day],
            settings: .default,
            maxCount: 60
        )

        let now = Date()
        for notification in schedule {
            XCTAssertTrue(notification.fireDate > now, "All notifications must be in the future")
        }
    }

    func testNotificationScheduleIsSortedByDate() {
        let days = (0..<14).map { offset -> PrayerTimeDay in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
            return makeMockDay(baseDate: date)
        }

        let schedule = engine.buildNotificationSchedule(
            days: days,
            settings: .default,
            maxCount: 60
        )

        for i in 1..<schedule.count {
            XCTAssertTrue(schedule[i].fireDate >= schedule[i-1].fireDate, "Schedule must be sorted by date")
        }
    }

    func testEmptySettingsProducesNoNotifications() {
        let day = makeMockDay()
        let emptySettings = ReminderSettings(
            prayerEnabled: [:],
            prayerOffsetMinutes: [:],
            imsakEnabled: false,
            imsakOffsetMinutes: 15,
            iftarEnabled: false,
            iftarOffsetMinutes: 15,
            alarmModeEnabled: false
        )

        let schedule = engine.buildNotificationSchedule(
            days: [day],
            settings: emptySettings,
            maxCount: 60
        )

        XCTAssertEqual(schedule.count, 0, "No notifications when everything is disabled")
    }
}
