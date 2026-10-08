import Foundation

/// A draft transaction representing uncommitted user or voice input.
/// Before persistence or domain application, this draft must pass validation.
public struct TransactionDraft: Equatable, Sendable {
    public var type: TransactionType
    public var amountMinor: Int64
    public var currencyCode: String
    public var categoryId: UUID?
    public var categoryNameSnapshot: String?
    public var merchant: String?
    public var note: String?
    public var transactionDay: String // YYYY-MM-DD
    public var paymentMethod: PaymentMethod?
    public var source: TransactionSource
    public var recurringRuleId: UUID?
    
    public init(
        type: TransactionType = .expense,
        amountMinor: Int64 = 0,
        currencyCode: String = "INR",
        categoryId: UUID? = nil,
        categoryNameSnapshot: String? = nil,
        merchant: String? = nil,
        note: String? = nil,
        transactionDay: String = "",
        paymentMethod: PaymentMethod? = nil,
        source: TransactionSource = .manual,
        recurringRuleId: UUID? = nil
    ) {
        self.type = type
        self.amountMinor = amountMinor
        self.currencyCode = currencyCode
        self.categoryId = categoryId
        self.categoryNameSnapshot = categoryNameSnapshot
        self.merchant = merchant
        self.note = note
        self.transactionDay = transactionDay
        self.paymentMethod = paymentMethod
        self.source = source
        self.recurringRuleId = recurringRuleId
    }
    
    /// Validates the draft against domain invariants.
    /// Throws `ValidationError` if amount <= 0, currency is invalid, or date format is invalid.
    public func validate() throws -> Transaction {
        guard amountMinor > 0 else {
            throw ValidationError.zeroOrNegativeAmount(amountMinor)
        }
        
        let trimmedCurrency = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmedCurrency.count == 3 else {
            throw ValidationError.invalidCurrencyCode(currencyCode)
        }
        
        let trimmedDate = transactionDay.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidDateString(trimmedDate) else {
            throw ValidationError.invalidDateFormat(transactionDay)
        }
        
        return Transaction(
            type: type,
            amountMinor: amountMinor,
            currencyCode: trimmedCurrency,
            categoryId: categoryId,
            categoryNameSnapshot: categoryNameSnapshot,
            merchant: merchant?.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            transactionDay: trimmedDate,
            paymentMethod: paymentMethod,
            source: source,
            recurringRuleId: recurringRuleId
        )
    }
    
    public static func isValidDateString(_ dateString: String) -> Bool {
        // Expected format: YYYY-MM-DD
        let parts = dateString.split(separator: "-")
        guard parts.count == 3 else { return false }
        guard parts[0].count == 4, parts[1].count == 2, parts[2].count == 2 else { return false }
        guard let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return false }
        guard month >= 1 && month <= 12 else { return false }
        
        let calendarMonth = CalendarMonth(year: year, month: month)
        guard day >= 1 && day <= calendarMonth.numberOfDays else { return false }
        return true
    }
}
