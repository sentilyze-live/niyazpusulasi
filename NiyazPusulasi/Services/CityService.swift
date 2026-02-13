//
//  CityService.swift
//  NiyazPusulasi
//
//  Service for managing city database and location selection
//

import Foundation
import CoreLocation

/// Service for managing city database
class CityService {
    static let shared = CityService()

    private var database: CityDatabase?
    private var citiesByCountry: [String: [City]] = [:]

    private init() {
        loadDatabase()
    }

    /// Load city database from JSON bundle
    private func loadDatabase() {
        guard let url = Bundle.main.url(forResource: "cities_database", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let db = try? JSONDecoder().decode(CityDatabase.self, from: data) else {
            print("Error: Failed to load cities_database.json")
            return
        }

        self.database = db

        // Group cities by country for easier filtering
        for city in db.cities {
            citiesByCountry[city.country, default: []].append(city)
        }

        print("Loaded \(db.totalCities) cities from \(citiesByCountry.keys.count) countries")
    }

    /// Get all cities
    var allCities: [City] {
        database?.cities ?? []
    }

    /// Get cities grouped by country
    var countries: [String] {
        Array(citiesByCountry.keys).sorted()
    }

    /// Get cities for a specific country
    func cities(for country: String) -> [City] {
        citiesByCountry[country] ?? []
    }

    /// Search cities by name
    func search(query: String) -> [City] {
        guard !query.isEmpty else { return allCities }

        let lowercased = query.lowercased()
        return allCities.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.country.lowercased().contains(lowercased) ||
            $0.displayNameTurkish.lowercased().contains(lowercased)
        }
    }

    /// Find city by name and country
    func findCity(name: String, country: String) -> City? {
        allCities.first { $0.name == name && $0.country == country }
    }

    /// Get cities sorted by distance from a location
    func citiesNearby(location: CLLocation, limit: Int = 10) -> [City] {
        let sorted = allCities.sorted { city1, city2 in
            let loc1 = CLLocation(latitude: city1.lat, longitude: city1.lng)
            let loc2 = CLLocation(latitude: city2.lat, longitude: city2.lng)
            return location.distance(from: loc1) < location.distance(from: loc2)
        }
        return Array(sorted.prefix(limit))
    }

    /// Get Turkish cities only
    var turkishCities: [City] {
        cities(for: "Turkey")
    }

    /// Get featured cities (capitals and major cities)
    var featuredCities: [City] {
        let featured = [
            // Turkey
            "Istanbul", "Ankara", "Izmir", "Bursa", "Antalya",
            // Middle East
            "Mecca", "Medina", "Dubai", "Cairo", "Jerusalem",
            // Europe
            "London", "Paris", "Berlin", "Amsterdam", "Vienna",
            // Others
            "New York", "Toronto", "Sydney"
        ]

        return allCities.filter { featured.contains($0.name) }
    }
}

// MARK: - UserDefaults Extension for Selected City

extension UserDefaults {
    private enum Keys {
        static let selectedCityName = "selectedCityName"
        static let selectedCityCountry = "selectedCityCountry"
        static let useGPS = "useGPS"
    }

    /// Save selected city
    func setSelectedCity(_ city: City) {
        set(city.name, forKey: Keys.selectedCityName)
        set(city.country, forKey: Keys.selectedCityCountry)
        set(false, forKey: Keys.useGPS)
    }

    /// Get selected city
    func getSelectedCity() -> City? {
        guard let name = string(forKey: Keys.selectedCityName),
              let country = string(forKey: Keys.selectedCityCountry) else {
            return nil
        }
        return CityService.shared.findCity(name: name, country: country)
    }

    /// Clear selected city (will use GPS)
    func clearSelectedCity() {
        removeObject(forKey: Keys.selectedCityName)
        removeObject(forKey: Keys.selectedCityCountry)
        set(true, forKey: Keys.useGPS)
    }

    /// Check if using GPS or city selection
    var isUsingGPS: Bool {
        get { bool(forKey: Keys.useGPS) }
        set { set(newValue, forKey: Keys.useGPS) }
    }
}
