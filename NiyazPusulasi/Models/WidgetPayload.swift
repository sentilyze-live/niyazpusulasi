import Foundation
import SwiftUI

/// Data contract between the main app and WidgetKit extensions.
/// Serialized to App Group UserDefaults as JSON.
struct WidgetPayload: Codable {
    let updatedAt: Date
    let locationName: String
    let todayPrayers: PrayerTimeDay
    let nextPrayerName: String
    let nextPrayerTime: Date
    let isRamadan: Bool
    let todayImsak: Date?
    let todayIftar: Date?
    let widgetTheme: WidgetTheme?

    /// UserDefaults key for the payload.
    static let userDefaultsKey = "widget_payload"

    /// App Group suite name shared between app and widget.
    static let appGroupId = "group.com.niyazpusulasi.shared"
}

/// Theme customization for widgets
struct WidgetTheme: Codable, Equatable {
    let accentColorHex: String
    let backgroundColorHex: String
    let gradientStartHex: String
    let gradientEndHex: String
    let fontScale: Double

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var backgroundColor: Color {
        Color(hex: backgroundColorHex)
    }

    var gradientColors: [Color] {
        [Color(hex: gradientStartHex), Color(hex: gradientEndHex)]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
