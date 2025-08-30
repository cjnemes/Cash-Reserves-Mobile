import SwiftUI
import ReserveEngine

struct TierDetailView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State var tier: Tier
    @State private var editMode: Bool = false
    @State private var newAccount = false

    var body: some View {
        Form {
            Section("Tier") {
                TextField("Name", text: Binding(get: { tier.name }, set: { tier.name = $0 }))
                TextField("Purpose", text: Binding(get: { tier.purpose }, set: { tier.purpose = $0 }))
                TextField("Target", value: Binding(get: { tier.target }, set: { tier.target = $0 }), formatter: NumberFormatter())
                Stepper("Priority: \(tier.priority)", value: Binding(get: { tier.priority }, set: { tier.priority = $0 }), in: 1...99)
                Picker("Preferred Account", selection: Binding(get: { tier.preferredAccount ?? "(None)" }, set: { tier.preferredAccount = $0 == "(None)" ? nil : $0 })) {
                    Text("(None)").tag("(None)")
                    ForEach(tier.accounts, id: \.name) { a in Text(a.name).tag(a.name) }
                }
            }
            Section("Accounts") {
                ForEach(tier.accounts.indices, id: \.self) { i in
                    NavigationLink(destination: AccountEditorView(tier: $tier, accountIndex: i)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tier.accounts[i].name)
                                Text("APY: \(tier.accounts[i].apyPct, specifier: "%.2f")%  •  W: \(tier.accounts[i].allocWeight, specifier: "%.2f")").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(MoneyFormat.format(tier.accounts[i].balance, privacy: vm.privacyMode))
                        }
                    }
                }
                .onDelete { idx in tier.accounts.remove(atOffsets: idx) }
                Button { newAccount = true } label: { Label("Add Account", systemImage: "plus") }
            }
        }
        .navigationTitle(tier.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .sheet(isPresented: $newAccount) {
            AccountEditorView(tier: $tier, accountIndex: nil)
        }
    }

    func save() {
        if let idx = vm.plan.tiers.firstIndex(where: { $0.name == tier.name }) {
            vm.plan.tiers[idx] = tier
        } else if let oldIdx = vm.plan.tiers.firstIndex(where: { $0.priority == tier.priority && $0.purpose == tier.purpose }) {
            vm.plan.tiers[oldIdx] = tier
        }
        vm.save()
    }
}

struct AccountEditorView: View {
    @EnvironmentObject var vm: PlanViewModel
    @Binding var tier: Tier
    var accountIndex: Int?

    @State private var name: String = ""
    @State private var balance: String = "0"
    @State private var apy: String = "0"
    @State private var weight: String = "1"
    @State private var cap: String = ""
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Name", text: $name)
                    TextField("Balance", text: $balance).keyboardType(.decimalPad)
                    TextField("APY %", text: $apy).keyboardType(.decimalPad)
                    TextField("Weight", text: $weight).keyboardType(.decimalPad)
                    TextField("Cap (optional)", text: $cap).keyboardType(.decimalPad)
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle(accountIndex == nil ? "Add Account" : "Edit Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
            .onAppear(perform: load)
        }
    }

    func load() {
        if let i = accountIndex {
            let a = tier.accounts[i]
            name = a.name
            balance = String(a.balance)
            apy = String(a.apyPct)
            weight = String(a.allocWeight)
            cap = a.accountTarget.map { String($0) } ?? ""
            notes = a.notes
        }
    }

    func save() {
        let acc = Account(
            name: name,
            balance: Double(balance) ?? 0,
            apyPct: Double(apy) ?? 0,
            notes: notes,
            allocWeight: Double(weight) ?? 1,
            accountTarget: Double(cap)
        )
        if let i = accountIndex { tier.accounts[i] = acc } else { tier.accounts.append(acc) }
        vm.save(); dismiss()
    }
}
