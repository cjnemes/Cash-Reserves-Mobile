import SwiftUI
import ReserveEngine

// MARK: - Welcome Step

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            WelcomeAnimationView()
            
            VStack(spacing: AppTheme.Spacing.lg) {
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Build Financial Security")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Transform how you think about emergency funds and financial planning with our proven 6-tier cash reserve system.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    FeatureHighlightCard(
                        icon: "target",
                        title: "Priority-Based Planning",
                        description: "Organize your savings by importance and urgency",
                        color: AppTheme.Colors.primary,
                        isHighlighted: true
                    )
                    
                    FeatureHighlightCard(
                        icon: "arrow.triangle.branch",
                        title: "Smart Allocation",
                        description: "Automatically distribute money where it's needed most",
                        color: AppTheme.Colors.success
                    )
                    
                    FeatureHighlightCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Progress",
                        description: "Visual insights into your financial growth",
                        color: AppTheme.Colors.info
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Concept Explanation

struct ConceptExplanationView: View {
    @State private var selectedTierIndex: Int = 0
    
    private let conceptTiers = [
        (
            title: "Tier 1: Buffer",
            purpose: "Daily expenses & small emergencies",
            example: "Unexpected bill, car repair",
            target: "$500 - $1,000",
            priority: 1,
            color: Color.blue
        ),
        (
            title: "Tier 2: Emergency Fund",
            purpose: "Major life disruptions",
            example: "Job loss, medical emergency",
            target: "3-6 months expenses",
            priority: 2,
            color: Color.green
        ),
        (
            title: "Tier 3: Major Repairs",
            purpose: "Home & vehicle maintenance",
            example: "HVAC repair, new roof",
            target: "$5,000 - $15,000",
            priority: 3,
            color: Color.orange
        ),
        (
            title: "Tier 4: Opportunities",
            purpose: "Investment & growth",
            example: "Market dip, new business",
            target: "Variable amount",
            priority: 4,
            color: Color.purple
        ),
        (
            title: "Tier 5: Long-term Goals",
            purpose: "Future major purchases",
            example: "Home down payment, education",
            target: "Goal-specific",
            priority: 5,
            color: Color.indigo
        ),
        (
            title: "Tier 6: Legacy",
            purpose: "Wealth preservation",
            example: "Estate planning, inheritance",
            target: "Discretionary",
            priority: 6,
            color: Color.pink
        )
    ]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Explanation text
            VStack(spacing: AppTheme.Spacing.md) {
                Text("How the 6-Tier System Works")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Each tier serves a specific purpose and has a priority level. Money flows to fill gaps in order of priority, ensuring your most critical needs are covered first.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .primaryCard()
            
            // Interactive tier selector
            VStack(spacing: AppTheme.Spacing.lg) {
                // Tier buttons
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppTheme.Spacing.sm) {
                    ForEach(0..<conceptTiers.count, id: \.self) { index in
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedTierIndex = index
                            }
                            
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } label: {
                            VStack(spacing: AppTheme.Spacing.xs) {
                                Text("Tier \(conceptTiers[index].priority)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(selectedTierIndex == index ? .white : conceptTiers[index].color)
                                
                                Text(conceptTiers[index].title.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces))
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundColor(selectedTierIndex == index ? .white.opacity(0.9) : AppTheme.Colors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(selectedTierIndex == index ? conceptTiers[index].color : conceptTiers[index].color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm, style: .continuous)
                                    .stroke(conceptTiers[index].color.opacity(selectedTierIndex == index ? 0.0 : 0.3), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Select \(conceptTiers[index].title)")
                    }
                }
                
                // Selected tier details
                let selectedTier = conceptTiers[selectedTierIndex]
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Circle()
                            .fill(selectedTier.color)
                            .frame(width: 8, height: 8)
                        
                        Text(selectedTier.title)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        Spacer()
                        
                        Text("Priority \(selectedTier.priority)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .padding(.horizontal, AppTheme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(selectedTier.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        DetailRow(title: "Purpose", value: selectedTier.purpose)
                        DetailRow(title: "Example", value: selectedTier.example)
                        DetailRow(title: "Typical Target", value: selectedTier.target)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(selectedTier.color.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                        .stroke(selectedTier.color.opacity(0.2), lineWidth: 1)
                )
                .id("tier-details-\(selectedTierIndex)") // Force re-render with animation
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: 10)),
                    removal: .opacity.combined(with: .scale(scale: 1.05)).combined(with: .offset(y: -10))
                ))
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Text(value)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primaryText)
        }
    }
}

// MARK: - Tier Demo

