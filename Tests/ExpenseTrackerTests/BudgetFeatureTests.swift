import XCTest
#if canImport(ExpenseTrackerCore)
@testable import ExpenseTrackerCore
#elseif canImport(ExpenseTracker)
@testable import ExpenseTracker
#endif

final class BudgetFeatureTests: XCTestCase {
    
    var tempDirectory: URL!
    var store: LocalFileStore!
    var budgetRepo: LocalBudgetRepository!
    var txRepo: LocalTransactionRepository!
    var catRepo: LocalCategoryRepository!
    
    let targetMonth = CalendarMonth(year: 2026, month: 10)
    let inr = CurrencyCode.inr
    
    override func setUp() async throws {
        try await super.setUp()
        let uniqueSubdir = "ExpenseTrackerTests_Budget_\(UUID().uuidString)"
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueSubdir, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        store = LocalFileStore(baseDirectory: tempDirectory)
        budgetRepo = LocalBudgetRepository(store: store)
        txRepo = LocalTransactionRepository(store: store)
        catRepo = LocalCategoryRepository(store: store)
    }
    
    override func tearDown() async throws {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        try await super.tearDown()
    }
    
    // MARK: - Category Spending Aggregation Tests
    
    func testCategorySpendingAggregation() async throws {
        let categories = try await catRepo.list(includeArchived: false)
        let foodCat = categories.first { $0.name == "Food & Drink" }!
        let transportCat = categories.first { $0.name == "Transport" }!
        
        let txs: [Transaction] = [
            // Food & Drink: ₹500 + ₹300 = ₹800
            Transaction(type: .expense, amountMinor: 50000, categoryId: foodCat.id, categoryNameSnapshot: foodCat.name, transactionDay: "2026-10-02"),
            Transaction(type: .expense, amountMinor: 30000, categoryId: foodCat.id, categoryNameSnapshot: foodCat.name, transactionDay: "2026-10-05"),
            // Food & Drink Refund: ₹100 -> Net Food = ₹700 (70,000 paise)
            Transaction(type: .refund, amountMinor: 10000, categoryId: foodCat.id, categoryNameSnapshot: foodCat.name, transactionDay: "2026-10-06"),
            // Transport: ₹300 (30,000 paise)
            Transaction(type: .expense, amountMinor: 30000, categoryId: transportCat.id, categoryNameSnapshot: transportCat.name, transactionDay: "2026-10-08"),
            // Uncategorized: ₹200 (20,000 paise)
            Transaction(type: .expense, amountMinor: 20000, categoryId: nil, categoryNameSnapshot: nil, transactionDay: "2026-10-10"),
            // Income (Must be excluded from category spend)
            Transaction(type: .income, amountMinor: 5000000, transactionDay: "2026-10-01"),
            // Transfer (Must be excluded from category spend)
            Transaction(type: .transfer, amountMinor: 1000000, transactionDay: "2026-10-03")
        ]
        
        let breakdown = CategorySpendSummary.compute(
            for: targetMonth,
            currency: inr,
            transactions: txs,
            categories: categories
        )
        
        XCTAssertEqual(breakdown.count, 3) // Food, Transport, Uncategorized
        
        // Total net spend = 700 + 300 + 200 = ₹1,200 (120,000 paise)
        let foodSummary = breakdown.first { $0.categoryId == foodCat.id }
        XCTAssertEqual(foodSummary?.netSpend.amountMinor, 70000)
        XCTAssertEqual(foodSummary?.transactionCount, 3)
        // Proportion: 700 / 1200 ≈ 0.5833
        XCTAssertEqual(foodSummary?.proportionOfTotal ?? 0, 70000.0 / 120000.0, accuracy: 0.001)
        
        let transportSummary = breakdown.first { $0.categoryId == transportCat.id }
        XCTAssertEqual(transportSummary?.netSpend.amountMinor, 30000)
        XCTAssertEqual(transportSummary?.transactionCount, 1)
        
        let uncategorizedSummary = breakdown.first { $0.categoryId == nil }
        XCTAssertEqual(uncategorizedSummary?.netSpend.amountMinor, 20000)
        XCTAssertEqual(uncategorizedSummary?.categoryName, "Uncategorized")
    }
    
    // MARK: - Warning Threshold Logic
    
    func testWarningThresholdAndOverBudgetStates() {
        let budgetLimitMinor: Int64 = 1000000 // ₹10,000
        
        // Case 1: 50% spent with 80% threshold -> Normal
        let summary50 = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: budgetLimitMinor,
            transactions: [Transaction(type: .expense, amountMinor: 500000, transactionDay: "2026-10-05")]
        )
        XCTAssertEqual(summary50.budgetUsedPercent, 50.0)
        XCTAssertFalse(summary50.isOverBudget)
        
        // Case 2: 85% spent with 80% threshold -> Warning reached
        let summary85 = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: budgetLimitMinor,
            transactions: [Transaction(type: .expense, amountMinor: 850000, transactionDay: "2026-10-05")]
        )
        XCTAssertEqual(summary85.budgetUsedPercent, 85.0)
        XCTAssertFalse(summary85.isOverBudget)
        let isWarning85 = (summary85.budgetUsedPercent ?? 0) >= 80.0 && !summary85.isOverBudget
        XCTAssertTrue(isWarning85)
        
        // Case 3: 110% spent -> Over Budget
        let summary110 = BudgetSummary.calculate(
            for: targetMonth,
            currency: inr,
            budgetLimitMinor: budgetLimitMinor,
            transactions: [Transaction(type: .expense, amountMinor: 1100000, transactionDay: "2026-10-05")]
        )
        XCTAssertEqual(try XCTUnwrap(summary110.budgetUsedPercent), 110.0, accuracy: 0.001)
        XCTAssertTrue(summary110.isOverBudget)
        XCTAssertEqual(summary110.budgetRemaining?.amountMinor, -100000) // -₹1,000
    }
    
    // MARK: - Budget Repository Multi-Month Persistence
    
    func testMultiMonthBudgetPersistence() async throws {
        let monthOct = CalendarMonth(year: 2026, month: 10)
        let monthNov = CalendarMonth(year: 2026, month: 11)
        
        let budgetOct = Budget(month: monthOct, limitMinor: 5000000, currencyCode: "INR", warningThresholdPercent: 80)
        let budgetNov = Budget(month: monthNov, limitMinor: 6000000, currencyCode: "INR", warningThresholdPercent: 90)
        
        try await budgetRepo.save(budget: budgetOct)
        try await budgetRepo.save(budget: budgetNov)
        
        let fetchedOct = try await budgetRepo.get(month: monthOct)
        let fetchedNov = try await budgetRepo.get(month: monthNov)
        
        XCTAssertEqual(fetchedOct?.limitMinor, 5000000)
        XCTAssertEqual(fetchedOct?.warningThresholdPercent, 80)
        
        XCTAssertEqual(fetchedNov?.limitMinor, 6000000)
        XCTAssertEqual(fetchedNov?.warningThresholdPercent, 90)
    }
}
