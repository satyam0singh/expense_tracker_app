import Foundation

/// A compact snippet of a recent transaction for display on widgets.
public struct WidgetTransactionSnippet: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let categoryName: String
    public let amountMinor: Int64
    public let currencyCode: String
    public let formattedAmount: String
    public let type: TransactionType
    public let transactionDay: String
    
    public init(
        id: UUID = UUID(),
        categoryName: String,
        amountMinor: Int64,
        currencyCode: String,
        formattedAmount: String,
        type: TransactionType,
        transactionDay: String
    ) {
        self.id = id
        self.categoryName = categoryName
        self.amountMinor = amountMinor
        self.currencyCode = currencyCode
        self.formattedAmount = formattedAmount
        self.type = type
        self.transactionDay = transactionDay
    }
}

/// A serialized snapshot of budget and spend metrics consumed by WidgetKit extensions and App Intents.
/// Invariants:
/// - No bank balance is ever displayed or claimed (ADR-004).
/// - All currency calculations are stored as integer minor units.
/// - Supports redaction for locked-screen privacy modes.
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let currencyCode: String
    public let currentMonthTitle: String
    
    // Monthly Budget metrics
    public let budgetLimitMinor: Int64?
    public let spentMinor: Int64
    public let remainingMinor: Int64?
    public let isOverBudget: Bool
    public let formattedBudgetRemaining: String
    public let formattedSpent: String
    public let formattedBudgetLimit: String
    public let budgetPacePercentage: Double
    
    // Safe-to-Spend / Pay Cycle metrics
    public let hasSafeToSpend: Bool
    public let safeToSpendTodayMinor: Int64?
    public let safeToSpendCycleMinor: Int64?
    public let cycleDaysRemaining: Int?
    public let formattedSafeToSpendToday: String?
    public let safeToSpendExplanation: String
    
    // Recent activity (up to 3 items)
    public let recentTransactions: [WidgetTransactionSnippet]
    
    // Privacy flag
    public let isPrivacyRedacted: Bool
    
    public init(
        generatedAt: Date = Date(),
        currencyCode: String,
        currentMonthTitle: String,
        budgetLimitMinor: Int64?,
        spentMinor: Int64,
        remainingMinor: Int64?,
        isOverBudget: Bool,
        formattedBudgetRemaining: String,
        formattedSpent: String,
        formattedBudgetLimit: String,
        budgetPacePercentage: Double,
        hasSafeToSpend: Bool,
        safeToSpendTodayMinor: Int64?,
        safeToSpendCycleMinor: Int64?,
        cycleDaysRemaining: Int?,
        formattedSafeToSpendToday: String?,
        safeToSpendExplanation: String,
        recentTransactions: [WidgetTransactionSnippet] = [],
        isPrivacyRedacted: Bool = false
    ) {
        self.generatedAt = generatedAt
        self.currencyCode = currencyCode
        self.currentMonthTitle = currentMonthTitle
        self.budgetLimitMinor = budgetLimitMinor
        self.spentMinor = spentMinor
        self.remainingMinor = remainingMinor
        self.isOverBudget = isOverBudget
        self.formattedBudgetRemaining = formattedBudgetRemaining
        self.formattedSpent = formattedSpent
        self.formattedBudgetLimit = formattedBudgetLimit
        self.budgetPacePercentage = budgetPacePercentage
        self.hasSafeToSpend = hasSafeToSpend
        self.safeToSpendTodayMinor = safeToSpendTodayMinor
        self.safeToSpendCycleMinor = safeToSpendCycleMinor
        self.cycleDaysRemaining = cycleDaysRemaining
        self.formattedSafeToSpendToday = formattedSafeToSpendToday
        self.safeToSpendExplanation = safeToSpendExplanation
        self.recentTransactions = recentTransactions
        self.isPrivacyRedacted = isPrivacyRedacted
    }
    
    /// Returns a placeholder snapshot for WidgetKit gallery previews.
    public static var placeholder: WidgetSnapshot {
        WidgetSnapshot(
            currencyCode: "INR",
            currentMonthTitle: "October 2026",
            budgetLimitMinor: 5000000, // 50,000.00
            spentMinor: 2150000,       // 21,500.00
            remainingMinor: 2850000,   // 28,500.00
            isOverBudget: false,
            formattedBudgetRemaining: "₹28,500",
            formattedSpent: "₹21,500",
            formattedBudgetLimit: "₹50,000",
            budgetPacePercentage: 0.43,
            hasSafeToSpend: true,
            safeToSpendTodayMinor: 142500, // 1,425.00
            safeToSpendCycleMinor: 2850000,
            cycleDaysRemaining: 20,
            formattedSafeToSpendToday: "₹1,425",
            safeToSpendExplanation: "Based on configured budget limit minus eligible spending and commitments.",
            recentTransactions: [
                WidgetTransactionSnippet(
                    categoryName: "Groceries",
                    amountMinor: 85000,
                    currencyCode: "INR",
                    formattedAmount: "-₹850",
                    type: .expense,
                    transactionDay: "2026-10-08"
                ),
                WidgetTransactionSnippet(
                    categoryName: "Coffee",
                    amountMinor: 25000,
                    currencyCode: "INR",
                    formattedAmount: "-₹250",
                    type: .expense,
                    transactionDay: "2026-10-07"
                )
            ],
            isPrivacyRedacted: false
        )
    }
    
    /// Produces a copy of this snapshot with sensitive numbers obscured.
    public func redacted() -> WidgetSnapshot {
        let currencySymbol = CurrencyCode.from(code: currencyCode).symbol
        return WidgetSnapshot(
            generatedAt: generatedAt,
            currencyCode: currencyCode,
            currentMonthTitle: currentMonthTitle,
            budgetLimitMinor: budgetLimitMinor,
            spentMinor: spentMinor,
            remainingMinor: remainingMinor,
            isOverBudget: isOverBudget,
            formattedBudgetRemaining: "\(currencySymbol)••••",
            formattedSpent: "\(currencySymbol)••••",
            formattedBudgetLimit: "\(currencySymbol)••••",
            budgetPacePercentage: budgetPacePercentage,
            hasSafeToSpend: hasSafeToSpend,
            safeToSpendTodayMinor: safeToSpendTodayMinor,
            safeToSpendCycleMinor: safeToSpendCycleMinor,
            cycleDaysRemaining: cycleDaysRemaining,
            formattedSafeToSpendToday: hasSafeToSpend ? "\(currencySymbol)••••" : nil,
            safeToSpendExplanation: safeToSpendExplanation,
            recentTransactions: recentTransactions.map { item in
                WidgetTransactionSnippet(
                    id: item.id,
                    categoryName: item.categoryName,
                    amountMinor: item.amountMinor,
                    currencyCode: item.currencyCode,
                    formattedAmount: "\(currencySymbol)••••",
                    type: item.type,
                    transactionDay: item.transactionDay
                )
            },
            isPrivacyRedacted: true
        )
    }
}
