# Architecture

## Overview
- Engine (Swift Package `ReserveEngine`): Codable models, pure algorithms (Allocator, Rebalancer, Forecaster), JSON PlanStore.
- iOS App (SwiftUI): Views + ViewModels, imports engine, file import/export, simple in-memory history (upgradeable to Core Data).
- Interop: JSON schema compatible with desktop Python app for the Plan; optional CSV for exports later.

## Code Layout
- ios/ReserveEngine
  - Models.swift – Account, Tier, Plan, Transaction
  - Allocator.swift – Tier-level and detailed splits
  - Rebalancer.swift – Over/under greedy matching
  - Forecaster.swift – Monthly compounding
  - PlanStore.swift – JSON read/write, default plan
- ios/CashReservesApp
  - App – `CashReservesApp.swift` (entry) and theme helpers
  - ViewModels – `PlanViewModel`
  - Views – DashboardView, TierListView, TierDetailView, PlannerView, HistoryView, SettingsView

## Data Flow
- View → ViewModel → Engine
- ViewModel persists changes via PlanStore.
- Planner uses engine to preview and optionally apply allocations.

## Future Persistence
- Core Data or GRDB (SQLite) for `Transaction` history; import/export CSV.
- Optional iCloud file picker; App Group for shared plan files.

