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
            case .system: return "theme_system".localized
            case .light:  return "theme_light".localized
            case .dark:   return "theme_dark".localized
            }
        }
    }

    enum TimeFormat: String, Codable, CaseIterable, Identifiable {
        case twelve
        case twentyFour

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .twelve:     return "time_format_12".localized
            case .twentyFour: return "time_format_24".localized
            }
        }
    }

    var location: LocationSelection
    var calcSettings: CalcSettings
    var reminderSettings: ReminderSettings
    var theme: Theme
    var premiumTheme: PremiumTheme?
    var timeFormat: TimeFormat
    var selectedAppIcon: String? = nil

    static let `default` = AppSettings(
        location: .istanbul,
        calcSettings: .turkeyDefault,
        reminderSettings: .default,
        theme: .system,
        premiumTheme: nil,
        timeFormat: .twentyFour
    )
}
