import SwiftUI

/// Manages the active premium theme and provides reactive color/gradient properties.
/// Injected as EnvironmentObject to all views for app-wide theming.
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var activeTheme: PremiumTheme?

    private init() {}

    func setTheme(_ theme: PremiumTheme?) {
        withAnimation(.easeInOut(duration: 0.3)) {
            activeTheme = theme
        }
    }

    var accentColor: Color {
        activeTheme?.accentColor ?? .blue
    }

    var gradient: LinearGradient {
        let colors = activeTheme?.gradientColors ?? [Color.blue, Color.cyan]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var radialGradient: RadialGradient {
        let colors = activeTheme?.gradientColors ?? [Color.blue, Color.cyan]
        return RadialGradient(
            colors: colors,
            center: .center,
            startRadius: 5,
            endRadius: 500
        )
    }
}
