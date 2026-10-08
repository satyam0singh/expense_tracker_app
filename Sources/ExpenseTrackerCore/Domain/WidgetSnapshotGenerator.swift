import Foundation

/// Pure deterministic generator that builds a `WidgetSnapshot` from domain inputs.
public enum WidgetSnapshotGenerator {
    
    public static func generate(
        userProfile: UserProfile,
        month: CalendarMonth,
        budget: Budget?,
        transactions: [Transaction],
        categories: [Category],
        recurringRules: [RecurringRule],
        asOfDate: Date = Date(),
        isPrivacyRedacted: Bool = false
    ) -> WidgetSnapshot {
        let currency = CurrencyCode.from(code: userProfile.defaultCurrencyCode)
        let activeTxs = transactions.filter { !$0.isDeleted }
        
        // Filter transactions for this calendar month
        let monthTxs = activeTxs.filter { tx in
            tx.transactionDay.hasPrefix(month.yearMonthString)
        }
        
        // Calculate spend: expenses - refunds (transfers strictly excluded)
        var expensesMinor: Int64 = 0
        var refundsMinor: Int64 = 0
        for tx in monthTxs {
            switch tx.type {
            case .expense:
                expensesMinor += tx.amountMinor
            case .refund:
                refundsMinor += tx.amountMinor
            case .income, .transfer:
                break
            }
        }
        let spentMinor = max(0, expensesMinor - refundsMinor)
        
        let limitMinor = budget?.limitMinor ?? userProfile.monthlyBudgetLimitMinor
        let remainingMinor: Int64?
        let isOverBudget: Bool
        let pacePercentage: Double
        let formattedRemaining: String
        let formattedLimit: String
        
        if let limit = limitMinor {
            let diff = limit - spentMinor
            remainingMinor = diff
            isOverBudget = spentMinor > limit
            pacePercentage = limit > 0 ? min(2.0, Double(spentMinor) / Double(limit)) : 1.0
            formattedRemaining = CurrencyFormatter.format(money: Money(amountMinor: diff, currency: currency))
            formattedLimit = CurrencyFormatter.format(money: Money(amountMinor: limit, currency: currency))
        } else {
            remainingMinor = nil
            isOverBudget = false
            pacePercentage = 0.0
            formattedRemaining = "No Budget"
            formattedLimit = "Not Set"
        }
        
        let formattedSpent = CurrencyFormatter.format(money: Money(amountMinor: spentMinor, currency: currency))
        
        // Date formatting for asOfDate
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let todayString = df.string(from: asOfDate)
        
        // Safe to spend calculation
        var hasSafeToSpend = false
        var safeTodayMinor: Int64? = nil
        var safeCycleMinor: Int64? = nil
        var cycleDaysRemaining: Int? = nil
        var formattedSafeToday: String? = nil
        var safeExplanation = "Configured budget limit minus eligible spending."
        
        let pool = limitMinor ?? userProfile.expectedMonthlyIncomeMinor
        if let startingPool = pool, startingPool > 0 {
            let cycle = PayCycle.active(for: todayString, paydayOfMonth: userProfile.payCycleStartDay)
            let sts = SafeToSpendCalculation.compute(
                payCycle: cycle,
                asOfDate: todayString,
                currency: currency,
                basis: limitMinor != nil ? .budgetLimit : .expectedIncome,
                startingPoolMinor: startingPool,
                transactions: activeTxs,
                recurringRules: recurringRules.filter { $0.isActive }
            )
            hasSafeToSpend = true
            safeTodayMinor = sts.safeToSpendTodayMinor
            safeCycleMinor = sts.safeToSpendTotalMinor
            cycleDaysRemaining = sts.daysRemainingInCycle
            formattedSafeToday = CurrencyFormatter.format(money: sts.safeToSpendToday)
            safeExplanation = sts.calculationBasisNote
        }
        
        // Category lookup dictionary
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
        
        // Recent 3 transactions
        let sortedTxs = activeTxs.sorted { lhs, rhs in
            if lhs.transactionDay != rhs.transactionDay {
                return lhs.transactionDay > rhs.transactionDay
            }
            return lhs.createdAt > rhs.createdAt
        }
        
        let recentSnippets: [WidgetTransactionSnippet] = sortedTxs.prefix(3).map { tx in
            let catName: String
            if let catId = tx.categoryId, let name = categoryMap[catId] {
                catName = name
            } else if let snap = tx.categoryNameSnapshot, !snap.isEmpty {
                catName = snap
            } else {
                catName = "Uncategorized"
            }
            
            let signPrefix: String
            switch tx.type {
            case .expense: signPrefix = "-"
            case .income: signPrefix = "+"
            case .refund: signPrefix = "+"
            case .transfer: signPrefix = ""
            }
            
            let moneyStr = CurrencyFormatter.format(money: Money(amountMinor: tx.amountMinor, currency: currency))
            let formattedAmount = "\(signPrefix)\(moneyStr)"
            
            return WidgetTransactionSnippet(
                id: tx.id,
                categoryName: catName,
                amountMinor: tx.amountMinor,
                currencyCode: tx.currencyCode,
                formattedAmount: formattedAmount,
                type: tx.type,
                transactionDay: tx.transactionDay
            )
        }
        
        let snapshot = WidgetSnapshot(
            generatedAt: asOfDate,
            currencyCode: currency.code,
            currentMonthTitle: month.displayTitle(),
            budgetLimitMinor: limitMinor,
            spentMinor: spentMinor,
            remainingMinor: remainingMinor,
            isOverBudget: isOverBudget,
            formattedBudgetRemaining: formattedRemaining,
            formattedSpent: formattedSpent,
            formattedBudgetLimit: formattedLimit,
            budgetPacePercentage: pacePercentage,
            hasSafeToSpend: hasSafeToSpend,
            safeToSpendTodayMinor: safeTodayMinor,
            safeToSpendCycleMinor: safeCycleMinor,
            cycleDaysRemaining: cycleDaysRemaining,
            formattedSafeToSpendToday: formattedSafeToday,
            safeToSpendExplanation: safeExplanation,
            recentTransactions: recentSnippets,
            isPrivacyRedacted: false
        )
        
        return isPrivacyRedacted ? snapshot.redacted() : snapshot
    }
}
