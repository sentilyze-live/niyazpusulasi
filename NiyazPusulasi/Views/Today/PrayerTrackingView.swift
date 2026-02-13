import SwiftUI

/// Premium feature: Track which daily prayers the user has performed.
struct PrayerTrackingView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var prayersDone: Set<PrayerName> = []
    @State private var showPaywall = false

    private let defaults = UserDefaults(suiteName: WidgetPayload.appGroupId)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Namaz Takibi")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(prayersDone.count)/5")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(prayersDone.count == 5 ? .green : .secondary)
            }

            HStack(spacing: 8) {
                ForEach(PrayerName.obligatory) { prayer in
                    Button {
                        if premiumManager.hasAccess(to: .prayerTracking) {
                            togglePrayer(prayer)
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: prayersDone.contains(prayer) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(prayersDone.contains(prayer) ? .green : .secondary)
                                .contentTransition(.symbolEffect(.replace))

                            Text(prayer.turkishName)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: geo.size.width * CGFloat(prayersDone.count) / 5.0, height: 6)
                        .animation(.spring(response: 0.3), value: prayersDone.count)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "prayer_tracking_\(formatter.string(from: Date()))"
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
