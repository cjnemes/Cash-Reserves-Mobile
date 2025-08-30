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
            AccountsView()
                .tabItem { Label("Accounts", systemImage: "creditcard") }
                .tag(2)
            PlannerView()
                .tabItem { Label("Planner", systemImage: "plus.slash.minus") }
                .tag(3)
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(4)
        }
        .task { await vm.load() }
    }
}
