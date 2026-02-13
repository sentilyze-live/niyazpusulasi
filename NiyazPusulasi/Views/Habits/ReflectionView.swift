import SwiftUI

/// Daily spiritual reflection with rating and optional note.
struct ReflectionView: View {
    @Binding var rating: Int
    @Binding var note: String
    let onSave: () -> Void

    @FocusState private var isNoteFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Günlük Değerlendirme")
                .font(.subheadline.weight(.medium))

            // Rating
            VStack(spacing: 8) {
                HStack {
                    Text("Ruh halin nasıl?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(rating)/10")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ratingColor)
                }

                // Custom slider with emoji
                HStack(spacing: 0) {
                    ForEach(1...10, id: \.self) { value in
                        Button {
                            withAnimation(.spring(response: 0.2)) {
                                rating = value
                                onSave()
                            }
                        } label: {
                            Circle()
                                .fill(value <= rating ? ratingColor : Color(.tertiarySystemFill))
                                .frame(width: value == rating ? 28 : 20, height: value == rating ? 28 : 20)
                                .animation(.spring(response: 0.2), value: rating)
                        }
                        .buttonStyle(.plain)

                        if value < 10 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Note
            VStack(alignment: .leading, spacing: 4) {
                Text("Not (isteğe bağlı)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Bugün hakkında bir not...", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .lineLimit(3...6)
                    .padding(8)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .focused($isNoteFocused)
                    .onSubmit {
                        onSave()
                    }
                    .onChange(of: isNoteFocused) { _, focused in
                        if !focused { onSave() }
                    }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
