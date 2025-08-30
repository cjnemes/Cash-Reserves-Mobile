import SwiftUI
import ReserveEngine
import Charts

struct DashboardView: View {
    @EnvironmentObject var vm: PlanViewModel
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    totalsCard
                    gapsCard
                    distributionChart
                }
                .padding()
            }
            .navigationTitle("Cash Reserves")
        }
    }

    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Reserves").font(.headline)
            Text(MoneyFormat.format(vm.plan.totalReserves, privacy: vm.privacyMode, compact: true)).font(.largeTitle).bold()
            Divider()
            ForEach(vm.plan.sortedByPriority, id: \.name) { tier in
                HStack {
                    Text(tier.name).font(.subheadline)
                    Spacer()
                    Text(MoneyFormat.format(tier.total, privacy: vm.privacyMode))
                }
            }
        }
        .sectionCard()
    }

    private var gapsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Funding Progress").font(.headline)
            ForEach(vm.plan.sortedByPriority, id: \.name) { tier in
                VStack(alignment: .leading) {
                    HStack {
                        Text(tier.name)
                        Spacer()
                        let pct = tier.target > 0 ? min(1.0, tier.total / max(1, tier.target)) : 0
                        Text(String(format: "%.0f%%", pct * 100)).foregroundStyle(.secondary)
                    }
                    ProgressView(value: tier.target > 0 ? tier.total / max(1, tier.target) : 0)
                }
            }
        }
        .sectionCard()
    }

    private var distributionChart: some View {
        VStack(alignment: .leading) {
            Text("Distribution by Tier").font(.headline)
            Chart(vm.plan.sortedByPriority, id: \.name) { tier in
                BarMark(
                    x: .value("Amount", tier.total),
                    y: .value("Tier", tier.name)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: CGFloat(max(120, vm.plan.tiers.count * 24)))
        }
        .sectionCard()
    }
}
