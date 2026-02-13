import Foundation
import Combine

/// Persists all user settings to App Group UserDefaults.
/// Single source of truth for app configuration.
@MainActor
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var settings: AppSettings {
        didSet {
            save()
        }
    }

    private let defaults: UserDefaults
    private let settingsKey = "app_settings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        self.defaults = UserDefaults(suiteName: WidgetPayload.appGroupId) ?? .standard

        // Load existing settings or use defaults
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? decoder.decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    // MARK: - Convenience Accessors

    var location: LocationSelection {
        get { settings.location }
        set { settings.location = newValue }
    }

    var calcSettings: CalcSettings {
        get { settings.calcSettings }
        set { settings.calcSettings = newValue }
    }

    var reminderSettings: ReminderSettings {
        get { settings.reminderSettings }
        set { settings.reminderSettings = newValue }
    }

    var theme: AppSettings.Theme {
        get { settings.theme }
        set { settings.theme = newValue }
    }

    var timeFormat: AppSettings.TimeFormat {
        get { settings.timeFormat }
        set { settings.timeFormat = newValue }
    }

    // MARK: - Time Formatting

    /// Returns a DateFormatter configured per user preferences.
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: settings.location.timezone)
        switch settings.timeFormat {
        case .twelve:     formatter.dateFormat = "h:mm a"
        case .twentyFour: formatter.dateFormat = "HH:mm"
        }
        return formatter
    }

    /// Format a prayer time for display.
    func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}
