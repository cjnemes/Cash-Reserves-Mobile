import Foundation
import SwiftUI

enum MoneyFormat {
    static func format(_ value: Double, privacy: Bool = false, compact: Bool = false) -> String {
        if privacy { return "•••••" }
        if compact {
            let v = abs(value)
            if v >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
            if v >= 1_000 { return String(format: "$%.1fK", value / 1_000) }
        }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

extension View {
    func sectionCard() -> some View { self.padding().background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 12)) }
}

// MARK: - Lightweight input formatting helpers

enum InputFormatters {
    static func cleanNumberString(_ s: String) -> String {
        s.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static func cleanPercentString(_ s: String) -> String {
        s.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static func formatCurrencyString(_ s: String) -> String {
        let cleaned = cleanNumberString(s)
        guard let v = Double(cleaned) else { return s }
        let f = NumberFormatter(); f.numberStyle = .currency; f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? s
    }
    static func formatPercentString(_ s: String) -> String {
        let cleaned = cleanPercentString(s)
        guard let v = Double(cleaned) else { return s }
        return String(format: "%.2f%%", v)
    }
}
