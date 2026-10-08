import XCTest
#if canImport(ExpenseTrackerCore)
@testable import ExpenseTrackerCore
#elseif canImport(ExpenseTracker)
@testable import ExpenseTracker
#endif

final class DataExportAndDeleteTests: XCTestCase {
    
    // MARK: - CSV Exporter Formatting Tests
    
    func testCSVHeaderFormat() {
        let csv = CSVExporter.generateCSV(transactions: [])
        XCTAssertTrue(csv.starts(with: "Date,Type,Amount,Currency,Category,Merchant,Note,Payment Method\r\n"))
    }
    
    func testCSVFieldEscaping() {
        XCTAssertEqual(CSVExporter.escapeField("SimpleText"), "SimpleText")
        XCTAssertEqual(CSVExporter.escapeField("Chai, samosa"), "\"Chai, samosa\"")
        XCTAssertEqual(CSVExporter.escapeField("Dinner with \"Team\""), "\"Dinner with \"\"Team\"\"\"")
        XCTAssertEqual(CSVExporter.escapeField("Line1\nLine2"), "\"Line1\nLine2\"")
        XCTAssertEqual(CSVExporter.escapeField("Line1\r\nLine2"), "\"Line1\r\nLine2\"")
        XCTAssertEqual(CSVExporter.escapeField("Quotes, and \"commas\""), "\"Quotes, and \"\"commas\"\"\"")
    }
    
    func testAmountDecimalFormattingWithoutFloat() {
        // Exponent 2 (INR, USD, EUR)
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: 35000, exponent: 2), "350.00")
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: 125050, exponent: 2), "1250.50")
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: 5, exponent: 2), "0.05")
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: 0, exponent: 2), "0.00")
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: 99, exponent: 2), "0.99")
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: 100, exponent: 2), "1.00")
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: -4525, exponent: 2), "-45.25")
        
        // Exponent 0 (JPY)
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: 5000, exponent: 0), "5000")
        
        // Exponent 3 (e.g. KWD/BHD)
        XCTAssertEqual(CSVExporter.formatDecimal(amountMinor: 1234, exponent: 3), "1.234")
    }
    
    func testCSVGenerationWithTransactions() {
        let catId = UUID()
        let catMap = [catId: "Food & Dining"]
        
        let tx1 = Transaction(
            type: .expense,
            amountMinor: 25000,
            currencyCode: "INR",
            categoryId: catId,
            categoryNameSnapshot: "Food & Dining",
            merchant: "Haldiram's, CP",
            note: "Lunch with \"colleagues\"",
            transactionDay: "2026-10-05",
            paymentMethod: .upi
        )
        
        let tx2 = Transaction(
            type: .income,
            amountMinor: 7500000,
            currencyCode: "INR",
            merchant: "Employer Ltd",
            note: "October Salary",
            transactionDay: "2026-10-01",
            paymentMethod: .bankTransfer
        )
        
        let csv = CSVExporter.generateCSV(transactions: [tx1, tx2], categoryNames: catMap)
        
        XCTAssertTrue(csv.contains("Date,Type,Amount,Currency,Category,Merchant,Note,Payment Method\r\n"))
        // tx1 row should have escaped merchant and note
        XCTAssertTrue(csv.contains("2026-10-05,Expense,250.00,INR,Food & Dining,\"Haldiram's, CP\",\"Lunch with \"\"colleagues\"\"\",UPI"))
        // tx2 row
        XCTAssertTrue(csv.contains("2026-10-01,Income,75000.00,INR,Uncategorized,Employer Ltd,October Salary,BANK_TRANSFER"))
        
        // Verify UTF-8 data generation
        let data = CSVExporter.generateCSVData(transactions: [tx1, tx2], categoryNames: catMap)
        XCTAssertNotNil(data)
        XCTAssertTrue(data!.count > 0)
    }
    
    func testCSVDateFilteringAndExclusionOfDeleted() {
        let tx1 = Transaction(
            type: .expense,
            amountMinor: 10000,
            transactionDay: "2026-09-28"
        )
        let tx2 = Transaction(
            type: .expense,
            amountMinor: 20000,
            transactionDay: "2026-10-02"
        )
        let tx3 = Transaction(
            type: .expense,
            amountMinor: 30000,
            transactionDay: "2026-10-15"
        )
        var txDeleted = Transaction(
            type: .expense,
            amountMinor: 40000,
            transactionDay: "2026-10-05"
        )
        txDeleted.deletedAt = Date()
        
        let options = CSVExportOptions(
            startDay: "2026-10-01",
            endDay: "2026-10-10"
        )
        
        let filtered = CSVExporter.filter(transactions: [tx1, tx2, tx3, txDeleted], options: options)
        
        // Only tx2 is in October 1-10 range and not deleted
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.transactionDay, "2026-10-02")
    }
    
    // MARK: - Local Data Erase Tests
    
    func testClearAllDataResetsFileStoreCleanly() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExpenseTracker_EraseTest_\(UUID().uuidString)")
        
        let store = LocalFileStore(baseDirectory: tempDir)
        let profileRepo = LocalUserProfileRepository(store: store)
        let txRepo = LocalTransactionRepository(store: store)
        let catRepo = LocalCategoryRepository(store: store)
        let budgetRepo = LocalBudgetRepository(store: store)
        
        // 1. Seed data
        _ = try await profileRepo.completeOnboarding(
            currencyCode: "EUR",
            displayName: "Test User",
            expectedIncomeMinor: 300000,
            monthlyBudgetMinor: 200000
        )
        
        let draft = TransactionDraft(
            type: .expense,
            amountMinor: 5000,
            currencyCode: "EUR",
            transactionDay: "2026-10-08"
        )
        _ = try await txRepo.add(draft: draft)
        
        let customCat = Category(name: "Gadgets", iconKey: "laptopcomputer")
        _ = try await catRepo.create(category: customCat)
        
        let budget = Budget(month: CalendarMonth(year: 2026, month: 10), limitMinor: 200000, currencyCode: "EUR")
        try await budgetRepo.save(budget: budget)
        
        // Verify records exist
        let allTxsBefore = try await txRepo.listAll()
        XCTAssertEqual(allTxsBefore.count, 1)
        
        let profileBefore = try await profileRepo.getProfile()
        XCTAssertTrue(profileBefore.onboardingCompleted)
        XCTAssertEqual(profileBefore.defaultCurrencyCode, "EUR")
        
        // 2. Perform Delete All Data
        try await store.clearAllData()
        
        // 3. Verify clean state
        let allTxsAfter = try await txRepo.listAll()
        XCTAssertTrue(allTxsAfter.isEmpty)
        
        // Profile should return default un-onboarded profile
        let profileAfter = try await profileRepo.getProfile()
        XCTAssertFalse(profileAfter.onboardingCompleted)
        XCTAssertEqual(profileAfter.defaultCurrencyCode, "INR")
        
        // Clean up temp dir if still exists
        try? FileManager.default.removeItem(at: tempDir)
    }
}
