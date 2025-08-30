import Foundation

public struct Account: Codable, Identifiable, Hashable {
    public var id = UUID()
    public var name: String
    public var balance: Double
    public var apyPct: Double
    public var notes: String
    public var allocWeight: Double
    public var accountTarget: Double?

    public init(name: String, balance: Double = 0, apyPct: Double = 0, notes: String = "", allocWeight: Double = 1, accountTarget: Double? = nil) {
        self.name = name
        self.balance = balance
        self.apyPct = apyPct
        self.notes = notes
        self.allocWeight = allocWeight
        self.accountTarget = accountTarget
    }

    public var remainingRoom: Double {
        guard let cap = accountTarget else { return .infinity }
        return max(0, cap - balance)
    }

    enum CodingKeys: String, CodingKey {
        case name, balance, notes
        case apyPct = "apy_pct"
        case allocWeight = "alloc_weight"
        case accountTarget = "account_target"
    }
}

public struct Tier: Codable, Identifiable, Hashable {
    public var id = UUID()
    public var name: String
    public var purpose: String
    public var target: Double
    public var priority: Int
    public var accounts: [Account]
    public var preferredAccount: String?

    public init(name: String, purpose: String, target: Double, priority: Int, accounts: [Account], preferredAccount: String? = nil) {
        self.name = name
        self.purpose = purpose
        self.target = target
        self.priority = priority
        self.accounts = accounts
        self.preferredAccount = preferredAccount
    }

    public var total: Double { accounts.reduce(0) { $0 + $1.balance } }
    public var gap: Double { max(0, target - total) }

    enum CodingKeys: String, CodingKey {
        case name, purpose, target, priority, accounts
        case preferredAccount = "preferred_account"
    }
}

public struct Plan: Codable, Hashable {
    public var tiers: [Tier]
    public var lastUpdated: String

    public init(tiers: [Tier], lastUpdated: String = ISO8601DateFormatter().string(from: Date())) {
        self.tiers = tiers
        self.lastUpdated = lastUpdated
    }

    public var totalReserves: Double { tiers.reduce(0) { $0 + $1.total } }
    public var sortedByPriority: [Tier] { tiers.sorted { $0.priority < $1.priority } }

    enum CodingKeys: String, CodingKey { case tiers; case lastUpdated = "last_updated" }
}

public struct Transaction: Codable, Identifiable, Hashable {
    public var id = UUID()
    public var timestamp: Date
    public var tierName: String
    public var accountName: String
    public var amount: Double
    public var balanceAfter: Double
    public var type: String
    public var description: String
    public var user: String

    public init(timestamp: Date = Date(), tierName: String, accountName: String, amount: Double, balanceAfter: Double, type: String, description: String = "", user: String = "system") {
        self.timestamp = timestamp
        self.tierName = tierName
        self.accountName = accountName
        self.amount = amount
        self.balanceAfter = balanceAfter
        self.type = type
        self.description = description
        self.user = user
    }
}

public enum ReserveError: Error { case tierNotFound, accountNotFound, decodeFailed, encodeFailed }

public extension Double {
    func rounded(to places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}

