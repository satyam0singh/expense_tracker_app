import SwiftUI
import ExpenseTrackerCore

public struct RecurringRulesView: View {
    private let ruleRepository: RecurringRuleRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let currencyCode: String
    
    @State private var rules: [RecurringRule] = []
    @State private var isLoading = true
    @State private var showingAddSheet = false
    @State private var editingRule: RecurringRule?
    @State private var ruleToPost: RecurringRule?
    @State private var showingPostConfirmation = false
    @State private var bannerMessage: String?
    
    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
    
    private var todayString: String {
        dayFormatter.string(from: Date())
    }
    
    public init(
        ruleRepository: RecurringRuleRepositoryProtocol,
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        currencyCode: String = "INR"
    ) {
        self.ruleRepository = ruleRepository
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.currencyCode = currencyCode
    }
    
    private var dueRules: [RecurringRule] {
        rules.filter { $0.isActive && $0.isDue(asOf: todayString) }
    }
    
    private var upcomingRules: [RecurringRule] {
        rules.filter { $0.isActive && !$0.isDue(asOf: todayString) }
    }
    
    private var pausedRules: [RecurringRule] {
        rules.filter { !$0.isActive }
    }
    
    public var body: some View {
        List {
            if let banner = bannerMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(banner)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // MARK: - Due Now Section
            if !dueRules.isEmpty {
                Section(header: Text("Due Now / Action Needed").foregroundStyle(.orange)) {
                    ForEach(dueRules) { rule in
                        dueRuleRow(rule)
                    }
                }
            }
            
            // MARK: - Upcoming Section
            if !upcomingRules.isEmpty {
                Section(header: Text("Upcoming Schedules")) {
                    ForEach(upcomingRules) { rule in
                        ruleRow(rule)
                    }
                }
            }
            
            // MARK: - Paused Section
            if !pausedRules.isEmpty {
                Section(header: Text("Paused")) {
                    ForEach(pausedRules) { rule in
                        ruleRow(rule)
                    }
                }
            }
            
            // MARK: - Empty State
            if rules.isEmpty && !isLoading {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                        Text("No Recurring Commitments")
                            .font(.headline)
                        Text("Track regular bills, rent, subscriptions, or salaries. A schedule acts as a reminder and will never post an expense without your explicit confirmation.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Recurring Items")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Recurring Commitment")
            }
        }
        .task {
            await loadRules()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditRecurringRuleView(
                ruleRepository: ruleRepository,
                categoryRepository: categoryRepository,
                currencyCode: currencyCode
            ) { _ in
                Task { await loadRules() }
            }
        }
        .sheet(item: $editingRule) { rule in
            AddEditRecurringRuleView(
                ruleRepository: ruleRepository,
                categoryRepository: categoryRepository,
                currencyCode: currencyCode,
                existingRule: rule
            ) { _ in
                Task { await loadRules() }
            }
        }
        .confirmationDialog(
            "Post Recurring Transaction?",
            isPresented: $showingPostConfirmation,
            titleVisibility: .visible
        ) {
            if let rule = ruleToPost {
                Button("Post & Advance Due Date") {
                    postTransaction(for: rule)
                }
                Button("Cancel", role: .cancel) {
                    ruleToPost = nil
                }
            }
        } message: {
            if let rule = ruleToPost {
                let amount = CurrencyFormatter.format(amountMinor: rule.amountMinor, currencyCode: rule.currencyCode)
                Text("This will record an actual \(rule.type.displayName.lowercased()) of \(amount) for date \(rule.nextDueDate) and advance the schedule.")
            }
        }
    }
    
    @ViewBuilder
    private func dueRuleRow(_ rule: RecurringRule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.title)
                        .font(.headline)
                    Text("Due: \(rule.nextDueDate) • \(rule.cadence.displayName)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Text(CurrencyFormatter.format(amountMinor: rule.amountMinor, currencyCode: rule.currencyCode))
                    .font(.headline)
                    .foregroundStyle(rule.type == .income ? .green : .primary)
            }
            
            HStack {
                Button {
                    ruleToPost = rule
                    showingPostConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(rule.type == .income ? "Record Income" : "Post as Paid")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .accessibilityLabel("Post transaction for \(rule.title)")
                
                Spacer()
                
                Button("Edit") {
                    editingRule = rule
                }
                .buttonStyle(.bordered)
                .font(.footnote)
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteRule(rule.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                toggleActive(rule.id)
            } label: {
                Label("Pause", systemImage: "pause.circle")
            }
            .tint(.orange)
        }
    }
    
    @ViewBuilder
    private func ruleRow(_ rule: RecurringRule) -> some View {
        Button {
            editingRule = rule
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.title)
                        .font(.headline)
                        .foregroundStyle(rule.isActive ? .primary : .secondary)
                    Text("\(rule.cadence.displayName) • Next: \(rule.nextDueDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(CurrencyFormatter.format(amountMinor: rule.amountMinor, currencyCode: rule.currencyCode))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(rule.isActive ? (rule.type == .income ? .green : .primary) : .secondary)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteRule(rule.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                toggleActive(rule.id)
            } label: {
                Label(rule.isActive ? "Pause" : "Resume", systemImage: rule.isActive ? "pause.circle" : "play.circle")
            }
            .tint(rule.isActive ? .orange : .green)
        }
    }
    
    private func loadRules() async {
        do {
            let loaded = try await ruleRepository.list(activeOnly: false)
            await MainActor.run {
                self.rules = loaded
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func postTransaction(for rule: RecurringRule) {
        Task {
            do {
                let draft = TransactionDraft(
                    type: rule.type,
                    amountMinor: rule.amountMinor,
                    currencyCode: rule.currencyCode,
                    categoryId: rule.categoryId,
                    categoryNameSnapshot: rule.categoryNameSnapshot,
                    merchant: rule.merchant,
                    note: rule.note ?? "Recurring: \(rule.title)",
                    transactionDay: rule.nextDueDate,
                    paymentMethod: rule.paymentMethod,
                    source: .recurring,
                    recurringRuleId: rule.id
                )
                _ = try await transactionRepository.add(draft: draft)
                _ = try await ruleRepository.advanceDueDate(id: rule.id)
                
                await loadRules()
                await MainActor.run {
                    self.bannerMessage = "Recorded transaction for \(rule.title)."
                }
            } catch {
                await MainActor.run {
                    self.bannerMessage = "Failed to post transaction."
                }
            }
        }
    }
    
    private func toggleActive(_ id: UUID) {
        Task {
            _ = try? await ruleRepository.toggleActive(id: id)
            await loadRules()
        }
    }
    
    private func deleteRule(_ id: UUID) {
        Task {
            try? await ruleRepository.delete(id: id)
            await loadRules()
        }
    }
}
