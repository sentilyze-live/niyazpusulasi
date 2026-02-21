import SwiftUI

struct RamadanView: View {
    @StateObject private var viewModel = RamadanViewModel()
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeDarkBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("İMSAKİYE")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text("RAMAZAN \(TimeEngine.shared.currentHijriYear())")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .tracking(1)
                                    .foregroundStyle(Color.themeCyan)
                            }
                            Spacer()
                            
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                                .overlay(
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.gray)
                                )
                        }
                        .padding(.top, 8)
                        
                        // Countdown header
                        ramadanCountdownHeader
                        
                        // Calendar list
                        if viewModel.ramadanDays.isEmpty && !viewModel.isLoading {
                            emptyState
                        } else {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Ramazan Takvimi")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    HStack {
                                        Text(settingsManager.location.displayName)
                                            .font(.caption)
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                    .foregroundStyle(.white)
                                }
                                .padding(.bottom, 16)
                                
                                LazyVStack(spacing: 2) {
                                    ForEach(viewModel.ramadanDays) { day in
                                        RamadanDayRow(
                                            day: day,
                                            isToday: day.isToday(),
                                            formatTime: settingsManager.formatTime
                                        )
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Ramazan İmsakiyesi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay {
                if viewModel.isLoading && viewModel.ramadanDays.isEmpty {
                    ProgressView("İmsakiye yükleniyor...")
                        .tint(Color.themeGold)
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
                baseColor: Color.themeCyan
            )
        case .fasting(let iftarTime):
            countdownCard(
                title: "İftara Kalan Süre",
                targetTime: iftarTime,
                baseColor: Color.themeCyan
            )
        case .afterIftar:
            infoCard(
                title: "Oruç Tamamlandı",
                subtitle: "Hayırlı iftarlar",
                baseColor: Color.themeGold
            )
        case .notRamadan:
            if !viewModel.ramadanDays.isEmpty {
                if let firstDay = viewModel.ramadanDays.first, firstDay.date > Date() {
                    countdownCard(
                        title: "Ramazan'a Kalan Süre",
                        targetTime: firstDay.date,
                        baseColor: Color.themeGold
                    )
                }
            }
        }
    }

    private func countdownCard(title: String, targetTime: Date, baseColor: Color) -> some View {
        VStack(spacing: 16) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundStyle(baseColor)

            Text(targetTime, style: .timer)
                .font(.system(size: 48, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            HStack {
                VStack {
                    Text("Hedef Vakit")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    Text(targetTime, style: .time)
                        .font(.headline)
                        .foregroundStyle(Color.themeGold)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassPanel(cornerRadius: 32, opacity: 0.8)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(baseColor.opacity(0.3), lineWidth: 2)
        )
    }

    private func infoCard(title: String, subtitle: String, baseColor: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(baseColor)
                .padding(.bottom, 8)
            Text(title)
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassPanel(cornerRadius: 32, opacity: 0.8)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(baseColor.opacity(0.3), lineWidth: 2)
        )
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
