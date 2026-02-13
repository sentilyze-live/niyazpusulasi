import Foundation

/// Central time logic service.
/// Determines current/next prayer, builds notification schedules,
/// and computes Ramadan fasting state.
final class TimeEngine {
    static let shared = TimeEngine()

    private init() {}

    // MARK: - Current / Next Prayer

    /// Determines the current active prayer period.
    func currentPrayer(from day: PrayerTimeDay, at now: Date = Date()) -> PrayerName? {
        let prayers = day.allPrayers
        var current: PrayerName?

        for (name, time) in prayers {
            if now >= time {
                current = name
            }
        }

        return current
    }

    /// Determines the next upcoming prayer and its time.
    /// Returns nil if all prayers for today have passed (caller should fetch tomorrow).
    func nextPrayer(from day: PrayerTimeDay, at now: Date = Date()) -> (PrayerName, Date)? {
        let prayers = day.allPrayers

        for (name, time) in prayers {
            if time > now {
                return (name, time)
            }
        }

        return nil // All prayers passed — need tomorrow's data
    }

    /// Determines the next prayer across today and tomorrow.
    func nextPrayer(
        today: PrayerTimeDay,
        tomorrow: PrayerTimeDay?,
        at now: Date = Date()
    ) -> (PrayerName, Date)? {
        if let next = nextPrayer(from: today, at: now) {
            return next
        }
        // All today's prayers passed — return first prayer of tomorrow
        if let tomorrow {
            return (.fajr, tomorrow.fajr)
        }
        return nil
    }

    /// Time interval until the next prayer.
    func timeUntilNextPrayer(
        today: PrayerTimeDay,
        tomorrow: PrayerTimeDay?,
        at now: Date = Date()
    ) -> TimeInterval? {
        guard let (_, time) = nextPrayer(today: today, tomorrow: tomorrow, at: now) else {
            return nil
        }
        return time.timeIntervalSince(now)
    }

    // MARK: - Ramadan State

    /// Determines the current fasting state.
    func ramadanState(imsak: Date, iftar: Date, at now: Date = Date()) -> RamadanState {
        if now < imsak {
            return .beforeSuhoor(imsakTime: imsak)
        } else if now < iftar {
            return .fasting(iftarTime: iftar)
        } else {
            return .afterIftar
        }
    }

    // MARK: - Notification Schedule Builder

    /// Represents a single scheduled notification.
    struct ScheduledNotification: Identifiable {
        let id: String              // Unique ID: "prayer_fajr_2026-02-14"
        let prayerName: String      // Display name
        let fireDate: Date          // When to fire
        let type: NotificationType
        let isTimeSensitive: Bool

        enum NotificationType {
            case prayer(PrayerName)
            case imsak
            case iftar
        }
    }

    /// Builds a notification schedule respecting the iOS 64-slot limit.
    /// Returns at most `maxCount` notifications sorted by fire date.
    func buildNotificationSchedule(
        days: [PrayerTimeDay],
        settings: ReminderSettings,
        maxCount: Int = 60
    ) -> [ScheduledNotification] {
        var notifications: [ScheduledNotification] = []
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for day in days {
            let dateString = dateFormatter.string(from: day.date)

            // Prayer notifications
            for prayer in PrayerName.obligatory {
                guard settings.prayerEnabled[prayer.rawValue] == true else { continue }

                let offset = settings.prayerOffsetMinutes[prayer.rawValue] ?? 0
                let fireDate = day.time(for: prayer).addingTimeInterval(TimeInterval(offset * 60))

                guard fireDate > now else { continue }

                notifications.append(ScheduledNotification(
                    id: "prayer_\(prayer.rawValue)_\(dateString)",
                    prayerName: prayer.turkishName,
                    fireDate: fireDate,
                    type: .prayer(prayer),
                    isTimeSensitive: true
                ))
            }

            // Imsak notification
            if settings.imsakEnabled {
                let fireDate = day.imsak.addingTimeInterval(
                    TimeInterval(-settings.imsakOffsetMinutes * 60)
                )
                if fireDate > now {
                    notifications.append(ScheduledNotification(
                        id: "imsak_\(dateString)",
                        prayerName: "İmsak",
                        fireDate: fireDate,
                        type: .imsak,
                        isTimeSensitive: true
                    ))
                }
            }

            // Iftar notification
            if settings.iftarEnabled {
                let fireDate = day.maghrib.addingTimeInterval(
                    TimeInterval(-settings.iftarOffsetMinutes * 60)
                )
                if fireDate > now {
                    notifications.append(ScheduledNotification(
                        id: "iftar_\(dateString)",
                        prayerName: "İftar",
                        fireDate: fireDate,
                        type: .iftar,
                        isTimeSensitive: true
                    ))
                }
            }
        }

        // Sort by fire date and cap at maxCount
        notifications.sort { $0.fireDate < $1.fireDate }

        if notifications.count > maxCount {
            notifications = Array(notifications.prefix(maxCount))
        }

        return notifications
    }

    /// Calculates how many days of coverage the current settings provide.
    func coverageDays(for settings: ReminderSettings) -> Int {
        settings.coverageDays
    }

    // MARK: - Ramadan Date Helpers

    /// Returns the Gregorian date range for Ramadan in the given Hijri year.
    func ramadanDateRange(hijriYear: Int) -> ClosedRange<Date>? {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

        var startComponents = DateComponents()
        startComponents.year = hijriYear
        startComponents.month = 9 // Ramadan
        startComponents.day = 1

        var endComponents = DateComponents()
        endComponents.year = hijriYear
        endComponents.month = 9
        endComponents.day = 30

        guard let start = hijriCalendar.date(from: startComponents),
              let end = hijriCalendar.date(from: endComponents) else {
            return nil
        }

        return start...end
    }

    /// Checks if a given date falls within Ramadan.
    func isRamadan(date: Date = Date()) -> Bool {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let month = hijriCalendar.component(.month, from: date)
        return month == 9
    }

    /// Returns the current Hijri year.
    func currentHijriYear() -> Int {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        return hijriCalendar.component(.year, from: Date())
    }
}
