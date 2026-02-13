import SwiftUI

struct RamadanView: View {
    @StateObject private var viewModel = RamadanViewModel()
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Countdown header
                    ramadanCountdownHeader

                    // Calendar list
                    if viewModel.ramadanDays.isEmpty && !viewModel.isLoading {
                        emptyState
                    } else {
                        LazyVStack(spacing: 2) {
                            ForEach(viewModel.ramadanDays) { day in
                                RamadanDayRow(
                                    day: day,
                                    isToday: day.isToday(),
                                    formatTime: settingsManager.formatTime
                                )
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    }
                }
                .padding()
            }
            .navigationTitle("Ramazan İmsakiyesi")
            .overlay {
                if viewModel.isLoading && viewModel.ramadanDays.isEmpty {
                    ProgressView("İmsakiye yükleniyor...")
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Countdown Header

    @ViewBuilder
    private var ramadanCountdownHeader: some View {
        switch viewModel.currentState {
        case .beforeSuhoor(let imsakTime):
            countdownCard(
                title: "Sahura Kalan Süre",
                targetTime: imsakTime,
                gradient: [.indigo, .purple]
            )
        case .fasting(let iftarTime):
            countdownCard(
                title: "İftara Kalan Süre",
                targetTime: iftarTime,
                gradient: [.orange, .red]
            )
        case .afterIftar:
            infoCard(
                title: "Oruç Tamamlandı",
                subtitle: "Hayırlı iftarlar",
                gradient: [.green, .teal]
            )
        case .notRamadan:
            if !viewModel.ramadanDays.isEmpty {
                if let firstDay = viewModel.ramadanDays.first, firstDay.date > Date() {
                    countdownCard(
                        title: "Ramazan'a Kalan Süre",
                        targetTime: firstDay.date,
                        gradient: [.teal, .cyan]
                    )
                }
            }
        }
    }

    private func countdownCard(title: String, targetTime: Date, gradient: [Color]) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            Text(targetTime, style: .relative)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text(targetTime, style: .time)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoCard(title: String, subtitle: String, gradient: [Color]) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.white)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("İmsakiye verisi bulunamadı")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Konum ayarlarınızı kontrol edin")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    RamadanView()
        .environmentObject(SettingsManager.shared)
}
