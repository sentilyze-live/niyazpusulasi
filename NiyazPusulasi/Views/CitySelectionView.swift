//
//  CitySelectionView.swift
//  NiyazPusulasi
//
//  City selection view for prayer times
//

import SwiftUI
import CoreLocation

struct CitySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCountry: String?
    @State private var useGPS = UserDefaults.standard.isUsingGPS

    let onCitySelected: (City?) -> Void

    private var cityService = CityService.shared

    init(onCitySelected: @escaping (City?) -> Void) {
        self.onCitySelected = onCitySelected
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // GPS Toggle
                gpsToggleSection

                Divider()

                if useGPS {
                    gpsInfoView
                } else {
                    citySelectionView
                }
            }
            .navigationTitle("Konum Seçimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - GPS Toggle Section

    private var gpsToggleSection: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $useGPS) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("GPS Kullan")
                        .font(.headline)
                }
            }
            .padding()
            .onChange(of: useGPS) { _, newValue in
                UserDefaults.standard.isUsingGPS = newValue
                if newValue {
                    UserDefaults.standard.clearSelectedCity()
                    onCitySelected(nil)
                    dismiss()
                }
            }

            if !useGPS {
                Text("Aşağıdaki listeden şehrinizi seçin")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - GPS Info View

    private var gpsInfoView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("GPS Konumu Kullanılıyor")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Namaz vakitleri mevcut konumunuza göre otomatik hesaplanacak")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 40)
    }

    // MARK: - City Selection View

    private var citySelectionView: some View {
        List {
            // Search Bar
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Şehir ara...", text: $searchText)
                        .autocorrectionDisabled()
                }
            }

            // Search Results or Country Groups
            if !searchText.isEmpty {
                searchResultsSection
            } else {
                countryGroupsSection
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        Section(header: Text("Arama Sonuçları")) {
            let results = cityService.search(query: searchText)
            if results.isEmpty {
                Text("Sonuç bulunamadı")
                    .foregroundColor(.secondary)
            } else {
                ForEach(results) { city in
                    cityRow(city)
                }
            }
        }
    }

    // MARK: - Country Groups

    private var countryGroupsSection: some View {
        Group {
            // Turkey (always first)
            if !cityService.turkishCities.isEmpty {
                Section(header: Text("Türkiye")) {
                    ForEach(cityService.turkishCities) { city in
                        cityRow(city)
                    }
                }
            }

            // Other countries alphabetically
            ForEach(cityService.countries.filter { $0 != "Turkey" }.sorted(), id: \.self) { country in
                Section(header: Text(countryNameInTurkish(country))) {
                    ForEach(cityService.cities(for: country)) { city in
                        cityRow(city)
                    }
                }
            }
        }
    }

    // MARK: - City Row

    private func cityRow(_ city: City) -> some View {
        Button {
            selectCity(city)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    if city.country != "Turkey" {
                        Text(countryNameInTurkish(city.country))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Show checkmark if selected
                if UserDefaults.standard.getSelectedCity()?.id == city.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Actions

    private func selectCity(_ city: City) {
        UserDefaults.standard.setSelectedCity(city)
        onCitySelected(city)
        dismiss()
    }

    // MARK: - Helpers

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
        case "Qatar": return "Katar"
        case "Kuwait": return "Kuveyt"
        case "Bahrain": return "Bahreyn"
        case "Oman": return "Umman"
        case "Lebanon": return "Lübnan"
        case "Syria": return "Suriye"
        case "Bangladesh": return "Bangladeş"
        case "Afghanistan": return "Afganistan"
        case "Germany": return "Almanya"
        case "France": return "Fransa"
        case "Netherlands": return "Hollanda"
        case "Belgium": return "Belçika"
        case "United Kingdom": return "İngiltere"
        case "Austria": return "Avusturya"
        case "Sweden": return "İsveç"
        case "Denmark": return "Danimarka"
        case "Norway": return "Norveç"
        case "Switzerland": return "İsviçre"
        case "Italy": return "İtalya"
        case "Spain": return "İspanya"
        case "USA": return "ABD"
        case "Canada": return "Kanada"
        case "Australia": return "Avustralya"
        case "South Africa": return "Güney Afrika"
        default: return country
        }
    }
}

// MARK: - Preview

#Preview {
    CitySelectionView { city in
        print("Selected city: \(city?.displayName ?? "GPS")")
    }
}
