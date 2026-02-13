import Foundation
import CoreData

/// A daily spiritual reflection entry with rating and optional note.
@objc(Reflection)
public class Reflection: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var rating: Int16      // 1-10
    @NSManaged public var note: String?
}

extension Reflection {
    /// Fetch reflection for a specific date.
    static func fetchForDate(_ date: Date) -> NSFetchRequest<Reflection> {
        let request = NSFetchRequest<Reflection>(entityName: "Reflection")
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reflection.date, ascending: false)]
        request.fetchLimit = 1
        return request
    }

    /// Fetch all reflections for a month (for history view).
    static func fetchForMonth(year: Int, month: Int) -> NSFetchRequest<Reflection> {
        let request = NSFetchRequest<Reflection>(entityName: "Reflection")
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
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reflection.date, ascending: true)]
        return request
    }
}
