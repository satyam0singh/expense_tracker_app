import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

#if canImport(AppIntents)
import AppIntents

/// App Intent for recording an expense via Siri voice commands or iOS Shortcuts.
public struct LogExpenseIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log Expense"
    public static var description = IntentDescription("Records an expense into Expense Tracker.")
    public static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Amount", description: "Expense amount in major currency units (e.g. 15.50)")
    public var amount: Double
    
    @Parameter(title: "Category", description: "Category name (e.g. Groceries, Food, Transport)")
    public var category: String?
    
    @Parameter(title: "Note", description: "Optional note or merchant details")
    public var note: String?
    
    @Parameter(title: "Payment Method", description: "Cash, Card, UPI, etc.")
    public var paymentMethod: String?
    
    public init() {}
    
    public init(amount: Double, category: String? = nil, note: String? = nil, paymentMethod: String? = nil) {
        self.amount = amount
        self.category = category
        self.note = note
        self.paymentMethod = paymentMethod
    }
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = LocalFileStore()
        let profileRepo = LocalUserProfileRepository(store: store)
        let txRepo = LocalTransactionRepository(store: store)
        let catRepo = LocalCategoryRepository(store: store)
        let budgetRepo = LocalBudgetRepository(store: store)
        let ruleRepo = LocalRecurringRuleRepository(store: store)
        let widgetStore = WidgetDataStore()
        
        let profile = (try? await profileRepo.getProfile()) ?? .default
        
        do {
            let result = try await LogExpenseIntentHandler.handle(
                amountMajor: amount,
                categoryName: category,
                note: note,
                paymentMethodName: paymentMethod,
                userProfile: profile,
                transactionRepository: txRepo,
                categoryRepository: catRepo,
                budgetRepository: budgetRepo,
                recurringRuleRepository: ruleRepo,
                widgetDataStore: widgetStore
            )
            return .result(dialog: IntentDialog(stringLiteral: result.confirmationMessage))
        } catch {
            return .result(dialog: IntentDialog("Could not record expense: \(error.localizedDescription)"))
        }
    }
}

/// App Intent for querying today's safe-to-spend target via Siri.
public struct ViewSafeToSpendIntent: AppIntent {
    public static var title: LocalizedStringResource = "Check Safe-to-Spend"
    public static var description = IntentDescription("Checks today's estimated safe-to-spend target.")
    public static var openAppWhenRun: Bool = false
    
    public init() {}
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let widgetStore = WidgetDataStore()
        if let snapshot = await widgetStore.loadSnapshot(),
           let safeToday = snapshot.formattedSafeToSpendToday {
            return .result(dialog: IntentDialog("You have \(safeToday) safe to spend today. This is a planning target, not an account balance."))
        } else {
            return .result(dialog: IntentDialog("Safe-to-spend is not configured yet. Set a budget or payday in Expense Tracker."))
        }
    }
}

/// App Intent to open the Add Expense screen directly.
public struct OpenAddExpenseIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Add Expense"
    public static var description = IntentDescription("Opens Expense Tracker directly to the Add Expense screen.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

/// App Intent to open the Voice Recording screen directly.
public struct OpenVoiceCaptureIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Voice Log"
    public static var description = IntentDescription("Opens Expense Tracker directly to the Voice Recording screen.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

/// Exposes pre-packaged App Shortcuts for Siri and the Shortcuts app.
public struct ExpenseTrackerShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add an expense in \(.applicationName)",
                "Record expense in \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "plus.circle.fill"
        )
        
        AppShortcut(
            intent: ViewSafeToSpendIntent(),
            phrases: [
                "What's my safe to spend in \(.applicationName)",
                "Safe to spend in \(.applicationName)"
            ],
            shortTitle: "Safe-to-Spend",
            systemImageName: "sparkles"
        )
        
        AppShortcut(
            intent: OpenVoiceCaptureIntent(),
            phrases: [
                "Voice expense in \(.applicationName)",
                "Speak an expense in \(.applicationName)"
            ],
            shortTitle: "Voice Log",
            systemImageName: "mic.fill"
        )
    }
}
#endif
