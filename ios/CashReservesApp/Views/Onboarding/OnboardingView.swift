import SwiftUI
import ReserveEngine

struct OnboardingView: View {
    @StateObject var viewModel = OnboardingViewModel()
    @EnvironmentObject var planVM: PlanViewModel
    @State private var showingSkipAlert = false
    @Environment(\.dismiss) private var dismiss
    
    // Optional parameter to indicate if this is a tutorial (modal) vs initial onboarding
    let isTutorial: Bool
    
    init(isTutorial: Bool = false) {
        self.isTutorial = isTutorial
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main scrollable content
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
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
            
            // Navigation buttons (at bottom of interface)
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
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.background.opacity(0.95),
                        AppTheme.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(.ultraThinMaterial.opacity(0.3))
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.Colors.border.opacity(0.2)),
                alignment: .top
            )
            .shadow(color: AppTheme.Shadow.light, radius: 8, x: 0, y: -2)
        }
        .appBackground()
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
        case .completion:
            CompletionStepView()
                .environmentObject(viewModel)
        }
    }
    
    private func handleNext() {
        OnboardingHaptics.light()
        viewModel.nextStep()
    }
    
    private func handleSkip() {
        OnboardingHaptics.light()
        OnboardingAnnouncements.announceSkipAction()
        viewModel.skipCurrentStep()
    }
    
    
    private func handleOnboardingComplete() {
        // Only mark onboarding as completed if this is the initial onboarding
        if !isTutorial {
            OnboardingPreferences.hasCompletedOnboarding = true
            
            // Refresh plan data
            Task {
                await planVM.load()
            }
        }
        
        // Success haptic and announcement
        OnboardingHaptics.success()
        OnboardingAnnouncements.announceCompletion()
        
        // Dismiss modal if this is a tutorial
        if isTutorial {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isTutorial: false)
        .environmentObject(PlanViewModel())
}