struct TierDemoView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var currentlyHighlighted: Int = 0
    @State private var autoAdvanceTimer: Timer?
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Your Tiers in Action")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("Here's how a sample cash reserve plan might look. Each tier has a different purpose and priority level.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .primaryCard()
            
            // Demo tiers
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(Array(viewModel.demoTiers.enumerated()), id: \.element.id) { index, tier in
                    TierDemoCard(
                        tier: tier,
                        isAnimating: currentlyHighlighted == index
                    )
                    .onTapGesture {
                        highlightTier(index)
                    }
                    .accessibilityAddTraits(currentlyHighlighted == index ? .isSelected : [])
                }
            }
            
            // Control buttons
            HStack(spacing: AppTheme.Spacing.md) {
                Button("Reset Demo") {
                    viewModel.resetDemoData()
                    currentlyHighlighted = 0
                    restartAutoAdvance()
                }
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .accessibilityLabel("Reset demo to initial state")
                
                Spacer()
                
                Button(autoAdvanceTimer == nil ? "Start Tour" : "Stop Tour") {
                    if autoAdvanceTimer == nil {
                        startAutoAdvance()
                    } else {
                        stopAutoAdvance()
                    }
                }
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primary)
                .accessibilityLabel(autoAdvanceTimer == nil ? "Start automatic tour of tiers" : "Stop automatic tour")
            }
        }
        .onAppear {
            startAutoAdvance()
        }
        .onDisappear {
            stopAutoAdvance()
        }
        .accessibilityElement(children: .contain)
    }
    
    private func highlightTier(_ index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentlyHighlighted = index
        }
        
        OnboardingHaptics.selection()
        
        restartAutoAdvance()
    }
    
    private func startAutoAdvance() {
        let tierCount = viewModel.demoTiers.count
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                currentlyHighlighted = (currentlyHighlighted + 1) % tierCount
            }
        }
    }
    
    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }
    
    private func restartAutoAdvance() {
        stopAutoAdvance()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            startAutoAdvance()
        }
    }
}

// MARK: - Allocation Demo

