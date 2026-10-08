import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

public struct VoiceReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let parseResult: VoiceParseResult
    private let currencyCode: String
    private let onSaved: (Transaction) -> Void
    
    @State private var type: TransactionType
    @State private var amountString: String
    @State private var selectedCategoryId: UUID?
    @State private var selectedDate: Date
    @State private var merchant: String
    @State private var note: String
    @State private var paymentMethod: PaymentMethod?
    @State private var categories: [Category] = []
    
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        parseResult: VoiceParseResult,
        currencyCode: String = "INR",
        onSaved: @escaping (Transaction) -> Void = { _ in }
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.parseResult = parseResult
        self.currencyCode = currencyCode
        self.onSaved = onSaved
        
        let draft = parseResult.draft
        _type = State(initialValue: draft.type)
        _selectedCategoryId = State(initialValue: draft.categoryId)
        _merchant = State(initialValue: draft.merchant ?? "")
        _note = State(initialValue: draft.note ?? "")
        _paymentMethod = State(initialValue: draft.paymentMethod)
        
        // Format initial minor units to major string
        let cur = CurrencyCode.from(code: currencyCode)
        let exp = cur.minorUnitExponent
        if draft.amountMinor > 0 {
            if exp == 0 {
                _amountString = State(initialValue: "\(draft.amountMinor)")
            } else {
                let div = Int64(pow10(exp))
                let major = draft.amountMinor / div
                let minor = draft.amountMinor % div
                if minor == 0 {
                    _amountString = State(initialValue: "\(major)")
                } else {
                    _amountString = State(initialValue: String(format: "%d.%0*d", major, exp, Int(minor)))
                }
            }
        } else {
            _amountString = State(initialValue: "")
        }
        
        let parsedDate = Self.dateFromDayString(draft.transactionDay) ?? Date()
        _selectedDate = State(initialValue: parsedDate)
    }
    
    private var currency: CurrencyCode {
        CurrencyCode.from(code: currencyCode)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Spoken Transcript & Warnings
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundStyle(.blue)
                            Text("What you said")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Text("\"\(parseResult.rawTranscript)\"")
                            .font(.body.italic())
                    }
                    .padding(.vertical, 2)
                    
                    if !parseResult.warnings.isEmpty {
                        ForEach(parseResult.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    Text("Voice Extraction")
                }
                
                // Section 2: Type & Amount (Amount-first)
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
                    .padding(.vertical, 4)
                } header: {
                    Text("Amount")
                }
                
                // Section 3: Category
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
                
                // Section 4: Details
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                    TextField("Merchant / Payee (Optional)", text: $merchant)
                    TextField("Note (Optional)", text: $note)
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
            .navigationTitle("Review Voice Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        confirmAndSave()
                    }
                    .font(.headline)
                    .disabled(isSaving || !isAmountValid)
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
                    // Ignore
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
    
    private func confirmAndSave() {
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
            source: .voice
        )
        
        isSaving = true
        Task {
            do {
                let saved = try await transactionRepository.add(draft: draft)
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
    
    private func parseAmountMinor(from text: String, exponent: Int) -> Int64? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
        guard !clean.isEmpty else { return nil }
        
        let parts = clean.split(separator: ".")
        if parts.count == 1 {
            guard let major = Int64(parts[0]) else { return nil }
            return major * Int64(pow10(exponent))
        } else if parts.count == 2 {
            guard let major = Int64(parts[0]) else { return nil }
            var minorPart = String(parts[1])
            if minorPart.count > exponent {
                minorPart = String(minorPart.prefix(exponent))
            } else while minorPart.count < exponent {
                minorPart.append("0")
            }
            guard let minor = Int64(minorPart) else { return nil }
            return major * Int64(pow10(exponent)) + minor
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
    
    private static func pow10(_ n: Int) -> Int {
        var res = 1
        for _ in 0..<n {
            res *= 10
        }
        return res
    }
}
