import Foundation

/// Local user preferences and planning context.
/// Invariants:
/// - expectedMonthlyIncomeMinor is a planning figure only; NEVER counted as actual received income.
/// - defaultCurrencyCode defaults to INR per docs/00_PRODUCT_BRAIN.md.
public struct UserProfile: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var displayName: String?
    public var defaultCurrencyCode: String
    public var localeIdentifier: String
    /// Planning figure in default currency; never included in actual income totals.
    public var expectedMonthlyIncomeMinor: Int64?
    public var monthlyBudgetLimitMinor: Int64?
    /// Day of the month on which the pay cycle begins (1...28). 1 = Calendar Month.
    public var payCycleStartDay: Int
    public var safeToSpendBasis: SafeToSpendBasis
    public var onboardingCompleted: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        displayName: String? = nil,
        defaultCurrencyCode: String = "INR",
        localeIdentifier: String = "en_IN",
        expectedMonthlyIncomeMinor: Int64? = nil,
        monthlyBudgetLimitMinor: Int64? = nil,
        payCycleStartDay: Int = 1,
        safeToSpendBasis: SafeToSpendBasis = .budgetLimit,
        onboardingCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        if let income = expectedMonthlyIncomeMinor {
            precondition(income >= 0, "Expected monthly income cannot be negative.")
        }
        if let budget = monthlyBudgetLimitMinor {
            precondition(budget >= 0, "Monthly budget limit cannot be negative.")
        }
        self.id = id
        self.displayName = displayName
        self.defaultCurrencyCode = defaultCurrencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.localeIdentifier = localeIdentifier
        self.expectedMonthlyIncomeMinor = expectedMonthlyIncomeMinor
        self.monthlyBudgetLimitMinor = monthlyBudgetLimitMinor
        self.payCycleStartDay = max(1, min(28, payCycleStartDay))
        self.safeToSpendBasis = safeToSpendBasis
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public static var `default`: UserProfile {
        UserProfile(
            displayName: nil,
            defaultCurrencyCode: "INR",
            localeIdentifier: "en_IN",
            expectedMonthlyIncomeMinor: nil,
            monthlyBudgetLimitMinor: nil,
            onboardingCompleted: false
        )
    }
}
