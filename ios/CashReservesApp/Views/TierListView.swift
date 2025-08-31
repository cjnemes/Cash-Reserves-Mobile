import SwiftUI
import ReserveEngine

struct TierListView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var showAdd = false
    @State private var showDeleteAlert = false
    @State private var tierToDelete: String? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.plan.tiers.isEmpty {
                    emptyState
                } else {
                    tiersList
                }
            }
            .appBackground()
            .navigationTitle("Tiers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add new tier")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTierSheet(isPresented: $showAdd)
            }
            .alert("Delete Tier", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let tierName = tierToDelete {
                        deleteTier(named: tierName)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All accounts in this tier will be removed.")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            EmptyStateView(
                title: "No Tiers Yet",
                subtitle: "Create your first tier to start organizing your cash reserves. Tiers help you prioritize and track different financial goals.",
                systemImage: "square.grid.2x2",
                actionTitle: "Create First Tier"
            ) {
                showAdd = true
            }
        }
        .padding(AppTheme.Spacing.md)
    }
    
    private var tiersList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(vm.plan.sortedByPriority, id: \.name) { tier in
                    NavigationLink(destination: TierDetailView(tier: tier)) {
                        TierCardView(
                            tier: tier,
                            privacy: vm.privacyMode,
                            onDelete: {
                                tierToDelete = tier.name
                                showDeleteAlert = true
                            }
                        )
                    }
                    .buttonStyle(TierCardButtonStyle())
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }
    
    private func deleteTier(named tierName: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            vm.plan.tiers.removeAll { $0.name == tierName }
            vm.save()
        }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}

// MARK: - Tier Card View
struct TierCardView: View {
    let tier: Tier
    let privacy: Bool
    let onDelete: () -> Void
    
    private var progress: Double {
        tier.target > 0 ? min(1.0, tier.total / max(1, tier.target)) : 0
    }
    
    private var progressColor: Color {
        // Use tier-specific color with progress-based opacity
        let tierColor = AppTheme.Colors.TierColors.colorForPriority(tier.priority)
        if progress >= 1.0 { return tierColor }
        if progress >= 0.75 { return tierColor.opacity(0.9) }
        if progress >= 0.5 { return tierColor.opacity(0.7) }
        return tierColor.opacity(0.5)
    }
    
    private var priorityBadgeColor: Color {
        return AppTheme.Colors.TierColors.colorForPriority(tier.priority)
    }
    
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header with priority and accounts count
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        // Tier color indicator
                        Circle()
                            .fill(AppTheme.Colors.TierColors.colorForPriority(tier.priority))
                            .frame(width: 16, height: 16)
                        
                        Text(tier.name)
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .lineLimit(1)
                        
                        // Priority badge
                        Text("P\(tier.priority)")
                            .font(AppTheme.Typography.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(priorityBadgeColor)
                            .clipShape(Capsule())
                    }
                    
                    Text(tier.purpose)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Accounts indicator
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("\(tier.accounts.count)")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        Text(tier.accounts.count == 1 ? "Account" : "Accounts")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
                
                // Financial metrics
                VStack(spacing: AppTheme.Spacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            
                            Text(MoneyFormat.format(tier.total, privacy: privacy, compact: true))
                                .font(AppTheme.Typography.moneySecondary)
                                .foregroundColor(AppTheme.Colors.primaryText)
                        }
                        
                        Spacer()
                        
                        if tier.target > 0 {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Target")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                
                                Text(MoneyFormat.format(tier.target, privacy: privacy, compact: true))
                                    .font(AppTheme.Typography.moneySecondary)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                            }
                        }
                    }
                    
                    // Progress bar and gap
                    if tier.target > 0 {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            HStack {
                                Text("\(progress * 100, specifier: "%.0f")% funded")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(progressColor)
                                
                                Spacer()
                                
                                if tier.gap > 0 {
                                    Text("Gap: \(MoneyFormat.format(tier.gap, privacy: privacy, compact: true))")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.warning)
                                }
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                                        .fill(AppTheme.Colors.border.opacity(0.3))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                                        .fill(
                                            LinearGradient(
                                                colors: [progressColor, progressColor.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progress, height: 8)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
        }
        .primaryCard()
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Tier", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tier.name), \(tier.purpose)")
        .accessibilityValue("Priority \(tier.priority), \(MoneyFormat.format(tier.total, privacy: false)) of \(MoneyFormat.format(tier.target, privacy: false)) target, \(tier.accounts.count) accounts")
        }
    }

// MARK: - Add Tier Sheet
struct AddTierSheet: View {
    @EnvironmentObject var vm: PlanViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var purpose = ""
    @State private var target = ""
    @State private var priority: Int = 1
    @State private var isLoading = false
    @FocusState private var targetFieldFocused: Bool
    
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !purpose.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Name") {
                        TextField("Emergency Fund", text: $name)
                            .textInputAutocapitalization(.words)
                    }
                    
                    LabeledContent("Purpose") {
                        TextField("3-6 months of expenses", text: $purpose)
                            .textInputAutocapitalization(.sentences)
                    }
                    
                    LabeledContent("Target Amount") {
                        HStack {
                            Text("$")
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            
                            TextField("25,000", text: $target)
                                .keyboardType(.decimalPad)
                                .focused($targetFieldFocused)
                                .onChange(of: targetFieldFocused) { focused in
                                    if !focused && !target.isEmpty {
                                        target = InputFormatters.formatCurrencyString(target)
                                    }
                                }
                        }
                    }
                    
                    LabeledContent("Priority") {
                        Picker("Priority", selection: $priority) {
                            ForEach(1...10, id: \.self) { level in
                                HStack {
                                    Text("\(level)")
                                    if level <= 2 {
                                        Text("(Critical)").font(.caption).foregroundColor(AppTheme.Colors.error)
                                    } else if level <= 4 {
                                        Text("(Important)").font(.caption).foregroundColor(AppTheme.Colors.warning)
                                    } else if level <= 6 {
                                        Text("(Medium)").font(.caption).foregroundColor(AppTheme.Colors.info)
                                    } else {
                                        Text("(Low)").font(.caption).foregroundColor(AppTheme.Colors.secondaryText)
                                    }
                                }
                                .tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Tier Details")
                } footer: {
                    Text("Lower priority numbers are funded first. Most emergency funds should be Priority 1-2.")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            .navigationTitle("New Tier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTier()
                    }
                    .disabled(!isValidInput || isLoading)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Set default priority to next available
                priority = (vm.plan.tiers.map { $0.priority }.max() ?? 0) + 1
            }
        }
        .loadingOverlay(isLoading)
    }
    
    private func addTier() {
        isLoading = true
        
        let cleanTarget = InputFormatters.cleanNumberString(target)
        let targetAmount = Double(cleanTarget) ?? 0
        
        let newTier = Tier(
            name: name.trimmingCharacters(in: .whitespaces),
            purpose: purpose.trimmingCharacters(in: .whitespaces),
            target: targetAmount,
            priority: priority,
            accounts: [],
            preferredAccount: nil
        )
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            vm.plan.tiers.append(newTier)
            vm.save()
        }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        isLoading = false
        isPresented = false
    }
}

// MARK: - Custom Button Style
struct TierCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if configuration.isPressed {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                    }
            )
    }
}