struct AllocationDemoView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var hasRunDemo = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Smart Money Allocation")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("Watch how new money automatically flows to fill gaps in priority order. Higher priority tiers get filled first.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .primaryCard()
            
            // Amount input
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    Text("New Money to Allocate:")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Spacer()
                }
                
                HStack(spacing: AppTheme.Spacing.md) {
                    TextField("Amount", text: $viewModel.demoAllocationAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: viewModel.demoAllocationAmount) { newValue in
                            let cleaned = InputFormatters.cleanNumberString(newValue)
                            if cleaned != newValue {
                                viewModel.demoAllocationAmount = cleaned
                            }
                        }
                    
                    Button("Run Demo") {
                        hideKeyboard()
                        runAllocationDemo()
                    }
                    .primaryButton()
                    .disabled(Double(viewModel.demoAllocationAmount) == nil || viewModel.showingAllocationPreview)
                    .accessibilityLabel("Run allocation demonstration")
                }
            }
            .primaryCard()
            
            // Demo tiers with allocation preview
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel.demoTiers) { tier in
                    TierDemoCard(
                        tier: tier,
                        isAnimating: viewModel.showingAllocationPreview && tier.gap > 0,
                        showAllocation: viewModel.showingAllocationPreview,
                        allocatedAmount: calculateAllocation(for: tier)
                    )
                }
            }
            
            // Reset button
            if hasRunDemo {
                Button("Reset Demo") {
                    resetDemo()
                }
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .accessibilityLabel("Reset allocation demo")
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func runAllocationDemo() {
        hasRunDemo = true
        viewModel.runAllocationDemo()
        
        OnboardingHaptics.medium()
        OnboardingAnnouncements.announceAllocationDemo(amount: viewModel.demoAllocationAmount)
    }
    
    private func resetDemo() {
        viewModel.resetDemoData()
        hasRunDemo = false
        
        OnboardingHaptics.light()
        OnboardingAnnouncements.announceDemoReset()
    }
    
    private func calculateAllocation(for tier: DemoTier) -> Double {
        guard let totalAmount = Double(viewModel.demoAllocationAmount) else { return 0 }
        
        var remaining = totalAmount
        for demoTier in viewModel.demoTiers.sorted(by: { $0.priority < $1.priority }) {
            let gap = max(0, demoTier.target - demoTier.current)
            let allocation = min(remaining, gap)
            
            if demoTier.id == tier.id {
                return allocation
            }
            
            remaining -= allocation
        }
        
        return 0
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - First Tier Setup

struct FirstTierSetupView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    private let tierSuggestions = [
        ("Emergency Buffer", "Daily expenses & small emergencies", "1000"),
        ("Emergency Fund", "3-6 months of living expenses", "15000"),
        ("Home Maintenance", "Major repairs & improvements", "8000"),
        ("Investment Fund", "Market opportunities & growth", "25000")
    ]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Create Your First Tier")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("Start with your most important financial goal. You can add more tiers later from the main app.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .primaryCard()
            
            // Quick suggestions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Popular Starting Points")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(tierSuggestions, id: \.0) { suggestion in
                        Button {
                            viewModel.firstTierName = suggestion.0
                            viewModel.firstTierPurpose = suggestion.1
                            viewModel.firstTierTarget = suggestion.2
                            
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } label: {
                            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.0)
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundColor(AppTheme.Colors.primaryText)
                                    
                                    Text(suggestion.1)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.secondaryText)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                Text(MoneyFormat.format(Double(suggestion.2) ?? 0, compact: true))
                                    .font(AppTheme.Typography.moneyTertiary)
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                                    .stroke(AppTheme.Colors.border.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Use suggestion: \(suggestion.0)")
                    }
                }
            }
            
            // Manual input form
            VStack(spacing: AppTheme.Spacing.lg) {
                Divider()
                
                Text("Or Create Your Own")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                VStack(spacing: AppTheme.Spacing.md) {
                    OnboardingTextField(
                        title: "Tier Name *",
                        placeholder: "e.g., Emergency Fund",
                        text: $viewModel.firstTierName
                    )
                    
                    OnboardingTextField(
                        title: "Purpose",
                        placeholder: "What is this money for?",
                        text: $viewModel.firstTierPurpose
                    )
                    
                    OnboardingTextField(
                        title: "Target Amount *",
                        placeholder: "0",
                        text: $viewModel.firstTierTarget,
                        keyboardType: .decimalPad,
                        formatter: { value in
                            let cleaned = InputFormatters.cleanNumberString(value)
                            return cleaned
                        }
                    )
                }
                .primaryCard()
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - First Account Setup

struct FirstAccountSetupView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    private let accountSuggestions = [
        ("Checking Account", "0"),
        ("Savings Account", "500"),
        ("High-Yield Savings", "1000"),
        ("Money Market", "2500")
    ]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Add Your First Account")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("Connect a bank account to your tier. This is where the money for this tier will be stored.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .primaryCard()
            
            // Current tier info
            if !viewModel.firstTierName.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Adding account to:")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.firstTierName)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        if !viewModel.firstTierPurpose.isEmpty {
                            Text(viewModel.firstTierPurpose)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        
                        if let target = Double(viewModel.firstTierTarget), target > 0 {
                            Text("Target: \(MoneyFormat.format(target))")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                .primaryCard()
            }
            
            // Quick suggestions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("Common Account Types")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(accountSuggestions, id: \.0) { suggestion in
                        Button {
                            viewModel.firstAccountName = suggestion.0
                            viewModel.firstAccountBalance = suggestion.1
                            
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        } label: {
                            HStack {
                                Text(suggestion.0)
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.Colors.primaryText)
                                
                                Spacer()
                                
                                Text(MoneyFormat.format(Double(suggestion.1) ?? 0))
                                    .font(AppTheme.Typography.moneyTertiary)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                                    .stroke(AppTheme.Colors.border.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Use suggestion: \(suggestion.0)")
                    }
                }
            }
            
            // Manual input form
            VStack(spacing: AppTheme.Spacing.lg) {
                Divider()
                
                Text("Or Enter Manually")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                VStack(spacing: AppTheme.Spacing.md) {
                    OnboardingTextField(
                        title: "Account Name *",
                        placeholder: "e.g., Chase Savings",
                        text: $viewModel.firstAccountName
                    )
                    
                    OnboardingTextField(
                        title: "Current Balance",
                        placeholder: "0",
                        text: $viewModel.firstAccountBalance,
                        keyboardType: .decimalPad,
                        formatter: { value in
                            let cleaned = InputFormatters.cleanNumberString(value)
                            return cleaned
                        }
                    )
                }
                .primaryCard()
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Completion Step

struct CompletionStepView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showingCelebration = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            // Celebration animation
            VStack(spacing: AppTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.success, AppTheme.Colors.success.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(showingCelebration ? 1.0 : 0.8)
                        .opacity(showingCelebration ? 1.0 : 0.0)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showingCelebration ? 1.0 : 0.6)
                        .opacity(showingCelebration ? 1.0 : 0.0)
                }
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        showingCelebration = true
                    }
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("You're All Set!")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text(viewModel.hasSkippedSetup ? 
                         "You can create tiers and accounts anytime from the main app." :
                         "Your first tier and account have been created. You're ready to start building your financial security!")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            
            // Next steps
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("What's Next?")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    FeatureHighlightCard(
                        icon: "plus.circle",
                        title: "Add Money",
                        description: "Use the Planner tab to allocate new cash to your tiers",
                        color: AppTheme.Colors.primary
                    )
                    
                    FeatureHighlightCard(
                        icon: "square.grid.2x2",
                        title: "Manage Tiers",
                        description: "Create additional tiers for different financial goals",
                        color: AppTheme.Colors.success
                    )
                    
                    FeatureHighlightCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Progress",
                        description: "Monitor your financial growth on the Dashboard",
                        color: AppTheme.Colors.info
                    )
                }
            }
            .primaryCard()
            
            // Additional resources
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Need Help?")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("Visit the Settings page for tutorials, tips, and support resources.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview("Welcome") {
    WelcomeStepView()
}

#Preview("Concept") {
    ConceptExplanationView()
}

#Preview("Completion") {
    CompletionStepView()
        .environmentObject(OnboardingViewModel())
}