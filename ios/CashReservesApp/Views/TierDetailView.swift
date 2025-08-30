import SwiftUI
import ReserveEngine

struct TierDetailView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State var tier: Tier
    @State private var editMode: Bool = false
    @State private var newAccount = false
    @State private var editingAccount = false
    @State private var editingIndex: Int? = nil

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
                if tier.accounts.isEmpty {
                    Text("No accounts yet. Tap ‘Add Account’ to create one.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(tier.accounts.indices, id: \.self) { i in
                        Button {
                            editingIndex = i
                            editingAccount = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(tier.accounts[i].name)
                                    Text("APY: \(tier.accounts[i].apyPct, specifier: "%.2f")%  •  W: \(tier.accounts[i].allocWeight, specifier: "%.2f")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(MoneyFormat.format(tier.accounts[i].balance, privacy: vm.privacyMode))
                            }
                        }
                    }
                    .onDelete { idx in tier.accounts.remove(atOffsets: idx) }
                }
                Button { newAccount = true } label: { Label("Add Account", systemImage: "plus") }
            }
        }
        .navigationTitle(tier.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .sheet(isPresented: $newAccount) { AccountEditorView(tier: $tier, accountIndex: nil) }
        .sheet(isPresented: $editingAccount, onDismiss: { editingIndex = nil }) {
            AccountEditorView(tier: $tier, accountIndex: editingIndex)
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
    @State private var balance: String = ""
    @State private var apy: String = ""
    @State private var weight: String = ""
    @State private var cap: String = ""
    @State private var notes: String = ""
    @State private var selectedTierName: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Tier") {
                        Picker("Tier", selection: $selectedTierName) {
                            ForEach(vm.plan.tiers.map { $0.name }, id: \.self) { n in
                                Text(n).tag(n)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    LabeledContent("Name") {
                        TextField("Savings", text: $name)
                            .textInputAutocapitalization(.words)
                    }
                    LabeledContent("Balance") {
                        TextField("e.g., 12000", text: $balance)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent("APY %") {
                        TextField("e.g., 4.25", text: $apy)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent("Weight") {
                        TextField("e.g., 2", text: $weight)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent("Cap (optional)") {
                        TextField("leave blank for no cap", text: $cap)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent("Notes") {
                        TextField("optional", text: $notes)
                    }
                }
                Section(footer: Text("Weight controls how new cash is split among accounts in this tier. Cap limits the max for this account.\nTip: Higher weight = larger share when allocating new money.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)) { EmptyView() }
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
        } else {
            // Defaults for new account: leave fields empty so placeholders and labels are clear
            if weight.isEmpty { weight = "1" }
        }
        if selectedTierName.isEmpty { selectedTierName = tier.name }
    }

    func save() {
        let acc = Account(
            name: name,
            balance: Double(balance.replacingOccurrences(of: ",", with: "")) ?? 0,
            apyPct: Double(apy.replacingOccurrences(of: "%", with: "")) ?? 0,
            notes: notes,
            allocWeight: Double(weight) ?? 1,
            accountTarget: Double(cap.replacingOccurrences(of: ",", with: ""))
        )
        if let i = accountIndex {
            if selectedTierName == tier.name {
                tier.accounts[i] = acc
            } else {
                // Move to another tier
                tier.accounts.remove(at: i)
                if let targetIdx = vm.plan.tiers.firstIndex(where: { $0.name == selectedTierName }) {
                    vm.plan.tiers[targetIdx].accounts.append(acc)
                }
            }
        } else {
            if selectedTierName == tier.name {
                tier.accounts.append(acc)
            } else if let targetIdx = vm.plan.tiers.firstIndex(where: { $0.name == selectedTierName }) {
                vm.plan.tiers[targetIdx].accounts.append(acc)
            }
        }
        vm.save(); dismiss()
    }
}
