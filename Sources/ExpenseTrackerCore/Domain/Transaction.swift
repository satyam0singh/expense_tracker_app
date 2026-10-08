import Foundation

/// Represents a recorded monetary transaction.
/// Invariants per docs/00_PRODUCT_BRAIN.md and docs/05_DATABASE_API_SPEC.md:
/// - amountMinor is strictly positive (> 0); type denotes spending vs income vs refund vs transfer.
/// - transactionDay is stored as canonical local calendar day (YYYY-MM-DD).
/// - createdAt and updatedAt are UTC timestamps.
public struct Transaction: Identifiable, Equatable, Hashable, Sendable, Codable {
    public let id: UUID
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
    public let createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    
    public init(
        id: UUID = UUID(),
        type: TransactionType,
        amountMinor: Int64,
        currencyCode: String = "INR",
        categoryId: UUID? = nil,
        categoryNameSnapshot: String? = nil,
        merchant: String? = nil,
        note: String? = nil,
        transactionDay: String,
        paymentMethod: PaymentMethod? = nil,
        source: TransactionSource = .manual,
        recurringRuleId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        precondition(amountMinor > 0, "Transaction amountMinor must be greater than zero.")
        self.id = id
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
    
    public var isDeleted: Bool {
        return deletedAt != nil
    }
}
