import SwiftUI
import ReserveEngine

struct AccountEditContext: Identifiable {
    let id = UUID()
    let tierIndex: Int
    let accountIndex: Int?
}

struct AccountsView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var editContext: AccountEditContext? = nil
    @State private var searchText = ""
    @State private var selectedFilter: AccountFilter = .all
    @State private var showingAddAccountSheet = false
    
    enum AccountFilter: String, CaseIterable {
        case all = "All"
        case preferred = "Preferred"
        case highYield = "High Yield"
        
        var systemImage: String {
            switch self {
            case .all: return "creditcard"
            case .preferred: return "star.fill"
            case .highYield: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    private var filteredAccounts: [(tier: Tier, accounts: [(account: Account, index: Int)])] {
        var result: [(tier: Tier, accounts: [(account: Account, index: Int)])] = []
        
        for tier in vm.plan.sortedByPriority {
            var filteredTierAccounts: [(account: Account, index: Int)] = []
            
            for (index, account) in tier.accounts.enumerated() {
                // Apply search filter
                let matchesSearch = searchText.isEmpty ||
                    account.name.localizedCaseInsensitiveContains(searchText) ||
                    tier.name.localizedCaseInsensitiveContains(searchText)
                
                // Apply category filter
                let matchesFilter: Bool
                switch selectedFilter {
                case .all:
                    matchesFilter = true
                case .preferred:
                    matchesFilter = tier.preferredAccount == account.name
                case .highYield:
                    matchesFilter = account.apyPct > 3.0
                }
                
                if matchesSearch && matchesFilter {
                    filteredTierAccounts.append((account: account, index: index))
                }
            }
            
            if !filteredTierAccounts.isEmpty {
                result.append((tier: tier, accounts: filteredTierAccounts))
            }
        }
        
        return result
    }
    
    private var totalAccounts: Int {
        vm.plan.tiers.flatMap(\.accounts).count
    }
    
    private var totalBalance: Double {
        vm.plan.tiers.flatMap(\.accounts).reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        NavigationStack {
            Group {
                if totalAccounts == 0 {
                    emptyState
                } else {
                    accountsList
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showingAddAccountSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add new account")
                }
            }
            .searchable(text: $searchText, prompt: "Search accounts...")
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
            .sheet(isPresented: $showingAddAccountSheet) {
                AddAccountSheet(isPresented: $showingAddAccountSheet, editContext: $editContext)
                    .environmentObject(vm)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            EmptyStateView(
                title: "No Accounts Yet",
                subtitle: "Add accounts to your tiers to start tracking your cash reserves. Each account can have different interest rates and allocation weights.",
                systemImage: "creditcard",
                actionTitle: "Add First Account"
            ) {
                showingAddAccountSheet = true
            }
        }
        .padding(AppTheme.Spacing.md)
    }
    
    private var accountsList: some View {
        VStack(spacing: 0) {
            // Summary header
            summaryCard
            
            // Filter tabs
            filterTabs
            
            // Accounts list
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    ForEach(filteredAccounts, id: \.tier.name) { tierData in
                        let actualTierIndex = vm.plan.tiers.firstIndex { $0.name == tierData.tier.name } ?? 0
                        AccountTierSection(
                            tier: tierData.tier,
                            accounts: tierData.accounts,
                            privacy: vm.privacyMode,
                            actualTierIndex: actualTierIndex,
                            onEditAccount: { accountIndex in
                                editContext = AccountEditContext(tierIndex: actualTierIndex, accountIndex: accountIndex)
                            },
                            onTogglePreferred: { accountName in
                                togglePreferred(tierIndex: actualTierIndex, accountName: accountName)
                            },
                            onAddAccount: {
                                editContext = AccountEditContext(tierIndex: actualTierIndex, accountIndex: nil)
                            }
                        )
                    }
                    
                    if filteredAccounts.isEmpty && !searchText.isEmpty {
                        EmptySearchResults()
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
    }
    
    private var summaryCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Total Balance")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Text(MoneyFormat.format(totalBalance, privacy: vm.privacyMode))
                        .font(AppTheme.Typography.moneySecondary)
                        .foregroundColor(AppTheme.Colors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                    Text("\(totalAccounts)")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text(totalAccounts == 1 ? "Account" : "Accounts")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            
            // Average APY
            if totalAccounts > 0 {
                let avgAPY = vm.plan.tiers.flatMap(\.accounts).reduce(0) { total, account in
                    total + (account.apyPct * account.balance)
                } / totalBalance
                
                HStack {
                    Text("Weighted Average APY")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(avgAPY, specifier: "%.2f")%")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.success)
                }
            }
        }
        .primaryCard()
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.md)
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(AccountFilter.allCases, id: \.rawValue) { filter in
                    FilterTab(
                        title: filter.rawValue,
                        systemImage: filter.systemImage,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
    
    private func countForFilter(_ filter: AccountFilter) -> Int {
        let allAccounts = vm.plan.tiers.flatMap { tier in
            tier.accounts.map { (tier, $0) }
        }
        
        switch filter {
        case .all:
            return allAccounts.count
        case .preferred:
            return allAccounts.filter { tier, account in
                tier.preferredAccount == account.name
            }.count
        case .highYield:
            return allAccounts.filter { _, account in
                account.apyPct > 3.0
            }.count
        }
    }
    
    private func togglePreferred(tierIndex: Int, accountName: String) {
        let currentPreferred = vm.plan.tiers[tierIndex].preferredAccount
        
        withAnimation(.spring(response: 0.3)) {
            if currentPreferred == accountName {
                vm.plan.tiers[tierIndex].preferredAccount = nil
            } else {
                vm.plan.tiers[tierIndex].preferredAccount = accountName
            }
            vm.save()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Supporting Views

struct FilterTab: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.caption)
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                
                if count > 0 {
                    Text("\(count)")
                        .font(AppTheme.Typography.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ?
                            AppTheme.Colors.primary.opacity(0.2) :
                            AppTheme.Colors.border.opacity(0.5)
                        )
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(
                isSelected ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText
            )
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                isSelected ?
                AppTheme.Colors.primaryLight :
                AppTheme.Colors.elevated
            )
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AccountTierSection: View {
    let tier: Tier
    let accounts: [(account: Account, index: Int)]
    let privacy: Bool
    let actualTierIndex: Int
    let onEditAccount: (Int) -> Void
    let onTogglePreferred: (String) -> Void
    let onAddAccount: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Section header
            HStack {
                Text(tier.name)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                Text("\(accounts.count) of \(tier.accounts.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            // Accounts
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(accounts, id: \.account.name) { accountData in
                    ModernAccountRowView(
                        account: accountData.account,
                        isPreferred: tier.preferredAccount == accountData.account.name,
                        privacy: privacy
                    ) {
                        // Edit account - pass the correct account index
                        onEditAccount(accountData.index)
                    } onTogglePreferred: {
                        // Toggle preferred
                        onTogglePreferred(accountData.account.name)
                    }
                }
            }
        }
        .primaryCard()
    }
}

struct ModernAccountRowView: View {
    let account: Account
    let isPreferred: Bool
    let privacy: Bool
    let onEdit: () -> Void
    let onTogglePreferred: () -> Void
    
    private var apyColor: Color {
        if account.apyPct >= 4.5 { return AppTheme.Colors.success }
        if account.apyPct >= 3.0 { return AppTheme.Colors.info }
        if account.apyPct >= 1.0 { return AppTheme.Colors.warning }
        return AppTheme.Colors.error
    }
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Account icon and info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(account.name)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .fontWeight(.medium)
                        
                        if isPreferred {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.warning)
                        }
                    }
                    
                    HStack(spacing: AppTheme.Spacing.md) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text("APY")
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            Text("\(account.apyPct, specifier: "%.2f")%")
                                .font(AppTheme.Typography.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(apyColor)
                        }
                        
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text("Weight")
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            Text("\(account.allocWeight, specifier: "%.1f")")
                                .font(AppTheme.Typography.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.Colors.primaryText)
                        }
                    }
                }
                
                Spacer()
                
                // Balance
                Text(MoneyFormat.format(account.balance, privacy: privacy))
                    .font(AppTheme.Typography.moneyTertiary)
                    .foregroundColor(AppTheme.Colors.primaryText)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Account", systemImage: "pencil")
            }
            
            if isPreferred {
                Button {
                    onTogglePreferred()
                } label: {
                    Label("Remove as Preferred", systemImage: "star.slash")
                }
            } else {
                Button {
                    onTogglePreferred()
                } label: {
                    Label("Set as Preferred", systemImage: "star.fill")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), \(MoneyFormat.format(account.balance, privacy: false)), \(account.apyPct, specifier: "%.2f") percent APY")
        .accessibilityHint(isPreferred ? "Preferred account" : "")
    }
}

struct EmptySearchResults: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Text("No matching accounts")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Text("Try adjusting your search terms or filters")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - Add Account Sheet
struct AddAccountSheet: View {
    @EnvironmentObject var vm: PlanViewModel
    @Binding var isPresented: Bool
    @Binding var editContext: AccountEditContext?
    @State private var selectedTierIndex = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                if vm.plan.tiers.isEmpty {
                    Text("Create a tier first before adding accounts")
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .padding()
                } else {
                    Form {
                        Section {
                            Picker("Tier", selection: $selectedTierIndex) {
                                ForEach(Array(vm.plan.tiers.enumerated()), id: \.offset) { index, tier in
                                    Text(tier.name).tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                        } header: {
                            Text("Select Tier")
                        } footer: {
                            Text("Choose which tier this account belongs to")
                        }
                    }
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        // Set edit context to create new account in selected tier
                        editContext = AccountEditContext(tierIndex: selectedTierIndex, accountIndex: nil)
                        isPresented = false
                    }
                    .disabled(vm.plan.tiers.isEmpty)
                }
            }
        }
    }
}
