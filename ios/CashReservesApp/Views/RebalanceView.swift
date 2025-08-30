import SwiftUI
import ReserveEngine

struct RebalanceView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var suggestions: [(route: String, amount: Double)] = []
    @State private var applying = false

    var body: some View {
        NavigationStack {
            List {
                Section("Suggestions") {
                    if suggestions.isEmpty {
                        Text("No rebalancing suggested — either no overfunded tiers or gaps are minimal.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(suggestions.enumerated()), id: \.offset) { _, s in
                            HStack {
                                Text(s.route)
                                Spacer()
                                Text(MoneyFormat.format(s.amount, privacy: vm.privacyMode))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rebalance")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") { refresh() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Apply Suggested Moves") { apply() }
                        .buttonStyle(.borderedProminent)
                        .disabled(suggestions.isEmpty || applying)
                }
            }
            .onAppear(perform: refresh)
        }
    }

    func refresh() {
        suggestions = Rebalancer.rebalancingMoves(vm.plan)
    }

    func apply() {
        applying = true
        defer { applying = false }
        vm.applyRebalancing(suggestions: suggestions)
        refresh()
    }
}

