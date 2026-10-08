import Foundation

/// Optional descriptive label for transaction payment method.
/// Invariant: This is a user-assigned label only. It never implies an account balance or bank aggregation.
public enum PaymentMethod: String, CaseIterable, Codable, Sendable {
    case cash = "CASH"
    case upi = "UPI"
    case debitCard = "DEBIT_CARD"
    case creditCard = "CREDIT_CARD"
    case bankTransfer = "BANK_TRANSFER"
    case wallet = "WALLET"
    case other = "OTHER"
    
    public var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .upi: return "UPI"
        case .debitCard: return "Debit Card"
        case .creditCard: return "Credit Card"
        case .bankTransfer: return "Bank Transfer"
        case .wallet: return "Wallet"
        case .other: return "Other"
        }
    }
}

public enum TransactionSource: String, CaseIterable, Codable, Sendable {
    case manual = "MANUAL"
    case voice = "VOICE"
    case importFile = "IMPORT"
    case recurring = "RECURRING"
    case shortcut = "SHORTCUT"
    case widget = "WIDGET"
}
