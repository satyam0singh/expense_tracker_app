import Foundation

/// Formats integer minor units into display strings without using Float or Double.
public enum CurrencyFormatter {
    
    /// Formats a `Money` value into a user-facing currency string (e.g. ₹1,234.50 or -₹50.00).
    /// Uses integer division and modulo or Decimal formatting to avoid floating-point errors.
    public static func format(
        money: Money,
        locale: Locale = Locale(identifier: "en_IN"),
        includeSymbol: Bool = true
    ) -> String {
        let isNegative = money.amountMinor < 0
        let absAmount = abs(money.amountMinor)
        let exponent = money.currency.minorUnitExponent
        
        let majorUnits: Int64
        let minorUnits: Int64
        
        if exponent == 0 {
            majorUnits = absAmount
            minorUnits = 0
        } else {
            let divisor = Int64(powerOfTen(exponent))
            majorUnits = absAmount / divisor
            minorUnits = absAmount % divisor
        }
        
        // Group major units using locale grouping
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = locale.groupingSeparator ?? ","
        
        let formattedMajor = numberFormatter.string(from: NSNumber(value: majorUnits)) ?? "\(majorUnits)"
        
        let formattedNumber: String
        if exponent > 0 {
            let minorString = String(format: "%0*d", exponent, Int(minorUnits))
            let decimalSeparator = locale.decimalSeparator ?? "."
            formattedNumber = "\(formattedMajor)\(decimalSeparator)\(minorString)"
        } else {
            formattedNumber = formattedMajor
        }
        
        let prefix = isNegative ? "-" : ""
        if includeSymbol {
            return "\(prefix)\(money.currency.symbol)\(formattedNumber)"
        } else {
            return "\(prefix)\(formattedNumber)"
        }
    }
    
    /// Formats integer minor units and currency code into a display string.
    public static func format(
        amountMinor: Int64,
        currencyCode: String,
        locale: Locale = Locale(identifier: "en_IN"),
        includeSymbol: Bool = true
    ) -> String {
        let currency = CurrencyCode.from(code: currencyCode)
        let money = Money(amountMinor: amountMinor, currency: currency)
        return format(money: money, locale: locale, includeSymbol: includeSymbol)
    }
    
    public static func powerOfTen(_ n: Int) -> Int {
        var res = 1
        for _ in 0..<n {
            res *= 10
        }
        return res
    }
}
