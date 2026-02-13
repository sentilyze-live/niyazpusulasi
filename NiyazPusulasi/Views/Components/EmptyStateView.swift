import SwiftUI

/// Reusable empty state placeholder.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    VStack(spacing: 40) {
        EmptyStateView(
            icon: "clock",
            title: "Veri Bulunamadı",
            message: "Namaz vakitleri henüz yüklenemedi. Lütfen internet bağlantınızı kontrol edin.",
            actionTitle: "Tekrar Dene",
            action: {}
        )

        EmptyStateView(
            icon: "moon.stars",
            title: "Ramazan Dışında",
            message: "Ramazan imsakiyesi yalnızca Ramazan ayında görüntülenir."
        )
    }
}
