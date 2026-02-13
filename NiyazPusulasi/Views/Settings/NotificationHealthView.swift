import SwiftUI
import UserNotifications

/// Diagnostic screen showing notification system health.
struct NotificationHealthView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var isLoading = false

    var body: some View {
        List {
            // Authorization Status
            Section("Bildirim Durumu") {
                HStack {
                    Text("Yetkilendirme")
                    Spacer()
                    statusBadge
                }

                HStack {
                    Text("Bekleyen Bildirimler")
                    Spacer()
                    Text("\(notificationManager.pendingCount) / 64")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Kapsam")
                    Spacer()
                    Text("\(notificationManager.coverageDays) gün")
                        .foregroundStyle(.secondary)
                }

                if let lastScheduled = notificationManager.lastScheduledAt {
                    HStack {
                        Text("Son Zamanlama")
                        Spacer()
                        Text(lastScheduled, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Next 5 Scheduled
            Section("Sonraki Bildirimler") {
                if pendingNotifications.isEmpty {
                    Text("Zamanlanmış bildirim yok")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pendingNotifications.prefix(10), id: \.identifier) { request in
                        notificationRow(request)
                    }
                }
            }

            // Actions
            Section {
                Button("Tümünü Yeniden Zamanla") {
                    Task {
                        isLoading = true
                        await notificationManager.rescheduleAllNotifications()
                        await loadPendingNotifications()
                        isLoading = false
                    }
                }
                .disabled(isLoading)

                if notificationManager.authorizationStatus == .denied {
                    Button("Bildirim Ayarlarını Aç") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
        }
        .navigationTitle("Bildirim Sağlığı")
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await notificationManager.refreshAuthorizationStatus()
            await loadPendingNotifications()
        }
    }

    // MARK: - Components

    private var statusBadge: some View {
        Group {
            switch notificationManager.authorizationStatus {
            case .authorized:
                Label("Aktif", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .provisional:
                Label("Geçici", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            case .denied:
                Label("Reddedildi", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .notDetermined:
                Label("Bekliyor", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.secondary)
            @unknown default:
                Label("Bilinmiyor", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }

    private func notificationRow(_ request: UNNotificationRequest) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(request.content.title)
                    .font(.subheadline.weight(.medium))
                Text(request.identifier)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextDate = trigger.nextTriggerDate() {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(nextDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(nextDate, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func loadPendingNotifications() async {
        let pending = await notificationManager.getPendingNotifications()
        self.pendingNotifications = pending.sorted { a, b in
            guard let dateA = (a.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(),
                  let dateB = (b.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else {
                return false
            }
            return dateA < dateB
        }
    }
}

#Preview {
    NavigationStack {
        NotificationHealthView()
    }
}
