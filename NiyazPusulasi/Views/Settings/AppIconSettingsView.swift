import SwiftUI

struct AppIconSettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var showPaywall = false

    let icons: [AppIconInfo] = [
        AppIconInfo(name: nil, displayKey: "app_icon_default", isFree: true),
        AppIconInfo(name: "Minimalist", displayKey: "app_icon_minimalist", isFree: true),
        AppIconInfo(name: "Ramadan", displayKey: "app_icon_ramadan", isFree: false),
        AppIconInfo(name: "Tesbih", displayKey: "app_icon_tesbih", isFree: false)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(icons) { icon in
                    AppIconCard(
                        icon: icon,
                        isSelected: settingsManager.settings.selectedAppIcon == icon.name,
                        onTap: { selectIcon(icon) }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("app_icon_settings_title".localized)
        .sheet(isPresented: $showPaywall) {
            PaywallView(trigger: .customAppIcons)
        }
    }

    private func selectIcon(_ icon: AppIconInfo) {
        guard icon.isFree || premiumManager.hasAccess(to: .customAppIcons) else {
            showPaywall = true
            return
        }

        UIApplication.shared.setAlternateIconName(icon.name) { error in
            if error == nil {
                settingsManager.settings.selectedAppIcon = icon.name
            }
        }
    }
}

struct AppIconInfo: Identifiable {
    let id = UUID()
    let name: String?
    let displayKey: String
    let isFree: Bool

    var displayName: String {
        displayKey.localized
    }
}

struct AppIconCard: View {
    let icon: AppIconInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: iconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .background(Color.white.clipShape(Circle()))
                }

                if !icon.isFree {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }

            Text(icon.displayName)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .onTapGesture(perform: onTap)
    }

    private var iconImage: UIImage {
        guard let name = icon.name else {
            return UIImage(named: "AppIcon") ?? UIImage()
        }
        return UIImage(named: name) ?? UIImage()
    }
}
