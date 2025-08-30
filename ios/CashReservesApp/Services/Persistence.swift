import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        // Build model programmatically to avoid needing a .xcdatamodeld file
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "CDTransaction"
        entity.managedObjectClassName = NSStringFromClass(CDTransaction.self)

        // Attributes
        var attrs: [NSAttributeDescription] = []
        func attr(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = type
            a.isOptional = optional
            return a
        }
        attrs.append(attr("timestamp", .dateAttributeType))
        attrs.append(attr("tierName", .stringAttributeType))
        attrs.append(attr("accountName", .stringAttributeType))
        attrs.append(attr("amount", .doubleAttributeType))
        attrs.append(attr("balanceAfter", .doubleAttributeType))
        attrs.append(attr("type", .stringAttributeType))
        attrs.append(attr("desc", .stringAttributeType, optional: true))
        attrs.append(attr("user", .stringAttributeType, optional: true))
        entity.properties = attrs
        model.entities = [entity]

        container = NSPersistentContainer(name: "CashReserves", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let url = PersistenceController.storeURL()
            let desc = NSPersistentStoreDescription(url: url)
            desc.shouldMigrateStoreAutomatically = true
            desc.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [desc]
        }
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Unresolved Core Data error: \(error)") }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    static func storeURL() -> URL {
        #if os(iOS)
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("CashReserves.sqlite")
        #else
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return dir.appendingPathComponent("CashReserves.sqlite")
        #endif
    }
}

@objc(CDTransaction)
final class CDTransaction: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var tierName: String
    @NSManaged var accountName: String
    @NSManaged var amount: Double
    @NSManaged var balanceAfter: Double
    @NSManaged var type: String
    @NSManaged var desc: String?
    @NSManaged var user: String?
}

