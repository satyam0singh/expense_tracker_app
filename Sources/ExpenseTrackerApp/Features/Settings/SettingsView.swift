import SwiftUI
import ExpenseTrackerCore

public struct SettingsView: View {
    public let userProfile: UserProfile?
    public let userProfileRepository: UserProfileRepositoryProtocol?
    public let transactionRepository: TransactionRepositoryProtocol?
    public let categoryRepository: CategoryRepositoryProtocol?
    public let recurringRuleRepository: RecurringRuleRepositoryProtocol?
    public let fileStore: LocalFileStore?
    public let onResetData: (() -> Void)?
    
    @State private var currentProfile: UserProfile
    @State private var showingExportSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingEditPreferences = false
    @State private var editIncomeText = ""
    @State private var editBudgetText = ""
    @State private var isDeleting = false
    
    public init(
        userProfile: UserProfile? = nil,
        userProfileRepository: UserProfileRepositoryProtocol? = nil,
        transactionRepository: TransactionRepositoryProtocol? = nil,
        categoryRepository: CategoryRepositoryProtocol? = nil,
        recurringRuleRepository: RecurringRuleRepositoryProtocol? = nil,
        fileStore: LocalFileStore? = nil,
        onResetData: (() -> Void)? = nil
    ) {
        self.userProfile = userProfile
        self.userProfileRepository = userProfileRepository
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.recurringRuleRepository = recurringRuleRepository
        self.fileStore = fileStore
        self.onResetData = onResetData
        _currentProfile = State(initialValue: userProfile ?? .default)
    }
    
    private let availableCurrencies = [
        CurrencyCode.inr,
        CurrencyCode.usd,
        CurrencyCode.eur,
        CurrencyCode.gbp,
        CurrencyCode.jpy
    ]
    
