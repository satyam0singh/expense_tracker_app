import SwiftUI
import ExpenseTrackerCore

public struct HomeView: View {
    public let userProfile: UserProfile
    public let transactionRepository: TransactionRepositoryProtocol?
    public let categoryRepository: CategoryRepositoryProtocol?
    public let budgetRepository: BudgetRepositoryProtocol?
    public let recurringRuleRepository: RecurringRuleRepositoryProtocol?
    
    @State private var selectedMonth = CalendarMonth(date: Date())
    @State private var summary: BudgetSummary?
    @State private var recentTransactions: [Transaction] = []
    @State private var categories: [Category] = []
    @State private var dueRecurringCount: Int = 0
    @State private var safeToSpend: SafeToSpendCalculation?
    @State private var isAddPresented = false
    @State private var isVoicePresented = false
    @State private var isLoading = false
    
    public init(
        userProfile: UserProfile = .default,
        transactionRepository: TransactionRepositoryProtocol? = nil,
        categoryRepository: CategoryRepositoryProtocol? = nil,
        budgetRepository: BudgetRepositoryProtocol? = nil,
        recurringRuleRepository: RecurringRuleRepositoryProtocol? = nil
    ) {
        self.userProfile = userProfile
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.budgetRepository = budgetRepository
        self.recurringRuleRepository = recurringRuleRepository
    }
    
