import Foundation

/// Result of processing a shortcut or Siri intent to log an expense.
public struct LogExpenseIntentResult: Sendable, Equatable {
    public let transaction: Transaction
    public let formattedAmount: String
    public let categoryName: String
    public let confirmationMessage: String
    
    public init(
        transaction: Transaction,
        formattedAmount: String,
        categoryName: String,
        confirmationMessage: String
    ) {
        self.transaction = transaction
        self.formattedAmount = formattedAmount
        self.categoryName = categoryName
        self.confirmationMessage = confirmationMessage
    }
}

/// Pure domain handler for processing Siri and iOS Shortcuts commands.
/// Enforces all product invariants:
/// - Pure integer minor units (no floating-point money storage).
/// - Validated positive amounts.
/// - Graceful category matching.
/// - Immediate refresh of the shared WidgetSnapshot.
/// - Zero logging of sensitive financial data (ADR-004 & AGENTS.md).
public enum LogExpenseIntentHandler {
    
    public static func handle(
        amountMajor: Double,
        categoryName: String?,
        note: String?,
        paymentMethodName: String? = nil,
        transactionDay: String? = nil,
        userProfile: UserProfile,
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        budgetRepository: BudgetRepositoryProtocol? = nil,
        recurringRuleRepository: RecurringRuleRepositoryProtocol? = nil,
        widgetDataStore: WidgetDataStoreProtocol? = nil
    ) async throws -> LogExpenseIntentResult {
        // 1. Validate and convert amount to integer minor units
        guard amountMajor > 0, !amountMajor.isNaN, !amountMajor.isInfinite else {
            throw ValidationError.zeroOrNegativeAmount(0)
        }
        
        let currency = CurrencyCode.from(code: userProfile.defaultCurrencyCode)
        // Convert to minor units with exact decimal rounding
        let decimalAmount = Decimal(amountMajor)
        let multiplier = Decimal(currency.minorUnitsFactor)
        let minorDecimal = (decimalAmount * multiplier)
        var roundedMinorDecimal = Decimal()
        var mutableMinor = minorDecimal
        NSDecimalRound(&roundedMinorDecimal, &mutableMinor, 0, .plain)
        
        let minorUnits = NSDecimalNumber(decimal: roundedMinorDecimal).int64Value
        guard minorUnits > 0 else {
            throw ValidationError.zeroOrNegativeAmount(minorUnits)
        }
        
        // 2. Resolve date
        let resolvedDay: String
        if let customDay = transactionDay, TransactionDraft.isValidDateString(customDay) {
            resolvedDay = customDay
        } else {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            resolvedDay = df.string(from: Date())
        }
        
        // 3. Resolve category
        let categories = (try? await categoryRepository.list(includeArchived: false)) ?? []
        var matchedCategoryId: UUID? = nil
        var matchedCategoryName = "Uncategorized"
        
        if let query = categoryName?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let lowerQuery = query.lowercased()
            if let found = categories.first(where: { $0.name.lowercased() == lowerQuery }) {
                matchedCategoryId = found.id
                matchedCategoryName = found.name
            } else if let partial = categories.first(where: { $0.name.lowercased().contains(lowerQuery) || lowerQuery.contains($0.name.lowercased()) }) {
                matchedCategoryId = partial.id
                matchedCategoryName = partial.name
            } else {
                matchedCategoryName = query
            }
        } else {
            // Default to "Other" or first category if available
            if let other = categories.first(where: { $0.name.lowercased() == "other" }) {
                matchedCategoryId = other.id
                matchedCategoryName = other.name
            } else if let first = categories.first {
                matchedCategoryId = first.id
                matchedCategoryName = first.name
            }
        }
        
        // 4. Resolve payment method
        var paymentMethod: PaymentMethod? = nil
        if let pmQuery = paymentMethodName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            paymentMethod = PaymentMethod.allCases.first {
                $0.rawValue.lowercased() == pmQuery || $0.displayName.lowercased() == pmQuery
            }
        }
        
        // 5. Build and validate draft
        let draft = TransactionDraft(
            type: .expense,
            amountMinor: minorUnits,
            currencyCode: currency.code,
            categoryId: matchedCategoryId,
            categoryNameSnapshot: matchedCategoryName,
            merchant: nil,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            transactionDay: resolvedDay,
            paymentMethod: paymentMethod,
            source: .shortcut,
            recurringRuleId: nil
        )
        
        let transaction = try draft.validate()
        try await transactionRepository.save(transaction)
        
        // 6. Refresh Widget Snapshot if data store is provided
        if let store = widgetDataStore {
            let activeMonth = CalendarMonth(dateString: resolvedDay) ?? CalendarMonth(date: Date())
            let txs = (try? await transactionRepository.listAll(includeDeleted: false)) ?? [transaction]
            let budget = try? await budgetRepository?.get(month: activeMonth)
            let rules = (try? await recurringRuleRepository?.list(activeOnly: true)) ?? []
            
            let snapshot = WidgetSnapshotGenerator.generate(
                userProfile: userProfile,
                month: activeMonth,
                budget: budget,
                transactions: txs,
                categories: categories,
                recurringRules: rules,
                asOfDate: Date()
            )
            try? await store.saveSnapshot(snapshot)
        }
        
        let formatted = CurrencyFormatter.format(money: Money(amountMinor: minorUnits, currency: currency))
        let confirmation = "Logged \(formatted) in \(matchedCategoryName)."
        
        return LogExpenseIntentResult(
            transaction: transaction,
            formattedAmount: formatted,
            categoryName: matchedCategoryName,
            confirmationMessage: confirmation
        )
    }
}
