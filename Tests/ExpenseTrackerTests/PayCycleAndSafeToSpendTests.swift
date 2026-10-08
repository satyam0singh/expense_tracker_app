import XCTest
#if canImport(ExpenseTrackerCore)
@testable import ExpenseTrackerCore
#elseif canImport(ExpenseTracker)
@testable import ExpenseTracker
#endif

final class PayCycleAndSafeToSpendTests: XCTestCase {
    
    // MARK: - PayCycle Bounds Tests
    
    func testCalendarMonthPayCycleBounds() {
        let cycle = PayCycle.active(for: "2026-10-08", paydayOfMonth: 1)
        XCTAssertEqual(cycle.startDayOfMonth, 1)
        XCTAssertEqual(cycle.startDateString, "2026-10-01")
        XCTAssertEqual(cycle.endDateString, "2026-10-31")
        XCTAssertEqual(cycle.totalDays, 31)
        XCTAssertTrue(cycle.contains(dayString: "2026-10-15"))
        XCTAssertFalse(cycle.contains(dayString: "2026-11-01"))
    }
    
    func testCustomPayCycleDay25Bounds() {
        // Reference date before payday (Oct 8 < Oct 25) -> cycle started Sep 25, ends Oct 24
        let cycleBeforePayday = PayCycle.active(for: "2026-10-08", paydayOfMonth: 25)
        XCTAssertEqual(cycleBeforePayday.startDayOfMonth, 25)
        XCTAssertEqual(cycleBeforePayday.startDateString, "2026-09-25")
        XCTAssertEqual(cycleBeforePayday.endDateString, "2026-10-24")
        XCTAssertEqual(cycleBeforePayday.totalDays, 30) // 6 days in Sep (25-30) + 24 days in Oct (1-24)
        
        // Reference date on or after payday (Oct 26 >= Oct 25) -> cycle started Oct 25, ends Nov 24
        let cycleAfterPayday = PayCycle.active(for: "2026-10-26", paydayOfMonth: 25)
        XCTAssertEqual(cycleAfterPayday.startDateString, "2026-10-25")
        XCTAssertEqual(cycleAfterPayday.endDateString, "2026-11-24")
    }
    
    func testDaysRemainingCalculation() {
        let cycle = PayCycle(
            startDayOfMonth: 25,
            startDateString: "2026-09-25",
            endDateString: "2026-10-24",
            totalDays: 30
        )
        
        // Oct 15 to Oct 24 inclusive: 10 days
        let remaining = cycle.daysRemaining(asOf: "2026-10-15")
        XCTAssertEqual(remaining, 10)
        
        // On end date: 1 day
        XCTAssertEqual(cycle.daysRemaining(asOf: "2026-10-24"), 1)
        
        // After cycle ended: 0 days
        XCTAssertEqual(cycle.daysRemaining(asOf: "2026-10-25"), 0)
    }
    
    // MARK: - Safe-to-Spend Computation Tests
    
    func testSafeToSpendCalculationMath() {
        let currency = CurrencyCode.inr
        let cycle = PayCycle(
            startDayOfMonth: 25,
            startDateString: "2026-09-25",
            endDateString: "2026-10-24",
            totalDays: 30
        )
        let asOfDate = "2026-10-15" // 10 days remaining
        
        // 1. Transactions in cycle: 20,000 expense, 2,000 refund -> net 18,000 (1800000 minor)
        let tx1 = Transaction(type: .expense, amountMinor: 2000000, currencyCode: "INR", transactionDay: "2026-09-28")
        let txRefund = Transaction(type: .refund, amountMinor: 200000, currencyCode: "INR", transactionDay: "2026-10-02")
        let transferTx = Transaction(type: .transfer, amountMinor: 5000000, currencyCode: "INR", transactionDay: "2026-10-05")
        
        // 2. Upcoming recurring rules in cycle: 12,000 expense (1200000 minor) due on Oct 20
        let ruleDueInCycle = RecurringRule(
            title: "Broadband",
            type: .expense,
            amountMinor: 1200000,
            currencyCode: "INR",
            nextDueDate: "2026-10-20",
            isActive: true
        )
        // Rule due after cycle ends: should NOT be deducted
        let ruleAfterCycle = RecurringRule(
            title: "Next Month Rent",
            type: .expense,
            amountMinor: 2500000,
            currencyCode: "INR",
            nextDueDate: "2026-10-28",
            isActive: true
        )
        
        // Starting pool: 50,000 INR (5000000 minor)
        let result = SafeToSpendCalculation.compute(
            payCycle: cycle,
            asOfDate: asOfDate,
            currency: currency,
            basis: .budgetLimit,
            startingPoolMinor: 5000000,
            transactions: [tx1, txRefund, transferTx],
            recurringRules: [ruleDueInCycle, ruleAfterCycle]
        )
        
        XCTAssertEqual(result.startingPoolMinor, 5000000)
        XCTAssertEqual(result.postedSpendMinor, 1800000) // transfer ignored!
        XCTAssertEqual(result.upcomingCommitmentsMinor, 1200000) // only ruleDueInCycle included!
        
        // Safe to spend: 5000000 - 1800000 - 1200000 = 2,000,000 (20,000 INR)
        XCTAssertEqual(result.safeToSpendTotalMinor, 2000000)
        XCTAssertEqual(result.deficitMinor, 0)
        XCTAssertFalse(result.isDeficit)
        
        // Daily pace: 2,000,000 / 10 days = 200,000 minor (2,000 INR/day)
        XCTAssertEqual(result.dailyPaceMinor, 200000)
        XCTAssertEqual(result.daysRemaining, 10)
        XCTAssertTrue(result.assumptionsText.contains("Planning forecast"))
        XCTAssertTrue(result.assumptionsText.contains("Not a bank balance"))
    }
    
    func testSafeToSpendDeficitScenario() {
        let currency = CurrencyCode.inr
        let cycle = PayCycle(
            startDayOfMonth: 1,
            startDateString: "2026-10-01",
            endDateString: "2026-10-31",
            totalDays: 31
        )
        
        // Starting pool: 25,000 INR (2500000 minor)
        // Posted spend: 20,000 INR (2000000 minor)
        // Upcoming bills: 10,000 INR (1000000 minor)
        // Total committed: 30,000 INR > 25,000 pool -> Deficit of 5,000 INR
        let tx = Transaction(type: .expense, amountMinor: 2000000, currencyCode: "INR", transactionDay: "2026-10-05")
        let rule = RecurringRule(title: "Insurance", amountMinor: 1000000, currencyCode: "INR", nextDueDate: "2026-10-20")
        
        let result = SafeToSpendCalculation.compute(
            payCycle: cycle,
            asOfDate: "2026-10-10",
            currency: currency,
            basis: .budgetLimit,
            startingPoolMinor: 2500000,
            transactions: [tx],
            recurringRules: [rule]
        )
        
        XCTAssertEqual(result.safeToSpendTotalMinor, 0)
        XCTAssertEqual(result.deficitMinor, 500000)
        XCTAssertTrue(result.isDeficit)
        XCTAssertEqual(result.dailyPaceMinor, 0)
    }
}
