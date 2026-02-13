import SwiftUI

/// Displays the Qibla direction as a compass bearing.
struct QiblaView: View {
    let direction: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "safari")
                    .foregroundStyle(.orange)
                Text("Kıble Yönü")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.1f°", direction))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            // Simple compass indicator
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 80)

                // Cardinal directions
                ForEach(["K", "D", "G", "B"], id: \.self) { label in
                    let index = ["K", "D", "G", "B"].firstIndex(of: label)!
                    let angle = Double(index) * 90.0

                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .offset(y: -45)
                        .rotationEffect(.degrees(angle))
                }

                // Qibla direction arrow
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange)
                    .offset(y: -28)
                    .rotationEffect(.degrees(direction))

                // Center dot
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    QiblaView(direction: 158.5)
        .padding()
}
