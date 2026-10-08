import XCTest
@testable import ExpenseTrackerCore

final class TrendsCalculationTests: XCTestCase {
    
    func testMonthOverMonthComparisonTotals() {
        let currency = CurrencyCode.inr
        let currentMonth = CalendarMonth(year: 2026, month: 10)
        let prevMonth = CalendarMonth(year: 2026, month: 9)
        
        let catFood = Category(name: "Food", iconName: "fork.knife", colorHex: "#FF9500", type: .expense)
        
        // October transactions: 500.00 expense, 50.00 refund -> net 450.00 (45000 minor)
        let txOct1 = Transaction(type: .expense, amountMinor: 50000, currencyCode: "INR", categoryId: catFood.id, transactionDay: "2026-10-05")
        let txOctRefund = Transaction(type: .refund, amountMinor: 5000, currencyCode: "INR", categoryId: catFood.id, transactionDay: "2026-10-06")
        
        // September transactions: 600.00 expense -> net 600.00 (60000 minor)
        let txSep1 = Transaction(type: .expense, amountMinor: 60000, currencyCode: "INR", categoryId: catFood.id, transactionDay: "2026-09-15")
        
        let trends = TrendsSummary.compute(
            currentMonth: currentMonth,
            currency: currency,
            currentMonthTransactions: [txOct1, txOctRefund],
            previousMonthTransactions: [txSep1],
            categories: [catFood]
        )
        
        XCTAssertEqual(trends.currentMonthNetSpendMinor, 45000)
        XCTAssertEqual(trends.previousMonthNetSpendMinor, 60000)
        XCTAssertEqual(trends.overallDeltaMinor, -15000)
        XCTAssertEqual(trends.overallDirection, .decreased)
        XCTAssertEqual(trends.overallPercentageChange, -25.0)
        XCTAssertTrue(trends.calculationBasisText.contains("Factual net expenditure"))
    }
    
    func testCategoryTrendsDeltasAndNewSpend() {
        let currency = CurrencyCode.inr
        let currentMonth = CalendarMonth(year: 2026, month: 10)
        
        let catA = Category(name: "Groceries", iconName: "cart", colorHex: "#34C759", type: .expense)
        let catB = Category(name: "Dining", iconName: "fork.knife", colorHex: "#FF9500", type: .expense)
        let catC = Category(name: "Travel", iconName: "airplane", colorHex: "#007AFF", type: .expense)
        
        // October: Groceries 300, Dining 150, Travel 50
        let octTxs = [
            Transaction(type: .expense, amountMinor: 30000, currencyCode: "INR", categoryId: catA.id, transactionDay: "2026-10-02"),
            Transaction(type: .expense, amountMinor: 15000, currencyCode: "INR", categoryId: catB.id, transactionDay: "2026-10-05"),
            Transaction(type: .expense, amountMinor: 5000, currencyCode: "INR", categoryId: catC.id, transactionDay: "2026-10-08")
        ]
        
        // September: Groceries 200, Dining 400, Travel 0
        let sepTxs = [
            Transaction(type: .expense, amountMinor: 20000, currencyCode: "INR", categoryId: catA.id, transactionDay: "2026-09-10"),
            Transaction(type: .expense, amountMinor: 40000, currencyCode: "INR", categoryId: catB.id, transactionDay: "2026-09-12")
        ]
        
        let trends = TrendsSummary.compute(
            currentMonth: currentMonth,
            currency: currency,
            currentMonthTransactions: octTxs,
            previousMonthTransactions: sepTxs,
            categories: [catA, catB, catC]
        )
        
        // Groceries: 30000 vs 20000 -> +10000 (+50%)
        let grocTrend = trends.categoryTrends.first { $0.categoryId == catA.id }
        XCTAssertNotNil(grocTrend)
        XCTAssertEqual(grocTrend?.deltaMinor, 10000)
        XCTAssertEqual(grocTrend?.direction, .increased)
        XCTAssertEqual(grocTrend?.percentageChange, 50.0)
        
        // Dining: 15000 vs 40000 -> -25000 (-62.5%)
        let dinTrend = trends.categoryTrends.first { $0.categoryId == catB.id }
        XCTAssertNotNil(dinTrend)
        XCTAssertEqual(dinTrend?.deltaMinor, -25000)
        XCTAssertEqual(dinTrend?.direction, .decreased)
        XCTAssertEqual(dinTrend?.percentageChange, -62.5)
        
        // Travel: 5000 vs 0 -> +5000 (newSpend)
        let travTrend = trends.categoryTrends.first { $0.categoryId == catC.id }
        XCTAssertNotNil(travTrend)
        XCTAssertEqual(travTrend?.deltaMinor, 5000)
        XCTAssertEqual(travTrend?.direction, .newSpend)
        XCTAssertNil(travTrend?.percentageChange)
    }
    
    func testTransfersAndDeletedAreExcluded() {
        let currency = CurrencyCode.inr
        let currentMonth = CalendarMonth(year: 2026, month: 10)
        
        let cat = Category(name: "General", iconName: "tag", colorHex: "#8E8E93", type: .expense)
        
        var deletedTx = Transaction(type: .expense, amountMinor: 10000, currencyCode: "INR", categoryId: cat.id, transactionDay: "2026-10-01")
        deletedTx.deletedAt = Date()
        
        let transferTx = Transaction(type: .transfer, amountMinor: 500000, currencyCode: "INR", transactionDay: "2026-10-02")
        let activeExpense = Transaction(type: .expense, amountMinor: 2500, currencyCode: "INR", categoryId: cat.id, transactionDay: "2026-10-03")
        
        let trends = TrendsSummary.compute(
            currentMonth: currentMonth,
            currency: currency,
            currentMonthTransactions: [deletedTx, transferTx, activeExpense],
            previousMonthTransactions: [],
            categories: [cat]
        )
        
        XCTAssertEqual(trends.currentMonthNetSpendMinor, 2500)
    }
    
    func testWeeklyBucketsDistribution() {
        let currency = CurrencyCode.inr
        let currentMonth = CalendarMonth(year: 2026, month: 10) // 31 days
        
        let txW1 = Transaction(type: .expense, amountMinor: 12000, currencyCode: "INR", transactionDay: "2026-10-03")
        let txW2 = Transaction(type: .expense, amountMinor: 18000, currencyCode: "INR", transactionDay: "2026-10-10")
        let txW4 = Transaction(type: .expense, amountMinor: 22000, currencyCode: "INR", transactionDay: "2026-10-25")
        
        let trends = TrendsSummary.compute(
            currentMonth: currentMonth,
            currency: currency,
            currentMonthTransactions: [txW1, txW2, txW4],
            previousMonthTransactions: [],
            categories: []
        )
        
        XCTAssertEqual(trends.weeklyBuckets.count, 5)
        XCTAssertEqual(trends.weeklyBuckets[0].netSpendMinor, 12000)
        XCTAssertEqual(trends.weeklyBuckets[0].transactionCount, 1)
        XCTAssertEqual(trends.weeklyBuckets[1].netSpendMinor, 18000)
        XCTAssertEqual(trends.weeklyBuckets[1].transactionCount, 1)
        XCTAssertEqual(trends.weeklyBuckets[2].netSpendMinor, 0)
        XCTAssertEqual(trends.weeklyBuckets[2].transactionCount, 0)
        XCTAssertEqual(trends.weeklyBuckets[3].netSpendMinor, 22000)
        XCTAssertEqual(trends.weeklyBuckets[3].transactionCount, 1)
    }
}
