import Foundation
import CryptoKit

public final class PlanStore {
    public static let shared = PlanStore()
    private init() {}
    
    // Encryption key stored securely in keychain
    private static let encryptionKeyTag = "com.cashreserves.encryption.key"
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key from keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.encryptionKeyTag,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }
        
        // Create new key if none exists
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.encryptionKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw NSError(domain: "Encryption", code: Int(addStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to store encryption key"])
        }
        
        return newKey
    }
    
    private func encryptData(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    private func decryptData(_ encryptedData: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    public func loadOrInitialize() throws -> Plan {
        let url = planURL()
        if FileManager.default.fileExists(atPath: url.path) {
            let encryptedData = try Data(contentsOf: url)
            let data = try decryptData(encryptedData)
            let plan = try JSONDecoder().decode(Plan.self, from: data)
            return plan
        } else {
            let plan = defaultPlan()
            try save(plan)
            return plan
        }
    }

    public func save(_ plan: Plan) throws {
        var copy = plan
        copy.lastUpdated = ISO8601DateFormatter().string(from: Date())
        let data = try JSONEncoder.withSnakeCaseDates().encode(copy)
        let encryptedData = try encryptData(data)
        
        // Set file protection attribute for additional security
        var options: Data.WritingOptions = [.atomic]
        try encryptedData.write(to: planURL(), options: options)
        
        // Set file protection level after writing
        try (planURL() as NSURL).setResourceValue(
            URLFileProtection.completeUntilFirstUserAuthentication,
            forKey: .fileProtectionKey
        )
    }

    public func importFrom(url: URL) throws -> Plan {
        let data = try Data(contentsOf: url)
        let plan = try JSONDecoder().decode(Plan.self, from: data)
        try save(plan)
        return plan
    }

    public func export(to url: URL) throws {
        // Export as unencrypted JSON for user readability and portability
        let encryptedData = try Data(contentsOf: planURL())
        let decryptedData = try decryptData(encryptedData)
        try decryptedData.write(to: url)
    }

    public func planURL() -> URL {
        #if os(iOS)
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #else
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        #endif
        return dir.appendingPathComponent("reserve_manager.json")
    }
}

extension JSONEncoder {
    static func withSnakeCaseDates() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted]
        return e
    }
}

public func defaultPlan() -> Plan {
    // Financial Disclaimer: These are example tiers for educational purposes only.
    // Amounts are suggestions and should be adjusted based on your personal financial situation.
    // This app does not provide professional financial advice.
    // Consult with a qualified financial advisor for personalized recommendations.
    
    let tier1 = Tier(
        name: "Tier 1: Buffer",
        purpose: "Daily expenses & small emergencies (example amounts)",
        target: 1000,
        priority: 1,
        accounts: [
            Account(name: "Checking", balance: 0),
            Account(name: "Savings", balance: 0)
        ],
        preferredAccount: "Savings"
    )
    
    let tier2 = Tier(
        name: "Tier 2: Emergency Fund",
        purpose: "Major life disruptions (example amount - typically 3-6 months expenses)",
        target: 15000,
        priority: 2,
        accounts: [
            Account(name: "Emergency Savings", balance: 0)
        ],
        preferredAccount: "Emergency Savings"
    )
    
    let tier3 = Tier(
        name: "Tier 3: Major Repairs",
        purpose: "Home & vehicle maintenance",
        target: 8000,
        priority: 3,
        accounts: [
            Account(name: "Repair Fund", balance: 0)
        ],
        preferredAccount: "Repair Fund"
    )
    
    let tier4 = Tier(
        name: "Tier 4: Opportunities",
        purpose: "Investment & growth",
        target: 25000,
        priority: 4,
        accounts: [
            Account(name: "Investment Account", balance: 0)
        ],
        preferredAccount: "Investment Account"
    )
    
    let tier5 = Tier(
        name: "Tier 5: Long-term Goals",
        purpose: "Future major purchases",
        target: 45000,
        priority: 5,
        accounts: [
            Account(name: "Goals Account", balance: 0)
        ],
        preferredAccount: "Goals Account"
    )
    
    let tier6 = Tier(
        name: "Tier 6: Legacy",
        purpose: "Wealth preservation",
        target: 100000,
        priority: 6,
        accounts: [
            Account(name: "Legacy Fund", balance: 0)
        ],
        preferredAccount: "Legacy Fund"
    )
    
    return Plan(tiers: [tier1, tier2, tier3, tier4, tier5, tier6], lastUpdated: ISO8601DateFormatter().string(from: Date()))
}

