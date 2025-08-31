import SwiftUI
import ReserveEngine

struct PlannerView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var inputAmount = ""
    @State private var isAllocating = false
    @State private var showConfirmationAlert = false
    @FocusState private var amountFieldFocused: Bool
    
    private var allocatableAmount: Double {
        Double(InputFormatters.cleanNumberString(inputAmount)) ?? 0
    }
    
    private var hasPreview: Bool {
        !vm.previewMovesTier.isEmpty || !vm.previewMovesDetailed.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    inputCard
                    
                    if hasPreview {
                        allocationPreview
                        detailedBreakdown
                    } else {
                        emptyStateCard
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
            .navigationTitle("Cash Planner")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                inputAmount = vm.previewAmount
            }
            .alert("Confirm Allocation", isPresented: $showConfirmationAlert) {
                Button("Allocate", role: .destructive) {
                    performAllocation()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will allocate \(MoneyFormat.format(allocatableAmount)) to your accounts. This action cannot be undone.")
            }
        }
    }
    
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("New Cash to Allocate")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            HStack {
                Text("$")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                TextField("0", text: $inputAmount)
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .keyboardType(.decimalPad)
                    .focused($amountFieldFocused)
                    .onChange(of: inputAmount) { newValue in
                        vm.previewAmount = newValue
                        vm.refreshPreview()
                    }
                    .onChange(of: amountFieldFocused) { focused in
                        if !focused && !inputAmount.isEmpty {
                            inputAmount = InputFormatters.formatCurrencyString(inputAmount)
                            let cleaned = InputFormatters.cleanNumberString(inputAmount)
                            inputAmount = cleaned
                        }
                    }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            
            if allocatableAmount > 0 {
                Button {
                    showConfirmationAlert = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Allocate \(MoneyFormat.format(allocatableAmount, compact: true))")
                    }
                    .frame(maxWidth: .infinity)
                }
                .primaryButton()
                .disabled(isAllocating)
            } else {
                Text("Enter an amount to see allocation preview")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, AppTheme.Spacing.md)
            }
        }
        .primaryCard()
        .loadingOverlay(isAllocating)
    }
    
    private var allocationPreview: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Allocation Preview")
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            if vm.previewMovesTier.isEmpty {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.Colors.success)
                    
                    Text("All Targets Met!")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text("Your priority tiers are fully funded. Consider allocating to growth tiers or creating new investment goals.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.Spacing.lg)
            } else {
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(vm.previewMovesTier.enumerated()), id: \.offset) { _, allocation in
                        TierAllocationRow(
                            tierName: allocation.0,
                            amount: allocation.1,
                            privacy: vm.privacyMode
                        )
                    }
                }
            }
        }
        .primaryCard()
    }
    
    private var detailedBreakdown: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Account Breakdown")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Spacer()
                
                Button {
                    // Could show more details or collapse/expand
                } label: {
                    Text("Details")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            LazyVStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(vm.previewMovesDetailed.enumerated()), id: \.offset) { _, detail in
                    AccountAllocationRow(
                        accountName: detail.0,
                        tierName: detail.1,
                        amount: detail.2,
                        privacy: vm.privacyMode
                    )
                }
            }
        }
        .primaryCard()
    }
    
    private var emptyStateCard: some View {
        EmptyStateView(
            title: "Plan Your Allocation",
            subtitle: "Enter an amount above to see how your cash will be allocated across your tiers based on priorities and targets.",
            systemImage: "plus.slash.minus",
            actionTitle: nil
        ) {}
        .padding(.vertical, AppTheme.Spacing.xl)
    }
    
    private func performAllocation() {
        isAllocating = true
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            vm.applyAllocation()
        }
        
        // Clear input after successful allocation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            inputAmount = ""
            vm.previewAmount = ""
            vm.refreshPreview()
            isAllocating = false
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
}

// MARK: - Supporting Views

struct TierAllocationRow: View {
    let tierName: String
    let amount: Double
    let privacy: Bool
    
    private var amountColor: Color {
        amount > 0 ? AppTheme.Colors.success : AppTheme.Colors.secondaryText
    }
    
    var body: some View {
        HStack {
            HStack(spacing: AppTheme.Spacing.sm) {
                Circle()
                    .fill(amountColor)
                    .frame(width: 8, height: 8)
                
                Text(tierName)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
            }
            
            Spacer()
            
            Text(MoneyFormat.format(amount, privacy: privacy))
                .font(AppTheme.Typography.moneyTertiary)
                .foregroundColor(amountColor)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tierName) will receive \(MoneyFormat.format(amount, privacy: false))")
    }
}

struct AccountAllocationRow: View {
    let accountName: String
    let tierName: String
    let amount: Double
    let privacy: Bool
    
    private var amountColor: Color {
        amount > 0 ? AppTheme.Colors.info : AppTheme.Colors.secondaryText
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(accountName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(tierName)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            Text(MoneyFormat.format(amount, privacy: privacy))
                .font(AppTheme.Typography.moneyTertiary)
                .foregroundColor(amountColor)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.elevated.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(accountName) in \(tierName) will receive \(MoneyFormat.format(amount, privacy: false))")
    }
}

