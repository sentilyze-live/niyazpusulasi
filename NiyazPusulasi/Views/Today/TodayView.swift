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
                    if viewModel.todayPrayers != nil {
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
                Text("HAYIRLI GÜNLER")
                    .font(.caption)
                    .fontWeight(.medium)
                    .tracking(1)
                    .foregroundStyle(.gray)

                Text(settingsManager.location.displayName)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
            }

            Spacer()

            // Notification Bell from prototype
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.themeGold)
                )
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Prayer Times List

    private func prayerTimesSection(_ prayers: PrayerTimeDay) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Bugünün Vakitleri")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Tümünü Gör")
                    .font(.caption)
                    .foregroundStyle(Color.themeGold)
            }
            .padding(.bottom, 12)
            .padding(.horizontal, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PrayerName.allCases) { prayer in
                        PrayerTimeRow(
                            prayer: prayer,
                            time: prayers.time(for: prayer),
                            isCurrent: viewModel.currentPrayer == prayer,
                            isNext: viewModel.nextPrayerInfo?.name == prayer,
                            formattedTime: settingsManager.formatTime(prayers.time(for: prayer))
                        )
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(LocationManager())
}
