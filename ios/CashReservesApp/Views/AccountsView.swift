import SwiftUI
import ReserveEngine

private struct AccountEditContext: Identifiable {
    let id = UUID()
    let tierIndex: Int
    let accountIndex: Int?
}

struct AccountsView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var editContext: AccountEditContext? = nil

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
                                    Button { editContext = AccountEditContext(tierIndex: tierIndex, accountIndex: aIndex) } label: {
                                        AccountRowView(account: a, isPreferred: tier.preferredAccount == a.name, privacy: vm.privacyMode)
                                    }
                                    .contextMenu {
                                        if tier.preferredAccount == a.name {
                                            Button(role: .destructive) { vm.plan.tiers[tierIndex].preferredAccount = nil; vm.save() } label: { Label("Unset Preferred", systemImage: "star.slash.fill") }
                                        } else {
                                            Button { vm.plan.tiers[tierIndex].preferredAccount = a.name; vm.save() } label: { Label("Set as Preferred", systemImage: "star.fill") }
                                        }
                                    }
                                }
                            }
                            Button {
                                editContext = AccountEditContext(tierIndex: tierIndex, accountIndex: nil)
                            } label: {
                                Label("Add Account", systemImage: "plus")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .listStyle(.insetGrouped)
            .sheet(item: $editContext) { ctx in
                AccountEditorView(
                    tier: Binding(
                        get: { vm.plan.tiers[ctx.tierIndex] },
                        set: { vm.plan.tiers[ctx.tierIndex] = $0 }
                    ),
                    accountIndex: ctx.accountIndex
                )
                .environmentObject(vm)
            }
        }
    }
}
