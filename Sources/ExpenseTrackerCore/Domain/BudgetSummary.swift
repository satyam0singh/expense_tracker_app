import Foundation

/// Calculated period summary distinguishing actual recorded cash flow from budget limits.
/// Invariants per docs/00_PRODUCT_BRAIN.md and docs/05_DATABASE_API_SPEC.md:
/// - Actual net != Bank balance (cash on hand and external accounts are unknown).
/// - Transfers are excluded from expense and income totals.
/// - budgetRemaining is NOT clamped to zero when spending exceeds the limit (may be negative).
public struct BudgetSummary: Equatable, Sendable {
    public let month: CalendarMonth
    public let currency: CurrencyCode
    
    // MARK: - Actual Recorded Cash Flow
    /// Sum of all confirmed INCOME transactions in this period.
    public let recordedIncome: Money
    
    /// Sum of all confirmed EXPENSE transactions in this period (excluding transfers).
    public let recordedExpenses: Money
    
    /// Sum of all confirmed REFUND transactions in this period.
    public let recordedRefunds: Money
    
    /// Actual net cash flow = income + refunds - expenses.
    /// Explicitly distinct from any bank balance.
    public let actualNet: Money
    
    // MARK: - Budget Tracking
    /// Configured monthly budget limit, if set.
    public let budgetLimit: Money?
    
    /// Net spend counting against the budget = max(0, recordedExpenses - recordedRefunds).
    public let netBudgetSpend: Money
    
    /// Remaining budget = budgetLimit - netBudgetSpend.
    /// Can be negative (over-budget). Nil if no budget limit is configured.
    public let budgetRemaining: Money?
    
    /// Percentage of budget used (0...100+). Nil if limit is zero or no budget configured.
    public let budgetUsedPercent: Double?
    
    /// True if net spend exceeds the configured budget limit.
    public var isOverBudget: Bool {
        guard let remaining = budgetRemaining else { return false }
        return remaining.amountMinor < 0
    }
    
    // MARK: - Factory / Calculation Engine
    
    /// Deterministically computes the summary from a set of transactions and optional budget limit.
    /// Only confirmed (non-deleted) transactions in the target month and matching currency are processed.
    public static func calculate(
        for month: CalendarMonth,
        currency: CurrencyCode = .inr,
        budgetLimitMinor: Int64? = nil,
        transactions: [Transaction]
    ) -> BudgetSummary {
        var incomeMinor: Int64 = 0
        var expenseMinor: Int64 = 0
        var refundMinor: Int64 = 0
        
        for tx in transactions {
            // Skip soft-deleted transactions
            if tx.isDeleted { continue }
            // Filter by currency
            guard tx.currencyCode == currency.code else { continue }
            // Filter by month
            guard month.contains(dayString: tx.transactionDay) else { continue }
            
            switch tx.type {
            case .income:
                incomeMinor += tx.amountMinor
            case .expense:
                expenseMinor += tx.amountMinor
            case .refund:
                refundMinor += tx.amountMinor
            case .transfer:
                // Transfers are explicitly excluded from spending and income
                break
            }
        }
        
        let incomeMoney = Money(amountMinor: incomeMinor, currency: currency)
        let expenseMoney = Money(amountMinor: expenseMinor, currency: currency)
        let refundMoney = Money(amountMinor: refundMinor, currency: currency)
        
        // actualNet = income + refunds - expenses
        let actualNetMinor = incomeMinor + refundMinor - expenseMinor
        let actualNetMoney = Money(amountMinor: actualNetMinor, currency: currency)
        
        // netBudgetSpend = max(0, expenses - refunds)
        let netSpendMinor = max(0, expenseMinor - refundMinor)
        let netSpendMoney = Money(amountMinor: netSpendMinor, currency: currency)
        
        let limitMoney: Money?
        let remainingMoney: Money?
        let usedPercent: Double?
        
        if let limit = budgetLimitMinor {
            limitMoney = Money(amountMinor: limit, currency: currency)
            // budgetRemaining = limit - netBudgetSpend (can be negative, not clamped)
            remainingMoney = Money(amountMinor: limit - netSpendMinor, currency: currency)
            
            if limit > 0 {
                usedPercent = (Double(netSpendMinor) / Double(limit)) * 100.0
            } else {
                usedPercent = nil // Undefined when limit is 0
            }
        } else {
            limitMoney = nil
            remainingMoney = nil
            usedPercent = nil
        }
        
        return BudgetSummary(
            month: month,
            currency: currency,
            recordedIncome: incomeMoney,
            recordedExpenses: expenseMoney,
            recordedRefunds: refundMoney,
            actualNet: actualNetMoney,
            budgetLimit: limitMoney,
            netBudgetSpend: netSpendMoney,
            budgetRemaining: remainingMoney,
            budgetUsedPercent: usedPercent
        )
    }
}
