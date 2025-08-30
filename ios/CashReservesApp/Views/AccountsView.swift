import SwiftUI
import ReserveEngine

struct AccountsView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var editingTierIndex: Int? = nil
    @State private var editingAccountIndex: Int? = nil
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(vm.plan.sortedByPriority.enumerated()), id: \.1.name) { _, tier in
                    if let tierIndex = vm.plan.tiers.firstIndex(where: { $0.name == tier.name && $0.priority == tier.priority }) {
                        Section(header: Text(tier.name)) {
                            if tier.accounts.isEmpty {
                                Text("No accounts in this tier.").foregroundStyle(.secondary)
                            } else {
                                ForEach(Array(tier.accounts.enumerated()), id: \.1.name) { aIndex, a in
                                    Button {
                                        editingTierIndex = tierIndex
                                        editingAccountIndex = aIndex
                                        showEditor = true
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(a.name)
                                                Text("APY: \(a.apyPct, specifier: "%.2f")%  •  W: \(a.allocWeight, specifier: "%.2f")")
                                                    .font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(MoneyFormat.format(a.balance))
                                        }
                                    }
                                }
                            }
                            Button {
                                editingTierIndex = tierIndex
                                editingAccountIndex = nil
                                showEditor = true
                            } label: {
                                Label("Add Account", systemImage: "plus")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .sheet(isPresented: $showEditor, onDismiss: { editingTierIndex = nil; editingAccountIndex = nil }) {
                if let tIdx = editingTierIndex {
                    AccountEditorView(
                        tier: Binding(
                            get: { vm.plan.tiers[tIdx] },
                            set: { vm.plan.tiers[tIdx] = $0 }
                        ),
                        accountIndex: editingAccountIndex
                    )
                    .environmentObject(vm)
                }
            }
        }
    }
}

