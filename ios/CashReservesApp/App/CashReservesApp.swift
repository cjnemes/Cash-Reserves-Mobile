import SwiftUI
import ReserveEngine

@main
struct CashReservesApp: App {
    @StateObject private var planVM = PlanViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(planVM)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var vm: PlanViewModel
    var body: some View {
        TabView(selection: $vm.selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge") }
                .tag(0)
            TierListView()
                .tabItem { Label("Tiers", systemImage: "square.grid.2x2") }
                .tag(1)
            PlannerView()
                .tabItem { Label("Planner", systemImage: "plus.slash.minus") }
                .tag(2)
            RebalanceView()
                .tabItem { Label("Rebalance", systemImage: "arrow.left.arrow.right") }
                .tag(3)
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(4)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(5)
        }
        .task { await vm.load() }
    }
}
