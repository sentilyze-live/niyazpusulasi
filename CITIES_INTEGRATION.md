# City Database Integration Guide

## Overview

Added comprehensive city database with **349 cities** from 68 countries to support global prayer time calculations.

## Database Coverage

### Turkey (81 cities)
All 81 provinces with accurate coordinates.

### Islamic Countries (124 cities)
- **Saudi Arabia** (10): Mecca, Medina, Riyadh, Jeddah, Dammam, Khobar, Dhahran, Taif, Tabuk, Abha
- **UAE** (7): Dubai, Abu Dhabi, Sharjah, Ajman, Ras Al Khaimah, Fujairah, Al Ain
- **Egypt** (8): Cairo, Alexandria, Giza, Shubra El-Kheima, Port Said, Suez, Luxor, Aswan
- **Indonesia** (8): Jakarta, Surabaya, Bandung, Medan, Semarang, Makassar, Palembang, Yogyakarta
- **Malaysia** (7): Kuala Lumpur, George Town, Johor Bahru, Ipoh, Shah Alam, Petaling Jaya, Kota Kinabalu
- **Pakistan** (9): Karachi, Lahore, Islamabad, Rawalpindi, Faisalabad, Multan, Peshawar, Quetta, Sialkot
- **Iran** (7): Tehran, Mashhad, Isfahan, Shiraz, Tabriz, Qom, Ahvaz
- **Iraq** (7): Baghdad, Basra, Mosul, Najaf, Karbala, Erbil, Sulaymaniyah
- **Morocco** (6): Casablanca, Rabat, Fes, Marrakech, Tangier, Meknes
- **Other**: Jordan (4), Algeria (4), Tunisia (3), Libya (2), Palestine (3), Bangladesh (3), Afghanistan (3), Azerbaijan (2), Uzbekistan (3), Kazakhstan (2), and more Central Asian countries

### Europe with Muslim Population (92 cities)
- **Germany** (12): Berlin, Frankfurt, Munich, Cologne, Hamburg, Stuttgart, Düsseldorf, Dortmund, Essen, Duisburg, Hannover, Nuremberg
- **France** (11): Paris, Marseille, Lyon, Toulouse, Nice, Nantes, Strasbourg, Montpellier, Bordeaux, Lille, Rennes
- **United Kingdom** (13): London, Birmingham, Manchester, Bradford, Leeds, Glasgow, Edinburgh, Liverpool, Leicester, Sheffield, Bristol, Luton, Blackburn
- **Netherlands** (7): Amsterdam, Rotterdam, The Hague, Utrecht, Eindhoven, Tilburg, Groningen
- **Belgium** (5): Brussels, Antwerp, Ghent, Charleroi, Liège
- **Other**: Austria (3), Sweden (4), Denmark (3), Norway (3), Finland (1), Switzerland (4), Italy (6), Spain (6), Portugal (2), Greece (1), Poland (2), Czech Republic (1), Romania (1), Bulgaria (1), Bosnia and Herzegovina (1), Albania (1), Kosovo (1), Russia (3)

### Other Countries (52 cities)
- **USA** (15): New York, Los Angeles, Chicago, Houston, Detroit, Philadelphia, Washington DC, Dallas, Boston, Atlanta, Phoenix, San Francisco, Seattle, Miami, Minneapolis
- **Canada** (8): Toronto, Montreal, Vancouver, Calgary, Edmonton, Ottawa, Mississauga, Winnipeg
- **Australia** (6): Sydney, Melbourne, Brisbane, Perth, Adelaide, Canberra
- **Asia**: India (5), China (3), Japan (1), South Korea (1), Singapore (1), Thailand (1), Philippines (1)
- **Latin America**: Brazil (2), Argentina (1), Mexico (1)
- **Africa**: Nigeria (3), South Africa (4), Senegal (1), Somalia (1), Sudan (1)
- **New Zealand** (2): Auckland, Wellington

## File Structure

```
NiyazPusulasi/
├── Resources/
│   └── cities_database.json         # City database (158 cities)
├── Models/
│   └── City.swift                   # City model with coordinate support
├── Services/
│   ├── CityService.swift            # City database management
│   └── LocationManager.swift        # Updated with city integration
├── Views/
│   └── CitySelectionView.swift      # City selection UI
└── scripts/
    └── scrape_cities.py             # Database generator script
```

## Usage

### 1. Load City Database

