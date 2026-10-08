import SwiftUI
import ExpenseTrackerCore

public struct BudgetsView: View {
    public let budgetRepository: BudgetRepositoryProtocol?
    public let transactionRepository: TransactionRepositoryProtocol?
    public let categoryRepository: CategoryRepositoryProtocol?
    public let currencyCode: String
    
    @State private var selectedMonth = CalendarMonth(date: Date())
    @State private var currentBudget: Budget?
    @State private var summary: BudgetSummary?
    @State private var categorySummaries: [CategorySpendSummary] = []
    
    @State private var isSetBudgetPresented = false
    @State private var isLoading = false
    
    public init(
        budgetRepository: BudgetRepositoryProtocol? = nil,
        transactionRepository: TransactionRepositoryProtocol? = nil,
        categoryRepository: CategoryRepositoryProtocol? = nil,
        currencyCode: String = "INR"
    ) {
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.currencyCode = currencyCode
    }
    
    private var currency: CurrencyCode {
        CurrencyCode.from(code: currencyCode)
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
                    
                    // Month Trends & Shifts Shortcut
                    if let txRepo = transactionRepository, let catRepo = categoryRepository {
                        NavigationLink {
                            TrendsView(
                                transactionRepository: txRepo,
                                categoryRepository: catRepo,
                                currencyCode: currencyCode
                            )
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundStyle(.blue)
                                Text("Month Trends & Category Shifts")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("View Month Trends and Category Shifts")
                    }
                    
                    // Main Budget Overview Card
                    if let budget = currentBudget, let sum = summary {
                        configuredBudgetCard(budget: budget, summary: sum)
                    } else {
                        noBudgetCard
                    }
                    
                    // Category Breakdown Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Spending by Category")
                            .font(.headline)
                        
                        if categorySummaries.isEmpty {
                            VStack(spacing: 8) {
                                Text("No category spending in \(selectedMonth.displayTitle())")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(categorySummaries) { catSummary in
                                    categorySpendRow(catSummary)
                                    if catSummary.id != categorySummaries.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Calculation Transparency Footer
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How this is calculated")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        Text("Budget remaining is your configured limit minus eligible spending (expenses net of refunds). Income and account transfers are never mixed into spending totals.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
                    
                    Spacer(minLength: 24)
                }
                .padding()
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(currentBudget == nil ? "Set Limit" : "Edit") {
                        isSetBudgetPresented = true
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .sheet(isPresented: $isSetBudgetPresented) {
                if let repo = budgetRepository {
                    SetBudgetView(
                        budgetRepository: repo,
                        month: selectedMonth,
                        currencyCode: currencyCode,
                        existingBudget: currentBudget,
                        onSaved: { _ in loadData() }
                    )
                }
            }
            .onAppear(perform: loadData)
        }
    }
    
    // MARK: - View Components
    
    private func configuredBudgetCard(budget: Budget, summary: BudgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Monthly Budget")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(CurrencyFormatter.format(money: Money(amountMinor: budget.limitMinor, currency: currency)))
                        .font(.title2.weight(.bold))
                }
                
                Spacer()
                
                Button("Edit") {
                    isSetBudgetPresented = true
                }
                .font(.subheadline.weight(.medium))
            }
            
            BudgetProgressBar(
                percentUsed: summary.budgetUsedPercent,
                warningThresholdPercent: budget.warningThresholdPercent,
                isOverBudget: summary.isOverBudget
            )
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent So Far")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(money: summary.netBudgetSpend))
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let remaining = summary.budgetRemaining {
                        Text(CurrencyFormatter.format(money: remaining))
                            .font(.headline)
                            .foregroundStyle(summary.isOverBudget ? .red : .primary)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var noBudgetCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No Budget for \(selectedMonth.displayTitle())")
                .font(.headline)
            
            Text("Set a monthly spending limit to track how much you have left and avoid overspending.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            Button("Set Monthly Budget") {
                isSetBudgetPresented = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func categorySpendRow(_ catSummary: CategorySpendSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: catSummary.iconKey)
                    .foregroundStyle(.orange)
                    .frame(width: 24)
                
                Text(catSummary.categoryName)
                    .font(.body.weight(.medium))
                
                Text("(\(catSummary.transactionCount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(CurrencyFormatter.format(money: catSummary.netSpend))
                    .font(.body.weight(.semibold))
            }
            
            // Category proportion track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.orange.opacity(0.8))
                        .frame(width: max(0, geo.size.width * catSummary.proportionOfTotal), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(catSummary.categoryName), \(CurrencyFormatter.format(money: catSummary.netSpend)), \(Int(catSummary.proportionOfTotal * 100)) percent of total spending")
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        guard let bRepo = budgetRepository, let txRepo = transactionRepository else { return }
        isLoading = true
        Task {
            let budget = try? await bRepo.get(month: selectedMonth)
            let txs = (try? await txRepo.list(month: selectedMonth)) ?? []
            let cats = (try? await categoryRepository?.list(includeArchived: true)) ?? []
            
            let calculatedSummary = BudgetSummary.calculate(
                for: selectedMonth,
                currency: currency,
                budgetLimitMinor: budget?.limitMinor,
                transactions: txs
            )
            
            let catSpend = CategorySpendSummary.compute(
                for: selectedMonth,
                currency: currency,
                transactions: txs,
                categories: cats
            )
            
            await MainActor.run {
                self.currentBudget = budget
                self.summary = calculatedSummary
                self.categorySummaries = catSpend
                self.isLoading = false
            }
        }
    }
}
