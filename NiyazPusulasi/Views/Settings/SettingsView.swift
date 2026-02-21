import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeDarkBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Text("AYARLAR")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        settingsSection("KONUM VE HESAPLAMA") {
                            NavigationLink {
                                LocationSettingsView()
                            } label: {
                                settingsRow(icon: "location.fill", title: "Konum", value: settingsManager.location.displayName)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Label("Yöntem", systemImage: "function")
                                    .foregroundStyle(.white)
                                Spacer()
                                Picker("", selection: $settingsManager.settings.calcSettings.method) {
                                    ForEach(CalcSettings.Method.allCases) { method in
                                        Text(method.displayName).tag(method)
                                    }
                                }
                                .tint(Color.themeCyan)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Label("Mezhep (Asr)", systemImage: "book.fill")
                                    .foregroundStyle(.white)
                                Spacer()
                                Picker("", selection: $settingsManager.settings.calcSettings.madhab) {
                                    ForEach(CalcSettings.Madhab.allCases) { madhab in
                                        Text(madhab.displayName).tag(madhab)
                                    }
                                }
                                .tint(Color.themeCyan)
                            }
                        }
                        
                        settingsSection("BİLDİRİMLER") {
                            NavigationLink {
                                NotificationSettingsView()
                            } label: {
                                settingsRow(icon: "bell.fill", title: "Bildirim Ayarları")
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            NavigationLink {
                                NotificationHealthView()
                            } label: {
                                settingsRow(icon: "heart.text.square.fill", title: "Bildirim Sağlığı")
                            }
                        }
                        
                        settingsSection("GÖRÜNÜM") {
                            NavigationLink {
                                AppIconSettingsView()
                            } label: {
                                HStack {
                                    Label("Uygulama İkonu", systemImage: "app.badge")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if let iconName = settingsManager.settings.selectedAppIcon {
                                        Image(uiImage: UIImage(named: iconName) ?? UIImage())
                                            .resizable()
                                            .frame(width: 29, height: 29)
                                            .cornerRadius(6)
                                    } else {
                                        Image(systemName: "app.fill")
                                            .foregroundStyle(.gray)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Label("Tema", systemImage: "paintbrush.fill")
                                    .foregroundStyle(.white)
                                Spacer()
                                Picker("", selection: $settingsManager.settings.theme) {
                                    ForEach(AppSettings.Theme.allCases) { theme in
                                        Text(theme.displayName).tag(theme)
                                    }
                                }
                                .tint(Color.themeCyan)
                            }
                            
                            if !premiumManager.hasAccess(to: .premiumThemes) {
                                Divider().background(Color.white.opacity(0.1))
                                Button {
                                    showPaywall = true
                                } label: {
                                    HStack {
                                        Label("Premium Temalar", systemImage: "crown.fill")
                                            .foregroundStyle(Color.themeGold)
                                        Spacer()
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                        }
                        
                        settingsSection("HAKKINDA") {
                            settingsRow(icon: "info.circle.fill", title: "Versiyon", value: "1.0.0")
                            Divider().background(Color.white.opacity(0.1))
                            settingsRow(icon: "swift", title: "Hesaplama Altyapısı", value: "Adhan Swift")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: .premiumThemes)
            }
        }
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1)
                .foregroundStyle(.gray)
                .padding(.leading, 8)
            
            VStack(spacing: 16) {
                content()
            }
            .padding()
            .glassPanel(cornerRadius: 16, opacity: 0.5)
        }
    }
    
    private func settingsRow(icon: String, title: String, value: String? = nil) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.white)
            Spacer()
            if let value = value {
                Text(value)
                    .foregroundStyle(.gray)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
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
