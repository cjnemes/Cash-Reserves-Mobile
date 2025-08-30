import SwiftUI
import ReserveEngine

struct HistoryView: View {
    @EnvironmentObject var vm: PlanViewModel
    var body: some View {
        NavigationStack {
            List(vm.transactions) { t in
                VStack(alignment: .leading) {
                    HStack {
                        Text(t.tierName)
                        Spacer()
                        Text(t.timestamp, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(t.accountName).font(.caption)
                        Spacer()
                        Text(MoneyFormat.format(t.amount))
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

