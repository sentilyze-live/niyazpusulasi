import SwiftUI
import BackgroundTasks
import RevenueCat

@main
struct NiyazPusulasiApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let persistenceController = PersistenceController.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var locationManager = LocationManager()
    @StateObject private var premiumManager = PremiumManager.shared

    init() {
        registerBackgroundTasks()
        PremiumManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(settingsManager)
                .environmentObject(locationManager)
                .environmentObject(premiumManager)
                .preferredColorScheme(colorScheme(for: settingsManager.settings.theme))
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await NotificationManager.shared.rescheduleAllNotifications()
                }
            case .background:
                persistenceController.save()
                scheduleBackgroundRefresh()
            default:
                break
            }
        }
    }

    private func colorScheme(for theme: AppSettings.Theme) -> ColorScheme? {
        switch theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    // MARK: - Background Tasks

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.niyazpusulasi.refresh",
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleAppRefresh(task: refreshTask)
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.niyazpusulasi.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600) // 6 hours
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Background refresh scheduling failed: \(error.localizedDescription)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleBackgroundRefresh()

        let workTask = Task {
            await NotificationManager.shared.rescheduleAllNotifications()
        }

        task.expirationHandler = {
            workTask.cancel()
        }

        Task {
            _ = await workTask.result
            task.setTaskCompleted(success: true)
        }
    }
}
