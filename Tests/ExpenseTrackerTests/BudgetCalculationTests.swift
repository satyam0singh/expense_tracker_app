import XCTest
#if canImport(ExpenseTrackerCore)
@testable import ExpenseTrackerCore
#elseif canImport(ExpenseTracker)
@testable import ExpenseTracker
#endif

final class BudgetCalculationTests: XCTestCase {
    
    let targetMonth = CalendarMonth(year: 2026, month: 10)
    let inr = CurrencyCode.inr
    
    func testWithinBudgetCalculation() {
        let transactions: [Transaction] = [
            Transaction(type: .income, amountMinor: 5000000, transactionDay: "2026-10-05"), // ₹50,000 income
            Transaction(type: .expense, amountMinor: 1500000, transactionDay: "2026-10-08"), // ₹15,000 expense
            Transaction(type: .expense, amountMinor: 500000, transactionDay: "2026-10-12")   // ₹5,000 expense
        ]
        
        let summary = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: 3000000, // ₹30,000 budget
            transactions: transactions
        )
        
        XCTAssertEqual(summary.recordedIncome.amountMinor, 5000000)
        XCTAssertEqual(summary.recordedExpenses.amountMinor, 2000000)
        XCTAssertEqual(summary.actualNet.amountMinor, 3000000) // ₹30,000 net cash flow
        XCTAssertEqual(summary.netBudgetSpend.amountMinor, 2000000)
        XCTAssertEqual(summary.budgetRemaining?.amountMinor, 1000000) // ₹10,000 remaining
        XCTAssertFalse(summary.isOverBudget)
        
        if let percent = summary.budgetUsedPercent {
            XCTAssertEqual(round(percent * 100) / 100, 66.67, accuracy: 0.01)
        } else {
            XCTFail("Expected budgetUsedPercent to be calculated")
        }
    }
    
    func testOverBudgetIsNotClamped() {
        let transactions: [Transaction] = [
            Transaction(type: .expense, amountMinor: 1200000, transactionDay: "2026-10-10") // ₹12,000 expense
        ]
        
        let summary = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: 1000000, // ₹10,000 budget
            transactions: transactions
        )
        
        XCTAssertEqual(summary.recordedExpenses.amountMinor, 1200000)
        XCTAssertEqual(summary.netBudgetSpend.amountMinor, 1200000)
        // Invariant: budgetRemaining is NOT clamped to 0 when over budget
        XCTAssertEqual(summary.budgetRemaining?.amountMinor, -200000) // -₹2,000
        XCTAssertTrue(summary.isOverBudget)
        XCTAssertEqual(summary.budgetUsedPercent, 120.0)
    }
    
    func testZeroBudgetCase() {
        let transactions: [Transaction] = [
            Transaction(type: .expense, amountMinor: 50000, transactionDay: "2026-10-02") // ₹500 expense
        ]
        
        let summary = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: 0, // ₹0 budget configured
            transactions: transactions
        )
        
        XCTAssertEqual(summary.budgetRemaining?.amountMinor, -50000)
        XCTAssertTrue(summary.isOverBudget)
        // Zero division protection: percent should be nil
        XCTAssertNil(summary.budgetUsedPercent)
    }
    
    func testNoBudgetConfigured() {
        let transactions: [Transaction] = [
            Transaction(type: .expense, amountMinor: 250000, transactionDay: "2026-10-14")
        ]
        
        let summary = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: nil, // No budget set
            transactions: transactions
        )
        
        XCTAssertEqual(summary.recordedExpenses.amountMinor, 250000)
        XCTAssertNil(summary.budgetLimit)
        XCTAssertNil(summary.budgetRemaining)
        XCTAssertNil(summary.budgetUsedPercent)
        XCTAssertFalse(summary.isOverBudget)
    }
    
    func testTransfersExcludedFromSpendingAndIncome() {
        let transactions: [Transaction] = [
            Transaction(type: .expense, amountMinor: 100000, transactionDay: "2026-10-01"), // ₹1,000
            Transaction(type: .income, amountMinor: 500000, transactionDay: "2026-10-01"),  // ₹5,000
            // Transfer: e.g. ATM withdrawal or card payment - must not inflate totals
            Transaction(type: .transfer, amountMinor: 2000000, transactionDay: "2026-10-02") // ₹20,000
        ]
        
        let summary = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: 200000,
            transactions: transactions
        )
        
        XCTAssertEqual(summary.recordedExpenses.amountMinor, 100000)
        XCTAssertEqual(summary.recordedIncome.amountMinor, 500000)
        XCTAssertEqual(summary.netBudgetSpend.amountMinor, 100000)
        XCTAssertEqual(summary.actualNet.amountMinor, 400000)
    }
    
    func testRefundsOffsetExpenseSpend() {
        let transactions: [Transaction] = [
            Transaction(type: .expense, amountMinor: 800000, transactionDay: "2026-10-05"), // ₹8,000 spend
            Transaction(type: .refund, amountMinor: 200000, transactionDay: "2026-10-09")   // ₹2,000 refund
        ]
        
        let summary = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: 1000000, // ₹10,000 limit
            transactions: transactions
        )
        
        XCTAssertEqual(summary.recordedExpenses.amountMinor, 800000)
        XCTAssertEqual(summary.recordedRefunds.amountMinor, 200000)
        // netBudgetSpend = 8,000 - 2,000 = 6,000
        XCTAssertEqual(summary.netBudgetSpend.amountMinor, 600000)
        // budgetRemaining = 10,000 - 6,000 = 4,000
        XCTAssertEqual(summary.budgetRemaining?.amountMinor, 400000)
        // actualNet = income(0) + refund(2000) - expense(8000) = -6,000
        XCTAssertEqual(summary.actualNet.amountMinor, -600000)
    }
    
    func testSoftDeletedTransactionsIgnored() {
        var deletedTx = Transaction(type: .expense, amountMinor: 500000, transactionDay: "2026-10-10")
        deletedTx.deletedAt = Date()
        
        let activeTx = Transaction(type: .expense, amountMinor: 200000, transactionDay: "2026-10-11")
        
        let summary = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: 500000,
            transactions: [deletedTx, activeTx]
        )
        
        XCTAssertEqual(summary.recordedExpenses.amountMinor, 200000)
        XCTAssertEqual(summary.netBudgetSpend.amountMinor, 200000)
        XCTAssertEqual(summary.budgetRemaining?.amountMinor, 300000)
    }
    
    func testOutSidePeriodIgnored() {
        let sepTx = Transaction(type: .expense, amountMinor: 500000, transactionDay: "2026-09-30")
        let octTx = Transaction(type: .expense, amountMinor: 200000, transactionDay: "2026-10-01")
        let novTx = Transaction(type: .expense, amountMinor: 700000, transactionDay: "2026-11-01")
        
        let summary = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: 500000,
            transactions: [sepTx, octTx, novTx]
        )
        
        XCTAssertEqual(summary.recordedExpenses.amountMinor, 200000)
    }
}
