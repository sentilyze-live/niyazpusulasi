import CoreData

/// Manages the CoreData stack for habits, logs, and reflections.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    /// In-memory store for previews and tests.
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Seed preview data
        let habits = ["Namaz kıldım", "Kur'an okudum", "Zikir çektim", "Sadaka verdim", "Dua ettim"]
        for (index, title) in habits.enumerated() {
            let habit = Habit(context: context)
            habit.id = UUID()
            habit.title = title
            habit.isActive = true
            habit.sortOrder = Int16(index)
            habit.createdAt = Date()
        }

        do {
            try context.save()
        } catch {
            fatalError("Preview CoreData save failed: \(error)")
        }
        return controller
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NiyazPusulasi")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error.localizedDescription)")
        }
    }
}
