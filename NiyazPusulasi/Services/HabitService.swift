import Foundation
import CoreData

/// CRUD operations for habits, logs, and reflections.
final class HabitService {
    static let shared = HabitService()

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    private init() {}

    // MARK: - Habits

    func createHabit(title: String) {
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.title = title
        habit.isActive = true
        habit.sortOrder = Int16(fetchActiveHabits().count)
        habit.createdAt = Date()
        persistence.save()
    }

    func fetchActiveHabits() -> [Habit] {
        let request = Habit.fetchAllActive()
        return (try? context.fetch(request)) ?? []
    }

    func fetchAllHabits() -> [Habit] {
        let request = Habit.fetchAll()
        return (try? context.fetch(request)) ?? []
    }

    func deleteHabit(_ habit: Habit) {
        context.delete(habit)
        persistence.save()
    }

    func toggleHabitActive(_ habit: Habit) {
        habit.isActive.toggle()
        persistence.save()
    }

    /// Seeds default habits if none exist.
    func seedDefaultHabitsIfNeeded() {
        guard fetchAllHabits().isEmpty else { return }

        let defaults = [
            "Namaz kıldım",
            "Kur'an okudum",
            "Zikir çektim",
            "Sadaka verdim",
            "Dua ettim"
        ]

        for (index, title) in defaults.enumerated() {
            let habit = Habit(context: context)
            habit.id = UUID()
            habit.title = title
            habit.isActive = true
            habit.sortOrder = Int16(index)
            habit.createdAt = Date()
        }

        persistence.save()
    }

    // MARK: - Habit Logs

    func toggleLog(habitId: UUID, date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Check if log exists
        let request = NSFetchRequest<HabitLog>(entityName: "HabitLog")
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        request.predicate = NSPredicate(
            format: "habitId == %@ AND date >= %@ AND date < %@",
            habitId as CVarArg, startOfDay as NSDate, endOfDay as NSDate
        )

        if let existing = (try? context.fetch(request))?.first {
            existing.isDone.toggle()
        } else {
            let log = HabitLog(context: context)
            log.id = UUID()
            log.date = startOfDay
            log.habitId = habitId
            log.isDone = true
        }

        persistence.save()
    }

    func isHabitDone(habitId: UUID, date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request = NSFetchRequest<HabitLog>(entityName: "HabitLog")
        request.predicate = NSPredicate(
            format: "habitId == %@ AND date >= %@ AND date < %@ AND isDone == YES",
            habitId as CVarArg, startOfDay as NSDate, endOfDay as NSDate
        )

        return ((try? context.count(for: request)) ?? 0) > 0
    }

    func logsForDate(_ date: Date) -> [HabitLog] {
        let request = HabitLog.fetchForDate(date)
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Streaks

    /// Calculates current consecutive-day streak for a habit.
    func streakCount(for habitId: UUID) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Check if today is done, if not start from yesterday
        if !isHabitDone(habitId: habitId, date: checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                return 0
            }
            checkDate = yesterday
        }

        while isHabitDone(habitId: habitId, date: checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }

        return streak
    }

    // MARK: - Heatmap Data

    /// Returns completion percentages for each day of a month.
    /// Key: day of month (1-31), Value: completion percentage (0.0-1.0)
    func monthlyHeatmap(year: Int, month: Int) -> [Int: Double] {
        let request = HabitLog.fetchForMonth(year: year, month: month)
        let logs = (try? context.fetch(request)) ?? []
        let activeHabitCount = fetchActiveHabits().count

        guard activeHabitCount > 0 else { return [:] }

        let calendar = Calendar.current
        var heatmap: [Int: Double] = [:]

        // Group logs by day
        let grouped = Dictionary(grouping: logs) { log in
            calendar.component(.day, from: log.date ?? Date())
        }

        for (day, dayLogs) in grouped {
            let doneCount = dayLogs.filter { $0.isDone }.count
            heatmap[day] = Double(doneCount) / Double(activeHabitCount)
        }

        return heatmap
    }

    // MARK: - Reflections

    func saveReflection(date: Date, rating: Int, note: String?) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Check for existing reflection
        let request = Reflection.fetchForDate(date)
        let existing = (try? context.fetch(request))?.first

        let reflection = existing ?? Reflection(context: context)
        if existing == nil {
            reflection.id = UUID()
        }
        reflection.date = startOfDay
        reflection.rating = Int16(rating)
        reflection.note = note

        persistence.save()
    }

    func fetchReflection(for date: Date) -> Reflection? {
        let request = Reflection.fetchForDate(date)
        return (try? context.fetch(request))?.first
    }
}
