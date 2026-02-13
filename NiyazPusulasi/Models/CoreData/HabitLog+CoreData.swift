import Foundation
import CoreData

/// Records whether a habit was completed on a given day.
@objc(HabitLog)
public class HabitLog: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var habitId: UUID?
    @NSManaged public var isDone: Bool
}

extension HabitLog {
    /// Fetch all logs for a specific date (normalized to start of day).
    static func fetchForDate(_ date: Date) -> NSFetchRequest<HabitLog> {
        let request = NSFetchRequest<HabitLog>(entityName: "HabitLog")
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitLog.date, ascending: true)]
        return request
    }

    /// Fetch all logs for a habit within a date range (for streak calculation).
    static func fetchForHabit(_ habitId: UUID, from startDate: Date, to endDate: Date) -> NSFetchRequest<HabitLog> {
        let request = NSFetchRequest<HabitLog>(entityName: "HabitLog")
        request.predicate = NSPredicate(
            format: "habitId == %@ AND date >= %@ AND date < %@ AND isDone == YES",
            habitId as CVarArg, startDate as NSDate, endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitLog.date, ascending: false)]
        return request
    }

    /// Fetch logs for a full month (for heatmap).
    static func fetchForMonth(year: Int, month: Int) -> NSFetchRequest<HabitLog> {
        let request = NSFetchRequest<HabitLog>(entityName: "HabitLog")
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let calendar = Calendar.current
        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else {
            return request
        }
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitLog.date, ascending: true)]
        return request
    }
}
