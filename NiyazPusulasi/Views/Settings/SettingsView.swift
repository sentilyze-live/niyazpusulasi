import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                // Location
                Section("Konum") {
                    NavigationLink {
                        LocationSettingsView()
                    } label: {
                        HStack {
                            Label("Konum", systemImage: "location.fill")
                            Spacer()
                            Text(settingsManager.location.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Calculation Method
                Section("Hesaplama") {
                    Picker("Yöntem", selection: $settingsManager.settings.calcSettings.method) {
                        ForEach(CalcSettings.Method.allCases) { method in
                            Text(method.displayName).tag(method)
                        }
                    }

                    Picker("Mezhep (Asr)", selection: $settingsManager.settings.calcSettings.madhab) {
                        ForEach(CalcSettings.Madhab.allCases) { madhab in
                            Text(madhab.displayName).tag(madhab)
                        }
                    }
                }

                // Notifications
                Section("Bildirimler") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Bildirim Ayarları", systemImage: "bell.fill")
                    }

                    NavigationLink {
                        NotificationHealthView()
                    } label: {
                        Label("Bildirim Sağlığı", systemImage: "heart.text.square.fill")
                    }
                }

                // Appearance
                Section("Görünüm") {
                    Picker("Tema", selection: $settingsManager.settings.theme) {
                        ForEach(AppSettings.Theme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }

                    // Premium theme picker
                    if premiumManager.hasAccess(to: .premiumThemes) {
                        Picker("Premium Tema", selection: Binding<PremiumTheme?>(
                            get: { settingsManager.settings.premiumTheme },
                            set: { settingsManager.settings.premiumTheme = $0 }
                        )) {
                            Text("Kapalı").tag(Optional<PremiumTheme>.none)
                            ForEach(PremiumTheme.allCases) { theme in
                                Label(theme.displayName, systemImage: theme.previewIcon)
                                    .tag(Optional(theme))
                            }
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Premium Temalar", systemImage: "paintpalette.fill")
                                Spacer()
                                HStack(spacing: 4) {
                                    ForEach(PremiumTheme.allCases.prefix(4)) { theme in
                                        Circle()
                                            .fill(theme.accentColor)
                                            .frame(width: 14, height: 14)
                                    }
                                }
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }

                    Picker("Saat Formatı", selection: $settingsManager.settings.timeFormat) {
                        ForEach(AppSettings.TimeFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                }

                // About
                Section("Hakkında") {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Hesaplama Kütüphanesi")
                        Spacer()
                        Text("Adhan Swift")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: .premiumThemes)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(LocationManager())
        .environmentObject(PremiumManager.shared)
}
