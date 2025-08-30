import SwiftUI
import ReserveEngine

struct AccountRowView: View {
    let account: Account
    let isPreferred: Bool
    let privacy: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(account.name)
                        .font(.body)
                    if isPreferred {
                        Text("Preferred")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
                Text("APY: \(account.apyPct, specifier: "%.2f")%  •  W: \(account.allocWeight, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(MoneyFormat.format(account.balance, privacy: privacy))
        }
    }
}

