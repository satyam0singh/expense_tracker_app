import Foundation

/// Trend direction representing change in expenditure compared to a prior period.
public enum TrendDirection: String, Sendable, Equatable {
    case increased
    case decreased
    case unchanged
    case newSpend
    
    public var label: String {
        switch self {
        case .increased: return "Higher"
        case .decreased: return "Lower"
        case .unchanged: return "Same"
        case .newSpend: return "New Category"
        }
    }
}

/// Factual category spend comparison between current and previous calendar periods.
public struct CategoryTrendItem: Identifiable, Equatable, Sendable {
    public var id: UUID { categoryId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
    public let categoryId: UUID?
    public let categoryName: String
    public let iconKey: String
    public let currentMonthSpendMinor: Int64
    public let previousMonthSpendMinor: Int64
    public let deltaMinor: Int64 // current - previous
    public let percentageChange: Double?
    public let direction: TrendDirection
    
    public init(
        categoryId: UUID?,
        categoryName: String,
        iconKey: String,
        currentMonthSpendMinor: Int64,
        previousMonthSpendMinor: Int64
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.iconKey = iconKey
        self.currentMonthSpendMinor = currentMonthSpendMinor
        self.previousMonthSpendMinor = previousMonthSpendMinor
        self.deltaMinor = currentMonthSpendMinor - previousMonthSpendMinor
        
        if previousMonthSpendMinor > 0 {
            self.percentageChange = (Double(currentMonthSpendMinor - previousMonthSpendMinor) / Double(previousMonthSpendMinor)) * 100.0
            if currentMonthSpendMinor > previousMonthSpendMinor {
                self.direction = .increased
            } else if currentMonthSpendMinor < previousMonthSpendMinor {
                self.direction = .decreased
            } else {
                self.direction = .unchanged
            }
        } else if currentMonthSpendMinor > 0 {
            self.percentageChange = nil
            self.direction = .newSpend
        } else {
            self.percentageChange = 0.0
            self.direction = .unchanged
        }
    }
}

/// Weekly expenditure bucket within a month (e.g. Days 1-7, 8-14, etc.).
public struct WeeklySpendBucket: Identifiable, Equatable, Sendable {
    public var id: Int { weekNumber }
    public let weekNumber: Int
    public let dateRangeLabel: String
    public let netSpendMinor: Int64
    public let transactionCount: Int
    
    public init(
        weekNumber: Int,
        dateRangeLabel: String,
        netSpendMinor: Int64,
        transactionCount: Int
    ) {
        self.weekNumber = weekNumber
        self.dateRangeLabel = dateRangeLabel
        self.netSpendMinor = netSpendMinor
        self.transactionCount = transactionCount
    }
}

/// Month-over-month trends and factual spending comparisons.
/// Invariants per docs/00_PRODUCT_BRAIN.md and US-077:
/// - Factual comparisons only; never claim to know account balances or predict unverifiable forecasts.
/// - Net spend = eligible expenses minus refunds; transfers are strictly excluded.
/// - Clearly discloses calculation basis.
public struct TrendsSummary: Equatable, Sendable {
    public let currentMonth: CalendarMonth
    public let previousMonth: CalendarMonth
    public let currency: CurrencyCode
    public let currentMonthNetSpendMinor: Int64
    public let previousMonthNetSpendMinor: Int64
    public let overallDeltaMinor: Int64 // current - previous
    public let overallPercentageChange: Double?
    public let overallDirection: TrendDirection
    public let categoryTrends: [CategoryTrendItem]
    public let weeklyBuckets: [WeeklySpendBucket]
    public let calculationBasisText: String
    
    public init(
        currentMonth: CalendarMonth,
        previousMonth: CalendarMonth,
        currency: CurrencyCode,
        currentMonthNetSpendMinor: Int64,
        previousMonthNetSpendMinor: Int64,
        categoryTrends: [CategoryTrendItem],
        weeklyBuckets: [WeeklySpendBucket]
    ) {
        self.currentMonth = currentMonth
        self.previousMonth = previousMonth
        self.currency = currency
        self.currentMonthNetSpendMinor = currentMonthNetSpendMinor
        self.previousMonthNetSpendMinor = previousMonthNetSpendMinor
        self.overallDeltaMinor = currentMonthNetSpendMinor - previousMonthNetSpendMinor
        
        if previousMonthNetSpendMinor > 0 {
            self.overallPercentageChange = (Double(currentMonthNetSpendMinor - previousMonthNetSpendMinor) / Double(previousMonthNetSpendMinor)) * 100.0
            if currentMonthNetSpendMinor > previousMonthNetSpendMinor {
                self.overallDirection = .increased
            } else if currentMonthNetSpendMinor < previousMonthNetSpendMinor {
                self.overallDirection = .decreased
            } else {
                self.overallDirection = .unchanged
            }
        } else if currentMonthNetSpendMinor > 0 {
            self.overallPercentageChange = nil
            self.overallDirection = .newSpend
        } else {
            self.overallPercentageChange = 0.0
            self.overallDirection = .unchanged
        }
        
        self.categoryTrends = categoryTrends
        self.weeklyBuckets = weeklyBuckets
        self.calculationBasisText = "Factual net expenditure (eligible expenses minus refunds; transfers excluded) in \(currentMonth.displayTitle()) compared against \(previousMonth.displayTitle()). Transformed locally on device without external sync."
    }
    
