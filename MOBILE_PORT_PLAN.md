# Cash Reserves – iOS Mobile Port Plan

This document captures how the existing desktop Python app works and proposes a concrete plan to build an iOS version using Swift/SwiftUI. It maps core concepts, logic, and user flows to a native mobile architecture.

## 1) What The Desktop App Does

- Purpose: Manage a 6‑tier cash reserve system with tier targets, priorities, and accounts per tier. Allocate new cash by priority, distribute within tiers by account weights and caps, suggest rebalancing moves, and forecast yields.
- Components:
  - `reserve_manager.py` (Core engine): Data models (Account, Tier, Plan), allocation algorithms, rebalancing, forecasting, JSON persistence, CLI.
  - `reserve_manager_enhanced.py` (Pro features): Transaction history via SQLite, recurring transactions, CSV/Excel export, PDF reports (matplotlib), import helpers.
  - `reserve_manager_pro_v3.py` (GUI app): Tkinter-based UI with charts, tier/account management dialogs, planner, history, settings, file management.
- Data storage: JSON for the plan (`reserve_manager.json`, with schema metadata); SQLite for transaction history; optional CSV/Excel/PDF exports. App data paths are platform-specific.

## 2) Core Data Model (Python → Swift mapping)

- Account
  - Python: `name, balance, apy_pct, notes, alloc_weight, account_target`
  - Swift: `struct Account: Codable { var name: String; var balance: Double; var apyPct: Double; var notes: String; var allocWeight: Double; var accountTarget: Double? }`

- Tier
  - Python: `name, purpose, target, priority, accounts[], preferred_account`
  - Swift: `struct Tier: Codable { var name: String; var purpose: String; var target: Double; var priority: Int; var accounts: [Account]; var preferredAccount: String? }`

- Plan
  - Python: `tiers[], last_updated`
  - Swift: `struct Plan: Codable { var tiers: [Tier]; var lastUpdated: String }`

- Transaction (Pro)
  - Python: `timestamp, tier_name, account_name, amount, balance_after, transaction_type, description, user`
  - Swift: `struct Transaction: Codable { var timestamp: Date; var tierName: String; var accountName: String; var amount: Double; var balanceAfter: Double; var type: String; var description: String; var user: String }`

Notes:
- Use `Codable` for JSON compatibility. Keep keys aligned with Python (`preferred_account` ↔ `preferredAccount` via CodingKeys) to support import/export of existing files.
- If we want exact compatibility with the current JSON output, mirror field names exactly via `CodingKeys` and maintain `last_updated` ISO dates.

## 3) Core Algorithms (to port to Swift)

Reference: `reserve_manager.py`

- Priority-based tier allocation (tier-level):
  1) Sort tiers by `priority` ascending.
  2) For each tier, allocate up to its `gap = max(0, target - total)` from `newCash`.
  3) Any leftover after all targets goes to Tier 4 (growth) if present.

- Detailed allocation (tier → accounts):
  1) For the amount destined to a tier, first try its `preferred_account` up to its remaining room (`account_target - balance`).
  2) Then distribute remaining by account `alloc_weight` among accounts with room.
  3) Respect per-account caps; round to 2 decimals consistently.
  4) Leftover after all targets goes to Tier 4 using the same account split rules.

- Rebalancing suggestions:
  - Compute overfunded tiers (`total > target`) and underfunded (`gap > 0`).
  - Greedily match excess to needs, producing moves like `"Tier A ➜ Tier B": amount`.

- Forecasting:
  - Compound monthly per account: `balance * ((1 + apy/100/12)^months - 1)` and sum per tier.

Edge cases and behaviors:
- Negative APY or zero balances yield zero growth.
- Weighted splits skip accounts without room; if all weights are zero, fall back to first candidate.
- Preferred account gets priority but still respects its cap.
- Rounding to 2 decimals on outward-facing move amounts.

## 4) iOS Architecture Proposal