    private var currency: CurrencyCode {
        CurrencyCode.from(code: userProfile.defaultCurrencyCode)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month selector bar
                    HStack {
                        Button(action: {
                            selectedMonth = selectedMonth.previous()
                            loadData()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityLabel("Previous month")
                        
                        Spacer()
                        
                        Text(selectedMonth.displayTitle())
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedMonth = selectedMonth.next()
                            loadData()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityLabel("Next month")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Due Recurring Commitments Banner
                    if dueRecurringCount > 0,
                       let ruleRepo = recurringRuleRepository,
                       let txRepo = transactionRepository,
                       let catRepo = categoryRepository {
                        NavigationLink {
                            RecurringRulesView(
                                ruleRepository: ruleRepo,
                                transactionRepository: txRepo,
                                categoryRepository: catRepo,
                                currencyCode: userProfile.defaultCurrencyCode
                            )
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .foregroundStyle(.orange)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(dueRecurringCount) Recurring Item\(dueRecurringCount == 1 ? "" : "s") Due")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Text("Tap to review and post as transaction")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("\(dueRecurringCount) recurring items due. Tap to review and post.")
                    }
                    
                    // Safe-to-Spend / Available Until Payday Card
                    if let sts = safeToSpend {
                        SafeToSpendCard(calculation: sts)
                    }
                    
                    // Headline Card: Budget Remaining
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget Remaining")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if let sum = summary, let remaining = sum.budgetRemaining {
                            Text(CurrencyFormatter.format(money: remaining))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(sum.isOverBudget ? .red : .primary)
                        } else {
                            Text("No budget set")
                                .font(.title2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Configured budget limit minus eligible spending. Not an account balance.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Explanation: Configured budget limit minus eligible spending. This is not an account balance.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Actual Recorded Cash Flow Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actual Recorded Cash Flow")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            cashFlowTile(
                                title: "Recorded Income",
                                money: summary?.recordedIncome ?? Money.zero(currency: currency),
                                color: .green
                            )
                            cashFlowTile(
                                title: "Recorded Expenses",
                                money: summary?.recordedExpenses ?? Money.zero(currency: currency),
                                color: .orange
                            )
                        }
                    }
                    
                    // Planning Context Card (if configured during onboarding)
                    if let expectedIncome = userProfile.expectedMonthlyIncomeMinor {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Expected Monthly Income (Planning)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(CurrencyFormatter.format(money: Money(amountMinor: expectedIncome, currency: currency)))
                                    .font(.subheadline.weight(.semibold))
                            }
                            Spacer()
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .accessibilityLabel("Planning reference: Expected monthly income \(CurrencyFormatter.format(money: Money(amountMinor: expectedIncome, currency: currency))). This is not recorded actual income.")
                    }
                    
                    // Recent Transactions Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.headline)
                            Spacer()
                            Button("Add") {
                                isAddPresented = true
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        
                        if recentTransactions.isEmpty {
                            VStack(spacing: 8) {
                                Text("No transactions in \(selectedMonth.displayTitle())")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Button("Record First Transaction") {
                                    isAddPresented = true
                                }
                                .font(.footnote.weight(.medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(recentTransactions.prefix(5)) { tx in
                                    TransactionRowView(transaction: tx, categories: categories)
                                    if tx.id != recentTransactions.prefix(5).last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { isVoicePresented = true }) {
                        Image(systemName: "mic.fill")
                    }
                    .accessibilityLabel("Speak Transaction")
                    
                    Button(action: { isAddPresented = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Transaction")
                }
            }
            .sheet(isPresented: $isAddPresented) {
                if let txRepo = transactionRepository, let catRepo = categoryRepository {
                    AddEditTransactionView(
                        transactionRepository: txRepo,
                        categoryRepository: catRepo,
                        currencyCode: userProfile.defaultCurrencyCode,
                        onSaved: { _ in loadData() }
                    )
                }
            }
            .sheet(isPresented: $isVoicePresented) {
                if let txRepo = transactionRepository, let catRepo = categoryRepository {
                    VoiceCaptureSheet(
                        transactionRepository: txRepo,
                        categoryRepository: catRepo,
                        currencyCode: userProfile.defaultCurrencyCode,
                        onSaved: { _ in loadData() }
                    )
                }
            }
            .onAppear(perform: loadData)
        }
    }
    
    private func loadData() {
        guard let txRepo = transactionRepository else {
            self.summary = BudgetSummary.calculate(
                for: selectedMonth,
                currency: currency,
                budgetLimitMinor: userProfile.monthlyBudgetLimitMinor,
                transactions: []
            )
            return
        }
        
        isLoading = true
        Task {
            let txs = (try? await txRepo.list(month: selectedMonth)) ?? []
            let cats = (try? await categoryRepository?.list(includeArchived: false)) ?? []
            let budget = try? await budgetRepository?.get(month: selectedMonth)
            let limitMinor = budget?.limitMinor ?? userProfile.monthlyBudgetLimitMinor
            
            let calculated = BudgetSummary.calculate(
                for: selectedMonth,
                currency: currency,
                budgetLimitMinor: limitMinor,
                transactions: txs
            )
            
            var dueCount = 0
            var computedSTS: SafeToSpendCalculation?
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            let today = df.string(from: Date())
            
            if let ruleRepo = recurringRuleRepository {
                let rules = (try? await ruleRepo.list(activeOnly: true)) ?? []
                dueCount = rules.filter { $0.isDue(asOf: today) }.count
                
                let pool = limitMinor ?? userProfile.expectedMonthlyIncomeMinor
                if let startingPool = pool, startingPool > 0 {
                    let cycle = PayCycle.active(for: today, paydayOfMonth: userProfile.payCycleStartDay)
                    let allTxs = (try? await txRepo.listAll(includeDeleted: false)) ?? txs
                    computedSTS = SafeToSpendCalculation.compute(
                        payCycle: cycle,
                        asOfDate: today,
                        currency: currency,
                        basis: limitMinor != nil ? .budgetLimit : .expectedIncome,
                        startingPoolMinor: startingPool,
                        transactions: allTxs,
                        recurringRules: rules
                    )
                }
            }
            
            // Refresh shared widget snapshot
            let allForSnapshot = (try? await txRepo.listAll(includeDeleted: false)) ?? txs
            let rulesForSnapshot = (try? await recurringRuleRepository?.list(activeOnly: true)) ?? []
            let snapshot = WidgetSnapshotGenerator.generate(
                userProfile: userProfile,
                month: selectedMonth,
                budget: budget,
                transactions: allForSnapshot,
                categories: cats,
                recurringRules: rulesForSnapshot,
                asOfDate: Date()
            )
            try? await WidgetDataStore().saveSnapshot(snapshot)
            
            await MainActor.run {
                self.transactionsOrRecent(txs)
                self.categories = cats
                self.summary = calculated
                self.dueRecurringCount = dueCount
                self.safeToSpend = computedSTS
                self.isLoading = false
            }
        }
    }
    
    private func transactionsOrRecent(_ all: [Transaction]) {
        self.recentTransactions = all.sorted { $0.transactionDay > $1.transactionDay }
    }
    
    private func cashFlowTile(title: String, money: Money, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(CurrencyFormatter.format(money: money))
                .font(.headline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
