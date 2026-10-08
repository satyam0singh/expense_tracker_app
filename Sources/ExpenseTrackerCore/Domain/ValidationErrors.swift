import Foundation

/// Errors that can occur when validating domain input.
public enum ValidationError: Error, Equatable, Sendable, LocalizedError {
    case zeroOrNegativeAmount(Int64)
    case invalidCurrencyCode(String)
    case invalidDateFormat(String)
    case missingRequiredField(String)
    
    public var errorDescription: String? {
        switch self {
        case .zeroOrNegativeAmount(let amount):
            return "Amount must be strictly greater than zero (received \(amount))."
        case .invalidCurrencyCode(let code):
            return "Invalid currency code: '\(code)'. Must be a 3-letter ISO code."
        case .invalidDateFormat(let date):
            return "Invalid calendar date format: '\(date)'. Expected format is YYYY-MM-DD."
        case .missingRequiredField(let field):
            return "Required field missing: \(field)."
        }
    }
}
