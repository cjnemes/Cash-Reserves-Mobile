import SwiftUI
import ReserveEngine
import UIKit

struct TierDetailView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State var tier: Tier
    @Environment(\.dismiss) private var dismissScreen
    @State private var editMode: Bool = false
    @State private var newAccount = false
    @State private var editingAccount = false
    @State private var editingIndex: Int? = nil

    var body: some View {
        Form {
            Section("Tier") {
                LabeledContent("Name") {
                    TextField("e.g., Tier 1", text: Binding(get: { tier.name }, set: { tier.name = $0 }))
                        .textInputAutocapitalization(.words)
                }
                LabeledContent("Purpose") {
                    TextField("e.g., Emergency Buffer", text: Binding(get: { tier.purpose }, set: { tier.purpose = $0 }))
                        .textInputAutocapitalization(.sentences)
                }
                LabeledContent("Target") {
                    HStack {
                        Text("$")
                        TextField("e.g., 30000", value: Binding(get: { tier.target }, set: { tier.target = $0 }), formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                    }
                }
                LabeledContent("Priority") {
                    Stepper(value: Binding(get: { tier.priority }, set: { tier.priority = $0 }), in: 1...99) {
                        Text("\(tier.priority)")
                    }
                }
                LabeledContent("Preferred Account") {
                    Picker("Preferred Account", selection: Binding(get: { tier.preferredAccount ?? "(None)" }, set: { tier.preferredAccount = $0 == "(None)" ? nil : $0 })) {
                        Text("(None)").tag("(None)")
                        ForEach(tier.accounts, id: \.name) { a in Text(a.name).tag(a.name) }
                    }
                    .pickerStyle(.menu)
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
                        .contextMenu {
                            if tier.preferredAccount == tier.accounts[i].name {
                                Button(role: .destructive) {
                                    tier.preferredAccount = nil
                                    vm.save()
                                } label: { Label("Unset Preferred", systemImage: "star.slash.fill") }
                            } else {
                                Button {
                                    tier.preferredAccount = tier.accounts[i].name
                                    vm.save()
                                } label: { Label("Set as Preferred", systemImage: "star.fill") }
                            }
                        }
                    }
                    .onDelete { idx in tier.accounts.remove(atOffsets: idx) }
                }
                Button { newAccount = true } label: { Label("Add Account", systemImage: "plus") }
            }
        }
        .navigationTitle(tier.name)
        .navigationBarTitleDisplayMode(.inline)
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
        // Haptic + dismiss to indicate success
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismissScreen()
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
    @State private var markPreferred: Bool = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var balanceFocused: Bool
    @FocusState private var apyFocused: Bool
    @FocusState private var capFocused: Bool

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
                        HStack {
                            Text("$")
                            TextField("e.g., 12,000", text: $balance)
                                .keyboardType(.decimalPad)
                                .textInputAutocapitalization(.never)
                                .focused($balanceFocused)
                                .onChange(of: balanceFocused) { foc in if !foc { balance = InputFormatters.formatCurrencyString(balance) } }
                        }
                    }
                    LabeledContent("APY %") {
                        TextField("e.g., 4.25", text: $apy)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                            .focused($apyFocused)
                            .onChange(of: apyFocused) { foc in if !foc { apy = InputFormatters.formatPercentString(apy) } }
                    }
                    LabeledContent("Weight") {
                        TextField("e.g., 2", text: $weight)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent("Cap (optional)") {
                        HStack {
                            Text("$")
                            TextField("leave blank for no cap", text: $cap)
                                .keyboardType(.decimalPad)
                                .textInputAutocapitalization(.never)
                                .focused($capFocused)
                                .onChange(of: capFocused) { foc in if !foc && !cap.isEmpty { cap = InputFormatters.formatCurrencyString(cap) } }
                        }
                    }
                    LabeledContent("Notes") {
                        TextField("optional", text: $notes)
                    }
                }
                Section {
                    Toggle("Mark as Preferred in this tier", isOn: $markPreferred)
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
        // Preferred toggle defaults
        if let i = accountIndex {
            let a = tier.accounts[i]
            markPreferred = (tier.preferredAccount == a.name)
        } else {
            markPreferred = false
        }
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
                // Same tier update
                let oldName = tier.accounts[i].name
                tier.accounts[i] = acc
                if markPreferred { tier.preferredAccount = acc.name }
                else if tier.preferredAccount == oldName { tier.preferredAccount = nil }
            } else {
                // Move to another tier
                let oldName = tier.accounts[i].name
                tier.accounts.remove(at: i)
                if let targetIdx = vm.plan.tiers.firstIndex(where: { $0.name == selectedTierName }) {
                    vm.plan.tiers[targetIdx].accounts.append(acc)
                    if markPreferred { vm.plan.tiers[targetIdx].preferredAccount = acc.name }
                }
                if tier.preferredAccount == oldName { tier.preferredAccount = nil }
            }
        } else {
            if selectedTierName == tier.name {
                tier.accounts.append(acc)
                if markPreferred { tier.preferredAccount = acc.name }
            } else if let targetIdx = vm.plan.tiers.firstIndex(where: { $0.name == selectedTierName }) {
                vm.plan.tiers[targetIdx].accounts.append(acc)
                if markPreferred { vm.plan.tiers[targetIdx].preferredAccount = acc.name }
            }
        }
        vm.save(); dismiss()
    }
}
