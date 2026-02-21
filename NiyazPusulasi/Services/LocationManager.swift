import Foundation
import CoreLocation
import Contacts
import Combine

/// Manages location services for prayer time calculation.
/// Supports GPS and manual city selection with significant location change monitoring.
@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: LocationSelection = .istanbul
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var isLocating = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // City-level is sufficient
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        isLocating = true
        locationError = nil
        manager.requestLocation()
    }

    /// Start monitoring for significant location changes (city-level moves).
    /// Wakes the app from terminated state.
    func startSignificantLocationMonitoring() {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
        manager.startMonitoringSignificantLocationChanges()
    }

    func stopSignificantLocationMonitoring() {
        manager.stopMonitoringSignificantLocationChanges()
    }

    /// Manually set location (bypasses GPS).
    func setManualLocation(_ location: LocationSelection) {
        currentLocation = location
    }

    /// Set location from City model.
    func setCity(_ city: City) {
        let location = LocationSelection(
            mode: .manual,
            country: city.country,
            city: city.name,
            latitude: city.lat,
            longitude: city.lng,
            timezone: timeZoneForCity(city)
        )
        setManualLocation(location)
    }

    /// Determine timezone for a city based on country.
    func timeZoneForCity(_ city: City) -> String {
        timeZoneForCountry(city.country)
    }

    /// Determine timezone based on country name.
    func timeZoneForCountry(_ country: String) -> String {
        // For Turkey, always use Europe/Istanbul (UTC+3 permanent)
        if country == "Turkey" {
            return "Europe/Istanbul"
        }

        // For other countries, try to determine timezone
        switch country {
        // Middle East
        case "Saudi Arabia", "UAE", "Qatar", "Kuwait", "Bahrain", "Oman":
            return "Asia/Riyadh"
        case "Egypt", "Libya", "Sudan":
            return "Africa/Cairo"
        case "Palestine":
            return "Asia/Jerusalem"
        case "Jordan", "Lebanon", "Syria":
            return "Asia/Amman"
        case "Iraq":
            return "Asia/Baghdad"
        case "Iran":
            return "Asia/Tehran"
        case "Yemen":
            return "Asia/Aden"

        // Southeast Asia
        case "Indonesia":
            return "Asia/Jakarta"
        case "Malaysia", "Singapore":
            return "Asia/Kuala_Lumpur"
        case "Thailand":
            return "Asia/Bangkok"
        case "Philippines":
            return "Asia/Manila"

        // South Asia
        case "Pakistan":
            return "Asia/Karachi"
        case "Bangladesh":
            return "Asia/Dhaka"
        case "Afghanistan":
            return "Asia/Kabul"
        case "India":
            return "Asia/Kolkata"

        // Central Asia
        case "Azerbaijan":
            return "Asia/Baku"
        case "Uzbekistan":
            return "Asia/Tashkent"
        case "Kazakhstan":
            return "Asia/Almaty"
        case "Turkmenistan":
            return "Asia/Ashgabat"
        case "Kyrgyzstan":
            return "Asia/Bishkek"
        case "Tajikistan":
            return "Asia/Dushanbe"

        // North Africa
        case "Morocco":
            return "Africa/Casablanca"
        case "Algeria", "Tunisia":
            return "Africa/Algiers"

        // Sub-Saharan Africa
        case "Somalia":
            return "Africa/Mogadishu"
        case "Senegal":
            return "Africa/Dakar"
        case "Nigeria":
            return "Africa/Lagos"
        case "South Africa":
            return "Africa/Johannesburg"

        // Western Europe
        case "United Kingdom":
            return "Europe/London"
        case "France":
            return "Europe/Paris"
        case "Netherlands", "Belgium":
            return "Europe/Amsterdam"
        case "Germany":
            return "Europe/Berlin"
        case "Switzerland":
            return "Europe/Zurich"
        case "Austria":
            return "Europe/Vienna"
        case "Spain":
            return "Europe/Madrid"
        case "Portugal":
            return "Europe/Lisbon"
        case "Italy":
            return "Europe/Rome"

        // Northern Europe
        case "Sweden":
            return "Europe/Stockholm"
        case "Denmark":
            return "Europe/Copenhagen"
        case "Norway":
            return "Europe/Oslo"
        case "Finland":
            return "Europe/Helsinki"

        // Eastern Europe
        case "Poland":
            return "Europe/Warsaw"
        case "Czech Republic":
            return "Europe/Prague"
        case "Romania":
            return "Europe/Bucharest"
        case "Bulgaria":
            return "Europe/Sofia"
        case "Greece":
            return "Europe/Athens"

        // Balkans
        case "Bosnia and Herzegovina":
            return "Europe/Sarajevo"
        case "Albania":
            return "Europe/Tirane"
        case "Kosovo":
            return "Europe/Belgrade"

        // Russia
        case "Russia":
            return "Europe/Moscow"

        // Americas
        case "USA":
            return "America/New_York" // Default to Eastern
        case "Canada":
            return "America/Toronto"
        case "Brazil":
            return "America/Sao_Paulo"
        case "Argentina":
            return "America/Buenos_Aires"
        case "Mexico":
            return "America/Mexico_City"

        // East Asia
        case "China":
            return "Asia/Shanghai"
        case "Japan":
            return "Asia/Tokyo"
        case "South Korea":
            return "Asia/Seoul"

        // Oceania
        case "Australia":
            return "Australia/Sydney"
        case "New Zealand":
            return "Pacific/Auckland"

        default:
            return TimeZone.current.identifier
        }
    }

    /// Reverse geocode coordinates to get city and country names.
    func reverseGeocode(latitude: Double, longitude: Double) async -> (city: String?, country: String?, timezone: TimeZone?) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let placemark = placemarks.first
            
            // Try to get timezone from the placemark
            var detectedTimezone: TimeZone? = nil
            if let area = placemark?.timeZone {
                detectedTimezone = area
            } else if let postalAddress = placemark?.postalAddress {
                // Fallback to timezone detection from state/region
                detectedTimezone = timezoneFromAddress(postalAddress)
            }
            
            return (placemark?.locality, placemark?.country, detectedTimezone)
        } catch {
            return (nil, nil, nil)
        }
    }
    
    private func timezoneFromAddress(_ address: CNPostalAddress) -> TimeZone? {
        // `address.state` contains a state/region name, not a timezone identifier.
        // Fall back to country-based detection instead.
        let country = address.country
        guard !country.isEmpty else { return nil }
        let identifier = timeZoneForCountry(country)
        return TimeZone(identifier: identifier)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.isLocating = false

            let (city, country, detectedTimezone) = await reverseGeocode(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )

            // Use detected timezone, or fallback to best guess from country, then device timezone
            let timezone: String
            if let tz = detectedTimezone {
                timezone = tz.identifier
            } else if let countryName = country {
                timezone = self.timeZoneForCountry(countryName)
            } else {
                timezone = TimeZone.current.identifier
            }

            self.currentLocation = LocationSelection(
                mode: .gps,
                country: country,
                city: city,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timezone: timezone
            )
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLocating = false
            self.locationError = error.localizedDescription
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                requestCurrentLocation()
                startSignificantLocationMonitoring()
            default:
                break
            }
        }
    }
}

// MARK: - City Integration

extension LocationManager {
    /// Get all available cities from CityService.
    var availableCities: [City] {
        CityService.shared.allCities
    }

    /// Get Turkish cities.
    var turkishCities: [City] {
        CityService.shared.turkishCities
    }

    /// Search cities by name.
    func searchCities(query: String) -> [City] {
        CityService.shared.search(query: query)
    }
}
