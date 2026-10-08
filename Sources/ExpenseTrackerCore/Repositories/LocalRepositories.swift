import Foundation

// MARK: - UserProfile Repository

public final class LocalUserProfileRepository: UserProfileRepositoryProtocol {
    private let store: LocalFileStore
    private let filename = "profile.json"
    
    public init(store: LocalFileStore) {
        self.store = store
    }
    
    public func getProfile() async throws -> UserProfile {
        if let existing = try await store.load(UserProfile.self, filename: filename) {
            return existing
        }
        let initial = UserProfile.default
        try await store.save(initial, filename: filename)
        return initial
    }
    
    public func updateProfile(_ profile: UserProfile) async throws {
        var updated = profile
        updated.updatedAt = Date()
        try await store.save(updated, filename: filename)
    }
    
    public func completeOnboarding(
        currencyCode: String,
        displayName: String?,
        expectedIncomeMinor: Int64?,
        monthlyBudgetMinor: Int64?
    ) async throws -> UserProfile {
        var profile = try await getProfile()
        profile.defaultCurrencyCode = currencyCode.uppercased()
        profile.displayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.expectedMonthlyIncomeMinor = expectedIncomeMinor
        profile.monthlyBudgetLimitMinor = monthlyBudgetMinor
        profile.onboardingCompleted = true
        profile.updatedAt = Date()
        try await store.save(profile, filename: filename)
        return profile
    }
}

// MARK: - Category Repository

public final class LocalCategoryRepository: CategoryRepositoryProtocol {
    private let store: LocalFileStore
    private let filename = "categories.json"
    
    public init(store: LocalFileStore) {
        self.store = store
    }
    
    public func list(includeArchived: Bool = false) async throws -> [Category] {
        var categories = try await loadCategories()
        if categories.isEmpty {
            // Seed starter categories once on first launch
            categories = Category.starterCategories
            try await store.save(categories, filename: filename)
        }
        
        let filtered = includeArchived ? categories : categories.filter { !$0.isArchived }
        return filtered.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    public func create(category: Category) async throws -> Category {
        var categories = try await list(includeArchived: true)
        var newCat = category
        newCat.sortOrder = (categories.map(\.sortOrder).max() ?? 0) + 1
        categories.append(newCat)
        try await store.save(categories, filename: filename)
        return newCat
    }
    
    public func update(category: Category) async throws -> Category {
        var categories = try await list(includeArchived: true)
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            throw ValidationError.missingRequiredField("Category with id \(category.id) not found")
        }
        var updated = category
        updated.updatedAt = Date()
        categories[index] = updated
        try await store.save(categories, filename: filename)
        return updated
    }
    
    public func archive(id: UUID) async throws {
        var categories = try await list(includeArchived: true)
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            return
        }
        categories[index].isArchived = true
        categories[index].updatedAt = Date()
        try await store.save(categories, filename: filename)
    }
    
    private func loadCategories() async throws -> [Category] {
        return (try await store.load([Category].self, filename: filename)) ?? []
    }
}

// MARK: - Transaction Repository

public final class LocalTransactionRepository: TransactionRepositoryProtocol {
    private let store: LocalFileStore
    private let filename = "transactions.json"
    
    public init(store: LocalFileStore) {
        self.store = store
    }
    
    public func add(draft: TransactionDraft) async throws -> Transaction {
        let transaction = try draft.validate()
        var all = try await loadAll()
        all.append(transaction)
        try await store.save(all, filename: filename)
        return transaction
    }
    
    public func update(id: UUID, draft: TransactionDraft) async throws -> Transaction {
        let validated = try draft.validate()
        var all = try await loadAll()
        guard let index = all.firstIndex(where: { $0.id == id && !$0.isDeleted }) else {
            throw ValidationError.missingRequiredField("Active transaction \(id) not found")
        }
        var updated = validated
        updated.updatedAt = Date()
        all[index] = updated
        try await store.save(all, filename: filename)
        return updated
    }
    
    public func delete(id: UUID) async throws {
        var all = try await loadAll()
        guard let index = all.firstIndex(where: { $0.id == id }) else {
            return
        }
        all[index].deletedAt = Date()
        all[index].updatedAt = Date()
        try await store.save(all, filename: filename)
    }
    
