import Foundation

/// Represents a financial pay-cycle period (e.g., calendar month, or salary period starting on day X of each month).
/// Invariants:
/// - Exact date arithmetic without floating-point approximations.
/// - Clamps days safely to month bounds (e.g. Day 31 in February clamped to 28/29).
public struct PayCycle: Equatable, Sendable, Codable {
    /// Day of the month on which the pay cycle begins (1...28, or up to 31 with clamping).
    /// Value of 1 represents a standard calendar month.
    public let startDayOfMonth: Int
    public let startDateString: String // Inclusive: YYYY-MM-DD
    public let endDateString: String   // Inclusive: YYYY-MM-DD
    public let totalDays: Int
    
    public init(startDayOfMonth: Int, startDateString: String, endDateString: String, totalDays: Int) {
        self.startDayOfMonth = max(1, min(31, startDayOfMonth))
        self.startDateString = startDateString
        self.endDateString = endDateString
        self.totalDays = totalDays
    }
    
    /// Computes the active pay cycle containing the given reference date (YYYY-MM-DD).
    public static func active(for dayString: String, paydayOfMonth: Int) -> PayCycle {
        let clampedPayday = max(1, min(31, paydayOfMonth))
        let parts = dayString.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            // Fallback to calendar month if invalid format
            let cm = CalendarMonth(year: 2026, month: 10)
            return PayCycle(startDayOfMonth: 1, startDateString: cm.startDateString, endDateString: cm.endDateString, totalDays: cm.numberOfDays)
        }
        
        if clampedPayday == 1 {
            let cm = CalendarMonth(year: year, month: month)
            return PayCycle(startDayOfMonth: 1, startDateString: cm.startDateString, endDateString: cm.endDateString, totalDays: cm.numberOfDays)
        }
        
        let startMonth: CalendarMonth
        let endMonth: CalendarMonth
        
        if day >= clampedPayday {
            // Started in current month on clampedPayday, ends in next month on clampedPayday - 1
            startMonth = CalendarMonth(year: year, month: month)
            endMonth = startMonth.next()
        } else {
            // Started in previous month on clampedPayday, ends in current month on clampedPayday - 1
            endMonth = CalendarMonth(year: year, month: month)
            startMonth = endMonth.previous()
        }
        
        let actualStartDay = min(clampedPayday, startMonth.numberOfDays)
        let actualEndDay = min(clampedPayday - 1, endMonth.numberOfDays)
        
        let startStr = String(format: "%04d-%02d-%02d", startMonth.year, startMonth.month, actualStartDay)
        let endStr = String(format: "%04d-%02d-%02d", endMonth.year, endMonth.month, actualEndDay)
        
        // Days in start month from actualStartDay to end of start month
        let daysInStartMonth = startMonth.numberOfDays - actualStartDay + 1
        // Days in end month from 1 to actualEndDay
        let daysInEndMonth = actualEndDay
        let total = daysInStartMonth + daysInEndMonth
        
        return PayCycle(
            startDayOfMonth: clampedPayday,
            startDateString: startStr,
            endDateString: endStr,
            totalDays: total
        )
    }
    
    /// Checks whether a canonical day string (YYYY-MM-DD) falls within this pay cycle.
    public func contains(dayString: String) -> Bool {
        return dayString >= startDateString && dayString <= endDateString
    }
    
    /// Calculates days remaining in this cycle from a reference date (YYYY-MM-DD), inclusive.
    public func daysRemaining(asOf todayString: String) -> Int {
        guard todayString <= endDateString else { return 0 }
        guard todayString >= startDateString else { return totalDays }
        
        // Count inclusive days between todayString and endDateString
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        
        guard let today = df.date(from: todayString),
              let end = df.date(from: endDateString) else {
            return max(1, totalDays)
        }
        
        let components = Calendar.current.dateComponents([.day], from: today, to: end)
        return max(1, (components.day ?? 0) + 1)
    }
    
    /// User-facing display title for the cycle (e.g. "Sep 25 - Oct 24").
    public var displayTitle: String {
        let dfIn = DateFormatter()
        dfIn.dateFormat = "yyyy-MM-dd"
        dfIn.locale = Locale(identifier: "en_US_POSIX")
        
        let dfOut = DateFormatter()
        dfOut.dateFormat = "MMM d"
        dfOut.locale = Locale(identifier: "en_US")
        
        if let s = dfIn.date(from: startDateString), let e = dfIn.date(from: endDateString) {
            return "\(dfOut.string(from: s)) - \(dfOut.string(from: e))"
        }
        return "\(startDateString) to \(endDateString)"
    }
}
