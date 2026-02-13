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
        country: "Türkiye",
        city: "İstanbul",
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
}
