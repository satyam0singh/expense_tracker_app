import XCTest
@testable import ExpenseTrackerCore

final class RecurringRulesTests: XCTestCase {
    
    // MARK: - Cadence Calculations Tests
    
    func testCadenceCalculationWeeklyAndBiweekly() {
        let current = "2026-10-08"
        let nextWeekly = RecurringRule.calculateNextDueDate(from: current, cadence: .weekly)
        XCTAssertEqual(nextWeekly, "2026-10-15")
        
        let nextBiweekly = RecurringRule.calculateNextDueDate(from: current, cadence: .biweekly)
        XCTAssertEqual(nextBiweekly, "2026-10-22")
        
        // Month rollover
        let lateOctober = "2026-10-28"
        let nextInNovember = RecurringRule.calculateNextDueDate(from: lateOctober, cadence: .weekly)
        XCTAssertEqual(nextInNovember, "2026-11-04")
    }
    
    func testCadenceCalculationMonthlyAndClamping() {
        let regular = "2026-10-15"
        let nextMonth = RecurringRule.calculateNextDueDate(from: regular, cadence: .monthly)
        XCTAssertEqual(nextMonth, "2026-11-15")
        
        // End of month day clamping (Jan 31 to Feb 28 in non-leap year 2027)
        let jan31 = "2027-01-31"
        let febDue = RecurringRule.calculateNextDueDate(from: jan31, cadence: .monthly)
        XCTAssertEqual(febDue, "2027-02-28")
        
        // Year rollover (Dec to Jan)
        let dec10 = "2026-12-10"
        let janDue = RecurringRule.calculateNextDueDate(from: dec10, cadence: .monthly)
        XCTAssertEqual(janDue, "2027-01-10")
    }
    
    func testCadenceCalculationYearly() {
        let current = "2026-05-20"
        let nextYear = RecurringRule.calculateNextDueDate(from: current, cadence: .yearly)
        XCTAssertEqual(nextYear, "2027-05-20")
    }
    
    func testRuleDueStatus() {
        let ruleDuePast = RecurringRule(
            title: "WiFi Bill",
            amountMinor: 99900,
            cadence: .monthly,
            nextDueDate: "2026-10-01",
            isActive: true
        )
        XCTAssertTrue(ruleDuePast.isDue(asOf: "2026-10-08"))
        
        let ruleDueToday = RecurringRule(
            title: "Gym Membership",
            amountMinor: 250000,
            cadence: .monthly,
            nextDueDate: "2026-10-08",
            isActive: true
        )
        XCTAssertTrue(ruleDueToday.isDue(asOf: "2026-10-08"))
        
        let ruleDueFuture = RecurringRule(
            title: "Rent",
            amountMinor: 2000000,
            cadence: .monthly,
            nextDueDate: "2026-11-01",
            isActive: true
        )
        XCTAssertFalse(ruleDueFuture.isDue(asOf: "2026-10-08"))
        
        // Inactive rules are never due
        var rulePaused = ruleDuePast
        rulePaused.isActive = false
        XCTAssertFalse(rulePaused.isDue(asOf: "2026-10-08"))
    }
    
    // MARK: - Invariant: Schedule ≠ Posted Transaction
    
    func testScheduleDoesNotAffectBudgetOrTransactionsUntilExplicitlyPosted() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExpenseTracker_RecurringTest_\(UUID().uuidString)")
        let store = LocalFileStore(baseDirectory: tempDir)
        let txRepo = LocalTransactionRepository(store: store)
        let ruleRepo = LocalRecurringRuleRepository(store: store)
        
        // 1. Create a planned recurring commitment for Rent (25,000 INR)
        let rentRule = RecurringRule(
            title: "Apartment Rent",
            type: .expense,
            amountMinor: 2500000,
            currencyCode: "INR",
            cadence: .monthly,
            nextDueDate: "2026-10-01"
        )
        _ = try await ruleRepo.create(rule: rentRule)
        
        // Invariant check: zero posted transactions exist!
        let allTxs = try await txRepo.listAll()
        XCTAssertTrue(allTxs.isEmpty, "Recurring rule must never post an actual transaction automatically.")
        
        // 2. User explicitly reviews and posts the recurring transaction on due date
        let postedDraft = TransactionDraft(
            type: rentRule.type,
            amountMinor: rentRule.amountMinor,
            currencyCode: rentRule.currencyCode,
            categoryId: rentRule.categoryId,
            categoryNameSnapshot: rentRule.categoryNameSnapshot,
            merchant: rentRule.merchant,
            note: "Recurring: \(rentRule.title)",
            transactionDay: rentRule.nextDueDate,
            paymentMethod: rentRule.paymentMethod,
            source: .recurring,
            recurringRuleId: rentRule.id
        )
        let postedTx = try await txRepo.add(draft: postedDraft)
        
        // Advance rule due date to November
        let advancedRule = try await ruleRepo.advanceDueDate(id: rentRule.id)
        XCTAssertEqual(advancedRule?.nextDueDate, "2026-11-01")
        
        // 3. Now exactly one transaction exists with source == .recurring
        let txsAfterPost = try await txRepo.listAll()
        XCTAssertEqual(txsAfterPost.count, 1)
        XCTAssertEqual(txsAfterPost.first?.id, postedTx.id)
        XCTAssertEqual(txsAfterPost.first?.source, .recurring)
        XCTAssertEqual(txsAfterPost.first?.recurringRuleId, rentRule.id)
        XCTAssertEqual(txsAfterPost.first?.amountMinor, 2500000)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }
    
    // MARK: - Repository CRUD Tests
    
    func testRecurringRepositoryLifecycle() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExpenseTracker_RuleLifecycleTest_\(UUID().uuidString)")
        let store = LocalFileStore(baseDirectory: tempDir)
        let repo = LocalRecurringRuleRepository(store: store)
        
        let rule1 = RecurringRule(
            title: "Netflix Subscription",
            amountMinor: 64900,
            currencyCode: "INR",
            cadence: .monthly,
            nextDueDate: "2026-10-18"
        )
        let rule2 = RecurringRule(
            title: "Salary Credit",
            type: .income,
            amountMinor: 8500000,
            currencyCode: "INR",
            cadence: .monthly,
            nextDueDate: "2026-10-31"
        )
        
        _ = try await repo.create(rule: rule1)
        _ = try await repo.create(rule: rule2)
        
        let allRules = try await repo.list(activeOnly: false)
        XCTAssertEqual(allRules.count, 2)
        
        // Toggle active
        let toggled = try await repo.toggleActive(id: rule1.id)
        XCTAssertEqual(toggled?.isActive, false)
        
        let activeRules = try await repo.list(activeOnly: true)
        XCTAssertEqual(activeRules.count, 1)
        XCTAssertEqual(activeRules.first?.id, rule2.id)
        
        // Delete
        try await repo.delete(id: rule1.id)
        let remaining = try await repo.list(activeOnly: false)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.id, rule2.id)
        
        // Clean up
        try? FileManager.default.removeItem(at: tempDir)
    }
}
