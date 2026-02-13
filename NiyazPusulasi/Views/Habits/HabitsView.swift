import SwiftUI

struct HabitsView: View {
    @StateObject private var viewModel = HabitsViewModel()
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showPaywall = false
    @State private var paywallTrigger: PremiumFeature = .unlimitedHabits

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date header
                    Text(dateFormatter.string(from: viewModel.currentDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Habit checklist
                    habitChecklistSection

                    // Monthly heatmap (premium gated)
                    if premiumManager.hasAccess(to: .heatmapView) {
                        HeatmapView(data: viewModel.heatmapData, currentDate: viewModel.currentDate)
                    } else {
                        premiumHeatmapTeaser
                    }

                    // Daily reflection
                    ReflectionView(
                        rating: $viewModel.reflectionRating,
                        note: $viewModel.reflectionNote,
                        onSave: viewModel.saveReflection
                    )
                }
                .padding()
            }
            .navigationTitle("Alışkanlıklar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        handleAddHabit()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddHabit) {
                addHabitSheet
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: paywallTrigger)
            }
        }
        .onAppear { viewModel.onAppear() }
    }

    // MARK: - Add Habit with Premium Gate

    private func handleAddHabit() {
        let currentCount = viewModel.habits.count
        if currentCount >= PremiumFeature.freeHabitLimit && !premiumManager.hasAccess(to: .unlimitedHabits) {
            paywallTrigger = .unlimitedHabits
            showPaywall = true
        } else {
            viewModel.showAddHabit = true
        }
    }

    // MARK: - Heatmap Teaser

    private var premiumHeatmapTeaser: some View {
        Button {
            paywallTrigger = .heatmapView
            showPaywall = true
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Text("Aylık Isı Haritası")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text("Premium")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Blurred preview
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.green.opacity(Double.random(in: 0.1...0.8)))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .blur(radius: 3)
                .frame(height: 30)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Checklist

    private var habitChecklistSection: some View {
        VStack(spacing: 2) {
            if viewModel.habits.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Henüz alışkanlık eklenmemiş")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(viewModel.habits) { habit in
                    habitRow(habit)
                }

                // Free tier indicator
                if !premiumManager.isPremium {
                    HStack {
                        Spacer()
                        Text("\(viewModel.habits.count)/\(PremiumFeature.freeHabitLimit) ücretsiz alışkanlık")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func habitRow(_ habit: HabitsViewModel.HabitItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.toggleHabit(habit)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: habit.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(habit.isDone ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))

                Text(habit.title)
                    .font(.body)
                    .foregroundStyle(habit.isDone ? .secondary : .primary)
                    .strikethrough(habit.isDone)

                Spacer()

                if habit.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("\(habit.streak)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Habit Sheet

    private var addHabitSheet: some View {
        NavigationStack {
            Form {
                TextField("Alışkanlık adı", text: $viewModel.newHabitTitle)
                    .textInputAutocapitalization(.sentences)
            }
            .navigationTitle("Yeni Alışkanlık")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        viewModel.showAddHabit = false
                        viewModel.newHabitTitle = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        viewModel.addHabit()
                    }
                    .disabled(viewModel.newHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    HabitsView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
