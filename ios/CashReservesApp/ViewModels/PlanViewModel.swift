import Foundation
import SwiftUI
import ReserveEngine

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var plan: Plan = defaultPlan()
    @Published var privacyMode: Bool = false
    @Published var selectedTab: Int = 0
    @Published var previewAmount: String = "1000"
    @Published var previewMovesTier: [(String, Double)] = []
    @Published var previewMovesDetailed: [(String, String, Double)] = []
    @Published var transactions: [ReserveEngine.Transaction] = []

    private let store = PlanStore.shared
    private let history = HistoryStore.shared

    func load() async {
        do {
            plan = try store.loadOrInitialize()
        } catch {
            plan = defaultPlan()
        }
        await history.load()
        transactions = await history.all()
        refreshPreview()
    }

    func save() {
        do { try store.save(plan) } catch { print("Save failed: \(error)") }
    }

    func importPlan(from url: URL) {
        do { plan = try store.importFrom(url: url); refreshPreview() } catch { print("Import failed: \(error)") }
    }

    func exportPlan(to url: URL) {
        do { try store.export(to: url) } catch { print("Export failed: \(error)") }
    }

    func refreshPreview() {
        let amt = Double(previewAmount) ?? 0
        previewMovesTier = Allocator.allocationPlan(plan, newCash: amt)
        previewMovesDetailed = Allocator.allocationPlanDetailed(plan, newCash: amt)
    }

    func applyAllocation() {
        let amt = Double(previewAmount) ?? 0
        var remaining = amt
        for tier in plan.sortedByPriority where remaining > 0 {
            let need = tier.gap
            guard need > 0 else { continue }
            let amtToTier = min(remaining, need)
            applyToTier(named: tier.name, amount: amtToTier)
            remaining -= amtToTier
        }
        if remaining > 0, let growth = plan.sortedByPriority.first(where: { $0.name.contains("Tier 4") || $0.purpose.localizedCaseInsensitiveContains("growth") }) {
            applyToTier(named: growth.name, amount: remaining)
        }
        save(); refreshPreview()
    }

    private func applyToTier(named tierName: String, amount: Double) {
        guard let idx = plan.tiers.firstIndex(where: { $0.name == tierName }) else { return }
        var tier = plan.tiers[idx]
        let splits = Allocator.splitIntoAccounts(tier: tier, amount: amount)
        for (accName, add) in splits {
            if let aIdx = tier.accounts.firstIndex(where: { $0.name == accName }) {
                tier.accounts[aIdx].balance += add
                let t = ReserveEngine.Transaction(tierName: tier.name, accountName: accName, amount: add, balanceAfter: tier.accounts[aIdx].balance, type: "allocation")
                transactions.insert(t, at: 0)
                Task { await history.append(t) }
            }
        }
        plan.tiers[idx] = tier
    }
    
    func applyRebalancing(suggestions: [(route: String, amount: Double)]) {
        for s in suggestions {
            let parts = s.route.components(separatedBy: " ➜ ")
            guard parts.count == 2 else { continue }
            let fromName = parts[0], toName = parts[1]
            moveBetweenTiers(from: fromName, to: toName, amount: s.amount)
        }
        save(); refreshPreview()
    }

    private func moveBetweenTiers(from fromName: String, to toName: String, amount: Double) {
        guard let fromIdx = plan.tiers.firstIndex(where: { $0.name == fromName }),
              let toIdx = plan.tiers.firstIndex(where: { $0.name == toName }) else { return }

        // 1) Remove from 'from' tier proportionally by account balance
        var fromTier = plan.tiers[fromIdx]
        let totalFrom = max(0.0, fromTier.total)
        if totalFrom > 0 {
            var remaining = amount
            for i in fromTier.accounts.indices {
                if remaining <= 0 { break }
                let accBal = fromTier.accounts[i].balance
                guard accBal > 0 else { continue }
                let share = amount * (accBal / totalFrom)
                let take = min(share, fromTier.accounts[i].balance)
                if take > 0 {
                    fromTier.accounts[i].balance -= take
                    let t = ReserveEngine.Transaction(tierName: fromTier.name, accountName: fromTier.accounts[i].name, amount: -take, balanceAfter: fromTier.accounts[i].balance, type: "rebalance")
                    transactions.insert(t, at: 0)
                    Task { await history.append(t) }
                    remaining -= take
                }
            }
            if remaining > 0 {
                for i in fromTier.accounts.indices {
                    if remaining <= 0 { break }
                    let take = min(remaining, fromTier.accounts[i].balance)
                    if take > 0 {
                        fromTier.accounts[i].balance -= take
                        let t = ReserveEngine.Transaction(tierName: fromTier.name, accountName: fromTier.accounts[i].name, amount: -take, balanceAfter: fromTier.accounts[i].balance, type: "rebalance")
                        transactions.insert(t, at: 0)
                        Task { await history.append(t) }
                        remaining -= take
                    }
                }
            }
        }
        plan.tiers[fromIdx] = fromTier

        // 2) Add to 'to' tier using allocation split
        var toTier = plan.tiers[toIdx]
        let splits = Allocator.splitIntoAccounts(tier: toTier, amount: amount)
        for (accName, add) in splits {
            if let aIdx = toTier.accounts.firstIndex(where: { $0.name == accName }) {
                toTier.accounts[aIdx].balance += add
                let t = ReserveEngine.Transaction(tierName: toTier.name, accountName: accName, amount: add, balanceAfter: toTier.accounts[aIdx].balance, type: "rebalance")
                transactions.insert(t, at: 0)
                Task { await history.append(t) }
            }
        }
        plan.tiers[toIdx] = toTier
    }
}
