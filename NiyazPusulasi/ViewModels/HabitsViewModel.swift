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
    @Published var validationError: String?
    
    private let habitService = HabitService.shared
    
    // MARK: - Validation Constants
    private let minTitleLength = 2
    private let maxTitleLength = 50
    
    /// Validates habit title input
    func validateHabitTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return "Başlık boş olamaz"
        }
        
        if trimmed.count < minTitleLength {
            return "Başlık en az \(minTitleLength) karakter olmalı"
        }
        
        if trimmed.count > maxTitleLength {
            return "Başlık en fazla \(maxTitleLength) karakter olmalı"
        }
        
        // Check for invalid characters
        let invalidChars = CharacterSet(charactersIn: "<>{}[]\\^~")
        if trimmed.rangeOfCharacter(from: invalidChars) != nil {
            return "Özel karakterler kullanılamaz"
        }
        
        return nil
    }

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
        
        // Validate
        if let error = validateHabitTitle(title) {
            validationError = error
            return
        }
        
        validationError = nil
        habitService.createHabit(title: title)
        newHabitTitle = ""
        showAddHabit = false
        loadHabits()
    }
    
    func clearValidationError() {
        validationError = nil
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
