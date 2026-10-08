import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

public struct RootTabView: View {
    public let userProfile: UserProfile
    public let transactionRepository: TransactionRepositoryProtocol
    public let categoryRepository: CategoryRepositoryProtocol
    public let budgetRepository: BudgetRepositoryProtocol
    public let recurringRuleRepository: RecurringRuleRepositoryProtocol?
    public let userProfileRepository: UserProfileRepositoryProtocol?
    public let fileStore: LocalFileStore?
    public let onResetData: (() -> Void)?
    
    public init(
        userProfile: UserProfile,
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        budgetRepository: BudgetRepositoryProtocol,
        recurringRuleRepository: RecurringRuleRepositoryProtocol? = nil,
        userProfileRepository: UserProfileRepositoryProtocol? = nil,
        fileStore: LocalFileStore? = nil,
        onResetData: (() -> Void)? = nil
    ) {
        self.userProfile = userProfile
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.budgetRepository = budgetRepository
        self.recurringRuleRepository = recurringRuleRepository
        self.userProfileRepository = userProfileRepository
        self.fileStore = fileStore
        self.onResetData = onResetData
    }
    
    @State private var isAddPresentedFromDeepLink = false
    @State private var isVoicePresentedFromDeepLink = false
    
    public var body: some View {
        TabView {
            HomeView(
                userProfile: userProfile,
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository,
                budgetRepository: budgetRepository,
                recurringRuleRepository: recurringRuleRepository
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .accessibilityLabel("Home Tab")
            .accessibilityHint("Shows monthly budget remaining and actual cash flow")
            
            ActivityView(
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository,
                currencyCode: userProfile.defaultCurrencyCode
            )
            .tabItem {
                Label("Activity", systemImage: "list.bullet.rectangle")
            }
            .accessibilityLabel("Activity Tab")
            .accessibilityHint("Shows transaction history and search")
            
            BudgetsView(
                budgetRepository: budgetRepository,
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository,
                currencyCode: userProfile.defaultCurrencyCode
            )
            .tabItem {
                Label("Budgets", systemImage: "chart.pie.fill")
            }
            .accessibilityLabel("Budgets Tab")
            .accessibilityHint("Shows monthly and category budget configuration")
            
            SettingsView(
                userProfile: userProfile,
                userProfileRepository: userProfileRepository,
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository,
                recurringRuleRepository: recurringRuleRepository,
                fileStore: fileStore,
                onResetData: onResetData
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .accessibilityLabel("Settings Tab")
            .accessibilityHint("Shows preferences, privacy status, and app information")
        }
        .onOpenURL { url in
            let action = (url.host ?? "") + url.path
            if action.contains("add-expense") {
                isAddPresentedFromDeepLink = true
            } else if action.contains("voice-capture") {
                isVoicePresentedFromDeepLink = true
            }
        }
        .sheet(isPresented: $isAddPresentedFromDeepLink) {
            AddEditTransactionView(
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository,
                currencyCode: userProfile.defaultCurrencyCode
            )
        }
        .sheet(isPresented: $isVoicePresentedFromDeepLink) {
            VoiceCaptureSheet(
                transactionRepository: transactionRepository,
                categoryRepository: categoryRepository,
                currencyCode: userProfile.defaultCurrencyCode
            )
        }
    }
}
