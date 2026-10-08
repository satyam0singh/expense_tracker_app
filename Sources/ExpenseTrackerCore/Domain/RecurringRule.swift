import Foundation

/// Cadence frequency for recurring commitments.
public enum RecurrenceCadence: String, CaseIterable, Codable, Sendable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case biweekly = "BIWEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
    
    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

/// Represents a recurring financial commitment (e.g., rent, utility bill, salary, subscription).
/// Invariants per docs/00_PRODUCT_BRAIN.md and docs/05_DATABASE_API_SPEC.md:
/// - A RecurringRule is a planned commitment schedule, NEVER a posted transaction.
/// - Schedules NEVER inflate actual spending, income, or budget totals until explicitly posted.
/// - Silent automatic posting is forbidden; posting requires explicit user action/confirmation.
public struct RecurringRule: Identifiable, Equatable, Hashable, Sendable, Codable {
    public let id: UUID
    public var title: String
    public var type: TransactionType
    public var amountMinor: Int64
    public var currencyCode: String
    public var cadence: RecurrenceCadence
    public var nextDueDate: String // Canonical YYYY-MM-DD
    public var categoryId: UUID?
    public var categoryNameSnapshot: String?
    public var merchant: String?
    public var note: String?
    public var paymentMethod: PaymentMethod?
    public var isActive: Bool
    public var reminderEnabled: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        type: TransactionType = .expense,
        amountMinor: Int64,
        currencyCode: String = "INR",
        cadence: RecurrenceCadence = .monthly,
        nextDueDate: String,
        categoryId: UUID? = nil,
        categoryNameSnapshot: String? = nil,
        merchant: String? = nil,
        note: String? = nil,
        paymentMethod: PaymentMethod? = nil,
        isActive: Bool = true,
        reminderEnabled: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        precondition(amountMinor > 0, "Recurring amountMinor must be greater than zero.")
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.type = type
        self.amountMinor = amountMinor
        self.currencyCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.cadence = cadence
        self.nextDueDate = nextDueDate.trimmingCharacters(in: .whitespacesAndNewlines)
        self.categoryId = categoryId
        self.categoryNameSnapshot = categoryNameSnapshot
        self.merchant = merchant?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.paymentMethod = paymentMethod
        self.isActive = isActive
        self.reminderEnabled = reminderEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Checks whether the commitment is due as of the given day string (YYYY-MM-DD).
    public func isDue(asOf dayString: String) -> Bool {
        guard isActive else { return false }
        return nextDueDate <= dayString
    }
    
    /// Advances the next due date by the rule's cadence frequency.
    public func advanced() -> RecurringRule {
        var copy = self
        copy.nextDueDate = Self.calculateNextDueDate(from: nextDueDate, cadence: cadence)
        copy.updatedAt = Date()
        return copy
    }
    
    /// Computes the subsequent due date from a canonical day string (YYYY-MM-DD).
    /// Pure, deterministic algorithm with month-end day clamping (e.g. Jan 31 -> Feb 28).
    public static func calculateNextDueDate(from currentDay: String, cadence: RecurrenceCadence) -> String {
        let parts = currentDay.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return currentDay
        }
        
        switch cadence {
        case .daily:
            return advanceDays(year: year, month: month, day: day, daysToAdd: 1)
        case .weekly:
            return advanceDays(year: year, month: month, day: day, daysToAdd: 7)
        case .biweekly:
            return advanceDays(year: year, month: month, day: day, daysToAdd: 14)
        case .monthly:
            var nextMonth = month + 1
            var nextYear = year
            if nextMonth > 12 {
                nextMonth = 1
                nextYear += 1
            }
            let targetMonth = CalendarMonth(year: nextYear, month: nextMonth)
            let clampedDay = min(day, targetMonth.numberOfDays)
            return String(format: "%04d-%02d-%02d", nextYear, nextMonth, clampedDay)
        case .yearly:
            let nextYear = year + 1
            let targetMonth = CalendarMonth(year: nextYear, month: month)
            let clampedDay = min(day, targetMonth.numberOfDays)
            return String(format: "%04d-%02d-%02d", nextYear, month, clampedDay)
        }
    }
    
    private static func advanceDays(year: Int, month: Int, day: Int, daysToAdd: Int) -> String {
        var curYear = year
        var curMonth = month
        var curDay = day + daysToAdd
        
        while true {
            let daysInMonth = CalendarMonth(year: curYear, month: curMonth).numberOfDays
            if curDay <= daysInMonth {
                break
            }
            curDay -= daysInMonth
            curMonth += 1
            if curMonth > 12 {
                curMonth = 1
                curYear += 1
            }
        }
        return String(format: "%04d-%02d-%02d", curYear, curMonth, curDay)
    }
}
