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

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy") {
                    Toggle("Privacy Mode", isOn: $vm.privacyMode)
                }
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
                Section("About") {
                    Text("Cash Reserves Mobile v0.1")
                }
            }
            .navigationTitle("Settings")
            .fileExporter(isPresented: $showExporter, document: ExportDoc(url: PlanStore.shared.planURL()), contentType: .json, defaultFilename: "reserve_manager.json") { result in
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
        }
    }
}

struct ExportDoc: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var url: URL
    init(url: URL) { self.url = url }
    init(configuration: ReadConfiguration) throws { self.url = URL(fileURLWithPath: "") }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { try FileWrapper(url: url) }
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