- Technology: Swift 5, SwiftUI, Combine, Swift Charts (iOS 16+), FileManager for JSON, optional GRDB or Core Data for history.
- Layers:
  - Engine (Swift module): Data models + pure functions for allocation, rebalancing, forecasting. Unit-tested to match Python behavior.
  - Persistence: `PlanStore` reads/writes JSON in App’s Documents directory (or App Group if needed). `HistoryStore` uses Core Data or GRDB (SQLite) for transactions.
  - App (SwiftUI): MVVM-ish with `@StateObject` view models. Screens: Dashboard, Tiers, Accounts, Planner (allocate), Rebalance, History, Reports, Settings.
  - Import/Export: Share Sheet for JSON/CSV export; Files picker for import. Maintain compatibility with current JSON schema.

### Suggested module layout

- ReserveEngine (Swift Package/target)
  - Models: `Account.swift`, `Tier.swift`, `Plan.swift`, `Transaction.swift`
  - Algorithms: `Allocator.swift`, `Rebalancer.swift`, `Forecaster.swift`
  - Persistence: `PlanStore.swift` (JSON), `HistoryStore.swift` (Core Data/GRDB)
  - Tests: parity tests vs. known fixtures from Python outputs

- iOS App target
  - Views: `DashboardView`, `PlannerView`, `TierDetailView`, `AccountEditor`, `HistoryView`, `ReportView`, `SettingsView`
  - ViewModels: `PlanViewModel`, `PlannerViewModel`, `HistoryViewModel`
  - Utilities: currency formatting, privacy mode, backups, quick actions

## 5) Swift Engine Sketches

```swift
// Account.swift
struct Account: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var balance: Double
    var apyPct: Double
    var notes: String
    var allocWeight: Double
    var accountTarget: Double?
    
    var remainingRoom: Double { (accountTarget ?? .infinity) - balance }.clamped(min: 0)
}

// Tier.swift
struct Tier: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var purpose: String
    var target: Double
    var priority: Int
    var accounts: [Account]
    var preferredAccount: String?
    
    var total: Double { accounts.reduce(0) { $0 + $1.balance } }
    var gap: Double { max(0, target - total) }
}

// Plan.swift
struct Plan: Codable {
    var tiers: [Tier]
    var lastUpdated: String
    
    var totalReserves: Double { tiers.reduce(0) { $0 + $1.total } }
    var sortedByPriority: [Tier] { tiers.sorted { $0.priority < $1.priority } }
}

// Allocator.swift
struct Allocator {
    static func allocationPlan(_ plan: Plan, newCash: Double) -> [(tier: String, amount: Double)] {
        var remaining = max(0, newCash)
        var result: [(String, Double)] = []
        for tier in plan.sortedByPriority where remaining > 0 {
            let need = tier.gap
            guard need > 0 else { continue }
            let amt = min(remaining, need).rounded(to: 2)
            if amt > 0 { result.append((tier.name, amt)); remaining -= amt }
        }
        if remaining > 0, let growth = plan.sortedByPriority.first(where: { $0.name.contains("Tier 4") || $0.purpose.contains("Growth") }) {
            result.append((growth.name, remaining.rounded(to: 2)))
        }
        return result
    }

    static func allocationPlanDetailed(_ plan: Plan, newCash: Double) -> [(tier: String, account: String, amount: Double)] {
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
        if remaining > 0, let growth = plan.sortedByPriority.first(where: { $0.name.contains("Tier 4") || $0.purpose.contains("Growth") }) {
            for s in splitIntoAccounts(tier: growth, amount: remaining) {
                out.append((growth.name, s.name, s.amount.rounded(to: 2)))
            }
        }
        return out
    }
    
    private static func splitIntoAccounts(tier: Tier, amount: Double) -> [(name: String, amount: Double)] {
        var remaining = max(0, amount)
        var moves: [(String, Double)] = []
        guard !tier.accounts.isEmpty, remaining > 0 else { return moves }
        // Preferred first
        if let pref = tier.preferredAccount, let a = tier.accounts.first(where: { $0.name == pref }) {
            let add = min(remaining, a.remainingRoom)
            if add > 0 { moves.append((a.name, add)); remaining -= add }
        }
        // Weighted split among accounts with room
        while remaining > 0 {
            let candidates = tier.accounts.filter { $0.remainingRoom > 0 }
            guard !candidates.isEmpty else { break }
            let totalW = candidates.map { max(0, $0.allocWeight) }.reduce(0, +)
            if totalW <= 0 {
                let a = candidates[0]; let add = min(remaining, a.remainingRoom)
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

extension Double { func rounded(to places: Int) -> Double { let p = pow(10.0, Double(places)); return (self * p).rounded() / p } }
extension Double { func clamped(min: Double = -.infinity, max: Double = .infinity) -> Double { Swift.max(min, Swift.min(max, self)) } }
```