    public var body: some View {
        NavigationStack {
            List {
                // MARK: - Preferences Section
                Section(header: Text("Preferences")) {
                    Picker("Default Currency", selection: Binding(
                        get: { currentProfile.defaultCurrencyCode },
                        set: { newCode in
                            updateCurrency(newCode)
                        }
                    )) {
                        ForEach(availableCurrencies, id: \.code) { currency in
                            Text("\(currency.code) (\(currency.symbol))").tag(currency.code)
                        }
                    }
                    Picker("Pay Cycle / Payday", selection: Binding(
                        get: { currentProfile.payCycleStartDay },
                        set: { newDay in
                            updatePayCycle(newDay)
                        }
                    )) {
                        Text("Calendar Month (1st)").tag(1)
                        Text("Mid-Month (15th)").tag(15)
                        Text("Salary Cycle (25th)").tag(25)
                        Text("Month-End (28th)").tag(28)
                    }
                    .accessibilityLabel("Pay Cycle and Payday Selector")
                    
                    Button {
                        let currency = CurrencyCode.from(code: currentProfile.defaultCurrencyCode)
                        if let inc = currentProfile.expectedMonthlyIncomeMinor {
                            editIncomeText = CSVExporter.formatDecimal(amountMinor: inc, exponent: currency.minorUnitExponent)
                        } else {
                            editIncomeText = ""
                        }
                        if let bud = currentProfile.monthlyBudgetLimitMinor {
                            editBudgetText = CSVExporter.formatDecimal(amountMinor: bud, exponent: currency.minorUnitExponent)
                        } else {
                            editBudgetText = ""
                        }
                        showingEditPreferences = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Monthly Planning")
                                    .foregroundStyle(.primary)
                                Text("Expected income and monthly budget limit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .accessibilityLabel("Edit Monthly Planning Preferences")
                }
                
                // MARK: - Commitments Section
                if let ruleRepo = recurringRuleRepository,
                   let txRepo = transactionRepository,
                   let catRepo = categoryRepository {
                    Section(header: Text("Commitments")) {
                        NavigationLink {
                            RecurringRulesView(
                                ruleRepository: ruleRepo,
                                transactionRepository: txRepo,
                                categoryRepository: catRepo,
                                currencyCode: currentProfile.defaultCurrencyCode
                            )
                        } label: {
                            Label("Recurring Bills & Subscriptions", systemImage: "calendar.badge.clock")
                        }
                        .accessibilityLabel("Recurring Bills and Subscriptions")
                        .accessibilityHint("Shows scheduled commitments and allows posting them when due")
                    }
                }
                
                // MARK: - Data Management Section
                Section(header: Text("Data & Storage")) {
                    if let txRepo = transactionRepository, let catRepo = categoryRepository {
                        Button {
                            showingExportSheet = true
                        } label: {
                            Label("Export Transactions (CSV)", systemImage: "square.and.arrow.up")
                        }
                        .sheet(isPresented: $showingExportSheet) {
                            ExportDataView(
                                transactionRepository: txRepo,
                                categoryRepository: catRepo
                            )
                        }
                        .accessibilityLabel("Export Transactions as CSV")
                        .accessibilityHint("Opens export view with date filtering and share sheet")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete All Local Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Delete All Local Data")
                    .accessibilityHint("Permanently erases all transactions, budgets, categories, and settings")
                }
                
                // MARK: - Privacy & Security Section
                Section(header: Text("Privacy & Security")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Local-First & Offline")
                                    .font(.headline)
                                Text("All transaction records, budgets, and categories remain strictly on this device. No network access, cloud sync, or external analytics SDKs are active.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "waveform")
                                .foregroundStyle(.blue)
                                .font(.title3)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("On-Device Voice Privacy")
                                    .font(.headline)
                                Text("Speech recognition utilizes Apple's on-device processing where available. Audio recordings and raw transcripts are never retained.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - About Section
                Section(header: Text("About & Architecture")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (MVP Release Candidate)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Platform Target")
                        Spacer()
                        Text("iOS 17.0+ (Provisional)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Money Precision")
                        Spacer()
                        Text("Integer Minor Units (Exact)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("SwiftUI + Clean Domain Core")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Erase All Data?",
                isPresented: $showingDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Erase Everything", role: .destructive) {
                    performDeleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all transactions, budgets, categories, and preferences from this device. This action cannot be undone.")
            }
            .sheet(isPresented: $showingEditPreferences) {
                NavigationStack {
                    Form {
                        Section(header: Text("Monthly Expected Income")) {
                            TextField("Amount", text: $editIncomeText)
                                .keyboardType(.decimalPad)
                            Text("Optional planning figure. Distinguish clearly from actual posted income.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Section(header: Text("Monthly Budget Limit")) {
                            TextField("Amount", text: $editBudgetText)
                                .keyboardType(.decimalPad)
                            Text("Monthly spending limit used to track budget pace.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("Edit Planning")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingEditPreferences = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                savePreferences()
                                showingEditPreferences = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateCurrency(_ newCode: String) {
        currentProfile.defaultCurrencyCode = newCode
        guard let profileRepo = userProfileRepository else { return }
        Task {
            do {
                var p = try await profileRepo.getProfile()
                p.defaultCurrencyCode = newCode
                try await profileRepo.updateProfile(p)
            } catch {
                // Maintain local state
            }
        }
    }
    
    private func updatePayCycle(_ newDay: Int) {
        currentProfile.payCycleStartDay = newDay
        guard let profileRepo = userProfileRepository else { return }
        Task {
            do {
                var p = try await profileRepo.getProfile()
                p.payCycleStartDay = newDay
                try await profileRepo.updateProfile(p)
            } catch {}
        }
    }
    
    private func savePreferences() {
        let currency = CurrencyCode.from(code: currentProfile.defaultCurrencyCode)
        let incomeMinor = parseMinor(from: editIncomeText, exponent: currency.minorUnitExponent)
        let budgetMinor = parseMinor(from: editBudgetText, exponent: currency.minorUnitExponent)
        
        currentProfile.expectedMonthlyIncomeMinor = incomeMinor
        currentProfile.monthlyBudgetLimitMinor = budgetMinor
        
        guard let profileRepo = userProfileRepository else { return }
        Task {
            do {
                var p = try await profileRepo.getProfile()
                p.expectedMonthlyIncomeMinor = incomeMinor
                p.monthlyBudgetLimitMinor = budgetMinor
                try await profileRepo.updateProfile(p)
            } catch {}
        }
    }
    
    private func parseMinor(from text: String, exponent: Int) -> Int64? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        
        let parts = clean.split(separator: ".", omittingEmptySubsequences: false)
        guard let units = Int64(parts[0]) else { return nil }
        
        var multiplier: Int64 = 1
        for _ in 0..<exponent { multiplier *= 10 }
        
        var minor = units * multiplier
        if parts.count > 1 && exponent > 0 {
            var fracStr = String(parts[1])
            if fracStr.count > exponent {
                fracStr = String(fracStr.prefix(exponent))
            }
            while fracStr.count < exponent {
                fracStr.append("0")
            }
            if let fracVal = Int64(fracStr) {
                minor += fracVal
            }
        }
        return minor
    }
    
    private func performDeleteAllData() {
        guard let fileStore = fileStore else {
            onResetData?()
            return
        }
        
        Task {
            do {
                try await fileStore.clearAllData()
                await MainActor.run {
                    onResetData?()
                }
            } catch {
                await MainActor.run {
                    onResetData?()
                }
            }
        }
    }
}
