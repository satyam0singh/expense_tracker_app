import SwiftUI
import ExpenseTrackerCore

public struct AddEditRecurringRuleView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let ruleRepository: RecurringRuleRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let currencyCode: String
    private let existingRule: RecurringRule?
    private let onSaved: ((RecurringRule) -> Void)?
    
    @State private var title: String = ""
    @State private var type: TransactionType = .expense
    @State private var amountString: String = ""
    @State private var cadence: RecurrenceCadence = .monthly
    @State private var dueDate: Date = Date()
    @State private var selectedCategoryId: UUID?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var isActive: Bool = true
    
    @State private var categories: [Category] = []
    @State private var errorMessage: String?
    
    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
    
    public init(
        ruleRepository: RecurringRuleRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        currencyCode: String = "INR",
        existingRule: RecurringRule? = nil,
        onSaved: ((RecurringRule) -> Void)? = nil
    ) {
        self.ruleRepository = ruleRepository
        self.categoryRepository = categoryRepository
        self.currencyCode = currencyCode
        self.existingRule = existingRule
        self.onSaved = onSaved
    }
    
    private var currency: CurrencyCode {
        CurrencyCode.from(code: currencyCode)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Commitment Details")) {
                    TextField("Title (e.g., Rent, Netflix, WiFi)", text: $title)
                        .accessibilityLabel("Recurring Commitment Title")
                    
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text(currency.symbol)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                            .fontWeight(.medium)
                            .accessibilityLabel("Commitment Amount")
                    }
                }
                
                Section(header: Text("Schedule")) {
                    Picker("Cadence", selection: $cadence) {
                        ForEach(RecurrenceCadence.allCases, id: \.self) { c in
                            Text(c.displayName).tag(c)
                        }
                    }
                    .accessibilityLabel("Cadence Frequency")
                    
                    DatePicker("Next Due Date", selection: $dueDate, displayedComponents: .date)
                        .accessibilityLabel("Next Due Date")
                }
                
                Section(header: Text("Category & Payment")) {
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("Uncategorized").tag(UUID?.none)
                        ForEach(categories) { cat in
                            HStack {
                                Image(systemName: cat.iconKey)
                                Text(cat.name)
                            }
                            .tag(Optional(cat.id))
                        }
                    }
                    .accessibilityLabel("Category Picker")
                    
                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                        Text("None").tag(PaymentMethod?.none)
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(Optional(method))
                        }
                    }
                    .accessibilityLabel("Payment Method Picker")
                }
                
                Section(header: Text("Status")) {
                    Toggle("Active Schedule", isOn: $isActive)
                        .accessibilityLabel("Active Schedule Toggle")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(existingRule == nil ? "New Recurring Item" : "Edit Recurring Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRule()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task {
                await loadCategories()
                populateExisting()
            }
        }
    }
    
    private func loadCategories() async {
        do {
            let cats = try await categoryRepository.list(includeArchived: false)
            await MainActor.run {
                self.categories = cats
            }
        } catch {}
    }
    
    private func populateExisting() {
        if let rule = existingRule {
            self.title = rule.title
            self.type = rule.type
            self.amountString = CSVExporter.formatDecimal(amountMinor: rule.amountMinor, exponent: currency.minorUnitExponent)
            self.cadence = rule.cadence
            self.selectedCategoryId = rule.categoryId
            self.selectedPaymentMethod = rule.paymentMethod
            self.isActive = rule.isActive
            if let date = dayFormatter.date(from: rule.nextDueDate) {
                self.dueDate = date
            }
        }
    }
    
    private func saveRule() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Please enter a title."
            return
        }
        
        guard let amountMinor = parseMinor(from: amountString, exponent: currency.minorUnitExponent), amountMinor > 0 else {
            errorMessage = "Please enter a valid amount greater than zero."
            return
        }
        
        let dueDayString = dayFormatter.string(from: dueDate)
        let catSnapshot = categories.first(where: { $0.id == selectedCategoryId })?.name
        
        Task {
            do {
                if let existing = existingRule {
                    var updated = existing
                    updated.title = cleanTitle
                    updated.type = type
                    updated.amountMinor = amountMinor
                    updated.cadence = cadence
                    updated.nextDueDate = dueDayString
                    updated.categoryId = selectedCategoryId
                    updated.categoryNameSnapshot = catSnapshot
                    updated.paymentMethod = selectedPaymentMethod
                    updated.isActive = isActive
                    let saved = try await ruleRepository.update(rule: updated)
                    await MainActor.run {
                        onSaved?(saved)
                        dismiss()
                    }
                } else {
                    let newRule = RecurringRule(
                        title: cleanTitle,
                        type: type,
                        amountMinor: amountMinor,
                        currencyCode: currencyCode,
                        cadence: cadence,
                        nextDueDate: dueDayString,
                        categoryId: selectedCategoryId,
                        categoryNameSnapshot: catSnapshot,
                        paymentMethod: selectedPaymentMethod,
                        isActive: isActive
                    )
                    let saved = try await ruleRepository.create(rule: newRule)
                    await MainActor.run {
                        onSaved?(saved)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to save commitment schedule."
                }
            }
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
}
