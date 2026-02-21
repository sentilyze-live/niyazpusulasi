import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @StateObject private var notificationManager = NotificationManager.shared

    private var reminderSettings: Binding<ReminderSettings> {
        $settingsManager.settings.reminderSettings
    }

    var body: some View {
        List {
            // Permission status
            if notificationManager.authorizationStatus == .notDetermined {
                Section {
                    Button("Bildirim İzni Ver") {
                        Task {
                            _ = await notificationManager.requestPermission()
                        }
                    }
                }
            } else if notificationManager.authorizationStatus == .denied {
                Section {
                    Label("Bildirimler kapalı. Ayarlardan açabilirsiniz.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Button("Ayarları Aç") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            // Prayer notifications
            Section("Namaz Bildirimleri") {
                ForEach(PrayerName.obligatory) { prayer in
                    Toggle(prayer.localizedName, isOn: prayerEnabledBinding(for: prayer))

                    if settingsManager.reminderSettings.prayerEnabled[prayer.rawValue] == true {
                        Picker("Bildirim zamanı", selection: prayerOffsetBinding(for: prayer)) {
                            Text("Vakit girdiğinde").tag(0)
                            Text("5 dk önce").tag(-5)
                            Text("10 dk önce").tag(-10)
                            Text("15 dk önce").tag(-15)
                            Text("30 dk önce").tag(-30)
                        }
                        .font(.caption)
                    }
                }
            }

            // Ramadan notifications
            Section("Ramazan Bildirimleri") {
                Toggle("İmsak Hatırlatması", isOn: reminderSettings.imsakEnabled)

                if settingsManager.reminderSettings.imsakEnabled {
                    Picker("İmsak bildirimi", selection: reminderSettings.imsakOffsetMinutes) {
                        Text("10 dk önce").tag(10)
                        Text("15 dk önce").tag(15)
                        Text("30 dk önce").tag(30)
                        Text("45 dk önce").tag(45)
                        Text("60 dk önce").tag(60)
                    }
                }

                Toggle("İftar Hatırlatması", isOn: reminderSettings.iftarEnabled)

                if settingsManager.reminderSettings.iftarEnabled {
                    Picker("İftar bildirimi", selection: reminderSettings.iftarOffsetMinutes) {
                        Text("10 dk önce").tag(10)
                        Text("15 dk önce").tag(15)
                        Text("30 dk önce").tag(30)
                        Text("45 dk önce").tag(45)
                        Text("60 dk önce").tag(60)
                    }
                }
            }

            // Alarm mode
            Section {
                Toggle("Alarm Modu", isOn: reminderSettings.alarmModeEnabled)
            } header: {
                Text("Alarm")
            } footer: {
                Text("Uygulama açıkken tam ekran alarm gösterir ve ezan sesi çalar.")
            }

            // Coverage info
            Section {
                HStack {
                    Text("Kapsam")
                    Spacer()
                    Text("\(settingsManager.reminderSettings.coverageDays) gün")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Günlük bildirim")
                    Spacer()
                    Text("\(settingsManager.reminderSettings.enabledSlotsPerDay) adet")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Bildirim Bütçesi")
            } footer: {
                Text("iOS en fazla 64 bekleyen bildirime izin verir. Daha az bildirim seçmek daha fazla gün kapsamı sağlar.")
            }
        }
        .navigationTitle("Bildirim Ayarları")
        .onChange(of: settingsManager.reminderSettings) { _, _ in
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
                await notificationManager.rescheduleAllNotifications()
            }
        }
    }

    // MARK: - Bindings

    private func prayerEnabledBinding(for prayer: PrayerName) -> Binding<Bool> {
        Binding(
            get: { settingsManager.reminderSettings.prayerEnabled[prayer.rawValue] ?? false },
            set: { settingsManager.settings.reminderSettings.prayerEnabled[prayer.rawValue] = $0 }
        )
    }

    private func prayerOffsetBinding(for prayer: PrayerName) -> Binding<Int> {
        Binding(
            get: { settingsManager.reminderSettings.prayerOffsetMinutes[prayer.rawValue] ?? 0 },
            set: { settingsManager.settings.reminderSettings.prayerOffsetMinutes[prayer.rawValue] = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .environmentObject(SettingsManager.shared)
    }
}
