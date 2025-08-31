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
                        color: AppTheme.Colors.primary
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
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Sample 6-Tier Plan")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("Here's how a complete cash reserve plan might look. Tap any tier to learn about its purpose and priority.")
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
            
            // Current tier explanation
            if currentlyHighlighted < viewModel.demoTiers.count {
                let currentTier = viewModel.demoTiers[currentlyHighlighted]
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Circle()
                            .fill(AppTheme.Colors.primary)
                            .frame(width: 8, height: 8)
                        
                        Text("Priority \(currentTier.priority)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        Spacer()
                    }
                    
                    Text(currentTier.purpose)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm, style: .continuous)
                        .stroke(AppTheme.Colors.primary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func highlightTier(_ index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentlyHighlighted = index
        }
        
        OnboardingHaptics.selection()
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
                    
                    Text("Your complete 6-tier cash reserve system is ready! Each tier has a specific purpose and target amount, but you can customize everything to match your personal financial goals.")
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
                        icon: "slider.horizontal.3",
                        title: "Customize Your Tiers",
                        description: "Edit targets, names, and purposes to match your goals",
                        color: AppTheme.Colors.primary
                    )
                    
                    FeatureHighlightCard(
                        icon: "creditcard",
                        title: "Add Your Accounts",
                        description: "Connect your bank accounts to each tier for tracking",
                        color: AppTheme.Colors.success
                    )
                    
                    FeatureHighlightCard(
                        icon: "plus.slash.minus",
                        title: "Start Allocating",
                        description: "Use the Planner to distribute money across your tiers",
                        color: AppTheme.Colors.info
                    )
                }
            }
            .primaryCard()
            
            // Financial disclaimer
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Important Disclaimer")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text("This app provides educational tools for organizing your finances. It does not offer professional financial advice. Consult with qualified financial advisors for personalized recommendations.")
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.sm)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.warning.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            
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