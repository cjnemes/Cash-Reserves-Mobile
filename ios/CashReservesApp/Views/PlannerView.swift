import SwiftUI
import ReserveEngine

struct PlannerView: View {
    @EnvironmentObject var vm: PlanViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("New Cash") {
                    TextField("Amount", text: $vm.previewAmount)
                        .keyboardType(.decimalPad)
                        .onChange(of: vm.previewAmount) { _ in vm.refreshPreview() }
                    Button("Apply Allocation") { vm.applyAllocation() }
                        .buttonStyle(.borderedProminent)
                }
                Section("By Tier") {
                    if vm.previewMovesTier.isEmpty { Text("All targets met. Consider Tier 4 for growth.").foregroundStyle(.secondary) }
                    ForEach(Array(vm.previewMovesTier.enumerated()), id: \.offset) { _, move in
                        HStack { Text(move.0); Spacer(); Text(MoneyFormat.format(move.1, privacy: vm.privacyMode)) }
                    }
                }
                Section("By Account") {
                    ForEach(Array(vm.previewMovesDetailed.enumerated()), id: \.offset) { _, m in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(m.0)
                                Text(m.1).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(MoneyFormat.format(m.2, privacy: vm.privacyMode))
                        }
                    }
                }
            }
            .navigationTitle("Planner")
        }
    }
}

