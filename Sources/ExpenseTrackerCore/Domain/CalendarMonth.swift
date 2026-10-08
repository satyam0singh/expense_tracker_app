import Foundation

/// Represents a calendar-month budget/summary period.
/// Invariant: Local calendar date semantics are preserved to prevent timezone shifts from altering periods.
public struct CalendarMonth: Hashable, Equatable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    
    public init(year: Int, month: Int) {
        precondition(month >= 1 && month <= 12, "Month must be between 1 and 12")
        self.year = year
        self.month = month
    }
    
    /// Initializes CalendarMonth from a Date using the specified Calendar (default: current).
    public init(date: Date, calendar: Calendar = Calendar.current) {
        let components = calendar.dateComponents([.year, .month], from: date)
        self.year = components.year ?? 2026
        self.month = components.month ?? 1
    }
    
    /// Returns the canonical year-month string, e.g. "2026-10".
    public var id: String {
        return String(format: "%04d-%02d", year, month)
    }
    
    public var description: String {
        return id
    }
    
    /// Next calendar month.
    public func next() -> CalendarMonth {
        if month == 12 {
            return CalendarMonth(year: year + 1, month: 1)
        } else {
            return CalendarMonth(year: year, month: month + 1)
        }
    }
    
    /// Previous calendar month.
    public func previous() -> CalendarMonth {
        if month == 1 {
            return CalendarMonth(year: year - 1, month: 12)
        } else {
            return CalendarMonth(year: year, month: month - 1)
        }
    }
    
    /// Returns the number of days in this specific month, correctly accounting for leap years.
    public var numberOfDays: Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12:
            return 31
        case 4, 6, 9, 11:
            return 30
        case 2:
            return isLeapYear(year) ? 29 : 28
        default:
            return 30
        }
    }
    
    /// Canonical start date string in YYYY-MM-DD format (inclusive).
    public var startDateString: String {
        return String(format: "%04d-%02d-01", year, month)
    }
    
    /// Canonical end date string in YYYY-MM-DD format (inclusive).
    public var endDateString: String {
        return String(format: "%04d-%02d-%02d", year, month, numberOfDays)
    }
    
    /// Checks whether a canonical day string (YYYY-MM-DD) falls within this month.
    public func contains(dayString: String) -> Bool {
        return dayString >= startDateString && dayString <= endDateString
    }
    
    /// User-facing display title (e.g. "October 2026").
    public func displayTitle(locale: Locale = Locale(identifier: "en_US")) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let date = calendar.date(from: components) else {
            return id
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    public static func < (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.month < rhs.month
    }
    
    private func isLeapYear(_ y: Int) -> Bool {
        return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)
    }
}
