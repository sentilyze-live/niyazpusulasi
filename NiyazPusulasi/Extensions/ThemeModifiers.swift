import SwiftUI

extension Font {
    /// Headings using Outfit font
    static func outfit(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Fallback to system if custom font fails to load,
        // but in a real app this would use Font.custom("Outfit-...", size: size)
        return .system(size: size, weight: weight, design: .rounded)
    }
    
    /// Body text using Inter font
    static func inter(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
}

// Global UI Modifiers
struct GlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(opacity))
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct GlowingTextModifier: ViewModifier {
    var color: Color
    var intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: intensity, x: 0, y: 0)
    }
}

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RadialGradient(
                    gradient: Gradient(colors: [Color.themeCyan.opacity(0.15), Color.themeDarkBg]),
                    center: .center,
                    startRadius: 10,
                    endRadius: (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.height ?? 800 * 0.7
                )
                .ignoresSafeArea()
            )
            .preferredColorScheme(.dark)
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 24, opacity: Double = 1.0) -> some View {
        modifier(GlassmorphismModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
    
    func glowingText(color: Color = .themeGold, intensity: CGFloat = 10) -> some View {
        modifier(GlowingTextModifier(color: color, intensity: intensity))
    }
    
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}
