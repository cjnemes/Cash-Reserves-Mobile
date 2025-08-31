import SwiftUI
import ReserveEngine
import UIKit

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
    @State private var showingOnboarding = false
    
    var body: some View {
        ZStack {
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
            .opacity(showingOnboarding ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: showingOnboarding)
            
            if showingOnboarding {
                OnboardingView()
                    .environmentObject(vm)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.05)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }
        }
        .task { await vm.load() }
        .onAppear {
            checkOnboardingStatus()
            configureTabBarAppearance()
        }
        .onChange(of: OnboardingPreferences.hasCompletedOnboarding) { completed in
            if completed {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showingOnboarding = false
                }
            }
        }
    }
    
    private func checkOnboardingStatus() {
        showingOnboarding = !OnboardingPreferences.hasCompletedOnboarding
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Apply to both standard and scrollEdge appearances
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
