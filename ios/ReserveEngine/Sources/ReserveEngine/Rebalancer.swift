import Foundation

public struct Rebalancer {
    public static func rebalancingMoves(_ plan: Plan) -> [(route: String, amount: Double)] {
        var under = plan.sortedByPriority.map { ($0, $0.gap) }.filter { $0.1 > 0 }
        var over = plan.tiers.map { ($0, $0.total - $0.target) }.filter { $0.1 > 0 }
        var moves: [(String, Double)] = []
        guard !under.isEmpty, !over.isEmpty else { return moves }
        var i = 0, j = 0
        while i < over.count && j < under.count {
            var (fromTier, excess) = over[i]
            var (toTier, need) = under[j]
            let amt = min(excess, need).rounded(to: 2)
            if amt > 0 {
                moves.append(("\(fromTier.name) ➜ \(toTier.name)", amt))
                excess -= amt; need -= amt
            }
            over[i] = (fromTier, excess)
            under[j] = (toTier, need)
            if excess <= 0.005 { i += 1 }
            if need <= 0.005 { j += 1 }
        }
        return moves
    }
}

