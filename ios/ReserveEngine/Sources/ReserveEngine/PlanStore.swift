import Foundation

public final class PlanStore {
    public static let shared = PlanStore()
    private init() {}

    public func loadOrInitialize() throws -> Plan {
        let url = planURL()
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            let plan = try JSONDecoder().decode(Plan.self, from: data)
            return plan
        } else {
            let plan = defaultPlan()
            try save(plan)
            return plan
        }
    }

    public func save(_ plan: Plan) throws {
        var copy = plan
        copy.lastUpdated = ISO8601DateFormatter().string(from: Date())
        let data = try JSONEncoder.withSnakeCaseDates().encode(copy)
        try data.write(to: planURL(), options: [.atomic])
    }

    public func importFrom(url: URL) throws -> Plan {
        let data = try Data(contentsOf: url)
        let plan = try JSONDecoder().decode(Plan.self, from: data)
        try save(plan)
        return plan
    }

    public func export(to url: URL) throws {
        let data = try Data(contentsOf: planURL())
        try data.write(to: url)
    }

    public func planURL() -> URL {
        #if os(iOS)
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #else
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        #endif
        return dir.appendingPathComponent("reserve_manager.json")
    }
}

extension JSONEncoder {
    static func withSnakeCaseDates() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted]
        return e
    }
}

public func defaultPlan() -> Plan {
    let tier1 = Tier(
        name: "Tier 1",
        purpose: "Buffer & short‑term emergencies",
        target: 0,
        priority: 1,
        accounts: [
            Account(name: "Checking"),
            Account(name: "Savings")
        ],
        preferredAccount: "Savings"
    )
    let tier2 = Tier(
        name: "Tier 2",
        purpose: "Emergency fund",
        target: 0,
        priority: 2,
        accounts: [
            Account(name: "Investment Account")
        ],
        preferredAccount: "Investment Account"
    )
    return Plan(tiers: [tier1, tier2], lastUpdated: ISO8601DateFormatter().string(from: Date()))
}

