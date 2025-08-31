import SwiftUI

struct MoreView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @State private var showingTutorial = false
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    // App header section
                    VStack(spacing: AppTheme.Spacing.md) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            // App Icon
                            Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 4) {
                                Text("Cash Reserves Mobile")
                                    .font(AppTheme.Typography.title3)
                                    .foregroundColor(AppTheme.Colors.primaryText)
                                    .fontWeight(.semibold)
                                
                                Text("Tier-based financial organization")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.md)
                    }
                    .primaryCard()
                    
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
                            
                            // Tutorial button
                            Button {
                                showingTutorial = true
                            } label: {
                                HStack(spacing: AppTheme.Spacing.md) {
                                    // Icon
                                    Image(systemName: "graduationcap")
                                        .font(.title2)
                                        .foregroundColor(AppTheme.Colors.primary)
                                        .frame(width: 32, height: 32)
                                    
                                    // Content
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Tutorial")
                                            .font(AppTheme.Typography.body)
                                            .foregroundColor(AppTheme.Colors.primaryText)
                                            .fontWeight(.medium)
                                        
                                        Text("Learn how to use the app")
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
                            .accessibilityLabel("Tutorial: Learn how to use the app")
                            .accessibilityHint("Tap to start tutorial")
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
            .appBackground()
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTutorial) {
                OnboardingView(isTutorial: true)
                    .environmentObject(planVM)
            }
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

