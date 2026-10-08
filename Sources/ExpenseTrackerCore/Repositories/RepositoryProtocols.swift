import Foundation

/// Repository contract for transaction CRUD operations.
/// Persistence implementation is deferred until the deployment target and data-store decision (ADR-008) are confirmed.
public protocol TransactionRepositoryProtocol: Sendable {
    func add(draft: TransactionDraft) async throws -> Transaction
    func update(id: UUID, draft: TransactionDraft) async throws -> Transaction
    func delete(id: UUID) async throws
    func undoDelete(id: UUID) async throws
    func list(month: CalendarMonth) async throws -> [Transaction]
    func listAll(includeDeleted: Bool) async throws -> [Transaction]
    func get(id: UUID) async throws -> Transaction?
}

/// Repository contract for category management.
public protocol CategoryRepositoryProtocol: Sendable {
    func list(includeArchived: Bool) async throws -> [Category]
    func create(category: Category) async throws -> Category
    func update(category: Category) async throws -> Category
    func archive(id: UUID) async throws
}

/// Repository contract for monthly budget configurations.
public protocol BudgetRepositoryProtocol: Sendable {
    func get(month: CalendarMonth) async throws -> Budget?
    func save(budget: Budget) async throws
}

/// Repository contract for recurring commitments and subscription schedules.
public protocol RecurringRuleRepositoryProtocol: Sendable {
    func list(activeOnly: Bool) async throws -> [RecurringRule]
    func create(rule: RecurringRule) async throws -> RecurringRule
    func update(rule: RecurringRule) async throws -> RecurringRule
    func delete(id: UUID) async throws
    func toggleActive(id: UUID) async throws -> RecurringRule?
    func advanceDueDate(id: UUID) async throws -> RecurringRule?
}

