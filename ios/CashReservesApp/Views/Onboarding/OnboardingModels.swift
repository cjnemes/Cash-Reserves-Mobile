import Foundation
import SwiftUI

// MARK: - Onboarding Models

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let content: OnboardingContent
    let canSkip: Bool
    let showProgress: Bool
}

enum OnboardingContent {
    case welcome
    case conceptExplanation
    case tierDemo
    case allocationDemo
    case firstTierSetup
    case firstAccountSetup
    case completion
}

// MARK: - Onboarding State Management

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStepIndex: Int = 0
    @Published var isCompleted: Bool = false
    @Published var hasSkippedSetup: Bool = false
    
    // Demo data for interactive examples
    @Published var demoTiers: [DemoTier] = []
    @Published var demoAllocationAmount: String = "2500"
    @Published var showingAllocationPreview: Bool = false
    
    // First tier setup
    @Published var firstTierName: String = ""
    @Published var firstTierPurpose: String = ""
    @Published var firstTierTarget: String = ""
    @Published var firstAccountName: String = ""
    @Published var firstAccountBalance: String = ""
    
    let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome to Cash Reserves",
            subtitle: "Build financial security with strategic cash management",
            content: .welcome,
            canSkip: false,
            showProgress: false
        ),
        OnboardingStep(
            title: "The 6-Tier System",
            subtitle: "Learn how priority-based cash reserves work",
            content: .conceptExplanation,
            canSkip: true,
            showProgress: true
        ),
        OnboardingStep(
            title: "See Tiers in Action",
            subtitle: "Interactive demonstration with sample data",
            content: .tierDemo,
            canSkip: true,
            showProgress: true
        ),
        OnboardingStep(
            title: "Smart Allocation",
            subtitle: "Watch money flow to fill gaps automatically",
            content: .allocationDemo,
            canSkip: true,
            showProgress: true
        ),
        OnboardingStep(
            title: "Create Your First Tier",
            subtitle: "Set up your emergency fund or financial goal",
            content: .firstTierSetup,
            canSkip: true,
            showProgress: true
        ),
        OnboardingStep(
            title: "Add Your First Account",
            subtitle: "Connect a bank account to your tier",
            content: .firstAccountSetup,
            canSkip: true,
            showProgress: true
        ),
        OnboardingStep(
            title: "You're All Set!",
            subtitle: "Start building your financial security today",
            content: .completion,
            canSkip: false,
            showProgress: false
        )
    ]
    
    init() {
        setupDemoData()
    }
    
    var currentStep: OnboardingStep {
        guard currentStepIndex < steps.count else { return steps.last! }
        return steps[currentStepIndex]
    }
    
    var canGoNext: Bool {
        switch currentStep.content {
        case .firstTierSetup:
            return !firstTierName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !firstTierPurpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   Double(firstTierTarget) != nil && Double(firstTierTarget)! > 0
        case .firstAccountSetup:
            return !firstAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   Double(firstAccountBalance) != nil && Double(firstAccountBalance)! >= 0
        default:
            return true
        }
    }
    
    var progress: Double {
        guard steps.count > 0 else { return 0 }
        return Double(currentStepIndex) / Double(steps.count - 1)
    }
    
    func nextStep() {
        guard currentStepIndex < steps.count - 1 else {
            completeOnboarding()
            return
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStepIndex += 1
        }
    }
    
    func previousStep() {
        guard currentStepIndex > 0 else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStepIndex -= 1
        }
    }
    
    func skipToEnd() {
        hasSkippedSetup = true
        completeOnboarding()
    }
    
    func skipCurrentStep() {
        if currentStep.content == .firstTierSetup || currentStep.content == .firstAccountSetup {
            hasSkippedSetup = true
        }
        nextStep()
    }
    
    private func completeOnboarding() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isCompleted = true
        }
        
        // Save onboarding completion
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Demo Data Setup
    
    private func setupDemoData() {
        demoTiers = [
            DemoTier(
                name: "Tier 1: Buffer",
                purpose: "Daily expenses & small emergencies",
                target: 1000,
                current: 850,
                priority: 1,
                color: .blue
            ),
            DemoTier(
                name: "Tier 2: Emergency",
                purpose: "3-6 months of expenses",
                target: 15000,
                current: 12000,
                priority: 2,
                color: .green
            ),
            DemoTier(
                name: "Tier 3: Major Repairs",
                purpose: "Home & car maintenance",
                target: 8000,
                current: 3500,
                priority: 3,
                color: .orange
            ),
            DemoTier(
                name: "Tier 4: Opportunities",
                purpose: "Investment opportunities",
                target: 25000,
                current: 8000,
                priority: 4,
                color: .purple
            )
        ]
    }
    
    func runAllocationDemo() {
        guard let amount = Double(demoAllocationAmount) else { return }
        
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            showingAllocationPreview = true
        }
        
        // Simulate allocation logic
        var remaining = amount
        for i in demoTiers.indices where remaining > 0 {
            let gap = max(0, demoTiers[i].target - demoTiers[i].current)
            let allocation = min(remaining, gap)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    self.demoTiers[i].current += allocation
                    remaining -= allocation
                }
            }
        }
        
        // Hide preview after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.showingAllocationPreview = false
            }
        }
    }
    
    func resetDemoData() {
        setupDemoData()
        showingAllocationPreview = false
    }
}

// MARK: - Demo Models

struct DemoTier: Identifiable {
    let id = UUID()
    let name: String
    let purpose: String
    let target: Double
    var current: Double
    let priority: Int
    let color: Color
    
    var progress: Double {
        target > 0 ? min(1.0, current / target) : 0
    }
    
    var gap: Double {
        max(0, target - current)
    }
}

// MARK: - Onboarding Persistence

struct OnboardingPreferences {
    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    static var hasSeenWelcome: Bool {
        get { UserDefaults.standard.bool(forKey: "hasSeenWelcome") }
        set { UserDefaults.standard.set(newValue, forKey: "hasSeenWelcome") }
    }
}