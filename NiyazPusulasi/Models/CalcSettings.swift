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
            case .turkey:               return "calc_method_turkey".localized
            case .muslimWorldLeague:    return "calc_method_mwl".localized
            case .egyptian:             return "calc_method_egyptian".localized
            case .karachi:              return "calc_method_karachi".localized
            case .ummAlQura:            return "calc_method_umm_al_qura".localized
            case .dubai:                return "calc_method_dubai".localized
            case .northAmerica:         return "calc_method_isna".localized
            case .kuwait:               return "calc_method_kuwait".localized
            case .qatar:                return "calc_method_qatar".localized
            case .singapore:            return "calc_method_singapore".localized
            case .tehran:               return "calc_method_tehran".localized
            case .moonsightingCommittee: return "calc_method_moonsighting".localized
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
            case .hanafi: return "madhab_hanafi".localized
            case .shafi:  return "madhab_shafi".localized
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
