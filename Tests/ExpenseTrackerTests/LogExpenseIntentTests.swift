import XCTest
@testable import ExpenseTrackerCore

final class LogExpenseIntentTests: XCTestCase {
    
    func testLogExpenseFromShortcutsValidatesAndSavesMinorUnits() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let fileStore = LocalFileStore(baseDirectory: tempDir)
        let txRepo = LocalTransactionRepository(store: fileStore)
        let catRepo = LocalCategoryRepository(store: fileStore)
        let profile = UserProfile(defaultCurrencyCode: "USD")
        
        // Seed categories
        let foodCat = Category(name: "Food & Dining", iconKey: "fork.knife")
        _ = try await catRepo.create(category: foodCat)
        
        let result = try await LogExpenseIntentHandler.handle(
            amountMajor: 24.50,
            categoryName: "food",
            note: "Coffee and sandwich",
            paymentMethodName: "Credit Card",
            transactionDay: "2026-10-08",
            userProfile: profile,
            transactionRepository: txRepo,
            categoryRepository: catRepo
        )
        
        // 24.50 USD = 2450 minor units
        XCTAssertEqual(result.transaction.amountMinor, 2450)
        XCTAssertEqual(result.transaction.currencyCode, "USD")
        XCTAssertEqual(result.transaction.source, .shortcut)
        XCTAssertEqual(result.transaction.paymentMethod, .creditCard)
        XCTAssertEqual(result.transaction.categoryId, foodCat.id)
        XCTAssertEqual(result.transaction.categoryNameSnapshot, "Food & Dining")
        XCTAssertEqual(result.transaction.note, "Coffee and sandwich")
        XCTAssertTrue(result.confirmationMessage.contains("$24.50"))
        
        // Verify saved in repository
        let savedTxs = try await txRepo.listAll(includeDeleted: false)
        XCTAssertEqual(savedTxs.count, 1)
        XCTAssertEqual(savedTxs.first?.id, result.transaction.id)
    }
    
    func testLogExpenseThrowsOnZeroOrNegativeAmount() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let fileStore = LocalFileStore(baseDirectory: tempDir)
        let txRepo = LocalTransactionRepository(store: fileStore)
        let catRepo = LocalCategoryRepository(store: fileStore)
        let profile = UserProfile(defaultCurrencyCode: "INR")
        
        do {
            _ = try await LogExpenseIntentHandler.handle(
                amountMajor: 0.0,
                categoryName: "Food",
                note: nil,
                userProfile: profile,
                transactionRepository: txRepo,
                categoryRepository: catRepo
            )
            XCTFail("Should throw zero or negative amount error")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
        
        do {
            _ = try await LogExpenseIntentHandler.handle(
                amountMajor: -15.0,
                categoryName: "Food",
                note: nil,
                userProfile: profile,
                transactionRepository: txRepo,
                categoryRepository: catRepo
            )
            XCTFail("Should throw zero or negative amount error")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    func testLogExpenseRefreshesWidgetSnapshot() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let fileStore = LocalFileStore(baseDirectory: tempDir)
        let txRepo = LocalTransactionRepository(store: fileStore)
        let catRepo = LocalCategoryRepository(store: fileStore)
        let widgetStore = WidgetDataStore(appGroupIdentifier: nil, fallbackDirectoryURL: tempDir)
        let profile = UserProfile(defaultCurrencyCode: "INR", monthlyBudgetLimitMinor: 500000)
        
        _ = try await LogExpenseIntentHandler.handle(
            amountMajor: 150.0,
            categoryName: "Groceries",
            note: "Vegetables",
            transactionDay: "2026-10-08",
            userProfile: profile,
            transactionRepository: txRepo,
            categoryRepository: catRepo,
            widgetDataStore: widgetStore
        )
        
        let snapshot = await widgetStore.loadSnapshot()
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.spentMinor, 15000) // 150.00 = 15,000 minor units
        XCTAssertEqual(snapshot?.recentTransactions.count, 1)
        XCTAssertEqual(snapshot?.recentTransactions.first?.categoryName, "Groceries")
    }
}
