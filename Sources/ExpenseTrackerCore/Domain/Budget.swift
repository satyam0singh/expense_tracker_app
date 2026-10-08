import Foundation

/// Represents a configured spending limit for a calendar month.
/// Invariants:
/// - limitMinor is >= 0.
/// - Currency must match transactions compared against it.
public struct Budget: Identifiable, Equatable, Hashable, Sendable, Codable {
    public let id: UUID
    public var month: CalendarMonth
    public var limitMinor: Int64
    public var currencyCode: String
    public var warningThresholdPercent: Int?
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        month: CalendarMonth,
        limitMinor: Int64,
        currencyCode: String = "INR",
        warningThresholdPercent: Int? = 80,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        precondition(limitMinor >= 0, "Budget limitMinor must be non-negative.")
        if let warning = warningThresholdPercent {
            precondition(warning >= 1 && warning <= 100, "Warning threshold must be between 1 and 100 percent.")
        }
        self.id = id
        self.month = month
        self.limitMinor = limitMinor
        self.currencyCode = currencyCode
        self.warningThresholdPercent = warningThresholdPercent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