    public func undoDelete(id: UUID) async throws {
        var all = try await loadAll()
        guard let index = all.firstIndex(where: { $0.id == id }) else {
            return
        }
        all[index].deletedAt = nil
        all[index].updatedAt = Date()
        try await store.save(all, filename: filename)
    }
    
    public func list(month: CalendarMonth) async throws -> [Transaction] {
        let all = try await loadAll()
        return all
            .filter { !$0.isDeleted }
            .filter { month.contains(dayString: $0.transactionDay) }
            .sorted { $0.transactionDay > $1.transactionDay }
    }
    
    public func listAll(includeDeleted: Bool = false) async throws -> [Transaction] {
        let all = try await loadAll()
        if includeDeleted {
            return all.sorted { $0.transactionDay > $1.transactionDay }
        } else {
            return all.filter { !$0.isDeleted }.sorted { $0.transactionDay > $1.transactionDay }
        }
    }
    
    public func get(id: UUID) async throws -> Transaction? {
        let all = try await loadAll()
        return all.first { $0.id == id && !$0.isDeleted }
    }
    
    private func loadAll() async throws -> [Transaction] {
        return (try await store.load([Transaction].self, filename: filename)) ?? []
    }
}

// MARK: - Budget Repository

public final class LocalBudgetRepository: BudgetRepositoryProtocol {
    private let store: LocalFileStore
    private let filename = "budgets.json"
    
    public init(store: LocalFileStore) {
        self.store = store
    }
    
    public func get(month: CalendarMonth) async throws -> Budget? {
        let all = try await loadAll()
        return all.first { $0.month == month }
    }
    
    public func save(budget: Budget) async throws {
        var all = try await loadAll()
        if let index = all.firstIndex(where: { $0.month == budget.month }) {
            var updated = budget
            updated.updatedAt = Date()
            all[index] = updated
        } else {
            all.append(budget)
        }
        try await store.save(all, filename: filename)
    }
    
    private func loadAll() async throws -> [Budget] {
        return (try await store.load([Budget].self, filename: filename)) ?? []
    }
}

// MARK: - RecurringRule Repository

public final class LocalRecurringRuleRepository: RecurringRuleRepositoryProtocol {
    private let store: LocalFileStore
    private let filename = "recurring_rules.json"
    
    public init(store: LocalFileStore) {
        self.store = store
    }
    
    public func list(activeOnly: Bool = false) async throws -> [RecurringRule] {
        let all = try await loadAll()
        let filtered = activeOnly ? all.filter { $0.isActive } : all
        return filtered.sorted { $0.nextDueDate < $1.nextDueDate }
    }
    
    public func create(rule: RecurringRule) async throws -> RecurringRule {
        var all = try await loadAll()
        all.append(rule)
        try await store.save(all, filename: filename)
        return rule
    }
    
    public func update(rule: RecurringRule) async throws -> RecurringRule {
        var all = try await loadAll()
        guard let index = all.firstIndex(where: { $0.id == rule.id }) else {
            throw ValidationError.missingRequiredField("Recurring rule \(rule.id) not found")
        }
        var updated = rule
        updated.updatedAt = Date()
        all[index] = updated
        try await store.save(all, filename: filename)
        return updated
    }
    
    public func delete(id: UUID) async throws {
        var all = try await loadAll()
        all.removeAll { $0.id == id }
        try await store.save(all, filename: filename)
    }
    
    public func toggleActive(id: UUID) async throws -> RecurringRule? {
        var all = try await loadAll()
        guard let index = all.firstIndex(where: { $0.id == id }) else { return nil }
        all[index].isActive.toggle()
        all[index].updatedAt = Date()
        let updated = all[index]
        try await store.save(all, filename: filename)
        return updated
    }
    
    public func advanceDueDate(id: UUID) async throws -> RecurringRule? {
        var all = try await loadAll()
        guard let index = all.firstIndex(where: { $0.id == id }) else { return nil }
        all[index] = all[index].advanced()
        let updated = all[index]
        try await store.save(all, filename: filename)
        return updated
    }
    
    private func loadAll() async throws -> [RecurringRule] {
        return (try await store.load([RecurringRule].self, filename: filename)) ?? []
    }
}

