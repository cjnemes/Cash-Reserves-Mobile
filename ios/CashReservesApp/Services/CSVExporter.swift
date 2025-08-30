import Foundation
import ReserveEngine

enum CSVExporter {
    static func accountsCSV(plan: Plan) -> Data {
        var rows: [String] = []
        rows.append("Tier,Account,Balance,APY %,Weight,Cap,Notes,Preferred")
        for t in plan.tiers {
            for a in t.accounts {
                let preferred = (t.preferredAccount == a.name) ? "Yes" : ""
                rows.append([t.name, a.name, String(format: "%.2f", a.balance), String(format: "%.2f", a.apyPct), String(format: "%.2f", a.allocWeight), a.accountTarget.map { String(format: "%.2f", $0) } ?? "", a.notes.replacingOccurrences(of: ",", with: ";"), preferred].joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    static func transactionsCSV(_ tx: [ReserveEngine.Transaction]) -> Data {
        var rows: [String] = []
        rows.append("Timestamp,Tier,Account,Amount,BalanceAfter,Type,Description,User")
        let iso = ISO8601DateFormatter()
        for t in tx {
            rows.append([
                iso.string(from: t.timestamp),
                t.tierName,
                t.accountName,
                String(format: "%.2f", t.amount),
                String(format: "%.2f", t.balanceAfter),
                t.type,
                t.description.replacingOccurrences(of: ",", with: ";"),
                t.user
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }
}

