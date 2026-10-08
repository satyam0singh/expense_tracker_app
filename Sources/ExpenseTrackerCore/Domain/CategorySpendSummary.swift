import Foundation

/// Calculated spending breakdown for a specific category within a calendar month.
public struct CategorySpendSummary: Identifiable, Equatable, Sendable {
    public var id: UUID { categoryId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
    public let categoryId: UUID?
    public let categoryName: String
    public let iconKey: String
    public let netSpend: Money
    public let transactionCount: Int
    /// Proportion of total net spend across all categories (0.0 ... 1.0).
    public let proportionOfTotal: Double
    
    public init(
        categoryId: UUID?,
        categoryName: String,
        iconKey: String,
        netSpend: Money,
        transactionCount: Int,
        proportionOfTotal: Double
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.iconKey = iconKey
        self.netSpend = netSpend
        self.transactionCount = transactionCount
        self.proportionOfTotal = proportionOfTotal
    }
    
    /// Deterministically computes the category breakdown for a month's transactions.
    public static func compute(
        for month: CalendarMonth,
        currency: CurrencyCode,
        transactions: [Transaction],
        categories: [Category]
    ) -> [CategorySpendSummary] {
        // Filter transactions for this month and currency (excluding transfers and deleted)
        let relevant = transactions
            .filter { !$0.isDeleted }
            .filter { $0.currencyCode == currency.code }
            .filter { month.contains(dayString: $0.transactionDay) }
            .filter { $0.type == .expense || $0.type == .refund }
        
        var categoryExpenses: [UUID?: Int64] = [:]
        var categoryRefunds: [UUID?: Int64] = [:]
        var categoryCounts: [UUID?: Int] = [:]
        
        for tx in relevant {
            if tx.type == .expense {
                categoryExpenses[tx.categoryId, default: 0] += tx.amountMinor
                categoryCounts[tx.categoryId, default: 0] += 1
            } else if tx.type == .refund {
                categoryRefunds[tx.categoryId, default: 0] += tx.amountMinor
                categoryCounts[tx.categoryId, default: 0] += 1
            }
        }
        
        // Compute net spend per category
        let allCategoryIds = Set(categoryExpenses.keys).union(categoryRefunds.keys)
        var totalNetSpendMinor: Int64 = 0
        var netSpends: [(id: UUID?, net: Int64, count: Int)] = []
        
        for catId in allCategoryIds {
            let exp = categoryExpenses[catId] ?? 0
            let ref = categoryRefunds[catId] ?? 0
            let net = max(0, exp - ref)
            let count = categoryCounts[catId] ?? 0
            netSpends.append((catId, net, count))
            totalNetSpendMinor += net
        }
        
        return netSpends.compactMap { item in
            guard item.net > 0 || item.count > 0 else { return nil }
            let cat = categories.first { $0.id == item.id }
            let name = cat?.name ?? (item.id == nil ? "Uncategorized" : "Other")
            let icon = cat?.iconKey ?? "tag"
            let proportion = totalNetSpendMinor > 0 ? Double(item.net) / Double(totalNetSpendMinor) : 0.0
            
            return CategorySpendSummary(
                categoryId: item.id,
                categoryName: name,
                iconKey: icon,
                netSpend: Money(amountMinor: item.net, currency: currency),
                transactionCount: item.count,
                proportionOfTotal: proportion
            )
        }
        .sorted { $0.netSpend.amountMinor > $1.netSpend.amountMinor }
    }
}
