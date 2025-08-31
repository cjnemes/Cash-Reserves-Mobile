import SwiftUI
import ReserveEngine
import Charts

struct DashboardView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var isLoading = false
    @State private var showPrivacyToggle = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    heroMetricsCard
                    quickActionButtons
                    fundingProgressCard
                    if !vm.plan.tiers.isEmpty {
                        distributionChart
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
            .refreshable {
                await refreshData()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            vm.privacyMode.toggle()
                        }
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    } label: {
                        Image(systemName: vm.privacyMode ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(vm.privacyMode ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                    }
                    .accessibilityLabel(vm.privacyMode ? "Show amounts" : "Hide amounts")
                }
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    private var heroMetricsCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Main total with animated counter
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Total Cash Reserves")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                    Text(MoneyFormat.format(vm.plan.totalReserves, privacy: vm.privacyMode))
                        .font(AppTheme.Typography.moneyPrimary)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .contentTransition(.numericText(value: vm.plan.totalReserves))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: vm.plan.totalReserves)
                    
                    let totalTarget = vm.plan.tiers.reduce(0) { $0 + $1.target }
                    if !vm.privacyMode && totalTarget > 0 {
                        let percentage = min(100, (vm.plan.totalReserves / totalTarget) * 100)
                        Text("(\(percentage, specifier: "%.0f")%)")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.success)
                    }
                }
            }
            
            // Key metrics row
            let totalTarget = vm.plan.tiers.reduce(0) { $0 + $1.target }
            HStack(spacing: AppTheme.Spacing.lg) {
                MetricView(
                    title: "Target",
                    value: MoneyFormat.format(totalTarget, privacy: vm.privacyMode, compact: true),
                    color: AppTheme.Colors.info
                )
                
                Divider()
                    .frame(height: 30)
                
                MetricView(
                    title: "Remaining",
                    value: MoneyFormat.format(max(0, totalTarget - vm.plan.totalReserves), privacy: vm.privacyMode, compact: true),
                    color: AppTheme.Colors.warning
                )
                
                Divider()
                    .frame(height: 30)
                
                MetricView(
                    title: "Accounts",
                    value: "\(vm.plan.tiers.flatMap(\.accounts).count)",
                    color: AppTheme.Colors.primary
                )
            }
            .frame(maxWidth: .infinity)
        }
        .primaryCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total reserves: \(MoneyFormat.format(vm.plan.totalReserves, privacy: false))")
    }
    
    private var quickActionButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.3)) {
                    vm.selectedTab = 3 // Planner tab
                }
            } label: {
                Label("Add Money", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .primaryButton()
            .accessibilityHint("Navigate to planner to allocate new cash")
            
            Button {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.3)) {
                    vm.selectedTab = 1 // Tiers tab
                }
            } label: {
                Label("Manage Tiers", systemImage: "square.grid.2x2")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity)
            }
            .secondaryButton()
            .accessibilityLabel("Manage tiers")
        }
    }
    
    private var fundingProgressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Funding Progress")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        vm.selectedTab = 1
                    }
                } label: {
                    Text("View All")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if vm.plan.tiers.isEmpty {
                EmptyStateView(
                    title: "No Tiers Yet",
                    subtitle: "Create your first tier to start tracking your cash reserves",
                    systemImage: "square.grid.2x2",
                    actionTitle: "Add Tier"
                ) {
                    vm.selectedTab = 1
                }
            } else {
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(vm.plan.sortedByPriority.prefix(4), id: \.name) { tier in
                        TierProgressRow(tier: tier, privacy: vm.privacyMode)
                    }
                    
                    if vm.plan.tiers.count > 4 {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                vm.selectedTab = 1
                            }
                        } label: {
                            HStack {
                                Text("View \(vm.plan.tiers.count - 4) more tiers")
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundColor(AppTheme.Colors.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                            .padding(.vertical, AppTheme.Spacing.xs)
                        }
                    }
                }
            }
        }
        .primaryCard()
    }
    
    private var distributionChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Portfolio Distribution")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
            }
            
            Chart(vm.plan.sortedByPriority, id: \.name) { tier in
                BarMark(
                    x: .value("Amount", tier.total),
                    y: .value("Tier", tier.name)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(4)
            }
            .frame(height: CGFloat(max(180, vm.plan.tiers.count * 32)))
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(MoneyFormat.format(doubleValue, compact: true))
                                .font(AppTheme.Typography.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let stringValue = value.as(String.self) {
                            Text(stringValue)
                                .font(AppTheme.Typography.caption2)
                        }
                    }
                }
            }
        }
        .primaryCard()
        .accessibilityLabel("Distribution chart showing cash allocation across tiers")
    }
    
    private func refreshData() async {
        isLoading = true
        await vm.load()
        isLoading = false
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Supporting Views

struct MetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.moneyTertiary)
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TierProgressRow: View {
    let tier: Tier
    let privacy: Bool
    
    private var progress: Double {
        tier.target > 0 ? min(1.0, tier.total / max(1, tier.target)) : 0
    }
    
    private var progressColor: Color {
        if progress >= 1.0 { return AppTheme.Colors.success }
        if progress >= 0.75 { return AppTheme.Colors.info }
        if progress >= 0.5 { return AppTheme.Colors.warning }
        return AppTheme.Colors.error
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(tier.name)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(MoneyFormat.format(tier.total, privacy: privacy, compact: true))
                        .font(AppTheme.Typography.moneyTertiary)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    if tier.target > 0 {
                        Text("\(progress * 100, specifier: "%.0f")%")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(progressColor)
                    }
                }
            }
            
            if tier.target > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                            .fill(AppTheme.Colors.border.opacity(0.3))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                            .fill(
                                LinearGradient(
                                    colors: [progressColor, progressColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 6)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tier.name): \(MoneyFormat.format(tier.total, privacy: false)) of \(MoneyFormat.format(tier.target, privacy: false)) target")
        .accessibilityValue("\(progress * 100, specifier: "%.0f") percent funded")
    }
}
