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
        
        // Preferred account first (if it exists and has room)
        if let pref = tier.preferredAccount, let prefAcc = tier.accounts.first(where: { $0.name == pref }) {
            let roomAvailable = prefAcc.remainingRoom
            // Handle infinite room (no cap) by allocating all remaining or a reasonable chunk
            let add = roomAvailable == .infinity ? remaining : min(remaining, roomAvailable)
            if add > 0 { 
                moves.append((prefAcc.name, add))
                remaining -= add 
            }
        }
        
        // If there's still money left, distribute among all accounts by weight
        if remaining > 0.01 { // Use small threshold to avoid floating point precision issues
            let candidates = tier.accounts.filter { account in
                // Include accounts that either have room or have infinite room
                account.remainingRoom > 0
            }
            
            guard !candidates.isEmpty else { return moves }
            
            let totalWeight = candidates.map { max(0.1, $0.allocWeight) }.reduce(0, +) // Minimum weight of 0.1
            
            // Single pass allocation - no loop needed
            for account in candidates {
                let weightRatio = max(0.1, account.allocWeight) / totalWeight
                let share = remaining * weightRatio
                
                let roomAvailable = account.remainingRoom
                let add = roomAvailable == .infinity ? share : min(share, roomAvailable)
                
                if add > 0.01 { // Only allocate meaningful amounts
                    moves.append((account.name, add.rounded(to: 2)))
                }
            }
        }
        
        return moves
    }
}
