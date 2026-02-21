import SwiftUI

/// Displays the Qibla direction as a compass bearing.
struct QiblaView: View {
    let direction: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.north.line.fill")
                .foregroundStyle(Color.themeCyan)
                .font(.system(size: 16, weight: .bold))
            
            Text("Kıble Yönü")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(String(format: "%.0f°", direction))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.themeGold)
                
                Image(systemName: "safari.fill")
                    .rotationEffect(.degrees(direction - 45)) // Safari icon points 45deg by default
                    .foregroundStyle(Color.themeGold)
            }
        }
        .padding()
        .glassPanel(cornerRadius: 20, opacity: 0.5)
    }
}

#Preview {
    QiblaView(direction: 153.0)
        .padding()
        .appBackground()
}
