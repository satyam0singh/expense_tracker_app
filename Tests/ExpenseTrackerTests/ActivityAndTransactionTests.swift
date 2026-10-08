import XCTest
@testable import ExpenseTrackerCore

final class ActivityAndTransactionTests: XCTestCase {
    
    var tempDirectory: URL!
    var store: LocalFileStore!
    var txRepo: LocalTransactionRepository!
    var catRepo: LocalCategoryRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        let uniqueSubdir = "ExpenseTrackerTests_Activity_\(UUID().uuidString)"
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueSubdir, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        store = LocalFileStore(baseDirectory: tempDirectory)
        txRepo = LocalTransactionRepository(store: store)
        catRepo = LocalCategoryRepository(store: store)
    }
    
    override func tearDown() async throws {
        if let dir = tempDirectory {
            try? FileManager.default.removeItem(at: dir)
        }
        try await super.tearDown()
    }
    
    func testAddExpenseAndIncome() async throws {
        let expenseDraft = TransactionDraft(
            type: .expense,
            amountMinor: 45000, // ₹450.00
            currencyCode: "INR",
            merchant: "Café Coffee",
            note: "Coffee with client",
            transactionDay: "2026-10-08",
            paymentMethod: .upi,
            source: .manual
        )
        
        let savedExpense = try await txRepo.add(draft: expenseDraft)
        XCTAssertEqual(savedExpense.type, .expense)
        XCTAssertEqual(savedExpense.amountMinor, 45000)
        XCTAssertEqual(savedExpense.merchant, "Café Coffee")
        
        let incomeDraft = TransactionDraft(
            type: .income,
            amountMinor: 8000000, // ₹80,000.00
            currencyCode: "INR",
            merchant: "Employer Corp",
            note: "October salary",
            transactionDay: "2026-10-08",
            paymentMethod: .bankTransfer,
            source: .manual
        )
        
        let savedIncome = try await txRepo.add(draft: incomeDraft)
        XCTAssertEqual(savedIncome.type, .income)
        XCTAssertEqual(savedIncome.amountMinor, 8000000)
        XCTAssertEqual(savedIncome.paymentMethod, .bankTransfer)
        
        let month = CalendarMonth(year: 2026, month: 10)
        let list = try await txRepo.list(month: month)
        XCTAssertEqual(list.count, 2)
    }
    
    func testUpdateTransaction() async throws {
        let draft = TransactionDraft(
            type: .expense,
            amountMinor: 20000,
            currencyCode: "INR",
            merchant: "Stationary",
            transactionDay: "2026-10-05"
        )
        
        let original = try await txRepo.add(draft: draft)
        
        // Update amount and add note
        let updatedDraft = TransactionDraft(
            type: .expense,
            amountMinor: 25000, // ₹250 instead of ₹200
            currencyCode: "INR",
            merchant: "Stationary",
            note: "Notebook and pen",
            transactionDay: "2026-10-05"
        )
        
        let updated = try await txRepo.update(id: original.id, draft: updatedDraft)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.amountMinor, 25000)
        XCTAssertEqual(updated.note, "Notebook and pen")
        
        let reloaded = try await txRepo.get(id: original.id)
        XCTAssertEqual(reloaded?.amountMinor, 25000)
        XCTAssertEqual(reloaded?.note, "Notebook and pen")
    }
    
    func testSoftDeleteAndUndo() async throws {
        let draft = TransactionDraft(
            type: .expense,
            amountMinor: 30000,
            currencyCode: "INR",
            merchant: "Bookstore",
            transactionDay: "2026-10-06"
        )
        
        let saved = try await txRepo.add(draft: draft)
        let month = CalendarMonth(year: 2026, month: 10)
        
        var list = try await txRepo.list(month: month)
        XCTAssertEqual(list.count, 1)
        
        // Delete
        try await txRepo.delete(id: saved.id)
        list = try await txRepo.list(month: month)
        XCTAssertEqual(list.count, 0) // Excluded from active list
        
        // Undo delete
        try await txRepo.undoDelete(id: saved.id)
        list = try await txRepo.list(month: month)
        XCTAssertEqual(list.count, 1) // Restored
        XCTAssertEqual(list.first?.id, saved.id)
    }
    
    func testSearchAndFilterLogic() async throws {
        _ = try await txRepo.add(draft: TransactionDraft(
            type: .expense,
            amountMinor: 50000,
            currencyCode: "INR",
            merchant: "Groceries Supermarket",
            note: "Weekly veggies",
            transactionDay: "2026-10-01"
        ))
        
        _ = try await txRepo.add(draft: TransactionDraft(
            type: .expense,
            amountMinor: 15000,
            currencyCode: "INR",
            merchant: "Pharmacy",
            note: "Cough syrup",
            transactionDay: "2026-10-02"
        ))
        
        _ = try await txRepo.add(draft: TransactionDraft(
            type: .income,
            amountMinor: 200000,
            currencyCode: "INR",
            merchant: "Freelance Client",
            note: "Design consultation",
            transactionDay: "2026-10-03"
        ))
        
        let month = CalendarMonth(year: 2026, month: 10)
        let allTxs = try await txRepo.list(month: month)
        XCTAssertEqual(allTxs.count, 3)
        
        // Filter by type: expense
        let expensesOnly = allTxs.filter { $0.type == .expense }
        XCTAssertEqual(expensesOnly.count, 2)
        
        // Filter by type: income
        let incomeOnly = allTxs.filter { $0.type == .income }
        XCTAssertEqual(incomeOnly.count, 1)
        XCTAssertEqual(incomeOnly.first?.merchant, "Freelance Client")
        
        // Filter by search query "syrup"
        let searchResults = allTxs.filter { tx in
            (tx.merchant?.lowercased().contains("syrup") ?? false) || (tx.note?.lowercased().contains("syrup") ?? false)
        }
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults.first?.merchant, "Pharmacy")
    }
}
