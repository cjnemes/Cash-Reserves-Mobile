import SwiftUI
import ReserveEngine

struct AccountRowView: View {
    let account: Account
    let isPreferred: Bool
    let privacy: Bool

    private var apyColor: Color {
        if account.apyPct >= 4.5 { return AppTheme.Colors.success }
        if account.apyPct >= 3.0 { return AppTheme.Colors.info }
        if account.apyPct >= 1.0 { return AppTheme.Colors.warning }
        return AppTheme.Colors.error
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(account.name)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .fontWeight(.medium)
                    
                    if isPreferred {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("Preferred")
                                .font(AppTheme.Typography.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.warning)
                        .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text("APY")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        Text("\(account.apyPct, specifier: "%.2f")%")
                            .font(AppTheme.Typography.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(apyColor)
                    }
                    
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text("Weight")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        Text("\(account.allocWeight, specifier: "%.1f")")
                            .font(AppTheme.Typography.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                }
            }
            
            Spacer()
            
            Text(MoneyFormat.format(account.balance, privacy: privacy))
                .font(AppTheme.Typography.moneyTertiary)
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), balance \(MoneyFormat.format(account.balance, privacy: false)), APY \(account.apyPct, specifier: "%.2f") percent")
        .accessibilityValue(isPreferred ? "Preferred account" : "")
    }
}

