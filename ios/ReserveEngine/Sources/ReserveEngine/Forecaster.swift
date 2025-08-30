import Foundation

public struct Forecaster {
    public static func forecast(_ plan: Plan, months: Int) -> [String: Double] {
        var result: [String: Double] = [:]
        for tier in plan.tiers {
            let growth = tier.accounts.reduce(0.0) { partial, acc in
                guard months > 0, acc.apyPct > 0, acc.balance > 0 else { return partial }
                let r = acc.apyPct / 100.0
                let g = acc.balance * (pow(1 + r/12.0, Double(months)) - 1)
                return partial + g
            }
            result[tier.name] = growth
        }
        return result
    }
}

