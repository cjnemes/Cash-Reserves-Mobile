import Foundation
import CoreData
import ReserveEngine

actor HistoryStore {
    static let shared = HistoryStore()
    private init() {}

    private var cache: [ReserveEngine.Transaction] = []
    private var context: NSManagedObjectContext { PersistenceController.shared.container.viewContext }

    // Load from Core Data; migrate from JSON if present
    func load() async {
        await migrateIfNeeded()
        await fetchAll()
    }

    func all() -> [ReserveEngine.Transaction] { cache }

    func append(_ t: ReserveEngine.Transaction) async {
        let cd = CDTransaction(context: context)
        cd.timestamp = t.timestamp
        cd.tierName = t.tierName
        cd.accountName = t.accountName
        cd.amount = t.amount
        cd.balanceAfter = t.balanceAfter
        cd.type = t.type
        cd.desc = t.description
        cd.user = t.user
        do { try context.save() } catch { }
        await fetchAll()
    }

    private func fetchAll() async {
        let req = NSFetchRequest<CDTransaction>(entityName: "CDTransaction")
        req.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            let rows = try context.fetch(req)
            self.cache = rows.map { r in
                ReserveEngine.Transaction(timestamp: r.timestamp,
                                           tierName: r.tierName,
                                           accountName: r.accountName,
                                           amount: r.amount,
                                           balanceAfter: r.balanceAfter,
                                           type: r.type,
                                           description: r.desc ?? "",
                                           user: r.user ?? "system")
            }
        } catch {
            self.cache = []
        }
    }

    // Migration from prior JSON file
    private func migrateIfNeeded() async {
        let url = historyURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let d = JSONDecoder()
            d.dateDecodingStrategy = .iso8601
            let rows = try d.decode([ReserveEngine.Transaction].self, from: data)
            for t in rows.reversed() { // oldest first
                let cd = CDTransaction(context: context)
                cd.timestamp = t.timestamp
                cd.tierName = t.tierName
                cd.accountName = t.accountName
                cd.amount = t.amount
                cd.balanceAfter = t.balanceAfter
                cd.type = t.type
                cd.desc = t.description
                cd.user = t.user
            }
            try context.save()
            try? FileManager.default.removeItem(at: url)
        } catch {
            // ignore and keep going
        }
    }

    private func historyURL() -> URL {
        #if os(iOS)
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #else
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        #endif
        return dir.appendingPathComponent("history.json")
    }
}
