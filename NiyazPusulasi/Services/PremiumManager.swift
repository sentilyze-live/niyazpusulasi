import Foundation
import RevenueCat

/// Manages premium subscription state and feature gating.
/// Single source of truth for "is user premium?" across the app.
@MainActor
final class PremiumManager: NSObject, ObservableObject {
    static let shared = PremiumManager()

    @Published var isPremium: Bool = false
    @Published var currentOffering: Offering?
    @Published var activeSubscription: String?
    @Published var expirationDate: Date?
    @Published var isLoading: Bool = false

    // MARK: - Product Identifiers

    static let monthlyProductId = "niyaz_premium_monthly"
    static let yearlyProductId = "niyaz_premium_yearly"
    static let entitlementId = "premium"

    // MARK: - Offerings

    static let defaultOfferingId = "default"
    static let ramadanOfferingId = "ramazan_campaign"

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    /// Call once in App init.
    func configure() {
        Purchases.logLevel = .warn
        Purchases.configure(
            with: .init(withAPIKey: "test_XOBsZUSCbusCTyQtPePOrMUsJJE")
                .with(usesStoreKit2IfAvailable: true)
        )

        // Listen for subscription changes
        Purchases.shared.delegate = self

        Task {
            await refreshStatus()
            await fetchOfferings()
        }
    }

    // MARK: - Status

    func refreshStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateFromCustomerInfo(customerInfo)
        } catch {
            print("[PremiumManager] Failed to fetch customer info: \(error.localizedDescription)")
        }
    }

    private func updateFromCustomerInfo(_ info: CustomerInfo) {
        let entitlement = info.entitlements[Self.entitlementId]
        isPremium = entitlement?.isActive == true
        activeSubscription = entitlement?.productIdentifier
        expirationDate = entitlement?.expirationDate
    }

    // MARK: - Offerings

    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            print("[PremiumManager] Failed to fetch offerings: \(error.localizedDescription)")
        }
    }

    /// Get the monthly package from current offering.
    var monthlyPackage: Package? {
        currentOffering?.monthly
    }

    /// Get the annual package from current offering.
    var annualPackage: Package? {
        currentOffering?.annual
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await Purchases.shared.purchase(package: package)

        if !result.userCancelled {
            updateFromCustomerInfo(result.customerInfo)
            return true
        }
        return false
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        let customerInfo = try await Purchases.shared.restorePurchases()
        updateFromCustomerInfo(customerInfo)
    }

    // MARK: - Feature Gating

    /// Check if a specific premium feature is accessible.
    func hasAccess(to feature: PremiumFeature) -> Bool {
        if isPremium { return true }
        return feature.isFreeFeature
    }
}

// MARK: - PurchasesDelegate

extension PremiumManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateFromCustomerInfo(customerInfo)
        }
    }
}

// MARK: - Premium Feature Definitions

/// All features that can be gated behind premium.
enum PremiumFeature: String, CaseIterable {
    // Notifications
    case customAdhanSounds
    case advancedNotificationOffsets

    // Widgets
    case lockScreenWidgets
    case allHomeScreenWidgets
    case ramadanWidget

    // Habits
    case unlimitedHabits
    case detailedHabitStats
    case heatmapView

    // Customization
    case premiumThemes
    case customAppIcon

    // New premium features
    case prayerTracking
    case tasbeehCounter
    case duaCollection

    // Sync
    case iCloudSync

    // General
    case adFreeExperience
    case prioritySupport

    /// Features available in the free tier.
    var isFreeFeature: Bool {
        switch self {
        case .adFreeExperience,
             .customAdhanSounds,
             .advancedNotificationOffsets,
             .lockScreenWidgets,
             .allHomeScreenWidgets,
             .ramadanWidget,
             .unlimitedHabits,
             .detailedHabitStats,
             .heatmapView,
             .premiumThemes,
             .customAppIcon,
             .prayerTracking,
             .tasbeehCounter,
             .duaCollection,
             .iCloudSync,
             .prioritySupport:
            return false
        }
    }

