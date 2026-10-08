import XCTest
@testable import ExpenseTrackerCore

final class WidgetSnapshotTests: XCTestCase {
    
    func testWidgetSnapshotCalculationFromTransactionsAndBudget() {
        let profile = UserProfile(
            monthlyBudgetLimitMinor: 500000, // ₹5,000.00
            defaultCurrencyCode: "INR",
            payCycleStartDay: 1
        )
        
        let month = CalendarMonth(year: 2026, month: 10)
        let budget = Budget(month: month, limitMinor: 500000, currencyCode: "INR")
        
        let tx1 = Transaction(
            type: .expense,
            amountMinor: 120000, // ₹1,200.00
            currencyCode: "INR",
            categoryNameSnapshot: "Food",
            transactionDay: "2026-10-05"
        )
        let tx2 = Transaction(
            type: .expense,
            amountMinor: 80000, // ₹800.00
            currencyCode: "INR",
            categoryNameSnapshot: "Transport",
            transactionDay: "2026-10-06"
        )
        let txRefund = Transaction(
            type: .refund,
            amountMinor: 20000, // ₹200.00 refund
            currencyCode: "INR",
            categoryNameSnapshot: "Food",
            transactionDay: "2026-10-07"
        )
        let txTransfer = Transaction(
            type: .transfer,
            amountMinor: 300000, // ₹3,000.00 transfer (must NOT inflate spend)
            currencyCode: "INR",
            transactionDay: "2026-10-07"
        )
        
        let asOf = CalendarMonth(year: 2026, month: 10).startDate
        let snapshot = WidgetSnapshotGenerator.generate(
            userProfile: profile,
            month: month,
            budget: budget,
            transactions: [tx1, tx2, txRefund, txTransfer],
            categories: [],
            recurringRules: [],
            asOfDate: asOf
        )
        
        // Net spend = 120,000 + 80,000 - 20,000 = 180,000 minor units (₹1,800)
        XCTAssertEqual(snapshot.spentMinor, 180000)
        XCTAssertEqual(snapshot.remainingMinor, 320000) // ₹3,200 remaining
        XCTAssertFalse(snapshot.isOverBudget)
        XCTAssertEqual(snapshot.budgetPacePercentage, 0.36, accuracy: 0.001)
        XCTAssertEqual(snapshot.recentTransactions.count, 3)
        XCTAssertFalse(snapshot.isPrivacyRedacted)
    }
    
    func testWidgetSnapshotOverBudget() {
        let profile = UserProfile(
            monthlyBudgetLimitMinor: 100000, // ₹1,000.00
            defaultCurrencyCode: "INR"
        )
        let month = CalendarMonth(year: 2026, month: 10)
        let budget = Budget(month: month, limitMinor: 100000, currencyCode: "INR")
        
        let tx = Transaction(
            type: .expense,
            amountMinor: 150000, // ₹1,500.00
            currencyCode: "INR",
            transactionDay: "2026-10-02"
        )
        
        let snapshot = WidgetSnapshotGenerator.generate(
            userProfile: profile,
            month: month,
            budget: budget,
            transactions: [tx],
            categories: [],
            recurringRules: [],
            asOfDate: Date()
        )
        
        XCTAssertTrue(snapshot.isOverBudget)
        XCTAssertEqual(snapshot.spentMinor, 150000)
        XCTAssertEqual(snapshot.remainingMinor, -50000)
        XCTAssertGreaterThan(snapshot.budgetPacePercentage, 1.0)
    }
    
    func testPrivacyRedaction() {
        let placeholder = WidgetSnapshot.placeholder
        let redacted = placeholder.redacted()
        
        XCTAssertTrue(redacted.isPrivacyRedacted)
        XCTAssertTrue(redacted.formattedBudgetRemaining.contains("••••"))
        XCTAssertTrue(redacted.formattedSpent.contains("••••"))
        if let sts = redacted.formattedSafeToSpendToday {
            XCTAssertTrue(sts.contains("••••"))
        }
        for item in redacted.recentTransactions {
            XCTAssertTrue(item.formattedAmount.contains("••••"))
        }
    }
    
    func testWidgetDataStoreSaveLoadClear() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let store = WidgetDataStore(appGroupIdentifier: nil, fallbackDirectoryURL: tempDir)
        
        let initial = await store.loadSnapshot()
        XCTAssertNil(initial)
        
        let snapshot = WidgetSnapshot.placeholder
        try await store.saveSnapshot(snapshot)
        
        let loaded = await store.loadSnapshot()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.currencyCode, snapshot.currencyCode)
        XCTAssertEqual(loaded?.spentMinor, snapshot.spentMinor)
        XCTAssertEqual(loaded?.remainingMinor, snapshot.remainingMinor)
        
        try await store.clearSnapshot()
        let cleared = await store.loadSnapshot()
        XCTAssertNil(cleared)
    }
}
