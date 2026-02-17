import SwiftUI
import BackgroundTasks
import RevenueCat

@main
struct NiyazPusulasiApp: App {
    private static let backgroundRefreshTaskId = "com.niyazpusulasi.app.refresh"

    @Environment(\.scenePhase) private var scenePhase

    let persistenceController = PersistenceController.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var locationManager = LocationManager()
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        registerBackgroundTasks()
        PremiumManager.shared.configure()
        HabitService.shared.seedDefaultHabitsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(settingsManager)
                .environmentObject(locationManager)
                .environmentObject(premiumManager)
                .environmentObject(themeManager)
                .preferredColorScheme(colorScheme(for: settingsManager.settings.theme))
                .onChange(of: settingsManager.settings.premiumTheme) { _, newTheme in
                    themeManager.setTheme(newTheme)
                }
                .onAppear {
                    themeManager.setTheme(settingsManager.settings.premiumTheme)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await NotificationManager.shared.rescheduleAllNotifications()
                }
            case .background:
                persistenceController.save()
                Self.scheduleBackgroundRefresh()
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
            forTaskWithIdentifier: Self.backgroundRefreshTaskId,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            Self.handleAppRefresh(task: refreshTask)
        }
    }

    private static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600) // 6 hours
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Background refresh scheduling failed: \(error.localizedDescription)")
        }
    }

    private static func handleAppRefresh(task: BGAppRefreshTask) {
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
