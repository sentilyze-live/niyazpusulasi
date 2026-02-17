import Foundation

/// Represents available adhan (call to prayer) sound options for notifications.
enum AdhanSound: String, Codable, CaseIterable, Identifiable {
    case `default` = "default"

    var id: String { rawValue }

    var displayName: String {
        String(localized: "adhan_sound_default")
    }

    var description: String {
        String(localized: "adhan_sound_default_desc")
    }

    var fileName: String? { nil }

    var emoji: String { "🔔" }

    var isPremium: Bool { false }

    var attribution: String? { nil }
}
