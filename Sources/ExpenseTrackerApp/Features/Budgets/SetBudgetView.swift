import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

public struct SetBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let budgetRepository: BudgetRepositoryProtocol
    private let month: CalendarMonth
    private let currencyCode: String
    private let existingBudget: Budget?
    private let onSaved: (Budget) -> Void
    
    @State private var limitMajorString: String = ""
    @State private var warningThreshold: Int = 80
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
    public init(
        budgetRepository: BudgetRepositoryProtocol,
        month: CalendarMonth,
        currencyCode: String = "INR",
        existingBudget: Budget? = nil,
        onSaved: @escaping (Budget) -> Void = { _ in }
    ) {
        self.budgetRepository = budgetRepository
        self.month = month
        self.currencyCode = currencyCode
        self.existingBudget = existingBudget
        self.onSaved = onSaved
        
        if let existing = existingBudget {
            let cur = CurrencyCode.from(code: existing.currencyCode)
            let exp = cur.minorUnitExponent
            let div = Int64(pow10(exp))
            let major = existing.limitMinor / div
            let minor = existing.limitMinor % div
            if minor == 0 {
                _limitMajorString = State(initialValue: "\(major)")
            } else {
                _limitMajorString = State(initialValue: String(format: "%d.%0*d", major, exp, Int(minor)))
            }
            _warningThreshold = State(initialValue: existing.warningThresholdPercent ?? 80)
        }
    }
    
    private var currency: CurrencyCode {
        CurrencyCode.from(code: currencyCode)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Text(currency.symbol)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        TextField("0", text: $limitMajorString)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Monthly Budget Limit Amount")
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Monthly Limit for \(month.displayTitle())")
                } footer: {
                    Text("Total spending target for the calendar month. Used to track remaining budget.")
                }
                
                Section {
                    Stepper("Warning at \(warningThreshold)%", value: $warningThreshold, in: 50...100, step: 5)
                        .accessibilityLabel("Warning threshold at \(warningThreshold) percent")
                } header: {
                    Text("Threshold Alert")
                } footer: {
                    Text("Displays a visual alert when your spending crosses this percentage of your budget.")
                }
            }
            .navigationTitle(existingBudget != nil ? "Edit Budget" : "Set Monthly Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .font(.headline)
                    .disabled(isSaving || !isValid)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred while saving the budget.")
            }
        }
    }
    
    private var isValid: Bool {
        guard let minor = parseAmountMinor(from: limitMajorString, exponent: currency.minorUnitExponent) else {
            return false
        }
        return minor >= 0
    }
    
    private func saveBudget() {
        guard let minor = parseAmountMinor(from: limitMajorString, exponent: currency.minorUnitExponent), minor >= 0 else {
            errorMessage = "Please enter a valid non-negative budget limit."
            return
        }
        
        let budget = Budget(
            id: existingBudget?.id ?? UUID(),
            month: month,
            limitMinor: minor,
            currencyCode: currency.code,
            warningThresholdPercent: warningThreshold
        )
        
        isSaving = true
        Task {
            do {
                try await budgetRepository.save(budget: budget)
                await MainActor.run {
                    self.isSaving = false
                    self.onSaved(budget)
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
    
    private static func pow10(_ n: Int) -> Int {
        var res = 1
        for _ in 0..<n {
            res *= 10
        }
        return res
    }
}
