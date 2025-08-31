import SwiftUI

// MARK: - Progress Indicator

struct OnboardingProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                        .fill(AppTheme.Colors.border.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 4)
            
            // Step counter
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Spacer()
                
                Text("\(Int(progress * 100))% complete")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.primary)
                    .contentTransition(.numericText(value: progress * 100))
                    .animation(.spring(response: 0.6), value: progress)
            }
        }
    }
}

// MARK: - Step Header

struct OnboardingStepHeader: View {
    let title: String
    let subtitle: String
    let showProgress: Bool
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            if showProgress {
                OnboardingProgressIndicator(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    progress: progress
                )
            }
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text(subtitle)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Navigation Buttons

struct OnboardingNavigationButtons: View {
    let canGoNext: Bool
    let canGoBack: Bool
    let canSkip: Bool
    let isLastStep: Bool
    let onNext: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Primary action button
            Button(action: onNext) {
                HStack {
                    Text(isLastStep ? "Get Started" : "Continue")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                    
                    if !isLastStep {
                        Image(systemName: "arrow.right")
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(canGoNext ? AppTheme.Colors.primary : AppTheme.Colors.border)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            }
            .disabled(!canGoNext)
            .accessibilityLabel(isLastStep ? "Get started using the app" : "Continue to next step")
            
            // Secondary actions
            HStack(spacing: AppTheme.Spacing.lg) {
                if canGoBack {
                    Button("Back", action: onBack)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primary)
                        .accessibilityLabel("Go back to previous step")
                }
                
                Spacer()
                
                if canSkip {
                    Button("Skip", action: onSkip)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .accessibilityLabel("Skip this step")
                }
            }
        }
    }
}

// MARK: - Feature Highlight Card

struct FeatureHighlightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isHighlighted: Bool
    
    init(icon: String, title: String, description: String, color: Color = AppTheme.Colors.primary, isHighlighted: Bool = false) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
        self.isHighlighted = isHighlighted
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            .scaleEffect(isHighlighted ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHighlighted)
            
            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(description)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.md)
        .background(isHighlighted ? color.opacity(0.05) : AppTheme.Colors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(isHighlighted ? color.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHighlighted)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Tier Demo Card

struct TierDemoCard: View {
    let tier: DemoTier
    let isAnimating: Bool
    let showAllocation: Bool
    let allocatedAmount: Double
    
    init(tier: DemoTier, isAnimating: Bool = false, showAllocation: Bool = false, allocatedAmount: Double = 0) {
        self.tier = tier
        self.isAnimating = isAnimating
        self.showAllocation = showAllocation
        self.allocatedAmount = allocatedAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                    
                    Text(tier.purpose)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(MoneyFormat.format(tier.current))
                        .font(AppTheme.Typography.moneyTertiary)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .contentTransition(.numericText(value: tier.current))
                    
                    Text("of \(MoneyFormat.format(tier.target, compact: true))")
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                        .fill(tier.color.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: [tier.color, tier.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * tier.progress, height: 8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: tier.progress)
                }
            }
            .frame(height: 8)
            
            // Allocation indicator
            if showAllocation && allocatedAmount > 0 {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.success)
                    
                    Text("+\(MoneyFormat.format(allocatedAmount))")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.success)
                        .contentTransition(.numericText(value: allocatedAmount))
                    
                    Spacer()
                }
                .opacity(showAllocation ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showAllocation)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(isAnimating ? tier.color.opacity(0.5) : tier.color.opacity(0.2), lineWidth: isAnimating ? 2 : 1)
                .animation(.easeInOut(duration: 0.3), value: isAnimating)
        )
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isAnimating)
        .shadow(color: AppTheme.Shadow.light, radius: isAnimating ? 8 : 4, x: 0, y: isAnimating ? 4 : 2)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isAnimating)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tier.name): \(MoneyFormat.format(tier.current)) of \(MoneyFormat.format(tier.target)) target, \(Int(tier.progress * 100)) percent complete")
    }
}

// MARK: - Input Field Components

struct OnboardingTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let formatter: ((String) -> String)?
    
    init(title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, formatter: ((String) -> String)? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.formatter = formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: text) { newValue in
                    if let formatter = formatter {
                        let formatted = formatter(newValue)
                        if formatted != newValue {
                            text = formatted
                        }
                    }
                }
        }
    }
}

// MARK: - Welcome Animation

struct WelcomeAnimationView: View {
    @State private var isAnimating = false
    @State private var showSecondary = false
    @State private var showTertiary = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // App icon or logo representation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
            
            // Floating elements
            HStack(spacing: AppTheme.Spacing.xl) {
                FloatingCard(
                    icon: "dollarsign.circle.fill",
                    text: "$12,500",
                    color: AppTheme.Colors.success,
                    delay: 0.3
                )
                .opacity(showSecondary ? 1.0 : 0.0)
                .offset(y: showSecondary ? 0 : 20)
                
                FloatingCard(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    text: "85%",
                    color: AppTheme.Colors.info,
                    delay: 0.6
                )
                .opacity(showTertiary ? 1.0 : 0.0)
                .offset(y: showTertiary ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                showSecondary = true
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6)) {
                showTertiary = true
            }
        }
    }
}

private struct FloatingCard: View {
    let icon: String
    let text: String
    let color: Color
    let delay: Double
    
    @State private var isFloating = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.primaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .offset(y: isFloating ? -4 : 4)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(delay), value: isFloating)
        .onAppear {
            isFloating = true
        }
    }
}