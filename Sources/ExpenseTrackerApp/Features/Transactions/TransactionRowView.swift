import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

public struct TransactionRowView: View {
    public let transaction: Transaction
    public let categories: [Category]
    
    public init(transaction: Transaction, categories: [Category] = []) {
        self.transaction = transaction
        self.categories = categories
    }
    
    private var category: Category? {
        categories.first { $0.id == transaction.categoryId }
    }
    
    private var categoryName: String {
        transaction.categoryNameSnapshot ?? category?.name ?? "Uncategorized"
    }
    
    private var iconKey: String {
        category?.iconKey ?? "tag"
    }
    
    private var money: Money {
        Money(amountMinor: transaction.amountMinor, currency: CurrencyCode.from(code: transaction.currencyCode))
    }
    
    private var amountString: String {
        let formatted = CurrencyFormatter.format(money: money)
        switch transaction.type {
        case .income:
            return "+\(formatted)"
        case .expense:
            return "-\(formatted)"
        case .refund:
            return "+\(formatted) [Refund]"
        case .transfer:
            return "\(formatted) [Transfer]"
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .primary
        case .refund: return .blue
        case .transfer: return .secondary
        }
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Category Icon
            Image(systemName: iconKey)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            // Details: Title/Merchant, Note, and Payment Method
            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let merchant = transaction.merchant, !merchant.isEmpty, transaction.merchant != categoryName {
                        Text(categoryName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let paymentMethod = transaction.paymentMethod {
                        Text(paymentMethod.displayName)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(4)
                    }
                    
                    if let note = transaction.note, !note.isEmpty {
                        Text("• \(note)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            Text(amountString)
                .font(.body.weight(.semibold))
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(categoryName), \(titleText), \(amountString), on \(transaction.transactionDay)")
    }
    
    private var titleText: String {
        if let merchant = transaction.merchant, !merchant.isEmpty {
            return merchant
        }
        return categoryName
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .orange
        case .refund: return .blue
        case .transfer: return .purple
        }
    }
}
