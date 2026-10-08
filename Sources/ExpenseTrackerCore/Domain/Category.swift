import Foundation

/// Represents a transaction classification.
public struct Category: Identifiable, Equatable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String
    public var iconKey: String
    public var sortOrder: Int
    public var isDefault: Bool
    public var isArchived: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        iconKey: String = "tag",
        sortOrder: Int = 0,
        isDefault: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconKey = iconKey
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Starter default categories per docs/00_PRODUCT_BRAIN.md section "India-friendly defaults"
    public static let starterCategories: [Category] = [
        Category(name: "Food & Drink", iconKey: "fork.knife", sortOrder: 1, isDefault: true),
        Category(name: "Groceries", iconKey: "cart", sortOrder: 2, isDefault: true),
        Category(name: "Transport", iconKey: "car", sortOrder: 3, isDefault: true),
        Category(name: "Shopping", iconKey: "bag", sortOrder: 4, isDefault: true),
        Category(name: "Bills", iconKey: "doc.text", sortOrder: 5, isDefault: true),
        Category(name: "Health", iconKey: "cross.case", sortOrder: 6, isDefault: true),
        Category(name: "Education", iconKey: "book", sortOrder: 7, isDefault: true),
        Category(name: "Travel", iconKey: "airplane", sortOrder: 8, isDefault: true),
        Category(name: "Personal", iconKey: "person", sortOrder: 9, isDefault: true),
        Category(name: "Other", iconKey: "ellipsis.circle", sortOrder: 10, isDefault: true)
    ]
}
