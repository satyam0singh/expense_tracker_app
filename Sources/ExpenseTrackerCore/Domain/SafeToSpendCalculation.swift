import Foundation

/// Basis used to establish the planning pool for the Safe-to-Spend estimate.
public enum SafeToSpendBasis: String, CaseIterable, Codable, Sendable {
    case budgetLimit = "BUDGET_LIMIT"
    case expectedIncome = "EXPECTED_INCOME"
    
    public var displayName: String {
        switch self {
        case .budgetLimit: return "Monthly Budget Limit"
        case .expectedIncome: return "Expected Monthly Income"
        }
    }
}

/// Computes the factual, transparent "Available until Payday / Safe-to-Spend" estimate.
/// Invariants per docs/00_PRODUCT_BRAIN.md and US-071:
/// - Explicitly labeled as a planning forecast; NEVER claims to know actual bank balances.
/// - Integer minor units only; zero floating-point money math.
/// - Clearly states assumptions: Starting pool minus posted spend minus upcoming commitments.
public struct SafeToSpendCalculation: Equatable, Sendable {
    public let payCycle: PayCycle
    public let asOfDate: String // YYYY-MM-DD
    public let currency: CurrencyCode
    public let basis: SafeToSpendBasis
    public let startingPoolMinor: Int64
    public let postedSpendMinor: Int64
    public let upcomingCommitmentsMinor: Int64
    public let safeToSpendTotalMinor: Int64
    public let deficitMinor: Int64
    public let daysRemaining: Int
    public let dailyPaceMinor: Int64
    public let isDeficit: Bool
    public let assumptionsText: String
    
    public init(
        payCycle: PayCycle,
        asOfDate: String,
        currency: CurrencyCode,
        basis: SafeToSpendBasis,
        startingPoolMinor: Int64,
        postedSpendMinor: Int64,
        upcomingCommitmentsMinor: Int64
    ) {
        self.payCycle = payCycle
        self.asOfDate = asOfDate
        self.currency = currency
        self.basis = basis
        self.startingPoolMinor = startingPoolMinor
        self.postedSpendMinor = postedSpendMinor
        self.upcomingCommitmentsMinor = upcomingCommitmentsMinor
        
        let totalCommitted = postedSpendMinor + upcomingCommitmentsMinor
        if totalCommitted >= startingPoolMinor {
            self.safeToSpendTotalMinor = 0
            self.deficitMinor = totalCommitted - startingPoolMinor
            self.isDeficit = totalCommitted > startingPoolMinor
        } else {
            self.safeToSpendTotalMinor = startingPoolMinor - totalCommitted
            self.deficitMinor = 0
            self.isDeficit = false
        }
        
        let remaining = payCycle.daysRemaining(asOf: asOfDate)
        self.daysRemaining = remaining
        self.dailyPaceMinor = remaining > 0 ? (safeToSpendTotalMinor / Int64(remaining)) : 0
        
        let startingFormatted = CurrencyFormatter.format(amountMinor: startingPoolMinor, currencyCode: currency.code)
        let postedFormatted = CurrencyFormatter.format(amountMinor: postedSpendMinor, currencyCode: currency.code)
        let upcomingFormatted = CurrencyFormatter.format(amountMinor: upcomingCommitmentsMinor, currencyCode: currency.code)
        
        self.assumptionsText = "Planning forecast: Starting \(basis.displayName.lowercased()) of \(startingFormatted) minus \(postedFormatted) posted spending and \(upcomingFormatted) in upcoming scheduled bills through \(payCycle.endDateString). Not a bank balance."
    }
    
    public var safeToSpendTodayMinor: Int64 {
        return dailyPaceMinor
    }
    
    public var safeToSpendToday: Money {
        return Money(amountMinor: dailyPaceMinor, currency: currency)
    }
    
    public var daysRemainingInCycle: Int {
        return daysRemaining
    }
    
    public var calculationBasisNote: String {
        return assumptionsText
    }
    
    /// Deterministically computes Safe-to-Spend for a given pay cycle, transactions, and scheduled rules.
    public static func compute(
        payCycle: PayCycle,
        asOfDate: String,
        currency: CurrencyCode,
        basis: SafeToSpendBasis,
        startingPoolMinor: Int64,
        transactions: [Transaction],
        recurringRules: [RecurringRule]
    ) -> SafeToSpendCalculation {
        // 1. Calculate posted net spend in cycle (expenses minus refunds; transfers excluded)
        let relevantTxs = transactions.filter { tx in
            !tx.isDeleted &&
            tx.currencyCode == currency.code &&
            payCycle.contains(dayString: tx.transactionDay)
        }
        
        var totalExp: Int64 = 0
        var totalRef: Int64 = 0
        for tx in relevantTxs {
            if tx.type == .expense {
                totalExp += tx.amountMinor
            } else if tx.type == .refund {
                totalRef += tx.amountMinor
            }
        }
        let postedNet = max(0, totalExp - totalRef)
        
        // 2. Calculate active upcoming commitments due between asOfDate and cycle end
        let upcomingCommitments = recurringRules.filter { rule in
            rule.isActive &&
            rule.type == .expense &&
            rule.currencyCode == currency.code &&
            rule.nextDueDate >= asOfDate &&
            rule.nextDueDate <= payCycle.endDateString
        }
        let upcomingTotal = upcomingCommitments.reduce(Int64(0)) { $0 + $1.amountMinor }
        
        return SafeToSpendCalculation(
            payCycle: payCycle,
            asOfDate: asOfDate,
            currency: currency,
            basis: basis,
            startingPoolMinor: startingPoolMinor,
            postedSpendMinor: postedNet,
            upcomingCommitmentsMinor: upcomingTotal
        )
    }
}
