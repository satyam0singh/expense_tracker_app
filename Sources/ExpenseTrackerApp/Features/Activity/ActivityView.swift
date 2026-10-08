import SwiftUI
import ExpenseTrackerCore

public struct ActivityView: View {
    public let transactionRepository: TransactionRepositoryProtocol?
    public let categoryRepository: CategoryRepositoryProtocol?
    public let currencyCode: String
    
    @State private var selectedMonth = CalendarMonth(date: Date())
    @State private var transactions: [Transaction] = []
    @State private var categories: [Category] = []
    @State private var searchText = ""
    @State private var selectedTypeFilter: TransactionType? = nil
    @State private var selectedCategoryFilter: UUID? = nil
    
    @State private var isAddPresented = false
    @State private var isVoicePresented = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var recentlyDeletedTransactionId: UUID? = nil
    @State private var showUndoBanner = false
    @State private var isLoading = false
    
    public init(
        transactionRepository: TransactionRepositoryProtocol? = nil,
        categoryRepository: CategoryRepositoryProtocol? = nil,
        currencyCode: String = "INR"
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.currencyCode = currencyCode
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month selector bar
                HStack {
                    Button(action: {
                        selectedMonth = selectedMonth.previous()
                        loadData()
                    }) {
                        Image(systemName: "chevron.left")
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
                    }
                    .accessibilityLabel("Next month")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                
                // Filters: Type and Category
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "All", isSelected: selectedTypeFilter == nil && selectedCategoryFilter == nil) {
                            selectedTypeFilter = nil
                            selectedCategoryFilter = nil
                        }
                        
                        filterChip(title: "Expenses", isSelected: selectedTypeFilter == .expense) {
                            selectedTypeFilter = selectedTypeFilter == .expense ? nil : .expense
                        }
                        
                        filterChip(title: "Income", isSelected: selectedTypeFilter == .income) {
                            selectedTypeFilter = selectedTypeFilter == .income ? nil : .income
                        }
                        
                        ForEach(categories) { cat in
                            filterChip(title: cat.name, isSelected: selectedCategoryFilter == cat.id) {
                                selectedCategoryFilter = selectedCategoryFilter == cat.id ? nil : cat.id
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
                .background(Color(.tertiarySystemBackground))
                
                // Transactions List or Empty State
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(groupedDayKeys, id: \.self) { dayKey in
                            Section(header: Text(formattedSectionHeader(dayKey))) {
                                ForEach(transactionsForDay(dayKey)) { tx in
                                    TransactionRowView(transaction: tx, categories: categories)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            transactionToEdit = tx
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteTransaction(tx)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                
                // Undo banner
                if showUndoBanner {
                    HStack {
                        Text("Transaction deleted")
                            .font(.subheadline)
                        Spacer()
                        Button("Undo") {
                            undoDelete()
                        }
                        .font(.subheadline.weight(.bold))
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Activity")
            .searchable(text: $searchText, prompt: "Search merchant or notes")
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
                        currencyCode: currencyCode,
                        onSaved: { _ in loadData() }
                    )
                }
            }
            .sheet(isPresented: $isVoicePresented) {
                if let txRepo = transactionRepository, let catRepo = categoryRepository {
                    VoiceCaptureSheet(
                        transactionRepository: txRepo,
                        categoryRepository: catRepo,
                        currencyCode: currencyCode,
                        onSaved: { _ in loadData() }
                    )
                }
            }
            .sheet(item: $transactionToEdit) { tx in
                if let txRepo = transactionRepository, let catRepo = categoryRepository {
                    AddEditTransactionView(
                        transactionRepository: txRepo,
                        categoryRepository: catRepo,
                        currencyCode: currencyCode,
                        existingTransaction: tx,
                        onSaved: { _ in loadData() }
                    )
                }
            }
            .onAppear(perform: loadData)
        }
    }
    
    // MARK: - Filter Logic
    
    private var filteredTransactions: [Transaction] {
        transactions.filter { tx in
            // Search text filter
            if !searchText.isEmpty {
                let term = searchText.lowercased()
                let merchantMatch = tx.merchant?.lowercased().contains(term) ?? false
                let noteMatch = tx.note?.lowercased().contains(term) ?? false
                let catMatch = tx.categoryNameSnapshot?.lowercased().contains(term) ?? false
                if !merchantMatch && !noteMatch && !catMatch {
                    return false
                }
            }
            // Type filter
            if let type = selectedTypeFilter, tx.type != type {
                return false
            }
            // Category filter
            if let catId = selectedCategoryFilter, tx.categoryId != catId {
                return false
            }
            return true
        }
    }
    
    private var groupedDayKeys: [String] {
        let uniqueDays = Set(filteredTransactions.map(\.transactionDay))
        return uniqueDays.sorted(by: >)
    }
    
    private func transactionsForDay(_ day: String) -> [Transaction] {
        filteredTransactions.filter { $0.transactionDay == day }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(isSelected ? .bold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemFill))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            if !searchText.isEmpty || selectedTypeFilter != nil || selectedCategoryFilter != nil {
                Text("No matching transactions")
                    .font(.headline)
                Text("Try adjusting your search query or active filters.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Clear Filters") {
                    searchText = ""
                    selectedTypeFilter = nil
                    selectedCategoryFilter = nil
                }
                .font(.subheadline.weight(.semibold))
            } else {
                Text("No Transactions Recorded")
                    .font(.headline)
                Text("You haven't recorded any activity in \(selectedMonth.displayTitle()).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Add Transaction") {
                    isAddPresented = true
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Actions & Persistence
    
    private func loadData() {
        guard let txRepo = transactionRepository else { return }
        isLoading = true
        Task {
            let txs = (try? await txRepo.list(month: selectedMonth)) ?? []
            let cats = (try? await categoryRepository?.list(includeArchived: false)) ?? []
            await MainActor.run {
                self.transactions = txs
                self.categories = cats
                self.isLoading = false
            }
        }
    }
    
    private func deleteTransaction(_ tx: Transaction) {
        guard let txRepo = transactionRepository else { return }
        recentlyDeletedTransactionId = tx.id
        withAnimation {
            showUndoBanner = true
            transactions.removeAll { $0.id == tx.id }
        }
        Task {
            try? await txRepo.delete(id: tx.id)
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                withAnimation {
                    self.showUndoBanner = false
                    self.recentlyDeletedTransactionId = nil
                }
            }
        }
    }
    
    private func undoDelete() {
        guard let txRepo = transactionRepository, let id = recentlyDeletedTransactionId else { return }
        Task {
            try? await txRepo.undoDelete(id: id)
            await MainActor.run {
                withAnimation {
                    self.showUndoBanner = false
                    self.recentlyDeletedTransactionId = nil
                }
                self.loadData()
            }
        }
    }
    
    private func formattedSectionHeader(_ dayString: String) -> String {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let dayFormatter = DateFormatter()
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dayFormatter.date(from: dayString) else {
            return dayString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}
