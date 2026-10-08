import Foundation

/// Domain error associated with monetary operations.
public enum MoneyError: Error, Equatable, Sendable {
    case currencyMismatch(expected: String, actual: String)
    case negativeAmountNotAllowed(Int64)
}

/// Represents an amount of money in minor currency units (e.g., paise for INR, cents for USD).
/// Non-negotiable invariant: NEVER use Float or Double for money calculations.
public struct Money: Equatable, Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    /// Amount stored in integer minor units (e.g. 100 paise = 1 INR).
    /// Can be negative for net balance or budget difference calculations.
    public let amountMinor: Int64
    
    /// The currency of this money instance.
    public let currency: CurrencyCode
    
    public init(amountMinor: Int64, currency: CurrencyCode = .inr) {
        self.amountMinor = amountMinor
        self.currency = currency
    }
    
    public static func zero(currency: CurrencyCode = .inr) -> Money {
        return Money(amountMinor: 0, currency: currency)
    }
    
    public var isZero: Bool {
        return amountMinor == 0
    }
    
    public var isPositive: Bool {
        return amountMinor > 0
    }
    
    public var isNegative: Bool {
        return amountMinor < 0
    }
    
    public var description: String {
        return "\(currency.code) \(amountMinor) [minor units]"
    }
    
    // MARK: - Safe Arithmetic Operations
    
    public static func + (lhs: Money, rhs: Money) throws -> Money {
        guard lhs.currency == rhs.currency else {
            throw MoneyError.currencyMismatch(expected: lhs.currency.code, actual: rhs.currency.code)
        }
        return Money(amountMinor: lhs.amountMinor + rhs.amountMinor, currency: lhs.currency)
    }
    
    public static func - (lhs: Money, rhs: Money) throws -> Money {
        guard lhs.currency == rhs.currency else {
            throw MoneyError.currencyMismatch(expected: lhs.currency.code, actual: rhs.currency.code)
        }
        return Money(amountMinor: lhs.amountMinor - rhs.amountMinor, currency: lhs.currency)
    }
    
    public static prefix func - (money: Money) -> Money {
        return Money(amountMinor: -money.amountMinor, currency: money.currency)
    }
    
    // MARK: - Comparable
    
    public static func < (lhs: Money, rhs: Money) -> Bool {
        precondition(lhs.currency == rhs.currency, "Cannot compare Money with different currencies (\(lhs.currency.code) vs \(rhs.currency.code))")
        return lhs.amountMinor < rhs.amountMinor
    }
}
