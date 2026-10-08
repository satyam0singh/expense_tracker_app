import SwiftUI
#if canImport(ExpenseTrackerCore)
import ExpenseTrackerCore
#endif

public struct TrendsView: View {
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let currencyCode: String
    
    @State private var selectedMonth = CalendarMonth(date: Date())
    @State private var trends: TrendsSummary?
    @State private var isLoading = true
    
    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        currencyCode: String = "INR"
    ) {
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
                    // Month Navigation Bar
                    HStack {
                        Button {
                            selectedMonth = selectedMonth.previous()
                            loadTrends()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityLabel("Previous month")
                        
                        Spacer()
                        
                        Text(selectedMonth.displayTitle())
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        Spacer()
                        
                        Button {
                            selectedMonth = selectedMonth.next()
                            loadTrends()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityLabel("Next month")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    if isLoading {
                        ProgressView("Calculating factual trends...")
                            .padding(.vertical, 32)
                    } else if let summary = trends {
                        // Month-over-Month Overview Card
                        monthComparisonCard(summary)
                        
                        // Weekly Spending Rhythm
                        weeklyRhythmCard(summary)
                        
                        // Category Shifts
                        categoryTrendsSection(summary)
                        
                        // Factual Basis Disclosure Footer
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                Text("Factual Calculation Basis")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                            Text(summary.calculationBasisText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Trends & Shifts")
            .task {
                loadTrends()
            }
        }
    }
    
    @ViewBuilder
    private func monthComparisonCard(_ summary: TrendsSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Month-over-Month Pace")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
                Text(CurrencyFormatter.format(amountMinor: summary.currentMonthNetSpendMinor, currencyCode: currency.code))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Spacer()
                comparisonBadge(summary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Previous (\(summary.previousMonth.shortMonthName()))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.format(amountMinor: summary.previousMonthNetSpendMinor, currencyCode: currency.code))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Net Difference")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    let sign = summary.overallDeltaMinor > 0 ? "+" : ""
                    Text("\(sign)\(CurrencyFormatter.format(amountMinor: summary.overallDeltaMinor, currencyCode: currency.code))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(summary.overallDeltaMinor > 0 ? .orange : (summary.overallDeltaMinor < 0 ? .green : .secondary))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func comparisonBadge(_ summary: TrendsSummary) -> some View {
        switch summary.overallDirection {
        case .decreased:
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.right")
                if let pct = summary.overallPercentageChange {
                    Text(String(format: "%.1f%% lower", abs(pct)))
                } else {
                    Text("Lower spend")
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.green.opacity(0.15))
            .foregroundStyle(.green)
            .clipShape(Capsule())
        case .increased:
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                if let pct = summary.overallPercentageChange {
                    Text(String(format: "%.1f%% higher", pct))
                } else {
                    Text("Higher spend")
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.15))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
        case .unchanged:
            Text("Pace unchanged")
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.15))
                .foregroundStyle(.secondary)
                .clipShape(Capsule())
        case .newSpend:
            Text("First recorded spend")
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    private func weeklyRhythmCard(_ summary: TrendsSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Spending Rhythm")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            let maxWeekSpend = max(1, summary.weeklyBuckets.map(\.netSpendMinor).max() ?? 1)
            
            VStack(spacing: 10) {
                ForEach(summary.weeklyBuckets) { bucket in
                    HStack(spacing: 12) {
                        Text("W\(bucket.weekNumber)")
                            .font(.caption.weight(.bold))
                            .frame(width: 28, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(bucket.dateRangeLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(CurrencyFormatter.format(amountMinor: bucket.netSpendMinor, currencyCode: currency.code))
                                    .font(.caption.weight(.semibold))
                            }
                            
                            GeometryReader { geo in
                                let proportion = CGFloat(bucket.netSpendMinor) / CGFloat(maxWeekSpend)
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(.tertiarySystemFill))
                                    Capsule()
                                        .fill(Color.blue)
                                        .frame(width: max(4, geo.size.width * proportion))
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func categoryTrendsSection(_ summary: TrendsSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Shifts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if summary.categoryTrends.isEmpty {
                Text("No category expenditures recorded this period.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(summary.categoryTrends) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.iconKey)
                                .font(.body)
                                .frame(width: 32, height: 32)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.categoryName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Last: \(CurrencyFormatter.format(amountMinor: item.previousMonthSpendMinor, currencyCode: currency.code))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(CurrencyFormatter.format(amountMinor: item.currentMonthSpendMinor, currencyCode: currency.code))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                categoryDeltaPill(item)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if item.id != summary.categoryTrends.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func categoryDeltaPill(_ item: CategoryTrendItem) -> some View {
        switch item.direction {
        case .increased:
            let sign = "+"
            let text = item.percentageChange.map { String(format: "%@%.0f%%", sign, $0) } ?? sign
            Text(text)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case .decreased:
            let text = item.percentageChange.map { String(format: "%.0f%%", $0) } ?? "Lower"
            Text(text)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        case .unchanged:
            Text("0%")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .foregroundStyle(.secondary)
                .clipShape(Capsule())
        case .newSpend:
            Text("New")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
    }
    
    private func loadTrends() {
        isLoading = true
        let curMonth = selectedMonth
        let prevMonth = selectedMonth.previous()
        
        Task {
            let curTxs = (try? await transactionRepository.list(month: curMonth)) ?? []
            let prevTxs = (try? await transactionRepository.list(month: prevMonth)) ?? []
            let cats = (try? await categoryRepository.list(includeArchived: true)) ?? []
            
            let calculated = TrendsSummary.compute(
                currentMonth: curMonth,
                currency: currency,
                currentMonthTransactions: curTxs,
                previousMonthTransactions: prevTxs,
                categories: cats
            )
            
            await MainActor.run {
                self.trends = calculated
                self.isLoading = false
            }
        }
    }
}

private extension CalendarMonth {
    func shortMonthName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.shortMonthSymbols[month - 1]
    }
}
