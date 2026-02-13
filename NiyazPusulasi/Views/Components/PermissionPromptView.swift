import SwiftUI

/// Reusable pre-permission prompt shown before system permission dialogs.
struct PermissionPromptView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String
    let onAllow: () -> Void
    var onSkip: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.blue)
                .padding(.bottom, 8)

            Text(title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onAllow) {
                    Text(buttonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                if let onSkip {
                    Button("Şimdi Değil", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preset Prompts

extension PermissionPromptView {
    /// Pre-permission prompt for location access.
    static func location(onAllow: @escaping () -> Void, onSkip: @escaping () -> Void) -> PermissionPromptView {
        PermissionPromptView(
            icon: "location.fill",
            title: "Konum İzni",
            message: "Namaz vakitlerini doğru hesaplayabilmek için konumunuza ihtiyacımız var. Konumunuz yalnızca bu amaçla kullanılır.",
            buttonTitle: "Konuma İzin Ver",
            onAllow: onAllow,
            onSkip: onSkip
        )
    }

    /// Pre-permission prompt for notifications.
    static func notifications(onAllow: @escaping () -> Void, onSkip: @escaping () -> Void) -> PermissionPromptView {
        PermissionPromptView(
            icon: "bell.fill",
            title: "Bildirim İzni",
            message: "Namaz vakitlerinde, imsak ve iftar zamanlarında sizi bilgilendirmek için bildirimlere ihtiyacımız var.",
            buttonTitle: "Bildirimlere İzin Ver",
            onAllow: onAllow,
            onSkip: onSkip
        )
    }
}

#Preview {
    PermissionPromptView.location(
        onAllow: {},
        onSkip: {}
    )
}
