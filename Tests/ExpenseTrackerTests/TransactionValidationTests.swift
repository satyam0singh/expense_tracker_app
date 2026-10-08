import XCTest
@testable import ExpenseTrackerCore

final class TransactionValidationTests: XCTestCase {
    
    func testValidDraftSucceeds() throws {
        let draft = TransactionDraft(
            type: .expense,
            amountMinor: 25000, // ₹250.00
            currencyCode: "INR",
            merchant: "Grocery Store",
            note: "Weekly vegetables",
            transactionDay: "2026-10-08",
            paymentMethod: .upi,
            source: .manual
        )
        
        let tx = try draft.validate()
        XCTAssertEqual(tx.amountMinor, 25000)
        XCTAssertEqual(tx.currencyCode, "INR")
        XCTAssertEqual(tx.transactionDay, "2026-10-08")
        XCTAssertEqual(tx.merchant, "Grocery Store")
        XCTAssertEqual(tx.type, .expense)
        XCTAssertEqual(tx.paymentMethod, .upi)
        XCTAssertEqual(tx.source, .manual)
    }
    
    func testZeroAmountThrows() {
        let draft = TransactionDraft(
            type: .expense,
            amountMinor: 0,
            currencyCode: "INR",
            transactionDay: "2026-10-08"
        )
        
        XCTAssertThrowsError(try draft.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.zeroOrNegativeAmount(0))
        }
    }
    
    func testNegativeAmountThrows() {
        let draft = TransactionDraft(
            type: .expense,
            amountMinor: -500,
            currencyCode: "INR",
            transactionDay: "2026-10-08"
        )
        
        XCTAssertThrowsError(try draft.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.zeroOrNegativeAmount(-500))
        }
    }
    
    func testInvalidCurrencyCodeThrows() {
        let draftShort = TransactionDraft(
            amountMinor: 1000,
            currencyCode: "IN",
            transactionDay: "2026-10-08"
        )
        XCTAssertThrowsError(try draftShort.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidCurrencyCode("IN"))
        }
        
        let draftEmpty = TransactionDraft(
            amountMinor: 1000,
            currencyCode: "",
            transactionDay: "2026-10-08"
        )
        XCTAssertThrowsError(try draftEmpty.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidCurrencyCode(""))
        }
    }
    
    func testInvalidDateThrows() {
        let invalidFormat = TransactionDraft(
            amountMinor: 1000,
            currencyCode: "INR",
            transactionDay: "08/10/2026"
        )
        XCTAssertThrowsError(try invalidFormat.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidDateFormat("08/10/2026"))
        }
        
        // Invalid day (February 30th)
        let invalidFebDay = TransactionDraft(
            amountMinor: 1000,
            currencyCode: "INR",
            transactionDay: "2026-02-30"
        )
        XCTAssertThrowsError(try invalidFebDay.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidDateFormat("2026-02-30"))
        }
        
        // Leap year check: Feb 29 in non-leap year (2025) is invalid
        let nonLeapFeb29 = TransactionDraft(
            amountMinor: 1000,
            currencyCode: "INR",
            transactionDay: "2025-02-29"
        )
        XCTAssertThrowsError(try nonLeapFeb29.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidDateFormat("2025-02-29"))
        }
        
        // Leap year check: Feb 29 in leap year (2024) is valid
        let leapFeb29 = TransactionDraft(
            amountMinor: 1000,
            currencyCode: "INR",
            transactionDay: "2024-02-29"
        )
        XCTAssertNoThrow(try leapFeb29.validate())
    }
}
