import SwiftUI
import ReserveEngine

struct TierListView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var showAdd = false
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.plan.sortedByPriority, id: \.name) { tier in
                    NavigationLink(value: tier.name) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tier.name).font(.headline)
                                Text(tier.purpose).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(MoneyFormat.format(tier.total, privacy: vm.privacyMode))
                                if tier.target > 0 { Text("Gap: \(MoneyFormat.format(tier.gap, privacy: vm.privacyMode))").font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteTier)
            }
            .navigationTitle("Tiers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(for: String.self) { name in
                if let t = vm.plan.tiers.first(where: { $0.name == name }) {
                    TierDetailView(tier: t)
                }
            }
            .sheet(isPresented: $showAdd) { AddTierSheet(isPresented: $showAdd) }
        }
    }

    func deleteTier(at offsets: IndexSet) {
        let names = vm.plan.sortedByPriority.enumerated().filter { offsets.contains($0.offset) }.map { $0.element.name }
        vm.plan.tiers.removeAll { names.contains($0.name) }
        vm.save()
    }
}

struct AddTierSheet: View {
    @EnvironmentObject var vm: PlanViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var purpose = ""
    @State private var target = "0"
    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    TextField("Purpose", text: $purpose)
                    TextField("Target", text: $target).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Tier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { add() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
    }
    func add() {
        let priority = (vm.plan.tiers.map { $0.priority }.max() ?? 0) + 1
        let t = Tier(name: name, purpose: purpose, target: Double(target) ?? 0, priority: priority, accounts: [], preferredAccount: nil)
        vm.plan.tiers.append(t)
        vm.save(); isPresented = false
    }
}

