import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

public struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    
    public enum ExportRangePreset: String, CaseIterable, Identifiable {
        case allTime = "All Time"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case custom = "Custom Range"
        
        public var id: String { rawValue }
    }
    
    @State private var selectedPreset: ExportRangePreset = .allTime
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var includeMerchant = true
    @State private var includeNotes = true
    
    @State private var allTransactions: [Transaction] = []
    @State private var categories: [Category] = []
    @State private var isLoading = true
    @State private var exportFileURL: URL?
    
    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
    
    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }
    
    private var categoryMap: [UUID: String] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
    }
    
    private var activeOptions: CSVExportOptions {
        let (start, end): (String?, String?) = {
            let today = Date()
            let calendar = Calendar.current
            switch selectedPreset {
            case .allTime:
                return (nil, nil)
            case .thisMonth:
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
                return (dayFormatter.string(from: startOfMonth), dayFormatter.string(from: today))
            case .lastMonth:
                guard let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: today),
                      let startOfPrevMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: prevMonthDate)),
                      let range = calendar.range(of: .day, in: .month, for: prevMonthDate),
                      let endOfPrevMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfPrevMonth) else {
                    return (nil, nil)
                }
                return (dayFormatter.string(from: startOfPrevMonth), dayFormatter.string(from: endOfPrevMonth))
            case .custom:
                return (dayFormatter.string(from: customStartDate), dayFormatter.string(from: customEndDate))
            }
        }()
        
        return CSVExportOptions(
            startDay: start,
            endDay: end,
            types: nil,
            includeNotes: includeNotes,
            includeMerchant: includeMerchant
        )
    }
    
    private var filteredTransactions: [Transaction] {
        CSVExporter.filter(transactions: allTransactions, options: activeOptions)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Export Scope")) {
                    Picker("Date Range", selection: $selectedPreset) {
                        ForEach(ExportRangePreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .accessibilityLabel("Select Date Range Preset")
                    
                    if selectedPreset == .custom {
                        DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Included Fields")) {
                    Toggle("Merchant / Location", isOn: $includeMerchant)
                    Toggle("Notes", isOn: $includeNotes)
                }
                
                Section(header: Text("Preview")) {
                    if isLoading {
                        ProgressView("Loading records...")
                    } else {
                        HStack {
                            Text("Matching Transactions")
                            Spacer()
                            Text("\(filteredTransactions.count)")
                                .fontWeight(.bold)
                                .foregroundStyle(filteredTransactions.isEmpty ? .secondary : .primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Columns in CSV:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Date, Type, Amount, Currency, Category, Merchant, Note, Payment Method")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Section(footer: Text("The CSV file is generated locally and presented via the iOS Share Sheet. No records leave your device or upload to any cloud service.")) {
                    if let fileURL = exportFileURL, !filteredTransactions.isEmpty {
                        ShareLink(
                            item: fileURL,
                            preview: SharePreview("Expense Tracker Export", icon: Image(systemName: "tablecells"))
                        ) {
                            HStack {
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                Text("Share CSV File (\(filteredTransactions.count) records)")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Share CSV File")
                        .accessibilityHint("Opens system share sheet to AirDrop, save to files, or export transactions")
                    } else {
                        Button {
                            prepareExportFile()
                        } label: {
                            HStack {
                                Spacer()
                                Text(filteredTransactions.isEmpty ? "No Transactions to Export" : "Prepare CSV Export")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(filteredTransactions.isEmpty || isLoading)
                        .accessibilityLabel("Prepare CSV Export")
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        cleanupTemporaryFile()
                        dismiss()
                    }
                }
            }
            .task {
                await loadData()
            }
            .onChange(of: selectedPreset) { _ in
                prepareExportFile()
            }
            .onChange(of: customStartDate) { _ in
                prepareExportFile()
            }
            .onChange(of: customEndDate) { _ in
                prepareExportFile()
            }
            .onChange(of: includeMerchant) { _ in
                prepareExportFile()
            }
            .onChange(of: includeNotes) { _ in
                prepareExportFile()
            }
            .onDisappear {
                cleanupTemporaryFile()
            }
        }
    }
    
    private func loadData() async {
        do {
            let txs = try await transactionRepository.listAll(includeDeleted: false)
            let cats = try await categoryRepository.list(includeArchived: true)
            await MainActor.run {
                self.allTransactions = txs
                self.categories = cats
                self.isLoading = false
                prepareExportFile()
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func prepareExportFile() {
        cleanupTemporaryFile()
        
        let txs = filteredTransactions
        guard !txs.isEmpty else {
            self.exportFileURL = nil
            return
        }
        
        let csvString = CSVExporter.generateCSV(
            transactions: txs,
            categoryNames: categoryMap,
            options: activeOptions
        )
        
        guard let data = csvString.data(using: .utf8) else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExpenseTracker_Export_\(timestamp).csv")
        
        do {
            try data.write(to: tempURL)
            self.exportFileURL = tempURL
        } catch {
            self.exportFileURL = nil
        }
    }
    
    private func cleanupTemporaryFile() {
        if let url = exportFileURL {
            try? FileManager.default.removeItem(at: url)
            self.exportFileURL = nil
        }
    }
}
