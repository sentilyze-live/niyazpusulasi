import SwiftUI

/// Daily spiritual reflection with rating and optional note.
struct ReflectionView: View {
    @Binding var rating: Int
    @Binding var note: String
    let onSave: () -> Void

    @FocusState private var isNoteFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Günün Özeti")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Bugün maneviyatını nasıl hissediyorsun?")
                .font(.caption)
                .foregroundStyle(.gray)

            // Rating Emojis
            HStack(spacing: 24) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            rating = value * 2 // map 1-5 to 1-10 rating
                            onSave()
                        }
                    } label: {
                        Text(emojiFor(rating: value * 2))
                            .font(.system(size: rating >= value * 2 - 1 && rating <= value * 2 + 1 ? 36 : 24))
                            .opacity(rating >= value * 2 - 1 && rating <= value * 2 + 1 ? 1.0 : 0.4)
                            .shadow(color: rating >= value * 2 - 1 ? Color.themeCyan.opacity(0.3) : .clear, radius: 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            // Note
            TextField("Bugün neler hissettin? (Opsiyonel)", text: $note, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(3...6)
                .padding(12)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .focused($isNoteFocused)
                .onSubmit {
                    onSave()
                }
                .onChange(of: isNoteFocused) { _, focused in
                    if !focused { onSave() }
                }

            Button {
                isNoteFocused = false
                onSave()
            } label: {
                Text("Kaydet")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themeGold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }
        .padding(20)
        .glassPanel(cornerRadius: 24, opacity: 0.5)
    }

    private func emojiFor(rating: Int) -> String {
        switch rating {
        case 1...2: return "😔"
        case 3...4: return "😕"
        case 5...6: return "😐"
        case 7...8: return "🙂"
        case 9...10: return "😇"
        default: return "😐"
        }
    }

    private var ratingColor: Color {
        switch rating {
        case 1...3:  return .red
        case 4...5:  return .orange
        case 6...7:  return .yellow
        case 8...9:  return .green
        case 10:     return .teal
        default:     return .secondary
        }
    }
}

#Preview {
    ReflectionView(
        rating: .constant(7),
        note: .constant("Güzel bir gün geçirdim"),
        onSave: {}
    )
    .padding()
}
