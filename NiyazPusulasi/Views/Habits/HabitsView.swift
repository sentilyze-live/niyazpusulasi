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
            ZStack {
                Color.themeDarkBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Date header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("GÖREVLER")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text(dateFormatter.string(from: viewModel.currentDate).uppercased())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .tracking(1)
                                    .foregroundStyle(Color.themeGold)
                            }
                            Spacer()
                            
                            // Done counter
                            let doneCount = viewModel.habits.filter { $0.isDone }.count
                            let totalCount = viewModel.habits.count
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text("\(doneCount)/\(totalCount)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.themeCyan)
                                )
                        }
                        .padding(.top, 8)
                        
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
        VStack(spacing: 12) {
            if viewModel.habits.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 36))
                        .foregroundStyle(.gray)
                    Text("Henüz görev eklenmemiş")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
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
                        Text("\(viewModel.habits.count)/\(PremiumFeature.freeHabitLimit) ücretsiz görev")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func habitRow(_ habit: HabitsViewModel.HabitItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.toggleHabit(habit)
            }
        } label: {
            HStack(spacing: 16) {
                // Custom Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(habit.isDone ? Color.themeGold : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .background(habit.isDone ? Color.themeGold.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    if habit.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.themeGold)
                            .transition(.scale)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(habit.isDone ? .gray : .white)
                        .strikethrough(habit.isDone, color: .gray)
                }

                Spacer()

                if habit.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(Color.themeGold)
                        Text("\(habit.streak)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding()
            .glassPanel(cornerRadius: 16, opacity: 0.4)
            .shadow(color: habit.isDone ? .clear : Color.themeCyan.opacity(0.05), radius: 5, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(habit.isDone ? Color.themeGold.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Habit Sheet

    private var addHabitSheet: some View {
        NavigationStack {
            Form {
                TextField("Alışkanlık adı", text: $viewModel.newHabitTitle)
                    .textInputAutocapitalization(.sentences)
                    .onChange(of: viewModel.newHabitTitle) { _, _ in
                        viewModel.clearValidationError()
                    }
                
                if let error = viewModel.validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Yeni Alışkanlık")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        viewModel.showAddHabit = false
                        viewModel.newHabitTitle = ""
                        viewModel.clearValidationError()
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

}
#Preview {
    HabitsView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
