import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    // Tools section
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Tools")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .padding(.horizontal, AppTheme.Spacing.md)
                        
                        VStack(spacing: AppTheme.Spacing.sm) {
                            NavigationMenuRow(
                                title: "Rebalance",
                                subtitle: "Optimize allocation across tiers",
                                systemImage: "arrow.left.arrow.right",
                                destination: RebalanceView()
                            )
                            
                            NavigationMenuRow(
                                title: "History",
                                subtitle: "View transaction history and trends",
                                systemImage: "clock.arrow.circlepath",
                                destination: HistoryView()
                            )
                        }
                        .primaryCard()
                    }
                    
                    // Settings section
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Settings")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .padding(.horizontal, AppTheme.Spacing.md)
                        
                        VStack(spacing: AppTheme.Spacing.sm) {
                            NavigationMenuRow(
                                title: "Settings",
                                subtitle: "Privacy, data export, and preferences",
                                systemImage: "gear",
                                destination: SettingsView()
                            )
                        }
                        .primaryCard()
                    }
                    
                    // App info
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Cash Reserves Mobile")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        
                        Text("Version 1.0")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    .padding(.vertical, AppTheme.Spacing.lg)
                }
                .padding(AppTheme.Spacing.md)
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Navigation Menu Row
struct NavigationMenuRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 32, height: 32)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(subtitle)")
        .accessibilityHint("Tap to navigate")
    }
}

