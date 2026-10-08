import XCTest
@testable import ExpenseTrackerCore

final class VoiceParserTests: XCTestCase {
    
    let categories = Category.starterCategories
    let referenceDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 8))!
    
    // MARK: - Required Test Plan Fixtures (docs/09_TEST_PLAN.md)
    
    func testFixtureSpentOnLunch() {
        let result = VoiceTransactionParser.parse(
            transcript: "Spent 350 rupees on lunch.",
            defaultCurrencyCode: "INR",
            referenceDate: referenceDate,
            categories: categories
        )
        
        XCTAssertEqual(result.draft.type, .expense)
        XCTAssertEqual(result.draft.amountMinor, 35000) // ₹350.00
        XCTAssertEqual(result.draft.categoryNameSnapshot, "Food & Drink")
        XCTAssertEqual(result.confidence, .high)
        XCTAssertEqual(result.draft.transactionDay, "2026-10-08")
    }
    
    func testFixturePaidForElectricity() {
        let result = VoiceTransactionParser.parse(
            transcript: "Paid 800 for electricity.",
            defaultCurrencyCode: "INR",
            referenceDate: referenceDate,
            categories: categories
        )
        
        XCTAssertEqual(result.draft.type, .expense)
        XCTAssertEqual(result.draft.amountMinor, 80000) // ₹800.00
        XCTAssertEqual(result.draft.categoryNameSnapshot, "Bills")
        XCTAssertEqual(result.confidence, .high)
    }
    
    func testFixtureGotFromFreelanceWork() {
        let result = VoiceTransactionParser.parse(
            transcript: "Got 5000 from freelance work.",
            defaultCurrencyCode: "INR",
            referenceDate: referenceDate,
            categories: categories
        )
        
        XCTAssertEqual(result.draft.type, .income)
        XCTAssertEqual(result.draft.amountMinor, 500000) // ₹5,000.00
        XCTAssertEqual(result.draft.merchant, "Freelance Work")
        XCTAssertEqual(result.confidence, .high)
    }
    
    func testFixtureChaiUPI() {
        let result = VoiceTransactionParser.parse(
            transcript: "₹250 chai, UPI.",
            defaultCurrencyCode: "INR",
            referenceDate: referenceDate,
            categories: categories
        )
        
        XCTAssertEqual(result.draft.type, .expense)
        XCTAssertEqual(result.draft.amountMinor, 25000) // ₹250.00
        XCTAssertEqual(result.draft.paymentMethod, .upi)
        XCTAssertEqual(result.draft.categoryNameSnapshot, "Food & Drink")
    }
    
    func testFixtureAutoYesterday() {
        let result = VoiceTransactionParser.parse(
            transcript: "Auto 120 yesterday.",
            defaultCurrencyCode: "INR",
            referenceDate: referenceDate,
            categories: categories
        )
        
        XCTAssertEqual(result.draft.type, .expense)
        XCTAssertEqual(result.draft.amountMinor, 12000) // ₹120.00
        XCTAssertEqual(result.draft.categoryNameSnapshot, "Transport")
        XCTAssertEqual(result.draft.transactionDay, "2026-10-07") // Yesterday
    }
    
    func testFixtureKalMetro() {
        let result = VoiceTransactionParser.parse(
            transcript: "Kal metro 40.",
            defaultCurrencyCode: "INR",
            referenceDate: referenceDate,
            categories: categories
        )
        
        XCTAssertEqual(result.draft.type, .expense)
        XCTAssertEqual(result.draft.amountMinor, 4000) // ₹40.00
        XCTAssertEqual(result.draft.categoryNameSnapshot, "Transport")
        XCTAssertEqual(result.draft.transactionDay, "2026-10-07") // Yesterday
        // Invariant: Ambiguous "kal" requires explicit-date review notice
        XCTAssertTrue(result.warnings.contains { $0.contains("kal") })
    }
    
    // MARK: - Edge Cases & Invariants
    
    func testMissingAmountCannotSilentlySave() {
        let result = VoiceTransactionParser.parse(
            transcript: "Delicious pizza with friends",
            defaultCurrencyCode: "INR",
            referenceDate: referenceDate,
            categories: categories
        )
        
        XCTAssertEqual(result.draft.amountMinor, 0)
        XCTAssertEqual(result.confidence, .low)
        XCTAssertTrue(result.warnings.contains { $0.contains("amount") })
        
        // Invariant: Draft with 0 amount must throw validation error if attempted to save
        XCTAssertThrowsError(try result.draft.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.zeroOrNegativeAmount(0))
        }
    }
    
    func testEmptyTranscriptHandledGracefully() {
        let result = VoiceTransactionParser.parse(
            transcript: "   ",
            defaultCurrencyCode: "INR",
            categories: categories
        )
        
        XCTAssertEqual(result.draft.amountMinor, 0)
        XCTAssertEqual(result.confidence, .low)
        XCTAssertFalse(result.warnings.isEmpty)
    }
}