## 6) Screens and Flows (SwiftUI)

- Dashboard: Totals, coverage %, gaps, quick actions (Allocate, Rebalance). Swift Charts for distribution and progress.
- Planner: Enter new cash amount; see tier-level and detailed splits; apply and record transactions.
- Tiers: List by priority; create/edit/delete tiers; set targets, preferred accounts, priorities.
- Accounts: Per-tier list; add/edit accounts, caps, weights, APY; account-level balances.
- History: Recent transactions with filters; charts by account; export CSV.
- Reports: On-device PDF generation (Swift Charts snapshots + PDFKit) as a simplified alternative to matplotlib.
- Settings: Privacy mode, locale/currency, backups, import/export JSON, default contribution amount.

## 7) Data Persistence

- Plan JSON: Store at `Documents/reserve_manager.json`. Provide Import/Export with compatibility to Python schema (`tiers`, `last_updated`, account fields).
- History: Start with Core Data entity `Transaction` or GRDB-backed SQLite. Schema mirrors Python fields. Provide retention settings and export to CSV.
- Recurring: Simple JSON in app container; process on launch and via background tasks; local notifications for due items (user approval required).
- Backups: Optional rolling daily backup of plan JSON (retain N days, setting-driven).

## 8) Migration and Interop

- Import existing desktop JSON: Use File importer to load, map to `Plan` via CodingKeys, update `lastUpdated`.
- Export JSON/CSV so desktop can read it back if desired. Keep floats to two decimals where appropriate.
- If needed, provide a one-time script to convert desktop history SQLite → CSV for mobile import.

## 9) Roadmap & Milestones

1. Engine parity
   - Implement models and algorithms in Swift + unit tests using fixtures based on Python outputs.
2. Persistence
   - JSON PlanStore with import/export; simple HistoryStore (start with JSON or Core Data).
3. UI v1
   - Dashboard, Tiers, Accounts, Planner (apply allocations only, no charts).
4. Rebalance & Forecast
   - Rebalancing suggestions UI; 12‑month forecast view.
5. History & Reports
   - Transactions list, CSV export; basic PDF report using PDFKit/Swift Charts.
6. Polish
   - Charts, privacy mode, settings, backups, iCloud Drive file picker integration.

## 10) Validation Strategy

- Cross-check Swift engine with Python by generating test fixtures: run Python allocation and rebalancing on known inputs, store JSON of expected moves, and assert equality in Swift tests.
- Numerical tolerance: compare to 2 decimal places to match rounding behavior.

## 11) Next Steps

- Option A: I scaffold a Swift Package “ReserveEngine” and a SwiftUI app target that uses it, plus unit tests for algorithms.
- Option B: If you prefer React Native/Flutter, we can reuse the same algorithmic spec, but native SwiftUI is simplest for iOS and best for performance and UX.

---
This plan keeps the iOS app aligned with the desktop app’s schema and logic, ensures feature parity where it matters (allocation, rebalancing, forecasting), and sequences work for fast validation.

