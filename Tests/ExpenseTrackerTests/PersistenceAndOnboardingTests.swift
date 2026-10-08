import XCTest
@testable import ExpenseTrackerCore

final class PersistenceAndOnboardingTests: XCTestCase {
    
    var tempDirectory: URL!
    var store: LocalFileStore!
    
    override func setUp() async throws {
        try await super.setUp()
        let uniqueSubdir = "ExpenseTrackerTests_\(UUID().uuidString)"
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueSubdir, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        store = LocalFileStore(baseDirectory: tempDirectory)
    }
    
    override func tearDown() async throws {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        try await super.tearDown()
    }
    
    // MARK: - Category Seeding & Archive Tests
    
    func testStarterCategoriesSeededIdempotently() async throws {
        let categoryRepo = LocalCategoryRepository(store: store)
        
        // Initial launch: should seed exactly 10 starter categories
        let initialCategories = try await categoryRepo.list(includeArchived: false)
        XCTAssertEqual(initialCategories.count, 10)
        XCTAssertTrue(initialCategories.contains(where: { $0.name == "Food & Drink" }))
        XCTAssertTrue(initialCategories.contains(where: { $0.name == "Groceries" }))
        XCTAssertTrue(initialCategories.contains(where: { $0.name == "Transport" }))
        
        // Simulated app restart with new repository instance on the same store
        let restartedRepo = LocalCategoryRepository(store: store)
        let restartedCategories = try await restartedRepo.list(includeArchived: false)
        
        // Invariant: Must not duplicate categories on relaunch
        XCTAssertEqual(restartedCategories.count, 10)
    }
    
    func testCategoryArchivePreservesHistory() async throws {
        let categoryRepo = LocalCategoryRepository(store: store)
        let categories = try await categoryRepo.list(includeArchived: false)
        guard let foodCategory = categories.first(where: { $0.name == "Food & Drink" }) else {
            XCTFail("Food & Drink category expected")
            return
        }
        
        // Archive the category
        try await categoryRepo.archive(id: foodCategory.id)
        
        // Active list should now have 9 items and NOT include Food & Drink
        let activeCategories = try await categoryRepo.list(includeArchived: false)
        XCTAssertEqual(activeCategories.count, 9)
        XCTAssertFalse(activeCategories.contains(where: { $0.id == foodCategory.id }))
        
        // All list (includeArchived: true) must still preserve it
        let allCategories = try await categoryRepo.list(includeArchived: true)
        XCTAssertEqual(allCategories.count, 10)
        let archived = allCategories.first(where: { $0.id == foodCategory.id })
        XCTAssertEqual(archived?.isArchived, true)
    }
    
    func testCreateCustomCategory() async throws {
        let categoryRepo = LocalCategoryRepository(store: store)
        let newCat = Category(name: "Gadgets", iconKey: "laptopcomputer")
        let created = try await categoryRepo.create(category: newCat)
        
        XCTAssertEqual(created.name, "Gadgets")
        let list = try await categoryRepo.list(includeArchived: false)
        XCTAssertEqual(list.count, 11)
        XCTAssertTrue(list.contains(where: { $0.name == "Gadgets" }))
    }
    
    // MARK: - Onboarding & Profile Persistence Tests
    
    func testOnboardingDefaultsAndCompletion() async throws {
        let profileRepo = LocalUserProfileRepository(store: store)
        
        // Clean install state
        let initialProfile = try await profileRepo.getProfile()
        XCTAssertEqual(initialProfile.defaultCurrencyCode, "INR")
        XCTAssertFalse(initialProfile.onboardingCompleted)
        XCTAssertNil(initialProfile.expectedMonthlyIncomeMinor)
        XCTAssertNil(initialProfile.monthlyBudgetLimitMinor)
        
        // Complete onboarding with custom planning context
        let completed = try await profileRepo.completeOnboarding(
            currencyCode: "INR",
            displayName: "Test User",
            expectedIncomeMinor: 6000000, // ₹60,000 planning figure
            monthlyBudgetMinor: 3500000   // ₹35,000 monthly budget
        )
        
        XCTAssertTrue(completed.onboardingCompleted)
        XCTAssertEqual(completed.displayName, "Test User")
        XCTAssertEqual(completed.expectedMonthlyIncomeMinor, 6000000)
        XCTAssertEqual(completed.monthlyBudgetLimitMinor, 3500000)
        
        // Simulate app relaunch
        let restartedRepo = LocalUserProfileRepository(store: store)
        let reloaded = try await restartedRepo.getProfile()
        XCTAssertTrue(reloaded.onboardingCompleted)
        XCTAssertEqual(reloaded.displayName, "Test User")
        XCTAssertEqual(reloaded.expectedMonthlyIncomeMinor, 6000000)
        XCTAssertEqual(reloaded.monthlyBudgetLimitMinor, 3500000)
    }
    
    func testOnboardingSkipPath() async throws {
        let profileRepo = LocalUserProfileRepository(store: store)
        
        // Skip onboarding
        let skipped = try await profileRepo.completeOnboarding(
            currencyCode: "INR",
            displayName: nil,
            expectedIncomeMinor: nil,
            monthlyBudgetMinor: nil
        )
        
        XCTAssertTrue(skipped.onboardingCompleted)
        XCTAssertEqual(skipped.defaultCurrencyCode, "INR")
        XCTAssertNil(skipped.expectedMonthlyIncomeMinor)
        XCTAssertNil(skipped.monthlyBudgetLimitMinor)
    }
    
    // MARK: - Transaction & Budget Persistence Round-trip
    
    func testTransactionPersistenceAndSoftDelete() async throws {
        let txRepo = LocalTransactionRepository(store: store)
        let draft = TransactionDraft(
            type: .expense,
            amountMinor: 250000, // ₹2,500
            currencyCode: "INR",
            merchant: "Supermarket",
            note: "Groceries for the week",
            transactionDay: "2026-10-08",
            paymentMethod: .upi,
            source: .manual
        )
        
        let saved = try await txRepo.add(draft: draft)
        XCTAssertEqual(saved.amountMinor, 250000)
        XCTAssertEqual(saved.merchant, "Supermarket")
        
        // List by month
        let month = CalendarMonth(year: 2026, month: 10)
        let monthTxs = try await txRepo.list(month: month)
        XCTAssertEqual(monthTxs.count, 1)
        XCTAssertEqual(monthTxs.first?.id, saved.id)
        
        // Soft-delete
        try await txRepo.delete(id: saved.id)
        let afterDelete = try await txRepo.list(month: month)
        XCTAssertEqual(afterDelete.count, 0) // Soft-deleted items must not appear in active queries
    }
    
    func testBudgetPersistenceAndOverwrite() async throws {
        let budgetRepo = LocalBudgetRepository(store: store)
        let month = CalendarMonth(year: 2026, month: 10)
        
        let initialBudget = Budget(month: month, limitMinor: 4000000, currencyCode: "INR", warningThresholdPercent: 80)
        try await budgetRepo.save(budget: initialBudget)
        
        let fetched = try await budgetRepo.get(month: month)
        XCTAssertEqual(fetched?.limitMinor, 4000000)
        XCTAssertEqual(fetched?.warningThresholdPercent, 80)
        
        // Update budget for same month
        let updatedBudget = Budget(month: month, limitMinor: 4500000, currencyCode: "INR", warningThresholdPercent: 90)
        try await budgetRepo.save(budget: updatedBudget)
        
        let refetched = try await budgetRepo.get(month: month)
        XCTAssertEqual(refetched?.limitMinor, 4500000)
        XCTAssertEqual(refetched?.warningThresholdPercent, 90)
    }
}
