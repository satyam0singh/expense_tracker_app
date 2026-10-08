import Foundation

/// ISO 4217 Currency representation with minor unit exponent.
/// Invariant: All money amounts are stored in minor currency units (e.g. paise for INR, cents for USD).
public struct CurrencyCode: Hashable, Equatable, Sendable, Codable, CustomStringConvertible {
    public let code: String
    public let symbol: String
    public let minorUnitExponent: Int
    
    public init(code: String, symbol: String, minorUnitExponent: Int) {
        self.code = code.uppercased()
        self.symbol = symbol
        self.minorUnitExponent = minorUnitExponent
    }
    
    public var description: String {
        return code
    }
    
    /// Multiplier factor from major units to minor units (e.g. 100 for 2 decimal places, 1 for 0).
    public var minorUnitsFactor: Int {
        var res = 1
        for _ in 0..<minorUnitExponent {
            res *= 10
        }
        return res
    }
    
    // Default currency: Indian Rupee (INR) per docs/00_PRODUCT_BRAIN.md and ADR-003
    public static let inr = CurrencyCode(code: "INR", symbol: "₹", minorUnitExponent: 2)
    public static let usd = CurrencyCode(code: "USD", symbol: "$", minorUnitExponent: 2)
    public static let eur = CurrencyCode(code: "EUR", symbol: "€", minorUnitExponent: 2)
    public static let gbp = CurrencyCode(code: "GBP", symbol: "£", minorUnitExponent: 2)
    public static let jpy = CurrencyCode(code: "JPY", symbol: "¥", minorUnitExponent: 0)
    
    /// Look up or construct a currency code with default minorUnitExponent of 2 if unknown.
    public static func from(code: String) -> CurrencyCode {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch clean {
        case "INR": return .inr
        case "USD": return .usd
        case "EUR": return .eur
        case "GBP": return .gbp
        case "JPY": return .jpy
        default:
            return CurrencyCode(code: clean, symbol: clean, minorUnitExponent: 2)
        }
    }
}
