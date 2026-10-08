import XCTest
#if canImport(ExpenseTrackerCore)
@testable import ExpenseTrackerCore
#elseif canImport(ExpenseTracker)
@testable import ExpenseTracker
#endif

final class CalendarMonthTests: XCTestCase {
    
    func testMonthDaysAndLeapYear() {
        // Non-leap year February (2025, 2026)
        let feb2025 = CalendarMonth(year: 2025, month: 2)
        XCTAssertEqual(feb2025.numberOfDays, 28)
        XCTAssertEqual(feb2025.startDateString, "2025-02-01")
        XCTAssertEqual(feb2025.endDateString, "2025-02-28")
        
        let feb2026 = CalendarMonth(year: 2026, month: 2)
        XCTAssertEqual(feb2026.numberOfDays, 28)
        XCTAssertEqual(feb2026.startDateString, "2026-02-01")
        XCTAssertEqual(feb2026.endDateString, "2026-02-28")
        
        // Leap year February (2024, 2028)
        let feb2024 = CalendarMonth(year: 2024, month: 2)
        XCTAssertEqual(feb2024.numberOfDays, 29)
        XCTAssertEqual(feb2024.startDateString, "2024-02-01")
        XCTAssertEqual(feb2024.endDateString, "2024-02-29")
        
        // 31-day months
        let jan = CalendarMonth(year: 2026, month: 1)
        XCTAssertEqual(jan.numberOfDays, 31)
        XCTAssertEqual(jan.startDateString, "2026-01-01")
        XCTAssertEqual(jan.endDateString, "2026-01-31")
        
        let oct = CalendarMonth(year: 2026, month: 10)
        XCTAssertEqual(oct.numberOfDays, 31)
        XCTAssertEqual(oct.startDateString, "2026-10-01")
        XCTAssertEqual(oct.endDateString, "2026-10-31")
        
        // 30-day months
        let apr = CalendarMonth(year: 2026, month: 4)
        XCTAssertEqual(apr.numberOfDays, 30)
        XCTAssertEqual(apr.startDateString, "2026-04-01")
        XCTAssertEqual(apr.endDateString, "2026-04-30")
    }
    
    func testMonthNavigation() {
        let dec2026 = CalendarMonth(year: 2026, month: 12)
        let jan2027 = dec2026.next()
        XCTAssertEqual(jan2027.year, 2027)
        XCTAssertEqual(jan2027.month, 1)
        XCTAssertEqual(jan2027.id, "2027-01")
        
        let backToDec = jan2027.previous()
        XCTAssertEqual(backToDec.year, 2026)
        XCTAssertEqual(backToDec.month, 12)
        
        let jan2026 = CalendarMonth(year: 2026, month: 1)
        let dec2025 = jan2026.previous()
        XCTAssertEqual(dec2025.year, 2025)
        XCTAssertEqual(dec2025.month, 12)
    }
    
    func testDateContainment() {
        let oct2026 = CalendarMonth(year: 2026, month: 10)
        XCTAssertTrue(oct2026.contains(dayString: "2026-10-01"))
        XCTAssertTrue(oct2026.contains(dayString: "2026-10-15"))
        XCTAssertTrue(oct2026.contains(dayString: "2026-10-31"))
        
        // Boundaries outside October
        XCTAssertFalse(oct2026.contains(dayString: "2026-09-30"))
        XCTAssertFalse(oct2026.contains(dayString: "2026-11-01"))
        XCTAssertFalse(oct2026.contains(dayString: "2025-10-15"))
    }
}
