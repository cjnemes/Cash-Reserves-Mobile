import SwiftUI
import ReserveEngine

struct OnboardingView: View {
    @StateObject var viewModel = OnboardingViewModel()
    @EnvironmentObject var planVM: PlanViewModel
    @State private var showingSkipAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        AppTheme.Colors.background,
                        AppTheme.Colors.primaryLight.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Skip button (top-right)
                            if viewModel.currentStep.canSkip {
                                HStack {
                                    Spacer()
                                    Button("Skip All") {
                                        showingSkipAlert = true
                                    }
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                                    .accessibilityLabel("Skip entire onboarding process")
                                }
                                .padding(.horizontal, AppTheme.Spacing.md)
                            } else {
                                Spacer()
                                    .frame(height: AppTheme.Spacing.lg)
                            }
                            
                            // Step header
                            OnboardingStepHeader(
                                title: viewModel.currentStep.title,
                                subtitle: viewModel.currentStep.subtitle,
                                showProgress: viewModel.currentStep.showProgress,
                                currentStep: viewModel.currentStepIndex + 1,
                                totalSteps: viewModel.steps.count,
                                progress: viewModel.progress
                            )
                            .padding(.horizontal, AppTheme.Spacing.md)
                        }
                        .padding(.top, AppTheme.Spacing.md)
                        
                        // Content
                        currentStepContent
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.top, AppTheme.Spacing.xl)
                        
                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                
                // Navigation buttons (fixed at bottom)
                VStack {
                    Spacer()
                    
                    OnboardingNavigationButtons(
                        canGoNext: viewModel.canGoNext,
                        canGoBack: viewModel.currentStepIndex > 0,
                        canSkip: viewModel.currentStep.canSkip,
                        isLastStep: viewModel.currentStepIndex == viewModel.steps.count - 1,
                        onNext: handleNext,
                        onBack: viewModel.previousStep,
                        onSkip: handleSkip
                    )
                    .padding(AppTheme.Spacing.md)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .alert("Skip Onboarding?", isPresented: $showingSkipAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                viewModel.skipToEnd()
            }
        } message: {
            Text("You can always access help and tutorials from the Settings page later.")
        }
        .onChange(of: viewModel.isCompleted) { completed in
            if completed {
                handleOnboardingComplete()
            }
        }
        .onChange(of: viewModel.currentStepIndex) { stepIndex in
            OnboardingAnnouncements.announceStepChange(
                to: viewModel.currentStep,
                stepIndex: stepIndex,
                totalSteps: viewModel.steps.count
            )
        }
        .onboardingVoiceOver(
            step: viewModel.currentStep,
            stepIndex: viewModel.currentStepIndex,
            totalSteps: viewModel.steps.count
        )
        .onboardingDynamicType()
        .onboardingSafeArea()
    }
    
    @ViewBuilder
    private var currentStepContent: some View {
        switch viewModel.currentStep.content {
        case .welcome:
            WelcomeStepView()
        case .conceptExplanation:
            ConceptExplanationView()
        case .tierDemo:
            TierDemoView()
                .environmentObject(viewModel)
        case .allocationDemo:
            AllocationDemoView()
                .environmentObject(viewModel)
        case .firstTierSetup:
            FirstTierSetupView()
                .environmentObject(viewModel)
        case .firstAccountSetup:
            FirstAccountSetupView()
                .environmentObject(viewModel)
        case .completion:
            CompletionStepView()
                .environmentObject(viewModel)
        }
    }
    
    private func handleNext() {
        // Validate input if needed
        var canProceed = true
        
        if viewModel.currentStep.content == .firstTierSetup {
            let validation = OnboardingValidation.validateTierInput(
                name: viewModel.firstTierName,
                target: viewModel.firstTierTarget
            )
            if !validation.isValid {
                OnboardingHaptics.error()
                if let error = validation.errorMessage {
                    // You could show an alert here
                    print("Validation error: \(error)")
                }
                canProceed = false
            } else {
                createFirstTier()
                OnboardingAnnouncements.announceTierCreation(tierName: viewModel.firstTierName)
            }
        } else if viewModel.currentStep.content == .firstAccountSetup {
            let validation = OnboardingValidation.validateAccountInput(
                name: viewModel.firstAccountName,
                balance: viewModel.firstAccountBalance
            )
            if !validation.isValid {
                OnboardingHaptics.error()
                if let error = validation.errorMessage {
                    // You could show an alert here
                    print("Validation error: \(error)")
                }
                canProceed = false
            } else {
                addFirstAccount()
                OnboardingAnnouncements.announceAccountCreation(accountName: viewModel.firstAccountName)
            }
        }
        
        if canProceed {
            OnboardingHaptics.light()
            viewModel.nextStep()
        }
    }
    
    private func handleSkip() {
        OnboardingHaptics.light()
        
        if viewModel.currentStep.content == .firstTierSetup || viewModel.currentStep.content == .firstAccountSetup {
            showingSkipAlert = true
        } else {
            OnboardingAnnouncements.announceSkipAction()
            viewModel.skipCurrentStep()
        }
    }
    
    private func createFirstTier() {
        guard !viewModel.hasSkippedSetup,
              !viewModel.firstTierName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let target = Double(viewModel.firstTierTarget), target > 0 else {
            return
        }
        
        let newTier = Tier(
            name: viewModel.firstTierName.trimmingCharacters(in: .whitespacesAndNewlines),
            purpose: viewModel.firstTierPurpose.trimmingCharacters(in: .whitespacesAndNewlines),
            target: target,
            priority: 1,
            accounts: []
        )
        
        // Replace the default tier or add new one
        if planVM.plan.tiers.isEmpty {
            planVM.plan.tiers.append(newTier)
        } else {
            planVM.plan.tiers[0] = newTier
        }
        
        planVM.save()
    }
    
    private func addFirstAccount() {
        guard !viewModel.hasSkippedSetup,
              !viewModel.firstAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let balance = Double(viewModel.firstAccountBalance), balance >= 0,
              let tierIndex = planVM.plan.tiers.firstIndex(where: { _ in true }) else {
            return
        }
        
        let newAccount = Account(
            name: viewModel.firstAccountName.trimmingCharacters(in: .whitespacesAndNewlines),
            balance: balance
        )
        
        planVM.plan.tiers[tierIndex].accounts.append(newAccount)
        
        // Set as preferred if it's the only account
        if planVM.plan.tiers[tierIndex].accounts.count == 1 {
            planVM.plan.tiers[tierIndex].preferredAccount = newAccount.name
        }
        
        planVM.save()
    }
    
    private func handleOnboardingComplete() {
        // Mark onboarding as completed
        OnboardingPreferences.hasCompletedOnboarding = true
        
        // Refresh plan data
        Task {
            await planVM.load()
        }
        
        // Success haptic and announcement
        OnboardingHaptics.success()
        OnboardingAnnouncements.announceCompletion()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(PlanViewModel())
}