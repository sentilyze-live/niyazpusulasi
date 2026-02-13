//
//  City.swift
//  NiyazPusulasi
//
//  City model for prayer times location selection
//

import Foundation
import CoreLocation

/// Represents a city with geographic coordinates for prayer time calculation
struct City: Codable, Identifiable, Hashable {
    let name: String
    let country: String
    let lat: Double
    let lng: Double

    /// Unique identifier combining country and city name
    var id: String {
        "\(country)_\(name)"
    }

    /// CLLocationCoordinate2D for prayer time calculation
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// Display name with country (e.g., "Istanbul, Turkey")
    var displayName: String {
        "\(name), \(country)"
    }

    /// Display name in Turkish locale format
    var displayNameTurkish: String {
        // If country is Turkey, don't show country name
        if country == "Turkey" {
            return name
        }
        return "\(name), \(countryNameInTurkish)"
    }

    /// Country name translated to Turkish
    private var countryNameInTurkish: String {
        switch country {
        case "Turkey": return "Türkiye"
        case "Saudi Arabia": return "Suudi Arabistan"
        case "UAE": return "BAE"
        case "Egypt": return "Mısır"
        case "Indonesia": return "Endonezya"
        case "Malaysia": return "Malezya"
        case "Pakistan": return "Pakistan"
        case "Iran": return "İran"
        case "Iraq": return "Irak"
        case "Jordan": return "Ürdün"
        case "Morocco": return "Fas"
        case "Algeria": return "Cezayir"
        case "Tunisia": return "Tunus"
        case "Libya": return "Libya"
        case "Qatar": return "Katar"
        case "Kuwait": return "Kuveyt"
        case "Bahrain": return "Bahreyn"
        case "Oman": return "Umman"
        case "Lebanon": return "Lübnan"
        case "Syria": return "Suriye"
        case "Palestine": return "Filistin"
        case "Bangladesh": return "Bangladeş"
        case "Afghanistan": return "Afganistan"
        case "Azerbaijan": return "Azerbaycan"
        case "Uzbekistan": return "Özbekistan"
        case "Kazakhstan": return "Kazakistan"
        case "Turkmenistan": return "Türkmenistan"
        case "Kyrgyzstan": return "Kırgızistan"
        case "Tajikistan": return "Tacikistan"
        case "Yemen": return "Yemen"
        case "Sudan": return "Sudan"
        case "Somalia": return "Somali"
        case "Senegal": return "Senegal"
        case "Nigeria": return "Nijerya"
        case "Germany": return "Almanya"
        case "France": return "Fransa"
        case "Netherlands": return "Hollanda"
        case "Belgium": return "Belçika"
        case "United Kingdom": return "İngiltere"
        case "Austria": return "Avusturya"
        case "Sweden": return "İsveç"
        case "Denmark": return "Danimarka"
        case "Norway": return "Norveç"
        case "Finland": return "Finlandiya"
        case "Switzerland": return "İsviçre"
        case "Italy": return "İtalya"
        case "Spain": return "İspanya"
        case "Portugal": return "Portekiz"
        case "Greece": return "Yunanistan"
        case "Poland": return "Polonya"
        case "Czech Republic": return "Çek Cumhuriyeti"
        case "Romania": return "Romanya"
        case "Bulgaria": return "Bulgaristan"
        case "Bosnia and Herzegovina": return "Bosna Hersek"
        case "Albania": return "Arnavutluk"
        case "Kosovo": return "Kosova"
        case "Russia": return "Rusya"
        case "USA": return "ABD"
        case "Canada": return "Kanada"
        case "Australia": return "Avustralya"
        case "New Zealand": return "Yeni Zelanda"
        case "South Africa": return "Güney Afrika"
        case "Singapore": return "Singapur"
        case "Thailand": return "Tayland"
        case "Philippines": return "Filipinler"
        case "India": return "Hindistan"
        case "China": return "Çin"
        case "Japan": return "Japonya"
        case "South Korea": return "Güney Kore"
        case "Brazil": return "Brezilya"
        case "Argentina": return "Arjantin"
        case "Mexico": return "Meksika"
        default: return country
        }
    }
}

/// City database container
struct CityDatabase: Codable {
    let version: String
    let generatedAt: String
    let totalCities: Int
    let cities: [City]

    enum CodingKeys: String, CodingKey {
        case version
        case generatedAt = "generated_at"
        case totalCities = "total_cities"
        case cities
    }
}