    /// Maximum habits allowed in free tier.
    static let freeHabitLimit = 3

    /// Turkish description for paywall display.
    var paywallTitle: String {
        switch self {
        case .customAdhanSounds:          return "Özel Ezan Sesleri"
        case .advancedNotificationOffsets: return "Gelişmiş Bildirimler"
        case .lockScreenWidgets:          return "Kilit Ekranı Widget'ları"
        case .allHomeScreenWidgets:       return "Tüm Widget'lar"
        case .ramadanWidget:              return "Ramazan Widget'ı"
        case .unlimitedHabits:            return "Sınırsız Alışkanlık"
        case .detailedHabitStats:         return "Detaylı İstatistikler"
        case .heatmapView:               return "Isı Haritası"
        case .premiumThemes:              return "Premium Temalar"
        case .customAppIcon:              return "Özel Uygulama İkonu"
        case .prayerTracking:             return "Namaz Takibi"
        case .tasbeehCounter:             return "Tesbih Sayacı"
        case .duaCollection:              return "Dua Koleksiyonu"
        case .iCloudSync:                 return "iCloud Senkronizasyonu"
        case .adFreeExperience:           return "Reklamsız Deneyim"
        case .prioritySupport:            return "Öncelikli Destek"
        }
    }

    var paywallDescription: String {
        switch self {
        case .customAdhanSounds:          return "10+ müezzin sesi ile namazına hazırlan"
        case .advancedNotificationOffsets: return "Bildirimleri tam istediğin gibi ayarla"
        case .lockScreenWidgets:          return "Kilit ekranında namaz vakitlerini gör"
        case .allHomeScreenWidgets:       return "Ana ekranında tüm widget seçenekleri"
        case .ramadanWidget:              return "Ramazan imsak ve iftar widget'ı"
        case .unlimitedHabits:            return "Sınırsız alışkanlık ile hedeflerine ulaş"
        case .detailedHabitStats:         return "Haftalık, aylık, yıllık gelişim grafikleri"
        case .heatmapView:               return "Aylık performansını renkli harita ile gör"
        case .premiumThemes:              return "Kişiselleştirilmiş tema ile uygulamanı güzelleştir"
        case .customAppIcon:              return "5+ alternatif ikon ile uygulamanı kişiselleştir"
        case .prayerTracking:             return "Günlük kıldığın namazları takip et"
        case .tasbeehCounter:             return "Haptic feedback ile dijital tesbih çek"
        case .duaCollection:              return "Günlük dua önerileri ve kategorize arşiv"
        case .iCloudSync:                 return "Verilerini tüm cihazlarında senkronize et"
        case .adFreeExperience:           return "Tüm uygulamayı reklamsız kullan"
        case .prioritySupport:            return "24 saat içinde yanıt garantisi"
        }
    }

    var iconName: String {
        switch self {
        case .customAdhanSounds:          return "speaker.wave.3.fill"
        case .advancedNotificationOffsets: return "bell.badge.fill"
        case .lockScreenWidgets:          return "lock.rectangle.stack.fill"
        case .allHomeScreenWidgets:       return "rectangle.3.group.fill"
        case .ramadanWidget:              return "moon.fill"
        case .unlimitedHabits:            return "infinity"
        case .detailedHabitStats:         return "chart.bar.fill"
        case .heatmapView:               return "square.grid.3x3.fill"
        case .premiumThemes:              return "paintpalette.fill"
        case .customAppIcon:              return "app.badge.fill"
        case .prayerTracking:             return "checkmark.seal.fill"
        case .tasbeehCounter:             return "circle.dotted"
        case .duaCollection:              return "book.fill"
        case .iCloudSync:                 return "icloud.fill"
        case .adFreeExperience:           return "nosign"
        case .prioritySupport:            return "person.fill.questionmark"
        }
    }
}
