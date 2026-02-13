import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header: Location + Hijri date
                    headerSection

                    // Next prayer countdown card
                    if let next = viewModel.nextPrayerInfo {
                        CountdownView(
                            prayerName: next.name,
                            prayerTime: next.time
                        )
                    }

                    // Today's prayer times list
                    if let prayers = viewModel.todayPrayers {
                        prayerTimesSection(prayers)
                    }

                    // Prayer tracking (premium)
                    PrayerTrackingView()

                    // Qibla mini indicator
                    if viewModel.qiblaDirection > 0 {
                        QiblaView(direction: viewModel.qiblaDirection)
                    }
                }
                .padding()
            }
            .navigationTitle("Bugün")
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading && viewModel.todayPrayers == nil {
                    ProgressView("Namaz vakitleri yükleniyor...")
                }
            }
            .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Tamam") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(settingsManager.location.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.hijriDate.isEmpty {
                    Text(viewModel.hijriDate)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(Date(), style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Prayer Times List

    private func prayerTimesSection(_ prayers: PrayerTimeDay) -> some View {
        VStack(spacing: 2) {
            ForEach(PrayerName.allCases) { prayer in
                PrayerTimeRow(
                    prayer: prayer,
                    time: prayers.time(for: prayer),
                    isCurrent: viewModel.currentPrayer == prayer,
                    isNext: viewModel.nextPrayerInfo?.name == prayer,
                    formattedTime: settingsManager.formatTime(prayers.time(for: prayer))
                )
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    TodayView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(LocationManager())
}
