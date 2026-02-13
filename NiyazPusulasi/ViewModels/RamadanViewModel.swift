import Foundation
import Combine

/// ViewModel for the Ramadan tab — manages Imsakiye calendar and fasting state.
@MainActor
final class RamadanViewModel: ObservableObject {
    @Published var ramadanDays: [RamadanDay] = []
    @Published var todayRamadan: RamadanDay?
    @Published var currentState: RamadanState = .notRamadan
    @Published var isRamadan: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let provider = FallbackPrayerTimesProvider.shared
    private let timeEngine = TimeEngine.shared
    private let settingsManager = SettingsManager.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        settingsManager.$settings
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.loadRamadanTimes() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    func onAppear() {
        Task { await loadRamadanTimes() }
        startPeriodicUpdate()
    }

    func onDisappear() {
        stopPeriodicUpdate()
    }

    // MARK: - Data Loading

    func loadRamadanTimes() async {
        isLoading = true
        errorMessage = nil

        let location = settingsManager.location
        let settings = settingsManager.calcSettings

        // Determine current or upcoming Ramadan
        let hijriYear = timeEngine.currentHijriYear()
        guard let dateRange = timeEngine.ramadanDateRange(hijriYear: hijriYear) else {
            isLoading = false
            isRamadan = false
            return
        }

        isRamadan = timeEngine.isRamadan()

        do {
            let prayerDays = try await provider.fetchPrayerTimes(
                dateRange: dateRange,
                location: location,
                settings: settings
            )

            // Build Ramadan days
            let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
            var days: [RamadanDay] = []

            for (index, day) in prayerDays.enumerated() {
                let hijriComponents = hijriCalendar.dateComponents([.day, .month, .year], from: day.date)

                let monthNames: [Int: String] = [
                    1: "Muharrem", 2: "Safer", 3: "Rebiülevvel", 4: "Rebiülahir",
                    5: "Cemaziyelevvel", 6: "Cemaziyelahir", 7: "Recep", 8: "Şaban",
                    9: "Ramazan", 10: "Şevval", 11: "Zilkade", 12: "Zilhicce"
                ]
                let monthName = monthNames[hijriComponents.month ?? 9] ?? "Ramazan"
                let hijriDateString = "\(hijriComponents.day ?? 1) \(monthName) \(hijriComponents.year ?? 0)"

                let ramadanDay = RamadanDay(
                    id: UUID(),
                    date: day.date,
                    hijriDate: hijriDateString,
                    dayNumber: index + 1,
                    imsak: day.imsak,
                    iftar: day.maghrib
                )
                days.append(ramadanDay)
            }

            self.ramadanDays = days
            updateTodayAndState()

        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - State Updates

    private func updateTodayAndState() {
        let calendar = Calendar.current
        let today = Date()

        todayRamadan = ramadanDays.first { calendar.isDate($0.date, inSameDayAs: today) }

        if let todayData = todayRamadan {
            currentState = timeEngine.ramadanState(
                imsak: todayData.imsak,
                iftar: todayData.iftar,
                at: today
            )
        } else {
            currentState = .notRamadan
        }
    }

    // MARK: - Timer

    private func startPeriodicUpdate() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTodayAndState()
            }
        }
    }

    private func stopPeriodicUpdate() {
        timer?.invalidate()
        timer = nil
    }
}
