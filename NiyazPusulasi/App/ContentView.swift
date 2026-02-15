import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Bugün", systemImage: "clock.fill")
                }
                .tag(0)

            RamadanView()
                .tabItem {
                    Label("Ramazan", systemImage: "moon.fill")
                }
                .tag(1)

            HabitsView()
                .tabItem {
                    Label("Alışkanlıklar", systemImage: "checkmark.circle.fill")
                }
                .tag(2)

            MoreView()
                .tabItem {
                    Label("Daha Fazla", systemImage: "ellipsis.circle.fill")
                }
                .tag(3)
        }
    }
}

/// "More" tab containing Tasbeeh, Dua, and Settings.
struct MoreView: View {
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showPaywall = false
    @State private var paywallTrigger: PremiumFeature = .tasbeehCounter

    var body: some View {
        NavigationStack {
            List {
                // Premium tools
                Section("İbadet Araçları") {
                    NavigationLink {
                        TasbeehView()
                    } label: {
                        Label("Tesbih Sayacı", systemImage: "circle.dotted")
                            .badge(premiumManager.isPremium ? nil : Text("Premium"))
                    }

                    NavigationLink {
                        DuaCollectionView()
                    } label: {
                        Label("Dua Koleksiyonu", systemImage: "book.fill")
                            .badge(premiumManager.isPremium ? nil : Text("Premium"))
                    }
                }

                // Settings
                Section("Uygulama") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                    }

                    if !premiumManager.isPremium {
                        Button {
                            paywallTrigger = .premiumThemes
                            showPaywall = true
                        } label: {
                            Label {
                                HStack {
                                    Text("Premium'a Geç")
                                    Spacer()
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                }
                            } icon: {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    } else {
                        HStack {
                            Label("Premium Aktif", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            if let exp = premiumManager.expirationDate {
                                Text(exp, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Daha Fazla")
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: paywallTrigger)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(SettingsManager.shared)
        .environmentObject(LocationManager())
        .environmentObject(PremiumManager.shared)
}
