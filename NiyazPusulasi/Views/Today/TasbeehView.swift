import SwiftUI

/// Premium feature: Digital tasbeeh (dhikr) counter with haptic feedback.
struct TasbeehView: View {
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var count: Int = 0
    @State private var target: Int = 33
    @State private var selectedDhikr: DhikrType = .subhanallah
    @State private var showPaywall = false
    @State private var showReset = false

    enum DhikrType: String, CaseIterable, Identifiable {
        case subhanallah = "Sübhanallah"
        case elhamdulillah = "Elhamdülillah"
        case allahuEkber = "Allahu Ekber"
        case lailaheillallah = "Lâ ilâhe illallah"
        case estağfirullah = "Estağfirullah"
        case custom = "Özel"

        var id: String { rawValue }

        var defaultTarget: Int {
            switch self {
            case .subhanallah, .elhamdulillah, .allahuEkber: return 33
            case .lailaheillallah: return 100
            case .estağfirullah: return 100
            case .custom: return 99
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Dhikr selector
                Picker("Zikir", selection: $selectedDhikr) {
                    ForEach(DhikrType.allCases) { dhikr in
                        Text(dhikr.rawValue).tag(dhikr)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedDhikr) { _, newValue in
                    target = newValue.defaultTarget
                    count = 0
                }

                Spacer()

                // Counter display
                ZStack {
                    // Progress ring
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 12)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: min(CGFloat(count) / CGFloat(target), 1.0))
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.3), value: count)

                    VStack(spacing: 8) {
                        Text("\(count)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())

                        Text("/ \(target)")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(selectedDhikr.rawValue)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Tap button
                Button {
                    incrementCount()
                } label: {
                    Circle()
                        .fill(progressColor.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(progressColor)
                        }
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: count)

                // Reset
                Button("Sıfırla") {
                    showReset = true
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            }
            .navigationTitle("Tesbih Sayacı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach([33, 99, 100, 500, 1000], id: \.self) { t in
                            Button("Hedef: \(t)") {
                                target = t
                                count = 0
                            }
                        }
                    } label: {
                        Image(systemName: "target")
                    }
                }
            }
            .alert("Sıfırla", isPresented: $showReset) {
                Button("İptal", role: .cancel) {}
                Button("Sıfırla", role: .destructive) {
                    withAnimation { count = 0 }
                }
            } message: {
                Text("Sayacı sıfırlamak istediğinize emin misiniz?")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: .tasbeehCounter)
            }
        }
    }

    private var progressColor: Color {
        let ratio = Double(count) / Double(target)
        if ratio >= 1.0 { return .green }
        if ratio >= 0.5 { return .blue }
        return .orange
    }

    private func incrementCount() {
        guard premiumManager.hasAccess(to: .tasbeehCounter) else {
            showPaywall = true
            return
        }
        withAnimation(.spring(response: 0.2)) {
            count += 1
        }
    }
}

#Preview {
    TasbeehView()
}
