import SwiftUI

struct LocationSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var locationManager: LocationManager
    @State private var searchText = ""
    @State private var selectedCountry: String? = nil

    private let cityService = CityService.shared

    var body: some View {
        List {
            // GPS Mode
            Section {
                Button {
                    settingsManager.location.mode = .gps
                    locationManager.requestCurrentLocation()
                } label: {
                    HStack {
                        Label("GPS Kullan", systemImage: "location.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        if settingsManager.location.mode == .gps {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                if settingsManager.location.mode == .gps {
                    if locationManager.isLocating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Konum alınıyor...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            if let city = locationManager.currentLocation.city {
                                Text(city)
                                    .font(.subheadline)
                            }
                            Text(String(format: "%.4f, %.4f",
                                        locationManager.currentLocation.latitude,
                                        locationManager.currentLocation.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let error = locationManager.locationError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if locationManager.authorizationStatus == .denied {
                        Button("Konum İzni Ayarlarını Aç") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                    }
                }
            } header: {
                Text("Otomatik Konum")
            }

            // Manual City Selection
            Section {
                if !searchText.isEmpty {
                    // Search results
                    ForEach(filteredCities) { city in
                        newCityRow(city)
                    }
                } else {
                    // Show countries grouped
                    // Turkey first
                    if !cityService.turkishCities.isEmpty {
                        DisclosureGroup("Türkiye (\(cityService.turkishCities.count))") {
                            ForEach(cityService.turkishCities) { city in
                                newCityRow(city)
                            }
                        }
                    }

                    // Other countries
                    ForEach(cityService.countries.filter { $0 != "Turkey" }.sorted(), id: \.self) { country in
                        let cities = cityService.cities(for: country)
                        DisclosureGroup("\(countryNameInTurkish(country)) (\(cities.count))") {
                            ForEach(cities) { city in
                                newCityRow(city)
                            }
                        }
                    }
                }
            } header: {
                Text("Manuel Şehir Seçimi")
            } footer: {
                Text("\(cityService.allCities.count) şehir mevcut")
                    .font(.caption)
            }
        }
        .navigationTitle("Konum")
        .searchable(text: $searchText, prompt: "Şehir ara...")
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if settingsManager.location.mode == .gps {
                settingsManager.location = newLocation
            }
        }
    }

    private var filteredCities: [City] {
        guard !searchText.isEmpty else { return cityService.allCities }
        return cityService.search(query: searchText)
    }

    // New city row for City model
    private func newCityRow(_ city: City) -> some View {
        Button {
            // Convert City to LocationSelection
            locationManager.setCity(city)
            settingsManager.location = LocationSelection(
                mode: .manual,
                country: city.country,
                city: city.name,
                latitude: city.lat,
                longitude: city.lng,
                timezone: locationManager.timeZoneForCountry(city.country)
            )
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .foregroundStyle(.primary)

                    if city.country != "Turkey" {
                        Text(countryNameInTurkish(city.country))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if settingsManager.location.mode == .manual &&
                   settingsManager.location.city == city.name &&
                   settingsManager.location.country == city.country {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    // Old city row (for backward compatibility if needed)
    private func cityRow(_ city: LocationSelection) -> some View {
        Button {
            var selected = city
            selected.mode = .manual
            settingsManager.location = selected
        } label: {
            HStack {
                Text(city.city ?? "")
                    .foregroundStyle(.primary)
                Spacer()
                if settingsManager.location.mode == .manual &&
                   settingsManager.location.city == city.city {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func countryNameInTurkish(_ country: String) -> String {
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

// Make LocationSelection identifiable for ForEach
extension LocationSelection: Identifiable {
    var id: String { "\(latitude)_\(longitude)" }
}

#Preview {
    NavigationStack {
        LocationSettingsView()
            .environmentObject(SettingsManager.shared)
            .environmentObject(LocationManager())
    }
}
