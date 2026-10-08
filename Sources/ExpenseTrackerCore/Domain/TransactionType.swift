import Foundation

/// Defines the nature and direction of a transaction.
/// Invariants per docs/00_PRODUCT_BRAIN.md and docs/05_DATABASE_API_SPEC.md:
/// - Expense, income, refund, and transfer have distinct semantics.
/// - Transfers must NEVER inflate spending or income totals.
public enum TransactionType: String, CaseIterable, Codable, Sendable {
    /// Outgoing expenditure. Decreases budget remaining and actual net.
    case expense = "EXPENSE"
    
    /// Incoming funds received. Increases actual net. Does NOT increase expense budget limit.
    case income = "INCOME"
    
    /// Credit/return for an earlier expense. Offsets spend in budget calculation.
    case refund = "REFUND"
    
    /// Movement of money between self-held accounts/instruments (e.g. cash withdrawal, credit card bill payment).
    /// Excluded from spending and income calculations so as not to double-count.
    case transfer = "TRANSFER"
    
    public var displayName: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .refund: return "Refund"
        case .transfer: return "Transfer"
        }
    }
}
