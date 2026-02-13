import SwiftUI

/// Premium themes with custom color palettes.
enum PremiumTheme: String, CaseIterable, Identifiable, Codable {
    case ocean
    case desert
    case forest
    case night
    case sapphire
    case coral

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ocean:    return "Okyanus"
        case .desert:   return "Çöl"
        case .forest:   return "Orman"
        case .night:    return "Gece"
        case .sapphire: return "Safir"
        case .coral:    return "Mercan"
        }
    }

    var accentColor: Color {
        switch self {
        case .ocean:    return Color(red: 0.0, green: 0.48, blue: 0.80)
        case .desert:   return Color(red: 0.80, green: 0.58, blue: 0.26)
        case .forest:   return Color(red: 0.20, green: 0.60, blue: 0.32)
        case .night:    return Color(red: 0.35, green: 0.25, blue: 0.60)
        case .sapphire: return Color(red: 0.12, green: 0.24, blue: 0.64)
        case .coral:    return Color(red: 0.90, green: 0.38, blue: 0.35)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .ocean:    return [Color(red: 0.0, green: 0.3, blue: 0.6), Color(red: 0.0, green: 0.5, blue: 0.8)]
        case .desert:   return [Color(red: 0.7, green: 0.5, blue: 0.2), Color(red: 0.9, green: 0.7, blue: 0.3)]
        case .forest:   return [Color(red: 0.1, green: 0.4, blue: 0.2), Color(red: 0.2, green: 0.6, blue: 0.3)]
        case .night:    return [Color(red: 0.1, green: 0.05, blue: 0.2), Color(red: 0.3, green: 0.15, blue: 0.5)]
        case .sapphire: return [Color(red: 0.05, green: 0.1, blue: 0.4), Color(red: 0.15, green: 0.3, blue: 0.7)]
        case .coral:    return [Color(red: 0.8, green: 0.25, blue: 0.25), Color(red: 0.95, green: 0.45, blue: 0.4)]
        }
    }

    var previewIcon: String {
        switch self {
        case .ocean:    return "water.waves"
        case .desert:   return "sun.dust.fill"
        case .forest:   return "leaf.fill"
        case .night:    return "moon.stars.fill"
        case .sapphire: return "diamond.fill"
        case .coral:    return "flame.fill"
        }
    }
}
