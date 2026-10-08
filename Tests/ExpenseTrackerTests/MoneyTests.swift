import XCTest
#if canImport(ExpenseTrackerCore)
@testable import ExpenseTrackerCore
#elseif canImport(ExpenseTracker)
@testable import ExpenseTracker
#endif

final class MoneyTests: XCTestCase {
    
    func testZeroAndStatusFlags() {
        let zero = Money.zero(currency: .inr)
        XCTAssertTrue(zero.isZero)
        XCTAssertFalse(zero.isPositive)
        XCTAssertFalse(zero.isNegative)
        XCTAssertEqual(zero.amountMinor, 0)
        
        let positive = Money(amountMinor: 500, currency: .inr)
        XCTAssertFalse(positive.isZero)
        XCTAssertTrue(positive.isPositive)
        XCTAssertFalse(positive.isNegative)
        
        let negative = Money(amountMinor: -250, currency: .inr)
        XCTAssertFalse(negative.isZero)
        XCTAssertFalse(negative.isPositive)
        XCTAssertTrue(negative.isNegative)
    }
    
    func testAdditionSameCurrency() throws {
        let m1 = Money(amountMinor: 1500, currency: .inr)
        let m2 = Money(amountMinor: 2500, currency: .inr)
        let result = try m1 + m2
        XCTAssertEqual(result.amountMinor, 4000)
        XCTAssertEqual(result.currency, .inr)
    }
    
    func testSubtractionSameCurrency() throws {
        let m1 = Money(amountMinor: 5000, currency: .inr)
        let m2 = Money(amountMinor: 2000, currency: .inr)
        let result = try m1 - m2
        XCTAssertEqual(result.amountMinor, 3000)
        XCTAssertEqual(result.currency, .inr)
    }
    
    func testPrefixNegation() {
        let m = Money(amountMinor: 1000, currency: .inr)
        let negated = -m
        XCTAssertEqual(negated.amountMinor, -1000)
        XCTAssertEqual(negated.currency, .inr)
    }
    
    func testCurrencyMismatchThrows() {
        let inr = Money(amountMinor: 100, currency: .inr)
        let usd = Money(amountMinor: 100, currency: .usd)
        
        XCTAssertThrowsError(try inr + usd) { error in
            XCTAssertEqual(error as? MoneyError, MoneyError.currencyMismatch(expected: "INR", actual: "USD"))
        }
        
        XCTAssertThrowsError(try inr - usd) { error in
            XCTAssertEqual(error as? MoneyError, MoneyError.currencyMismatch(expected: "INR", actual: "USD"))
        }
    }
    
    func testComparison() {
        let m1 = Money(amountMinor: 100, currency: .inr)
        let m2 = Money(amountMinor: 200, currency: .inr)
        XCTAssertTrue(m1 < m2)
        XCTAssertFalse(m2 < m1)
    }
    
    // MARK: - Currency Formatting Boundaries
    
    func testFormattingBoundaries() {
        let enUS = Locale(identifier: "en_US")
        
        // Zero paise
        let zero = Money(amountMinor: 0, currency: .inr)
        XCTAssertEqual(CurrencyFormatter.format(money: zero, locale: enUS), "₹0.00")
        
        // 5 paise (single digit minor unit padding)
        let fivePaise = Money(amountMinor: 5, currency: .inr)
        XCTAssertEqual(CurrencyFormatter.format(money: fivePaise, locale: enUS), "₹0.05")
        
        // 99 paise
        let ninetyNinePaise = Money(amountMinor: 99, currency: .inr)
        XCTAssertEqual(CurrencyFormatter.format(money: ninetyNinePaise, locale: enUS), "₹0.99")
        
        // Exactly 1 Rupee (100 paise)
        let oneRupee = Money(amountMinor: 100, currency: .inr)
        XCTAssertEqual(CurrencyFormatter.format(money: oneRupee, locale: enUS), "₹1.00")
        
        // Thousands grouping (123,456 paise -> ₹1,234.56)
        let thousands = Money(amountMinor: 123456, currency: .inr)
        XCTAssertEqual(CurrencyFormatter.format(money: thousands, locale: enUS), "₹1,234.56")
        
        // Large amount (10,000,000 paise -> ₹100,000.00)
        let large = Money(amountMinor: 10000000, currency: .inr)
        XCTAssertEqual(CurrencyFormatter.format(money: large, locale: enUS), "₹100,000.00")
        
        // Negative amount (-500 paise -> -₹5.00)
        let negative = Money(amountMinor: -500, currency: .inr)
        XCTAssertEqual(CurrencyFormatter.format(money: negative, locale: enUS), "-₹5.00")
        
        // Zero-exponent currency (JPY)
        let yen = Money(amountMinor: 1500, currency: .jpy)
        XCTAssertEqual(CurrencyFormatter.format(money: yen, locale: enUS), "¥1,500")
    }
}
