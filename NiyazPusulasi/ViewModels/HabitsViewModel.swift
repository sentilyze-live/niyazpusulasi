import Foundation
import Combine

/// ViewModel for the Habits tab — manages checklist, streaks, and reflections.
@MainActor
final class HabitsViewModel: ObservableObject {
    @Published var habits: [HabitItem] = []
    @Published var heatmapData: [Int: Double] = [:]
    @Published var currentDate = Date()
    @Published var reflectionRating: Int = 5
    @Published var reflectionNote: String = ""
    @Published var showAddHabit = false
    @Published var newHabitTitle = ""

    private let habitService = HabitService.shared

    /// A view-friendly wrapper around Habit + its daily state.
    struct HabitItem: Identifiable {
        let id: UUID
        let title: String
        var isDone: Bool
        var streak: Int
    }

    // MARK: - Public API

    func onAppear() {
        habitService.seedDefaultHabitsIfNeeded()
        refresh()
    }

    func refresh() {
        loadHabits()
        loadHeatmap()
        loadReflection()
    }

    func toggleHabit(_ item: HabitItem) {
        habitService.toggleLog(habitId: item.id, date: currentDate)
        loadHabits() // Refresh state
    }

    func addHabit() {
        let title = newHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        habitService.createHabit(title: title)
        newHabitTitle = ""
        showAddHabit = false
        loadHabits()
    }

    func deleteHabit(at offsets: IndexSet) {
        let allHabits = habitService.fetchActiveHabits()
        for index in offsets {
            guard index < allHabits.count else { continue }
            habitService.deleteHabit(allHabits[index])
        }
        loadHabits()
    }

    func saveReflection() {
        let note = reflectionNote.trimmingCharacters(in: .whitespacesAndNewlines)
        habitService.saveReflection(
            date: currentDate,
            rating: reflectionRating,
            note: note.isEmpty ? nil : note
        )
    }

    // MARK: - Private

    private func loadHabits() {
        let activeHabits = habitService.fetchActiveHabits()
        habits = activeHabits.map { habit in
            HabitItem(
                id: habit.safeId,
                title: habit.safeTitle,
                isDone: habitService.isHabitDone(habitId: habit.safeId, date: currentDate),
                streak: habitService.streakCount(for: habit.safeId)
            )
        }
    }

    private func loadHeatmap() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        heatmapData = habitService.monthlyHeatmap(year: year, month: month)
    }

    private func loadReflection() {
        if let reflection = habitService.fetchReflection(for: currentDate) {
            reflectionRating = Int(reflection.rating)
            reflectionNote = reflection.note ?? ""
        } else {
            reflectionRating = 5
            reflectionNote = ""
        }
    }
}
