import Foundation
import CloudKit
import Combine

/// Manages iCloud synchronization for user data.
/// Requires CloudKit container configuration in Apple Developer Portal.
@MainActor
final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isCloudAvailable = false

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    // Record types
    private let settingsRecordType = "AppSettings"
    private let habitsRecordType = "Habits"

    private init() {
        container = CKContainer(identifier: "iCloud.com.niyazpusulasi.app")
        privateDatabase = container.privateCloudDatabase

        checkCloudStatus()
    }
    
    // MARK: - Cloud Status
    
    func checkCloudStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isCloudAvailable = true
                case .noAccount:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud hesabı bulunamadı"
                case .restricted:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud erişimi kısıtlı"
                case .couldNotDetermine:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud durumu belirlenemedi"
                case .temporarilyUnavailable:
                    self?.isCloudAvailable = false
                    self?.syncError = "iCloud geçici olarak kullanılamıyor"
                @unknown default:
                    self?.isCloudAvailable = false
                }
            }
        }
    }
    
    // MARK: - Sync Settings
    
    func syncSettings() async {
        guard isCloudAvailable else {
            await MainActor.run {
                syncError = "iCloud kullanılamıyor"
            }
            return
        }
        
        await MainActor.run { isSyncing = true }
        
        do {
            // Upload current settings
            let record = try await uploadSettings()
            
            // Download latest settings from cloud
            if let cloudSettings = try await downloadSettings() {
                await mergeSettings(cloudSettings)
            }
            
            await MainActor.run {
                lastSyncDate = Date()
                syncError = nil
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                syncError = error.localizedDescription
                isSyncing = false
            }
        }
    }
    
    private func uploadSettings() async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: "user_settings")
        let record = CKRecord(recordType: settingsRecordType, recordID: recordID)
        
        let settings = settingsManager.settings
        if let data = try? JSONEncoder().encode(settings) {
            record["data"] = data
        }
        record["updatedAt"] = Date()
        record["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        return try await privateDatabase.save(record)
    }
    
    private func downloadSettings() async throws -> AppSettings? {
        let recordID = CKRecord.ID(recordName: "user_settings")
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            if let data = record["data"] as? Data,
               let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
                return settings
            }
        } catch let error as CKError where error.code == .unknownItem {
            // No cloud data yet
            return nil
        }
        
        return nil
    }
    
    @MainActor
    private func mergeSettings(_ cloudSettings: AppSettings) {
        // Simple merge: use cloud version if it's newer
        // In a real app, you'd want more sophisticated conflict resolution
        let localModified = settingsManager.settings
        
        // For now, just update settings if cloud is available
        // Users can manually choose to use local or cloud in settings
        settingsManager.settings = cloudSettings
    }
    
    // MARK: - Delete Cloud Data
    
    func deleteAllCloudData() async throws {
        let recordID = CKRecord.ID(recordName: "user_settings")
        
        do {
            try await privateDatabase.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, nothing to delete
        }
    }
    
    // MARK: - Subscriptions (for push notifications on changes)
    
    func setupSubscription() {
        let subscriptionID = "settings-changes"
        
        let subscription = CKQuerySubscription(
            recordType: settingsRecordType,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        privateDatabase.save(subscription) { _, error in
            if let error {
                print("Failed to save subscription: \(error)")
            }
        }
    }
}
