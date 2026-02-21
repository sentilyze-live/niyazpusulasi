import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var selectedTab = 0
    @State private var onboardingStep: OnboardingStep = .checkNeeded

    enum OnboardingStep {
        case checkNeeded, location, notification, done
    }

    var body: some View {
        Group {
            switch onboardingStep {
            case .checkNeeded:
                Color.clear.onAppear { determineOnboardingStep() }
            case .location:
                PermissionPromptView.location(
                    onAllow: {
                        locationManager.requestPermission()
                        onboardingStep = .notification
                    },
                    onSkip: { onboardingStep = .notification }
                )
                .transition(.opacity)
            case .notification:
                PermissionPromptView.notifications(
                    onAllow: {
                        Task {
                            _ = await NotificationManager.shared.requestPermission()
                            onboardingStep = .done
                        }
                    },
                    onSkip: { onboardingStep = .done }
                )
                .transition(.opacity)
            case .done:
                mainTabs
            }
        }
        .animation(.easeInOut, value: onboardingStep)
    }

    private var mainTabs: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem {
                        Label("Bugün", systemImage: "clock.fill")
                    }
                    .tag(0)
                    .toolbarBackground(.hidden, for: .tabBar)

                HabitsView()
                    .tabItem {
                        Label("Görevler", systemImage: "checklist")
                    }
                    .tag(1)
                    .toolbarBackground(.hidden, for: .tabBar)

                RamadanView()
                    .tabItem {
                        Label("İmsakiye", systemImage: "calendar")
                    }
                    .tag(2)
                    .toolbarBackground(.hidden, for: .tabBar)

                SettingsView()
                    .tabItem {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                    }
                    .tag(3)
                    .toolbarBackground(.hidden, for: .tabBar)
            }
            .tint(Color.themeGold)
        }
        .appBackground()
    }

    private func determineOnboardingStep() {
        let locationStatus = locationManager.authorizationStatus
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

        if hasSeenOnboarding {
            onboardingStep = .done
            return
        }

        if locationStatus == .notDetermined {
            onboardingStep = .location
        } else {
            onboardingStep = .notification
        }

        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
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
