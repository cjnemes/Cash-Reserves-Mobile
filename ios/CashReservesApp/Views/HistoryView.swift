import SwiftUI
import ReserveEngine
import Charts

struct HistoryView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var selectedTier: String = "All"
    @State private var selectedAccount: String = "All"
    @State private var days: Int = 90
    var body: some View {
        NavigationStack {
            VStack {
                filters
                List(filtered) { t in
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
                if showChart {
                    chartSection
                        .padding()
                }
            }
            .navigationTitle("History")
            .listStyle(.insetGrouped)
        }
    }

    private var filters: some View {
        VStack(alignment: .leading) {
            HStack {
                Picker("Tier", selection: $selectedTier) {
                    Text("All").tag("All")
                    ForEach(vm.plan.tiers.map { $0.name }, id: \.self) { t in Text(t).tag(t) }
                }
                .pickerStyle(.menu)
                Picker("Account", selection: $selectedAccount) {
                    Text("All").tag("All")
                    ForEach(currentAccounts, id: \.self) { a in Text(a).tag(a) }
                }
                .pickerStyle(.menu)
            }
            Picker("Range", selection: $days) {
                Text("30d").tag(30)
                Text("90d").tag(90)
                Text("1y").tag(365)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }

    private var filtered: [ReserveEngine.Transaction] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        return vm.transactions.filter { t in
            guard t.timestamp >= cutoff else { return false }
            if selectedTier != "All" && t.tierName != selectedTier { return false }
            if selectedAccount != "All" && t.accountName != selectedAccount { return false }
            return true
        }
    }

    private var currentAccounts: [String] {
        if selectedTier == "All" { return Array(Set(vm.transactions.map { $0.accountName })).sorted() }
        return Array(Set(vm.transactions.filter { $0.tierName == selectedTier }.map { $0.accountName })).sorted()
    }

    private var showChart: Bool { selectedAccount != "All" }

    private var chartSection: some View {
        VStack(alignment: .leading) {
            (Text("Balance Trend (") + Text(selectedAccount).bold() + Text(")"))
            Chart(seriesData, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Balance", item.balance)
                )
            }
            .frame(height: 200)
        }
        .sectionCard()
    }

    private var seriesData: [(date: Date, balance: Double)] {
        let tx = filtered
            .filter { $0.accountName == selectedAccount }
            .sorted(by: { $0.timestamp < $1.timestamp })
        return tx.map { ($0.timestamp, $0.balanceAfter) }
    }
}
