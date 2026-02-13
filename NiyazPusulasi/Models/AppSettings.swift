import Foundation

/// Top-level container for all user-facing app settings.
/// Persisted via SettingsManager to App Group UserDefaults.
struct AppSettings: Codable, Equatable {

    enum Theme: String, Codable, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "Sistem"
            case .light:  return "Açık"
            case .dark:   return "Koyu"
            }
        }
    }

    enum TimeFormat: String, Codable, CaseIterable, Identifiable {
        case twelve
        case twentyFour

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .twelve:     return "12 Saat"
            case .twentyFour: return "24 Saat"
            }
        }
    }

    var location: LocationSelection
    var calcSettings: CalcSettings
    var reminderSettings: ReminderSettings
    var theme: Theme
    var premiumTheme: PremiumTheme?
    var timeFormat: TimeFormat

    static let `default` = AppSettings(
        location: .istanbul,
        calcSettings: .turkeyDefault,
        reminderSettings: .default,
        theme: .system,
        premiumTheme: nil,
        timeFormat: .twentyFour
    )
}
