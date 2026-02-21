import Foundation
import ActivityKit
import WidgetKit

/// Manages Live Activities for prayer times (Dynamic Island support).
/// Requires iOS 16.1+ and ActivityKit entitlement.
@available(iOS 16.1, *)
@MainActor
final class LiveActivityService: ObservableObject {
    static let shared = LiveActivityService()

    @Published var isActivityActive = false
    @Published var currentActivity: Activity<PrayerActivityAttributes>?

    private init() {
        // On init, re-adopt any activity that survived a process restart.
        // This prevents stale activities from lingering on the Lock Screen.
        adoptExistingActivityIfNeeded()
    }

    /// Re-adopts an existing Live Activity after a process restart.
    private func adoptExistingActivityIfNeeded() {
        let existing = Activity<PrayerActivityAttributes>.activities
        if let first = existing.first {
            currentActivity = first
            isActivityActive = true
        }
    }

    // MARK: - Start Live Activity

    func startActivity(nextPrayer: PrayerName, prayerTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // End any existing activity
        endActivity()

        let settingsManager = SettingsManager.shared

        let attributes = PrayerActivityAttributes(
            locationName: settingsManager.location.displayName
        )

        let contentState = PrayerActivityAttributes.ContentState(
            nextPrayerName: nextPrayer.localizedName,
            prayerTime: prayerTime,
            prayerTimeFormatted: settingsManager.formatTime(prayerTime)
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    // MARK: - Update Live Activity

    func updateActivity(nextPrayer: PrayerName, prayerTime: Date) {
        guard let activity = currentActivity else { return }

        let settingsManager = SettingsManager.shared

        let contentState = PrayerActivityAttributes.ContentState(
            nextPrayerName: nextPrayer.localizedName,
            prayerTime: prayerTime,
            prayerTimeFormatted: settingsManager.formatTime(prayerTime)
        )

        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
        }
    }
    
    // MARK: - End Live Activity
    
    func endActivity() {
        // End the tracked activity if present
        if let activity = currentActivity {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        // Also sweep any orphaned activities (e.g. from a previous process lifecycle)
        let orphans = Activity<PrayerActivityAttributes>.activities
            .filter { $0.id != currentActivity?.id }
        for orphan in orphans {
            Task { await orphan.end(nil, dismissalPolicy: .immediate) }
        }

        currentActivity = nil
        isActivityActive = false
    }
    
    // MARK: - End All Activities
    
    func endAllActivities() {
        Task {
            for activity in Activity<PrayerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        
        currentActivity = nil
        isActivityActive = false
    }
}

// MARK: - Activity Attributes

struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var nextPrayerName: String
        var prayerTime: Date
        var prayerTimeFormatted: String
    }
    
    var locationName: String
}

// MARK: - Fallback for older iOS versions

@MainActor
class LiveActivityServiceFallback {
    static let shared = LiveActivityServiceFallback()
    private init() {}

    var isSupported: Bool {
        if #available(iOS 16.1, *) {
            return true
        }
        return false
    }

    func startActivity(nextPrayer: PrayerName, prayerTime: Date) {
        guard isSupported else { return }
        if #available(iOS 16.1, *) {
            LiveActivityService.shared.startActivity(nextPrayer: nextPrayer, prayerTime: prayerTime)
        }
    }

    func updateActivity(nextPrayer: PrayerName, prayerTime: Date) {
        guard isSupported else { return }
        if #available(iOS 16.1, *) {
            LiveActivityService.shared.updateActivity(nextPrayer: nextPrayer, prayerTime: prayerTime)
        }
    }

    func endActivity() {
        guard isSupported else { return }
        if #available(iOS 16.1, *) {
            LiveActivityService.shared.endActivity()
        }
    }
}
