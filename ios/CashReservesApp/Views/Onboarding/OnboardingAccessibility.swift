import SwiftUI

// MARK: - Accessibility Extensions for Onboarding

extension OnboardingView {
    var accessibilityLabel: String {
        "Onboarding step \(viewModel.currentStepIndex + 1) of \(viewModel.steps.count): \(viewModel.currentStep.title)"
    }
    
    var accessibilityHint: String {
        switch viewModel.currentStep.content {
        case .welcome:
            return "Welcome to Cash Reserves app. Swipe right to continue or use the continue button."
        case .conceptExplanation:
            return "Learn about the 6-tier cash reserve system. Interactive elements available."
        case .tierDemo:
            return "Interactive demonstration of tiers. Tap tiers to highlight them."
        case .allocationDemo:
            return "See how money is allocated. Enter an amount and run the demo."
        case .completion:
            return "Onboarding complete. Get started button will take you to the main app."
        }
    }
}

// MARK: - Voice Over Support

struct OnboardingVoiceOverSupport: ViewModifier {
    let step: OnboardingStep
    let stepIndex: Int
    let totalSteps: Int
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Step \(stepIndex + 1) of \(totalSteps): \(step.title)")
            .accessibilityValue(step.subtitle)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(.default) {
                // Announce the step content
                let announcement = "\(step.title). \(step.subtitle). Double tap to continue."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: announcement)
                }
            }
    }
}

extension View {
    func onboardingVoiceOver(step: OnboardingStep, stepIndex: Int, totalSteps: Int) -> some View {
        self.modifier(OnboardingVoiceOverSupport(step: step, stepIndex: stepIndex, totalSteps: totalSteps))
    }
}

// MARK: - Reduced Motion Support

struct OnboardingReducedMotion: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    let enabledAnimation: Animation
    let reducedAnimation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : enabledAnimation, value: UUID())
    }
}

extension View {
    func onboardingAnimation(
        enabled: Animation = .spring(response: 0.6, dampingFraction: 0.8),
        reduced: Animation = .easeInOut(duration: 0.2)
    ) -> some View {
        self.modifier(OnboardingReducedMotion(enabledAnimation: enabled, reducedAnimation: reduced))
    }
}

// MARK: - Dynamic Type Support

struct OnboardingDynamicType: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(dynamicTypeSize > .xxxLarge ? .xxxLarge : dynamicTypeSize)
            .lineLimit(dynamicTypeSize > .large ? nil : 3)
    }
}

extension View {
    func onboardingDynamicType() -> some View {
        self.modifier(OnboardingDynamicType())
    }
}

// MARK: - High Contrast Support

struct OnboardingHighContrast: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if differentiateWithoutColor {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 2)
                    }
                }
            )
            .background(
                Group {
                    if reduceTransparency {
                        AppTheme.Colors.cardBackground
                    }
                }
            )
    }
}

extension View {
    func onboardingHighContrast() -> some View {
        self.modifier(OnboardingHighContrast())
    }
}

// MARK: - Focus Management

class OnboardingFocusManager: ObservableObject {
    @Published var currentFocus: OnboardingFocusField?
    
    enum OnboardingFocusField: Hashable {
        case tierName
        case tierPurpose
        case tierTarget
        case accountName
        case accountBalance
        case allocationAmount
    }
    
    func moveFocus(to field: OnboardingFocusField?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentFocus = field
        }
    }
    
    func nextField() {
        guard let current = currentFocus else { return }
        
        switch current {
        case .tierName:
            moveFocus(to: .tierPurpose)
        case .tierPurpose:
            moveFocus(to: .tierTarget)
        case .tierTarget:
            moveFocus(to: nil)
        case .accountName:
            moveFocus(to: .accountBalance)
        case .accountBalance:
            moveFocus(to: nil)
        case .allocationAmount:
            moveFocus(to: nil)
        }
    }
}

// MARK: - Accessibility Announcements

struct OnboardingAnnouncements {
    static func announceStepChange(to step: OnboardingStep, stepIndex: Int, totalSteps: Int) {
        let announcement = "Step \(stepIndex + 1) of \(totalSteps). \(step.title). \(step.subtitle)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .screenChanged, argument: announcement)
        }
    }
    
    static func announceCompletion() {
        let announcement = "Onboarding completed successfully. Welcome to Cash Reserves!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    static func announceAllocationDemo(amount: String) {
        let announcement = "Running allocation demo with \(amount). Watch as money flows to fill tier gaps in priority order."
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    static func announceSkipAction() {
        let announcement = "Step skipped. Moving to next section."
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    static func announceDemoReset() {
        let announcement = "Demo reset to initial state."
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    static func announceTierCreation(tierName: String) {
        let announcement = "Tier '\(tierName)' created successfully."
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    static func announceAccountCreation(accountName: String) {
        let announcement = "Account '\(accountName)' added successfully."
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// MARK: - Keyboard Navigation Support

struct OnboardingKeyboardSupport: ViewModifier {
    @FocusState private var isInputFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isInputFocused)
            .onSubmit {
                // Handle return key press
                isInputFocused = false
            }
    }
}

extension View {
    func onboardingKeyboardSupport() -> some View {
        self.modifier(OnboardingKeyboardSupport())
    }
}

// MARK: - Safe Area Insets for Different Devices

struct OnboardingSafeArea: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: AppTheme.Spacing.md)
            }
    }
}

extension View {
    func onboardingSafeArea() -> some View {
        self.modifier(OnboardingSafeArea())
    }
}

// MARK: - Error Handling and Validation

struct OnboardingValidation {
    static func validateTierInput(name: String, target: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return .invalid("Tier name is required")
        }
        
        guard let targetValue = Double(target), targetValue > 0 else {
            return .invalid("Target amount must be greater than zero")
        }
        
        guard targetValue <= 1_000_000 else {
            return .invalid("Target amount seems unusually high. Please verify.")
        }
        
        return .valid
    }
    
    static func validateAccountInput(name: String, balance: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return .invalid("Account name is required")
        }
        
        guard let balanceValue = Double(balance), balanceValue >= 0 else {
            return .invalid("Balance must be zero or greater")
        }
        
        guard balanceValue <= 10_000_000 else {
            return .invalid("Balance seems unusually high. Please verify.")
        }
        
        return .valid
    }
    
    enum ValidationResult {
        case valid
        case invalid(String)
        
        var isValid: Bool {
            switch self {
            case .valid: return true
            case .invalid: return false
            }
        }
        
        var errorMessage: String? {
            switch self {
            case .valid: return nil
            case .invalid(let message): return message
            }
        }
    }
}

// MARK: - Haptic Feedback Management

struct OnboardingHaptics {
    static func success() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }
    
    static func error() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
    
    static func warning() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
    }
    
    static func light() {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }
    
    static func medium() {
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
    }
    
    static func heavy() {
        let feedback = UIImpactFeedbackGenerator(style: .heavy)
        feedback.impactOccurred()
    }
    
    static func selection() {
        let feedback = UISelectionFeedbackGenerator()
        feedback.selectionChanged()
    }
}

// MARK: - Performance Optimizations

struct OnboardingPerformance: ViewModifier {
    func body(content: Content) -> some View {
        content
            .drawingGroup() // Optimize complex animations
            .compositingGroup() // Reduce overdraw
    }
}

extension View {
    func onboardingPerformance() -> some View {
        self.modifier(OnboardingPerformance())
    }
}