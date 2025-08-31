import Foundation
import SwiftUI

// MARK: - Design System

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Primary brand colors
        static let primary = Color("AccentColor")
        static let primaryLight = Color.blue.opacity(0.1)
        static let primaryDark = Color.blue.opacity(0.8)
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Surface colors
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let cardBackground = Color(UIColor.systemBackground)
        static let elevated = Color(UIColor.secondarySystemBackground)
        
        // Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(UIColor.tertiaryLabel)
        
        // Border colors
        static let border = Color(UIColor.separator)
        static let divider = Color(UIColor.opaqueSeparator)
        
        // Tier-specific colors (matching onboarding)
        struct TierColors {
            static let tier1 = Color.blue      // Buffer
            static let tier2 = Color.green     // Emergency Fund
            static let tier3 = Color.orange    // Major Repairs
            static let tier4 = Color.purple    // Opportunities
            static let tier5 = Color.indigo    // Long-term Goals
            static let tier6 = Color.pink      // Legacy
            
            static func colorForPriority(_ priority: Int) -> Color {
                switch priority {
                case 1: return tier1
                case 2: return tier2
                case 3: return tier3
                case 4: return tier4
                case 5: return tier5
                case 6: return tier6
                default: return AppTheme.Colors.primary
                }
            }
        }
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Financial-specific typography
        static let moneyPrimary = Font.title.weight(.bold).monospacedDigit()
        static let moneySecondary = Font.title2.weight(.semibold).monospacedDigit()
        static let moneyTertiary = Font.headline.weight(.medium).monospacedDigit()
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let round: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let heavy = Color.black.opacity(0.15)
    }
}

// MARK: - Money Formatting

enum MoneyFormat {
    static func format(_ value: Double, privacy: Bool = false, compact: Bool = false, showSign: Bool = false) -> String {
        if privacy { return "•••••" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        
        if compact {
            let absValue = abs(value)
            if absValue >= 1_000_000 {
                formatter.maximumFractionDigits = 1
                let formatted = formatter.string(from: NSNumber(value: value / 1_000_000)) ?? "$0.0"
                return formatted.replacingOccurrences(of: ".0", with: "") + "M"
            }
            if absValue >= 1_000 {
                formatter.maximumFractionDigits = 1
                let formatted = formatter.string(from: NSNumber(value: value / 1_000)) ?? "$0.0"
                return formatted.replacingOccurrences(of: ".0", with: "") + "K"
            }
        }
        
        var result = formatter.string(from: NSNumber(value: value)) ?? "$0.00"
        
        if showSign && value > 0 {
            result = "+" + result
        }
        
        return result
    }
    
    static func formatChange(_ value: Double, privacy: Bool = false) -> (text: String, color: Color) {
        if privacy { return ("•••••", AppTheme.Colors.secondaryText) }
        
        let formatted = format(value, showSign: true)
        let color: Color = value >= 0 ? AppTheme.Colors.success : AppTheme.Colors.error
        
        return (formatted, color)
    }
}

// MARK: - View Extensions

extension View {
    // MARK: - Backgrounds
    func appBackground() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.background,
                        AppTheme.Colors.primaryLight.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
    
    // MARK: - Cards
    func primaryCard() -> some View {
        self
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
            .shadow(color: AppTheme.Shadow.light, radius: 8, x: 0, y: 2)
            .shadow(color: AppTheme.Shadow.light, radius: 1, x: 0, y: 1)
    }
    
    func secondaryCard() -> some View {
        self
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            .shadow(color: AppTheme.Shadow.light, radius: 4, x: 0, y: 1)
    }
    
    func compactCard() -> some View {
        self
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sm, style: .continuous))
    }
    
    // MARK: - Buttons
    func primaryButton() -> some View {
        self
            .font(AppTheme.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }
    
    func secondaryButton() -> some View {
        self
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.primaryLight)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }
    
    // MARK: - Progress indicators
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            ProgressView()
                                .scaleEffect(1.2)
                        }
                }
            }
        )
    }
    
    // MARK: - Accessibility
    func dynamicTypeSize(range: ClosedRange<DynamicTypeSize>) -> some View {
        self.dynamicTypeSize(range)
    }
    
    // MARK: - Haptics
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Input Formatting

enum InputFormatters {
    static func cleanNumberString(_ s: String) -> String {
        s.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func cleanPercentString(_ s: String) -> String {
        s.replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func formatCurrencyString(_ s: String) -> String {
        let cleaned = cleanNumberString(s)
        guard let value = Double(cleaned), !value.isNaN else { return s }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? s
    }
    
    static func formatPercentString(_ s: String) -> String {
        let cleaned = cleanPercentString(s)
        guard let value = Double(cleaned), !value.isNaN else { return s }
        return String(format: "%.2f%%", value)
    }
}

// MARK: - Loading States

struct LoadingState<Content: View>: View {
    let isLoading: Bool
    let content: () -> Content
    
    var body: some View {
        ZStack {
            content()
                .opacity(isLoading ? 0.3 : 1.0)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Empty States

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, subtitle: String, systemImage: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                
                Text(subtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .secondaryButton()
                }
            }
        }
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - Legacy compatibility
extension View {
    func sectionCard() -> some View {
        primaryCard()
    }
}
