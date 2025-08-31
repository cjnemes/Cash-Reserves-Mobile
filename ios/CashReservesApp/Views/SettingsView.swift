import SwiftUI
import UniformTypeIdentifiers
import ReserveEngine

struct SettingsView: View {
    @EnvironmentObject var vm: PlanViewModel
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var importDoc: ImportDoc? = nil
    @State private var accountsCSVDoc: DataDocument? = nil
    @State private var txCSVDoc: DataDocument? = nil
    @State private var showResetDataAlert = false
    @State private var showResetOnboardingAlert = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false

    var body: some View {
        NavigationStack {
            Form {
                privacySection
                dataSection
                dataManagementSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .fileExporter(isPresented: $showExporter, document: ExportDoc(), contentType: .json, defaultFilename: "reserve_manager.json") { result in
                if case let .failure(error) = result { print("Export failed: \(error)") }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url): vm.importPlan(from: url)
                case .failure(let e): print("Import failed: \(e)")
                }
            }
            .fileExporter(isPresented: Binding(get: { accountsCSVDoc != nil }, set: { if !$0 { accountsCSVDoc = nil } }), document: accountsCSVDoc, contentType: .commaSeparatedText, defaultFilename: "accounts.csv") { _ in }
            .fileExporter(isPresented: Binding(get: { txCSVDoc != nil }, set: { if !$0 { txCSVDoc = nil } }), document: txCSVDoc, contentType: .commaSeparatedText, defaultFilename: "transactions.csv") { _ in }
            .alert("Reset All Data?", isPresented: $showResetDataAlert) {
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your tiers, accounts, and transaction history. This action cannot be undone.")
            }
            .alert("Reset Onboarding?", isPresented: $showResetOnboardingAlert) {
                Button("Reset", role: .destructive) {
                    resetOnboarding()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset your onboarding status, so the tutorial will show again when you restart the app.")
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                NavigationView {
                    PrivacyPolicyContent()
                        .navigationTitle("Privacy Policy")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showPrivacyPolicy = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showTermsOfService) {
                NavigationView {
                    TermsOfServiceContent()
                        .navigationTitle("Terms of Service")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showTermsOfService = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    private var privacySection: some View {
        Section("Privacy") {
            Toggle("Privacy Mode", isOn: $vm.privacyMode)
        }
    }
    
    private var dataSection: some View {
        Section("Data") {
            Button("Export Plan JSON") { showExporter = true }
            Button("Import Plan JSON") { showImporter = true }
            Button("Export Accounts CSV") {
                let data = CSVExporter.accountsCSV(plan: vm.plan)
                accountsCSVDoc = DataDocument(data: data)
            }
            Button("Export Transactions CSV") {
                let data = CSVExporter.transactionsCSV(vm.transactions)
                txCSVDoc = DataDocument(data: data)
            }
            Text("Plan Path: \(PlanStore.shared.planURL().lastPathComponent)").font(.caption).foregroundStyle(.secondary)
        }
    }
    
    private var dataManagementSection: some View {
        Section {
            Button("Reset All Data") {
                showResetDataAlert = true
            }
            .foregroundColor(.red)
            
            Button("Reset Onboarding") {
                showResetOnboardingAlert = true
            }
            .foregroundColor(.orange)
        } header: {
            Text("Data Management")
        } footer: {
            Text("Reset All Data will delete all tiers, accounts, and transaction history. Reset Onboarding will allow you to see the tutorial again on app launch.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var legalSection: some View {
        Section("Legal") {
            Button("Privacy Policy") {
                showPrivacyPolicy = true
            }
            Button("Terms of Service") {
                showTermsOfService = true
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            Text("Cash Reserves Mobile v0.1")
        }
    }
    
    private func resetAllData() {
        // Reset to default plan
        vm.plan = defaultPlan()
        vm.transactions = []
        vm.previewAmount = "1000"
        vm.previewMovesTier = []
        vm.previewMovesDetailed = []
        
        // Save the reset state
        vm.save()
        
        // Clear transaction history
        Task {
            await HistoryStore.shared.clear()
            await vm.load() // Reload to ensure everything is fresh
        }
        
        // Provide feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func resetOnboarding() {
        OnboardingPreferences.hasCompletedOnboarding = false
        
        // Provide feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}

struct ExportDoc: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    
    init() {
        do {
            // Read the encrypted file and decrypt it for export
            let encryptedData = try Data(contentsOf: PlanStore.shared.planURL())
            let planStore = PlanStore.shared
            // Use the existing decryptData method via export to temporary location
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp_export.json")
            try planStore.export(to: tempURL)
            self.data = try Data(contentsOf: tempURL)
            try FileManager.default.removeItem(at: tempURL) // Clean up temp file
        } catch {
            self.data = Data()
        }
    }
    
    init(configuration: ReadConfiguration) throws { 
        self.data = Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { 
        FileWrapper(regularFileWithContents: data) 
    }
}

struct ImportDoc: FileDocument { static var readableContentTypes: [UTType] { [.json] }
    init(configuration: ReadConfiguration) throws {}
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper() }
}

struct DataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { self.data = Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct PrivacyPolicyContent: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("**Last Updated:** December 31, 2024")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    legalSection("Introduction", content: "Cash Reserves Mobile is committed to protecting your privacy. This Privacy Policy explains how we handle information in our mobile application.")
                    
                    legalSection("Local Storage Only", content: "• All your financial data is stored exclusively on your device\n• Your data never leaves your device or gets transmitted anywhere\n• We have no servers or databases that store your information\n• Your data is yours and stays with you")
                    
                    legalSection("Data We Do NOT Collect", content: "• We do not access your bank accounts or financial institutions\n• We do not collect personal identification information\n• We do not track your location\n• We do not use analytics or tracking tools")
                    
                    legalSection("Your Data Control", content: "• You can export your data at any time through Settings\n• You can delete all data through \"Reset All Data\"\n• All data is encrypted for security\n• Only you have access to your financial information")
                    
                    legalSection("No Data Sharing", content: "• We never share, sell, or transmit your financial data\n• We do not use third-party analytics or advertising\n• Your financial information remains completely private")
                    
                    legalSection("Contact", content: "For questions about this Privacy Policy:\nEmail: cashreserves.support@gmail.com")
                }
            }
            .padding()
        }
    }
    
    private func legalSection(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
        }
    }
}

struct TermsOfServiceContent: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("**Last Updated:** December 31, 2024")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    legalSection("Agreement to Terms", content: "By using Cash Reserves Mobile, you agree to these Terms of Service. If you disagree, you may not use our App.")
                    
                    legalSection("Description of Service", content: "Cash Reserves Mobile is a personal financial organization tool that helps you:\n• Organize cash reserves into tiers\n• Track account balances and goals\n• Calculate allocation recommendations\n• Monitor progress toward targets")
                    
                    legalSection("Financial Disclaimer", content: "**IMPORTANT: This app is NOT professional financial advice.**\n• Does not provide investment recommendations\n• Does not guarantee financial outcomes\n• For educational purposes only\n• Consult qualified financial advisors for important decisions")
                    
                    legalSection("Your Responsibility", content: "• All financial decisions are your responsibility\n• You are responsible for data accuracy\n• App calculations are estimates only\n• Use proper device security")
                    
                    legalSection("Privacy & Data", content: "• All data stored locally on your device\n• We do not collect or transmit your information\n• You maintain complete control of your data\n• Refer to our Privacy Policy for details")
                    
                    legalSection("Limitation of Liability", content: "We are not liable for:\n• Financial losses from app use\n• Decisions based on app calculations\n• Data loss or corruption\nMaximum liability limited to app purchase price ($1.99).")
                    
                    legalSection("Contact", content: "For questions about these Terms:\nEmail: cashreserves.support@gmail.com")
                }
            }
            .padding()
        }
    }
    
    private func legalSection(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
        }
    }
}
