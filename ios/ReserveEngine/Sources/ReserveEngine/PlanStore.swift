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
        name: "Tier 1: Buffer",
        purpose: "Daily expenses & small emergencies",
        target: 1000,
        priority: 1,
        accounts: [
            Account(name: "Checking", balance: 0),
            Account(name: "Savings", balance: 0)
        ],
        preferredAccount: "Savings"
    )
    
    let tier2 = Tier(
        name: "Tier 2: Emergency Fund",
        purpose: "Major life disruptions",
        target: 15000,
        priority: 2,
        accounts: [
            Account(name: "Emergency Savings", balance: 0)
        ],
        preferredAccount: "Emergency Savings"
    )
    
    let tier3 = Tier(
        name: "Tier 3: Major Repairs",
        purpose: "Home & vehicle maintenance",
        target: 8000,
        priority: 3,
        accounts: [
            Account(name: "Repair Fund", balance: 0)
        ],
        preferredAccount: "Repair Fund"
    )
    
    let tier4 = Tier(
        name: "Tier 4: Opportunities",
        purpose: "Investment & growth",
        target: 25000,
        priority: 4,
        accounts: [
            Account(name: "Investment Account", balance: 0)
        ],
        preferredAccount: "Investment Account"
    )
    
    let tier5 = Tier(
        name: "Tier 5: Long-term Goals",
        purpose: "Future major purchases",
        target: 45000,
        priority: 5,
        accounts: [
            Account(name: "Goals Account", balance: 0)
        ],
        preferredAccount: "Goals Account"
    )
    
    let tier6 = Tier(
        name: "Tier 6: Legacy",
        purpose: "Wealth preservation",
        target: 100000,
        priority: 6,
        accounts: [
            Account(name: "Legacy Fund", balance: 0)
        ],
        preferredAccount: "Legacy Fund"
    )
    
    return Plan(tiers: [tier1, tier2, tier3, tier4, tier5, tier6], lastUpdated: ISO8601DateFormatter().string(from: Date()))
}

