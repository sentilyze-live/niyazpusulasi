import Foundation
import CoreLocation

/// User's selected location for prayer time calculation.
struct LocationSelection: Codable, Equatable {
    enum Mode: String, Codable {
        case gps
        case manual
    }

    var mode: Mode
    var country: String?
    var city: String?
    var latitude: Double
    var longitude: Double
    var timezone: String

    /// Istanbul default — used when no location is available.
    static let istanbul = LocationSelection(
        mode: .manual,
        country: "Turkey",
        city: "Istanbul",
        latitude: 41.0082,
        longitude: 28.9784,
        timezone: "Europe/Istanbul"
    )

    var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Display name for the location (city or coordinates).
    var displayName: String {
        if let city { return city }
        return String(format: "%.2f, %.2f", latitude, longitude)
    }

    /// Country display name in Turkish
    var countryDisplayName: String {
        guard let country else { return "" }
        return CountryNameMapper.turkishName(for: country)
    }
}

/// Maps country codes to Turkish names
enum CountryNameMapper {
    static func turkishName(for country: String) -> String {
        let mapping: [String: String] = [
            "Turkey": "Türkiye",
            "Saudi Arabia": "Suudi Arabistan",
            "UAE": "BAE",
            "Egypt": "Mısır",
            "Indonesia": "Endonezya",
            "Malaysia": "Malezya",
            "Pakistan": "Pakistan",
            "Iran": "İran",
            "Iraq": "Irak",
            "Jordan": "Ürdün",
            "Morocco": "Fas",
            "Algeria": "Cezayir",
            "Tunisia": "Tunus",
            "Libya": "Libya",
            "Qatar": "Katar",
            "Kuwait": "Kuveyt",
            "Bahrain": "Bahreyn",
            "Oman": "Umman",
            "Lebanon": "Lübnan",
            "Syria": "Suriye",
            "Palestine": "Filistin",
            "Bangladesh": "Bangladeş",
            "Afghanistan": "Afganistan",
            "Azerbaijan": "Azerbaycan",
            "Uzbekistan": "Özbekistan",
            "Kazakhstan": "Kazakistan",
            "Turkmenistan": "Türkmenistan",
            "Kyrgyzstan": "Kırgızistan",
            "Tajikistan": "Tacikistan",
            "Yemen": "Yemen",
            "Sudan": "Sudan",
            "Somalia": "Somali",
            "Senegal": "Senegal",
            "Nigeria": "Nijerya",
            "Germany": "Almanya",
            "France": "Fransa",
            "Netherlands": "Hollanda",
            "Belgium": "Belçika",
            "United Kingdom": "İngiltere",
            "Austria": "Avusturya",
            "Sweden": "İsveç",
            "Denmark": "Danimarka",
            "Norway": "Norveç",
            "Finland": "Finlandiya",
            "Switzerland": "İsviçre",
            "Italy": "İtalya",
            "Spain": "İspanya",
            "Portugal": "Portekiz",
            "Greece": "Yunanistan",
            "Poland": "Polonya",
            "Czech Republic": "Çek Cumhuriyeti",
            "Romania": "Romanya",
            "Bulgaria": "Bulgaristan",
            "Bosnia and Herzegovina": "Bosna Hersek",
            "Albania": "Arnavutluk",
            "Kosovo": "Kosova",
            "Russia": "Rusya",
            "USA": "ABD",
            "Canada": "Kanada",
            "Australia": "Avustralya",
            "New Zealand": "Yeni Zelanda",
            "South Africa": "Güney Afrika",
            "Singapore": "Singapur",
            "Thailand": "Tayland",
            "Philippines": "Filipinler",
            "India": "Hindistan",
            "China": "Çin",
            "Japan": "Japonya",
            "South Korea": "Güney Kore",
            "Brazil": "Brezilya",
            "Argentina": "Arjantin",
            "Mexico": "Meksika",
        ]
        return mapping[country] ?? country
    }
}
