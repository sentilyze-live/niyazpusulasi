import Foundation
import Combine
import Adhan
import ActivityKit

/// ViewModel for the Today tab — manages prayer times, countdown, and Qibla.
@MainActor
final class TodayViewModel: ObservableObject {
    @Published var todayPrayers: PrayerTimeDay?
    @Published var tomorrowPrayers: PrayerTimeDay?
    @Published var currentPrayer: PrayerName?
    @Published var nextPrayerInfo: (name: PrayerName, time: Date)?
    @Published var hijriDate: String = ""
    @Published var qiblaDirection: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let provider = FallbackPrayerTimesProvider.shared
    private let timeEngine = TimeEngine.shared
    private let settingsManager = SettingsManager.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private lazy var liveActivityManager = LiveActivityService.shared
    #endif

    init() {
        // Observe settings changes to reload
        settingsManager.$settings
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.loadPrayerTimes() }
            }
            .store(in: &cancellables)
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Public API

    func onAppear() {
        Task {
            await loadPrayerTimes()
        }
        startPeriodicUpdate()
    }

    func onDisappear() {
        // Only stop the UI refresh timer; keep Live Activity running so it
        // remains visible on the Lock Screen / Dynamic Island when the user
        // switches to another tab or backgrounds the app.
        stopPeriodicUpdate()
    }

    /// Call this only when the app is about to terminate or the user explicitly
    /// dismisses the activity (e.g. from a settings toggle).
    func terminateLiveActivity() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            liveActivityManager.endActivity()
        }
        #endif
    }

    func refresh() async {
        await loadPrayerTimes()
    }

    // MARK: - Data Loading

    func loadPrayerTimes() async {
        isLoading = true
        errorMessage = nil

        let location = settingsManager.location
        let settings = settingsManager.calcSettings

        do {
            let today = Date()
            let calendar = Calendar.current

            // Fetch today
            let todayData = try await provider.fetchPrayerTimes(
                for: today, location: location, settings: settings
            )
            self.todayPrayers = todayData

            // Fetch tomorrow (for next prayer calculation after isha)
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
                let tomorrowData = try await provider.fetchPrayerTimes(
                    for: tomorrow, location: location, settings: settings
                )
                self.tomorrowPrayers = tomorrowData
            }

            // Update current/next prayer
            updateCurrentAndNextPrayer()

            // Hijri date
            if let hijri = await provider.fetchHijriDate(for: today) {
                self.hijriDate = hijri.turkishDisplayString
            }

            // Qibla direction
            let coordinates = Coordinates(latitude: location.latitude, longitude: location.longitude)
            self.qiblaDirection = Qibla(coordinates: coordinates).direction

            // Update widget data
            await updateWidgetData()

        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Prayer State Updates

    private func updateCurrentAndNextPrayer() {
        guard let today = todayPrayers else { return }

        currentPrayer = timeEngine.currentPrayer(from: today)
        nextPrayerInfo = timeEngine.nextPrayer(
            today: today,
            tomorrow: tomorrowPrayers
        ).map { (name: $0.0, time: $0.1) }
        
        // Update Live Activity
        updateLiveActivity()
    }
    
    private func updateLiveActivity() {
        guard let nextInfo = nextPrayerInfo else { return }
        
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            if liveActivityManager.isActivityActive {
                liveActivityManager.updateActivity(
                    nextPrayer: nextInfo.name,
                    prayerTime: nextInfo.time
                )
            } else {
                liveActivityManager.startActivity(
                    nextPrayer: nextInfo.name,
                    prayerTime: nextInfo.time
                )
            }
        }
        #endif
    }

    // MARK: - Periodic Update

    private func startPeriodicUpdate() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentAndNextPrayer()
            }
        }
    }

    private func stopPeriodicUpdate() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Widget Data

    private func updateWidgetData() async {
        guard let today = todayPrayers else { return }
        let isRamadan = timeEngine.isRamadan()

        let payload = WidgetPayload(
            updatedAt: Date(),
            locationName: settingsManager.location.displayName,
            todayPrayers: today,
            nextPrayerName: nextPrayerInfo?.name.localizedName ?? "",
            nextPrayerTime: nextPrayerInfo?.time ?? Date(),
            isRamadan: isRamadan,
            todayImsak: isRamadan ? today.imsak : nil,
            todayIftar: isRamadan ? today.maghrib : nil,
            widgetTheme: computeWidgetTheme()
        )

        if let data = try? JSONEncoder().encode(payload),
           let defaults = UserDefaults(suiteName: WidgetPayload.appGroupId) {
            defaults.set(data, forKey: WidgetPayload.userDefaultsKey)
        }
    }

    private func computeWidgetTheme() -> WidgetTheme? {
        guard let premiumTheme = settingsManager.settings.premiumTheme else { return nil }

        return WidgetTheme(
            accentColorHex: premiumTheme.accentColor.toHex() ?? "#007AFF",
            backgroundColorHex: "#FFFFFF",
            gradientStartHex: premiumTheme.gradientColors[0].toHex() ?? "#0048A0",
            gradientEndHex: premiumTheme.gradientColors[1].toHex() ?? "#0078D0",
            fontScale: 1.0
        )
    }
}
