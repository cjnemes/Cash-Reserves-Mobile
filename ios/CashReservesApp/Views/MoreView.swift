import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { RebalanceView() } label: {
                    Label("Rebalance", systemImage: "arrow.left.arrow.right")
                }
                NavigationLink { HistoryView() } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink { SettingsView() } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("More")
        }
    }
}

