import SwiftUI
import RevenueCat

private enum AppURLs {
    static let privacyPolicy = URL(string: "https://niyazpusulasi.com/legal/privacy-policy")!
    static let termsOfUse = URL(string: "https://niyazpusulasi.com/legal/terms")!
}

/// Contextual soft paywall shown when user taps a premium feature.
struct PaywallView: View {
    let trigger: PremiumFeature
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var selectedPlan: PlanType = .yearly
    @State private var purchaseError: String?
    @State private var showRestoreSuccess = false

    enum PlanType {
        case monthly, yearly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Trigger-specific feature highlight
                    triggerHighlight

                    // All premium benefits
                    benefitsList

                    // Plan selection
                    planSelection

                    // Purchase button
                    purchaseButton

                    // Footer
                    footerSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .alert("Hata", isPresented: .constant(purchaseError != nil)) {
                Button("Tamam") { purchaseError = nil }
            } message: {
                Text(purchaseError ?? "")
            }
            .alert("Başarılı", isPresented: $showRestoreSuccess) {
                Button("Tamam") { dismiss() }
            } message: {
                Text("Satın alımlarınız geri yüklendi.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Niyaz Pusulası Premium")
                .font(.title2.weight(.bold))

            Text("İbadetini daha güzel yaşa")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Trigger Highlight

    private var triggerHighlight: some View {
        HStack(spacing: 12) {
            Image(systemName: trigger.iconName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(trigger.paywallTitle)
                    .font(.headline)
                Text(trigger.paywallDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Benefits List

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Premium ile neler kazanırsın?")
                .font(.subheadline.weight(.semibold))
                .padding(.bottom, 4)

            benefitRow("lock.rectangle.stack.fill", "Kilit ekranı widget'ları")
            benefitRow("rectangle.3.group.fill", "3 farklı ana ekran widget'ı")
            benefitRow("moon.fill", "Ramazan özel widget'ı")
            benefitRow("infinity", "Sınırsız alışkanlık takibi")
            benefitRow("square.grid.3x3.fill", "Aylık performans ısı haritası")
            benefitRow("paintpalette.fill", "6 premium tema")
            benefitRow("checkmark.seal.fill", "Namaz takibi")
            benefitRow("circle.dotted", "Dijital tesbih sayacı")
            benefitRow("book.fill", "26 dua koleksiyonu")
            // iCloud sync coming in a future update
        }
    }

    private func benefitRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }

    // MARK: - Plan Selection

    private var planSelection: some View {
        VStack(spacing: 10) {
            // Yearly (recommended)
            if let annual = premiumManager.annualPackage {
                planCard(
                    type: .yearly,
                    title: "Yıllık",
                    price: annual.localizedPriceString,
                    period: "/yıl",
                    badge: "%58 tasarruf",
                    subtitle: dailyPrice(from: annual),
                    package: annual
                )
            }

            // Monthly
            if let monthly = premiumManager.monthlyPackage {
                planCard(
                    type: .monthly,
                    title: "Aylık",
                    price: monthly.localizedPriceString,
                    period: "/ay",
                    badge: nil,
                    subtitle: nil,
                    package: monthly
                )
            }
        }
    }

    private func planCard(
        type: PlanType,
        title: String,
        price: String,
        period: String,
        badge: String?,
        subtitle: String?,
        package: Package
    ) -> some View {
        Button {
            selectedPlan = type
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title3.weight(.bold))
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedPlan == type ? Color.blue : Color.secondary.opacity(0.3), lineWidth: selectedPlan == type ? 2 : 1)
            )
            .background(
                selectedPlan == type ? Color.blue.opacity(0.05) : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func dailyPrice(from package: Package) -> String {
        let price = package.storeProduct.price as Decimal
        let daily = price / 365
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = package.storeProduct.priceFormatter?.locale ?? Locale.current
        formatter.maximumFractionDigits = 2
        if let formatted = formatter.string(from: daily as NSDecimalNumber) {
            return "\(formatted)/gün • 7 gün ücretsiz dene"
        }
        return "7 gün ücretsiz dene"
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await handlePurchase() }
            } label: {
                Group {
                    if premiumManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("7 Gün Ücretsiz Dene")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(premiumManager.isLoading)

            Text("Deneme süresi sonunda otomatik yenilenir. Dilediğin zaman iptal edebilirsin.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("Temel özellikler her zaman ücretsiz kalacak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Satın alımları geri yükle") {
                Task { await handleRestore() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button("Gizlilik Politikası") {
                    openURL(AppURLs.privacyPolicy)
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)

                Button("Kullanım Şartları") {
                    openURL(AppURLs.termsOfUse)
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Actions

    private func handlePurchase() async {
        let package: Package?
        switch selectedPlan {
        case .yearly:  package = premiumManager.annualPackage
        case .monthly: package = premiumManager.monthlyPackage
        }

        guard let pkg = package else {
            purchaseError = "Ürün bilgisi yüklenemedi. Lütfen tekrar deneyin."
            return
        }

        do {
            let success = try await premiumManager.purchase(package: pkg)
            if success {
                dismiss()
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func handleRestore() async {
        do {
            try await premiumManager.restorePurchases()
            if premiumManager.isPremium {
                showRestoreSuccess = true
            } else {
                purchaseError = "Aktif abonelik bulunamadı."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}

#Preview {
    PaywallView(trigger: .unlimitedHabits)
}
