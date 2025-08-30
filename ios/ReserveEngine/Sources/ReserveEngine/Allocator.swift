import Foundation

public struct Allocator {
    public static func allocationPlan(_ plan: Plan, newCash: Double) -> [(tier: String, amount: Double)] {
        var remaining = max(0, newCash)
        var result: [(String, Double)] = []
        for tier in plan.sortedByPriority where remaining > 0 {
            let need = tier.gap
            guard need > 0 else { continue }
            let amt = min(remaining, need).rounded(to: 2)
            if amt > 0 { result.append((tier.name, amt)); remaining -= amt }
        }
        if remaining > 0, let growth = plan.sortedByPriority.first(where: { $0.name.contains("Tier 4") || $0.purpose.localizedCaseInsensitiveContains("growth") }) {
            result.append((growth.name, remaining.rounded(to: 2)))
        }
        return result
    }

    public static func allocationPlanDetailed(_ plan: Plan, newCash: Double) -> [(tier: String, account: String, amount: Double)] {
        var remaining = max(0, newCash)
        var out: [(String, String, Double)] = []
        for tier in plan.sortedByPriority where remaining > 0 {
            let need = tier.gap
            guard need > 0 else { continue }
            let amt = min(remaining, need)
            let splits = splitIntoAccounts(tier: tier, amount: amt)
            for s in splits { out.append((tier.name, s.name, s.amount.rounded(to: 2))) }
            remaining -= amt
        }
        if remaining > 0, let growth = plan.sortedByPriority.first(where: { $0.name.contains("Tier 4") || $0.purpose.localizedCaseInsensitiveContains("growth") }) {
            for s in splitIntoAccounts(tier: growth, amount: remaining) {
                out.append((growth.name, s.name, s.amount.rounded(to: 2)))
            }
        }
        return out
    }

    public static func splitIntoAccounts(tier: Tier, amount: Double) -> [(name: String, amount: Double)] {
        var remaining = max(0, amount)
        var moves: [(String, Double)] = []
        guard !tier.accounts.isEmpty, remaining > 0 else { return moves }
        // Preferred first
        if let pref = tier.preferredAccount, let prefAcc = tier.accounts.first(where: { $0.name == pref }) {
            let add = min(remaining, prefAcc.remainingRoom)
            if add > 0 { moves.append((prefAcc.name, add)); remaining -= add }
        }
        // Weighted split among accounts with room
        while remaining > 0 {
            let candidates = tier.accounts.filter { $0.remainingRoom > 0 }
            guard !candidates.isEmpty else { break }
            let totalW = candidates.map { max(0, $0.allocWeight) }.reduce(0, +)
            if totalW <= 0 {
                let a = candidates[0]
                let add = min(remaining, a.remainingRoom)
                moves.append((a.name, add)); remaining -= add; break
            }
            var progressed = false
            for a in candidates {
                let share = remaining * (max(0, a.allocWeight) / totalW)
                let add = min(share, a.remainingRoom)
                if add > 0 { moves.append((a.name, add)); remaining -= add; progressed = true }
            }
            if !progressed { break }
        }
        return moves
    }
}
