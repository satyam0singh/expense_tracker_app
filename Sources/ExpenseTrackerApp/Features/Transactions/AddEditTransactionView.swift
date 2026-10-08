import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

public struct AddEditTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let currencyCode: String
    private let existingTransaction: Transaction?
    private let onSaved: (Transaction) -> Void
    
    @State private var type: TransactionType = .expense
    @State private var amountString: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var selectedDate: Date = Date()
    @State private var merchant: String = ""
    @State private var note: String = ""
    @State private var paymentMethod: PaymentMethod?
    @State private var categories: [Category] = []
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        currencyCode: String = "INR",
        existingTransaction: Transaction? = nil,
        onSaved: @escaping (Transaction) -> Void = { _ in }
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.currencyCode = currencyCode
        self.existingTransaction = existingTransaction
        self.onSaved = onSaved
        
        if let existing = existingTransaction {
            _type = State(initialValue: existing.type)
            _selectedCategoryId = State(initialValue: existing.categoryId)
            _merchant = State(initialValue: existing.merchant ?? "")
            _note = State(initialValue: existing.note ?? "")
            _paymentMethod = State(initialValue: existing.paymentMethod)
            
            // Format existing minor units to major string
            let cur = CurrencyCode.from(code: existing.currencyCode)
            let exp = cur.minorUnitExponent
            if exp == 0 {
                _amountString = State(initialValue: "\(existing.amountMinor)")
            } else {
                let div = Int64(CurrencyFormatter.powerOfTen(exp))
                let major = existing.amountMinor / div
                let minor = existing.amountMinor % div
                if minor == 0 {
                    _amountString = State(initialValue: "\(major)")
                } else {
                    _amountString = State(initialValue: String(format: "%d.%0*d", major, exp, Int(minor)))
                }
            }
            
            // Parse existing day string to Date
            if let parsedDate = Self.dateFromDayString(existing.transactionDay) {
                _selectedDate = State(initialValue: parsedDate)
            }
        }
    }
    
    private var isEditMode: Bool {
        existingTransaction != nil
    }
    
    private var currency: CurrencyCode {
        CurrencyCode.from(code: currencyCode)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Type & Amount (Amount-first)
                Section {
                    Picker("Transaction Type", selection: $type) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text(currency.symbol)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        TextField("0", text: $amountString)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Transaction Amount")
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Amount")
                }
                
                // Section 2: Category
                Section {
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("Select Category (Optional)").tag(nil as UUID?)
                        ForEach(categories) { cat in
                            HStack {
                                Image(systemName: cat.iconKey)
                                Text(cat.name)
                            }
                            .tag(cat.id as UUID?)
                        }
                    }
                } header: {
                    Text("Classification")
                }
                
                // Section 3: Date & Details
                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    
                    TextField("Merchant / Payee (Optional)", text: $merchant)
                        .accessibilityLabel("Merchant or Payee")
                    
                    TextField("Note (Optional)", text: $note)
                        .accessibilityLabel("Transaction note")
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        Text("None").tag(nil as PaymentMethod?)
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method as PaymentMethod?)
                        }
                    }
                } header: {
                    Text("Details")
                }
            }
            .navigationTitle(isEditMode ? "Edit Transaction" : "Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Save" : "Add") {
                        saveTransaction()
                    }
                    .font(.headline)
                    .disabled(isSaving || !isAmountValid)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unexpected error occurred.")
            }
            .task {
                do {
                    self.categories = try await categoryRepository.list(includeArchived: false)
                } catch {
                    // Ignore, categories list stays empty
                }
            }
        }
    }
    
    private var isAmountValid: Bool {
        guard let minor = parseAmountMinor(from: amountString, exponent: currency.minorUnitExponent) else {
            return false
        }
        return minor > 0
    }
    
    private func saveTransaction() {
        guard let minor = parseAmountMinor(from: amountString, exponent: currency.minorUnitExponent), minor > 0 else {
            errorMessage = "Please enter an amount greater than zero."
            return
        }
        
        let dayString = Self.dayStringFromDate(selectedDate)
        let selectedCategory = categories.first { $0.id == selectedCategoryId }
        
        let draft = TransactionDraft(
            type: type,
            amountMinor: minor,
            currencyCode: currency.code,
            categoryId: selectedCategoryId,
            categoryNameSnapshot: selectedCategory?.name,
            merchant: merchant.isEmpty ? nil : merchant,
            note: note.isEmpty ? nil : note,
            transactionDay: dayString,
            paymentMethod: paymentMethod,
            source: .manual
        )
        
        isSaving = true
        Task {
            do {
                let saved: Transaction
                if let existing = existingTransaction {
                    saved = try await transactionRepository.update(id: existing.id, draft: draft)
                } else {
                    saved = try await transactionRepository.add(draft: draft)
                }
                
                await MainActor.run {
                    self.isSaving = false
                    self.onSaved(saved)
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Safe Integer Parsing (No Float/Double Money Math)
    
    private func parseAmountMinor(from text: String, exponent: Int) -> Int64? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        guard !clean.isEmpty else { return nil }
        
        let parts = clean.split(separator: ".")
        if parts.count == 1 {
            guard let major = Int64(parts[0]) else { return nil }
            return major * Int64(CurrencyFormatter.powerOfTen(exponent))
        } else if parts.count == 2 {
            guard let major = Int64(parts[0]) else { return nil }
            var minorPart = String(parts[1])
            if minorPart.count > exponent {
                minorPart = String(minorPart.prefix(exponent))
            } else {
                while minorPart.count < exponent {
                    minorPart.append("0")
                }
            }
            guard let minor = Int64(minorPart) else { return nil }
            return major * Int64(CurrencyFormatter.powerOfTen(exponent)) + minor
        }
        return nil
    }
    
    private static func dayStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private static func dateFromDayString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