    /// Deterministically computes trends comparing currentMonth vs its immediately preceding month.
    public static func compute(
        currentMonth: CalendarMonth,
        currency: CurrencyCode,
        currentMonthTransactions: [Transaction],
        previousMonthTransactions: [Transaction],
        categories: [Category]
    ) -> TrendsSummary {
        let prevMonth = currentMonth.previous()
        
        // 1. Compute Category breakdowns for each month
        let currentCatSummaries = CategorySpendSummary.compute(
            for: currentMonth,
            currency: currency,
            transactions: currentMonthTransactions,
            categories: categories
        )
        let prevCatSummaries = CategorySpendSummary.compute(
            for: prevMonth,
            currency: currency,
            transactions: previousMonthTransactions,
            categories: categories
        )
        
        let currentNetTotal = currentCatSummaries.reduce(Int64(0)) { $0 + $1.netSpend.amountMinor }
        let prevNetTotal = prevCatSummaries.reduce(Int64(0)) { $0 + $1.netSpend.amountMinor }
        
        var currentMap: [UUID?: (net: Int64, name: String, icon: String)] = [:]
        for c in currentCatSummaries {
            currentMap[c.categoryId] = (c.netSpend.amountMinor, c.categoryName, c.iconKey)
        }
        
        var prevMap: [UUID?: (net: Int64, name: String, icon: String)] = [:]
        for p in prevCatSummaries {
            prevMap[p.categoryId] = (p.netSpend.amountMinor, p.categoryName, p.iconKey)
        }
        
        let allCategoryIds = Set(currentMap.keys).union(prevMap.keys)
        var trendItems: [CategoryTrendItem] = []
        
        for catId in allCategoryIds {
            let currentInfo = currentMap[catId]
            let prevInfo = prevMap[catId]
            
            let name = currentInfo?.name ?? prevInfo?.name ?? "Other"
            let icon = currentInfo?.icon ?? prevInfo?.icon ?? "tag"
            let curSpend = currentInfo?.net ?? 0
            let prevSpend = prevInfo?.net ?? 0
            
            let item = CategoryTrendItem(
                categoryId: catId,
                categoryName: name,
                iconKey: icon,
                currentMonthSpendMinor: curSpend,
                previousMonthSpendMinor: prevSpend
            )
            trendItems.append(item)
        }
        
        // Sort category trends by current spend descending
        trendItems.sort { $0.currentMonthSpendMinor > $1.currentMonthSpendMinor }
        
        // 2. Compute 7-day Weekly Buckets for Current Month
        let relevantCurrent = currentMonthTransactions
            .filter { !$0.isDeleted && $0.currencyCode == currency.code && currentMonth.contains(dayString: $0.transactionDay) }
            .filter { $0.type == .expense || $0.type == .refund }
        
        let daysInMonth = currentMonth.numberOfDays
        let bucketDefinitions: [(week: Int, start: Int, end: Int)] = [
            (1, 1, min(7, daysInMonth)),
            (2, 8, min(14, daysInMonth)),
            (3, 15, min(21, daysInMonth)),
            (4, 22, min(28, daysInMonth)),
            (5, 29, daysInMonth)
        ]
        
        var weeklyBuckets: [WeeklySpendBucket] = []
        for def in bucketDefinitions where def.start <= daysInMonth {
            let label = "\(currentMonth.shortMonthName()) \(def.start) - \(def.end)"
            
            var weekExp: Int64 = 0
            var weekRef: Int64 = 0
            var weekCount = 0
            
            for tx in relevantCurrent {
                let parts = tx.transactionDay.split(separator: "-")
                if parts.count == 3, let day = Int(parts[2]), day >= def.start && day <= def.end {
                    if tx.type == .expense {
                        weekExp += tx.amountMinor
                        weekCount += 1
                    } else if tx.type == .refund {
                        weekRef += tx.amountMinor
                        weekCount += 1
                    }
                }
            }
            
            let net = max(0, weekExp - weekRef)
            weeklyBuckets.append(WeeklySpendBucket(
                weekNumber: def.week,
                dateRangeLabel: label,
                netSpendMinor: net,
                transactionCount: weekCount
            ))
        }
        
        return TrendsSummary(
            currentMonth: currentMonth,
            previousMonth: prevMonth,
            currency: currency,
            currentMonthNetSpendMinor: currentNetTotal,
            previousMonthNetSpendMinor: prevNetTotal,
            categoryTrends: trendItems,
            weeklyBuckets: weeklyBuckets
        )
    }
}

private extension CalendarMonth {
    func shortMonthName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.shortMonthSymbols[month - 1]
    }
}
