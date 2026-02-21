import SwiftUI

/// Premium feature: Track which daily prayers the user has performed.
struct PrayerTrackingView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var prayersDone: Set<PrayerName> = []
    @State private var showPaywall = false

    private let defaults = UserDefaults(suiteName: WidgetPayload.appGroupId)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Namaz Takibi")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(prayersDone.count)/5")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(prayersDone.count == 5 ? Color.themeGold : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                ForEach(PrayerName.obligatory) { prayer in
                    Button {
                        if premiumManager.hasAccess(to: .prayerTracking) {
                            togglePrayer(prayer)
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    .frame(width: 32, height: 32)
                                    .background(prayersDone.contains(prayer) ? Color.themeGold.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                                
                                if prayersDone.contains(prayer) {
                                    Circle()
                                        .fill(Color.themeGold)
                                        .frame(width: 16, height: 16)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }

                            Text(prayer.localizedName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(prayersDone.contains(prayer) ? Color.themeGold : .gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.spring(response: 0.3), value: prayersDone)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color.themeCyan, Color.themeGold], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(prayersDone.count) / 5.0, height: 4)
                        .animation(.spring(response: 0.4), value: prayersDone.count)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .glassPanel(cornerRadius: 24, opacity: 0.5)
        .overlay {
            if !premiumManager.hasAccess(to: .prayerTracking) {
                premiumOverlay
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(trigger: .prayerTracking)
        }
        .onAppear { loadTodayTracking() }
    }

    private var premiumOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)

            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Premium")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .onTapGesture { showPaywall = true }
    }

    // MARK: - Persistence

    private static let trackingDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var todayKey: String {
        "prayer_tracking_\(Self.trackingDateFormatter.string(from: Date()))"
    }

    private func togglePrayer(_ prayer: PrayerName) {
        withAnimation(.spring(response: 0.3)) {
            if prayersDone.contains(prayer) {
                prayersDone.remove(prayer)
            } else {
                prayersDone.insert(prayer)
            }
        }
        saveTodayTracking()
    }

    private func loadTodayTracking() {
        guard let data = defaults?.data(forKey: todayKey),
              let names = try? JSONDecoder().decode([String].self, from: data) else { return }
        prayersDone = Set(names.compactMap { PrayerName(rawValue: $0) })
    }

    private func saveTodayTracking() {
        let names = prayersDone.map(\.rawValue)
        if let data = try? JSONEncoder().encode(names) {
            defaults?.set(data, forKey: todayKey)
        }
    }
}

#Preview {
    PrayerTrackingView()
        .environmentObject(SettingsManager.shared)
        .padding()
}
