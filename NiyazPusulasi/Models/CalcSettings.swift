import Foundation

/// Prayer time calculation method and juristic settings.
struct CalcSettings: Codable, Equatable {

    /// Calculation method identifier matching Adhan library methods.
    enum Method: String, Codable, CaseIterable, Identifiable {
        case turkey
        case muslimWorldLeague
        case egyptian
        case karachi
        case ummAlQura
        case dubai
        case northAmerica
        case kuwait
        case qatar
        case singapore
        case tehran
        case moonsightingCommittee

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .turkey:               return "Diyanet (Türkiye)"
            case .muslimWorldLeague:    return "Muslim World League"
            case .egyptian:             return "Egyptian General Authority"
            case .karachi:              return "University of Karachi"
            case .ummAlQura:            return "Umm al-Qura (Makkah)"
            case .dubai:                return "Dubai"
            case .northAmerica:         return "ISNA (North America)"
            case .kuwait:               return "Kuwait"
            case .qatar:                return "Qatar"
            case .singapore:            return "Singapore"
            case .tehran:               return "Tehran"
            case .moonsightingCommittee: return "Moonsighting Committee"
            }
        }
    }

    /// Juristic school for Asr calculation.
    enum Madhab: String, Codable, CaseIterable, Identifiable {
        case hanafi
        case shafi

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .hanafi: return "Hanefi"
            case .shafi:  return "Şafii"
            }
        }
    }

    /// High latitude adjustment rule.
    enum HighLatitudeRule: String, Codable, CaseIterable, Identifiable {
        case middleOfTheNight
        case seventhOfTheNight
        case twilightAngle

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .middleOfTheNight:  return "Middle of the Night"
            case .seventhOfTheNight: return "Seventh of the Night"
            case .twilightAngle:     return "Twilight Angle"
            }
        }
    }

    var method: Method
    var madhab: Madhab
    var highLatitudeRule: HighLatitudeRule?

    /// Default Turkish settings: Diyanet method + Hanafi madhab.
    static let turkeyDefault = CalcSettings(
        method: .turkey,
        madhab: .hanafi,
        highLatitudeRule: nil
    )
}
