import Foundation
import RevenueCat

private enum Config {
    // MARK: - RevenueCat API Key
    // ⚠️ BEFORE SUBMITTING TO APP STORE:
    //    1. RevenueCat Dashboard → Apps & providers → Add new app (App Store)
    //    2. App Store Connect app'ini bağla
    //    3. Oluşan "appl_..." prefix'li SDK key ile aşağıdakini değiştir
    static let revenueCatAPIKey = "appl_tV1VFWFwXeDPPwweVcyRXUGakFZ"
}

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

    override private init() {
        super.init()
    }

    // MARK: - Configuration

    /// Call once in App init.
    func configure() {
        Purchases.logLevel = .warn
        Purchases.configure(
            with: .init(withAPIKey: Config.revenueCatAPIKey)
                .with(storeKitVersion: .storeKit2)
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
    // Widgets
    case lockScreenWidgets
    case allHomeScreenWidgets
    case ramadanWidget

    // Habits
    case unlimitedHabits
    case heatmapView

    // Customization
    case premiumThemes
    case customAppIcons
    case customNotificationSounds

    // Spiritual Tools
    case prayerTracking
    case tasbeehCounter
    case duaCollection

    // Sync (coming in a future update)
    // case iCloudSync

    /// Features available in the free tier.
    var isFreeFeature: Bool {
        // All features require premium
        return false
    }

    /// Maximum habits allowed in free tier.
    static let freeHabitLimit = 3

    /// Localized title for paywall display.
    var paywallTitle: String {
        switch self {
        case .lockScreenWidgets:          return "premium_lockscreen_widgets_title".localized
        case .allHomeScreenWidgets:       return "premium_all_widgets_title".localized
        case .ramadanWidget:              return "premium_ramadan_widget_title".localized
        case .unlimitedHabits:            return "premium_unlimited_habits_title".localized
        case .heatmapView:                return "premium_heatmap_title".localized
        case .premiumThemes:              return "premium_themes_title".localized
        case .prayerTracking:             return "premium_prayer_tracking_title".localized
        case .tasbeehCounter:             return "premium_tasbeeh_title".localized
        case .duaCollection:              return "premium_dua_title".localized
        case .customAppIcons:             return "premium_custom_icons_title".localized
        case .customNotificationSounds:   return "premium_sounds_title".localized
        }
    }

    var paywallDescription: String {
        switch self {
        case .lockScreenWidgets:          return "premium_lockscreen_widgets_desc".localized
        case .allHomeScreenWidgets:       return "premium_all_widgets_desc".localized
        case .ramadanWidget:              return "premium_ramadan_widget_desc".localized
        case .unlimitedHabits:            return "premium_unlimited_habits_desc".localized
        case .heatmapView:                return "premium_heatmap_desc".localized
        case .premiumThemes:              return "premium_themes_desc".localized
        case .prayerTracking:             return "premium_prayer_tracking_desc".localized
        case .tasbeehCounter:             return "premium_tasbeeh_desc".localized
        case .duaCollection:              return "premium_dua_desc".localized
        case .customAppIcons:             return "premium_custom_icons_description".localized
        case .customNotificationSounds:   return "premium_sounds_description".localized
        }
    }

    var iconName: String {
        switch self {
        case .lockScreenWidgets:          return "lock.rectangle.stack.fill"
        case .allHomeScreenWidgets:       return "rectangle.3.group.fill"
        case .ramadanWidget:              return "moon.fill"
        case .unlimitedHabits:            return "infinity"
        case .heatmapView:                return "square.grid.3x3.fill"
        case .premiumThemes:              return "paintpalette.fill"
        case .prayerTracking:             return "checkmark.seal.fill"
        case .tasbeehCounter:             return "circle.dotted"
        case .duaCollection:              return "book.fill"
        case .customAppIcons:             return "app.badge.fill"
        case .customNotificationSounds:   return "speaker.wave.3.fill"
        }
    }
}
