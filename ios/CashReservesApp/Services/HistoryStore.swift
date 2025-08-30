import Foundation
import ReserveEngine

actor HistoryStore {
    static let shared = HistoryStore()
    private init() {}

    private var cache: [Transaction] = []

    func load() async {
        let url = historyURL()
        guard FileManager.default.fileExists(atPath: url.path) else { cache = []; return }
        do {
            let data = try Data(contentsOf: url)
            let d = JSONDecoder()
            d.dateDecodingStrategy = .iso8601
            cache = try d.decode([Transaction].self, from: data)
        } catch {
            cache = []
        }
    }

    func all() -> [Transaction] { cache }

    func append(_ t: Transaction) async {
        cache.insert(t, at: 0)
        await save()
    }

    private func save() async {
        let url = historyURL()
        do {
            let e = JSONEncoder()
            e.outputFormatting = [.prettyPrinted]
            e.dateEncodingStrategy = .iso8601
            let data = try e.encode(cache)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Silent for now
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

