import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

@main
struct ExpenseTrackerApp: App {
    private let store: LocalFileStore
    private let profileRepository: LocalUserProfileRepository
    private let transactionRepository: LocalTransactionRepository
    private let categoryRepository: LocalCategoryRepository
    private let budgetRepository: LocalBudgetRepository
    private let recurringRuleRepository: LocalRecurringRuleRepository
    
    @State private var currentProfile: UserProfile?
    @State private var isLoading = true
    
    init() {
        let fileStore = LocalFileStore()
        self.store = fileStore
        self.profileRepository = LocalUserProfileRepository(store: fileStore)
        self.transactionRepository = LocalTransactionRepository(store: fileStore)
        self.categoryRepository = LocalCategoryRepository(store: fileStore)
        self.budgetRepository = LocalBudgetRepository(store: fileStore)
        self.recurringRuleRepository = LocalRecurringRuleRepository(store: fileStore)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = currentProfile, profile.onboardingCompleted {
                    RootTabView(
                        userProfile: profile,
                        transactionRepository: transactionRepository,
                        categoryRepository: categoryRepository,
                        budgetRepository: budgetRepository,
                        recurringRuleRepository: recurringRuleRepository,
                        userProfileRepository: profileRepository,
                        fileStore: store,
                        onResetData: {
                            withAnimation {
                                self.currentProfile = nil
                            }
                        }
                    )
                } else {
                    OnboardingView(profileRepository: profileRepository) { completedProfile in
                        withAnimation {
                            self.currentProfile = completedProfile
                        }
                    }
                }
            }
            .task {
                do {
                    let profile = try await profileRepository.getProfile()
                    // Seed categories on initial startup
                    _ = try await categoryRepository.list(includeArchived: false)
                    await MainActor.run {
                        self.currentProfile = profile
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.currentProfile = .default
                        self.isLoading = false
                    }
                }
            }
        }
    }
}
