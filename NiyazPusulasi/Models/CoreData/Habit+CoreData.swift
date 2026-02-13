import Foundation
import CoreData

/// A user-defined spiritual habit to track daily.
@objc(Habit)
public class Habit: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var sortOrder: Int16
    @NSManaged public var createdAt: Date?
}

extension Habit {
    static func fetchAllActive() -> NSFetchRequest<Habit> {
        let request = NSFetchRequest<Habit>(entityName: "Habit")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.sortOrder, ascending: true)]
        return request
    }

    static func fetchAll() -> NSFetchRequest<Habit> {
        let request = NSFetchRequest<Habit>(entityName: "Habit")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.sortOrder, ascending: true)]
        return request
    }

    var safeTitle: String {
        title ?? ""
    }

    var safeId: UUID {
        id ?? UUID()
    }
}