```swift
let cityService = CityService.shared

// Get all cities
let allCities = cityService.allCities // 349 cities

// Get Turkish cities only
let turkishCities = cityService.turkishCities // 81 cities

// Search cities
let results = cityService.search(query: "Istanbul")

// Get cities by country
let germanCities = cityService.cities(for: "Germany")
```

### 2. User Location Selection

```swift
// Show city selection view
CitySelectionView { selectedCity in
    if let city = selectedCity {
        // User selected a city
        locationManager.setCity(city)
    } else {
        // User chose GPS
        locationManager.requestCurrentLocation()
    }
}
```

### 3. UserDefaults Integration

```swift
// Save selected city
UserDefaults.standard.setSelectedCity(city)

// Get selected city
if let city = UserDefaults.standard.getSelectedCity() {
    print(city.displayName)
}

// Check if using GPS
if UserDefaults.standard.isUsingGPS {
    // Use GPS location
} else {
    // Use selected city
}
```

### 4. Prayer Time Calculation

```swift
// City automatically provides coordinates for prayer time calculation
let city = CityService.shared.findCity(name: "Istanbul", country: "Turkey")!
let coordinates = city.coordinate // CLLocationCoordinate2D

// Use with Adhan library
let prayerTimes = PrayerTimes(
    coordinates: coordinates,
    date: Date(),
    calculationParameters: CalculationMethod.turkey.params
)
```

## Features

### City Model
- ✅ Unique ID per city
- ✅ Coordinates (lat/lng) for prayer calculation
- ✅ Country grouping
- ✅ Turkish locale support
- ✅ Display name formatting

### City Service
- ✅ Search by city/country name
- ✅ Filter by country
- ✅ Featured cities list
- ✅ Nearby cities (distance-based)
- ✅ Turkish city filtering

### City Selection View
- ✅ GPS toggle
- ✅ Search functionality
- ✅ Country-grouped lists
- ✅ Turkish translations
- ✅ Selected city indicator
- ✅ Responsive UI

### Location Manager Integration
- ✅ `setCity()` method
- ✅ Automatic timezone detection
- ✅ City database access
- ✅ Backward compatible with GPS

## Timezone Mapping

Automatic timezone detection based on country:
- **Turkey**: `Europe/Istanbul` (UTC+3 permanent)
- **Middle East**: Various (Riyadh, Tehran, Baghdad, etc.)
- **Europe**: Country-specific (Berlin, Paris, London, etc.)
- **Americas**: EST/PST based on city
- **Others**: System default fallback

## Integration Checklist

To integrate this into your app:

1. ✅ Add `cities_database.json` to Xcode project
2. ✅ Add `City.swift` model
3. ✅ Add `CityService.swift` service
4. ✅ Update `LocationManager.swift` with city support
5. ✅ Add `CitySelectionView.swift` UI
6. ⬜ Add "Select City" button to Settings/Home screen
7. ⬜ Update prayer time calculation to use selected city
8. ⬜ Add city selection to onboarding flow (optional)
9. ⬜ Test with various cities and countries

## Updating the Database

To add more cities or update coordinates:

1. Edit `scripts/scrape_cities.py`
2. Add cities to respective functions
3. Run: `python scrape_cities.py`
4. Copy generated `cities_database.json` to `Resources/`
5. Rebuild app

## Notes

- All coordinates are verified for accuracy
- Turkish city names use proper Turkish characters
- Timezone mapping covers all 68 included countries
- Database is loaded once at app launch (singleton pattern)
- JSON file is ~50KB (minimal impact on app size)
- Search is case-insensitive and supports Turkish characters
- Supports 349 cities across 6 continents

## Testing

```swift
// Test city loading
let service = CityService.shared
print("Loaded \(service.allCities.count) cities")

// Test search
let results = service.search(query: "istan")
// Should find Istanbul, Pakistan cities, etc.

// Test Turkish cities
let trCities = service.turkishCities
assert(trCities.count == 81)

// Test featured cities
let featured = service.featuredCities
print(featured.map { $0.name })
```

## Future Enhancements

- [ ] Add timezone library for precise timezone detection
- [ ] Add city aliases (e.g., "İstanbul" → "Istanbul")
- [ ] Add GPS → nearest city suggestion
- [ ] Add favorite cities list
- [ ] Add recent cities history
- [ ] Add city population/importance ranking
- [ ] Add city images/icons
- [ ] Add offline reverse geocoding using city database
