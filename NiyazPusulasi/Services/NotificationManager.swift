import Foundation
import UserNotifications

/// Manages all local notifications for prayer times, Imsak, and Iftar.
/// Operates within iOS's 64 pending notification limit.
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingCount: Int = 0
    @Published var lastScheduledAt: Date?
    @Published var coverageDays: Int = 0

    private let center = UNUserNotificationCenter.current()
    private let timeEngine = TimeEngine.shared
    private let provider = FallbackPrayerTimesProvider.shared
    private let settingsManager = SettingsManager.shared

    /// Maximum notifications to schedule (leaving 14 slots for other apps/system).
    /// iOS has a 64-notification limit per app.
    private let maxNotifications = 50
    
    /// iOS system notification limit
    static let iOSNotificationLimit = 64
    
    /// Safety margin for other apps
    static let safetyMargin = 14

    /// Notification category for prayer alerts.
    private let prayerCategory = "PRAYER_REMINDER"
    private let ramadanCategory = "RAMADAN_REMINDER"

    private init() {
        Task { await refreshAuthorizationStatus() }
        setupCategories()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge, .provisional]
            )
            await refreshAuthorizationStatus()
            return granted
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Scheduling

    /// Main scheduling entry point. Called on every foreground entry and background refresh.
    func rescheduleAllNotifications() async {
        // Cancel all existing
        center.removeAllPendingNotificationRequests()

        let settings = settingsManager.settings
        let location = settings.location
        let calcSettings = settings.calcSettings
        let reminderSettings = settings.reminderSettings

        // Calculate coverage days
        let days = reminderSettings.coverageDays
        self.coverageDays = days

        guard days > 0 else {
            pendingCount = 0
            return
        }

        // Fetch prayer times for the coverage period
        let calendar = Calendar.current
        let today = Date()
        guard let endDate = calendar.date(byAdding: .day, value: days, to: today) else { return }

        do {
            let prayerDays = try await provider.fetchPrayerTimes(
                dateRange: today...endDate,
                location: location,
                settings: calcSettings
            )

            // Build schedule
            let schedule = timeEngine.buildNotificationSchedule(
                days: prayerDays,
                settings: reminderSettings,
                maxCount: maxNotifications
            )

            // Schedule each notification
            for item in schedule {
                await scheduleNotification(item)
            }

            self.pendingCount = schedule.count
            self.lastScheduledAt = Date()

        } catch {
            print("Notification scheduling failed: \(error.localizedDescription)")
        }
    }

    /// Schedule a single notification.
    private func scheduleNotification(_ item: TimeEngine.ScheduledNotification) async {
        let content = UNMutableNotificationContent()

        switch item.type {
        case .prayer(let prayer):
            content.title = prayer.turkishName
            content.body = "\(prayer.turkishName) vakti geldi"
            content.categoryIdentifier = prayerCategory
        case .imsak:
            content.title = "İmsak Hatırlatması"
            content.body = "İmsak vaktine az kaldı"
            content.categoryIdentifier = ramadanCategory
        case .iftar:
            content.title = "İftar Hatırlatması"
            content.body = "İftar vaktine az kaldı"
            content.categoryIdentifier = ramadanCategory
        }

        // Sound — use selected adhan sound
        let adhanSound = settingsManager.settings.reminderSettings.adhanSound
        if let fileName = adhanSound.fileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(fileName).caf"))
        } else {
            content.sound = .default
        }

        // Time Sensitive for iOS 15+
        if item.isTimeSensitive {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }

        // Calendar trigger (non-repeating, specific date/time)
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: item.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: item.id,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification \(item.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Management

    /// Cancel all pending notifications.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        pendingCount = 0
    }

    /// Get list of pending notifications for the health check screen.
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    // MARK: - Categories

    private func setupCategories() {
        let prayerCategory = UNNotificationCategory(
            identifier: self.prayerCategory,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let ramadanCategory = UNNotificationCategory(
            identifier: self.ramadanCategory,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        center.setNotificationCategories([prayerCategory, ramadanCategory])
    }
}
