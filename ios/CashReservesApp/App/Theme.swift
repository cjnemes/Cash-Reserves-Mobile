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

