import SwiftUI
import ExpenseTrackerCore

/// Small Home Screen Widget View
public struct SmallBudgetWidgetView: View {
    public let snapshot: WidgetSnapshot
    
    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        Link(destination: URL(string: "expensetracker://add-expense")!) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: snapshot.hasSafeToSpend ? "sparkles" : "chart.pie.fill")
                        .foregroundStyle(.blue)
                        .font(.caption.weight(.bold))
                    Text(snapshot.hasSafeToSpend ? "Safe-to-Spend" : "Budget Left")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                Spacer()
                
                let primaryAmount = snapshot.hasSafeToSpend ? (snapshot.formattedSafeToSpendToday ?? snapshot.formattedBudgetRemaining) : snapshot.formattedBudgetRemaining
                
                Text(primaryAmount)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(snapshot.isOverBudget ? .red : .primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                if snapshot.hasSafeToSpend, let days = snapshot.cycleDaysRemaining {
                    Text("\(days)d left in cycle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Spent \(snapshot.formattedSpent)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.secondarySystemFill))
                            .frame(height: 5)
                        Capsule()
                            .fill(snapshot.isOverBudget ? Color.red : Color.blue)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(snapshot.budgetPacePercentage))), height: 5)
                    }
                }
                .frame(height: 5)
                
                Text("Not an account balance")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.systemBackground))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(snapshot.hasSafeToSpend ? "Safe-to-Spend today: \(snapshot.formattedSafeToSpendToday ?? ""), not an account balance" : "Budget remaining: \(snapshot.formattedBudgetRemaining), not an account balance")
    }
}

/// Medium Home Screen Widget View
public struct MediumBudgetWidgetView: View {
    public let snapshot: WidgetSnapshot
    
    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                // Left Column: Budget status
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.pie.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("Monthly Budget Left")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(snapshot.formattedBudgetRemaining)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(snapshot.isOverBudget ? .red : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Spent \(snapshot.formattedSpent) of \(snapshot.formattedBudgetLimit)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.secondarySystemFill))
                                .frame(height: 6)
                            Capsule()
                                .fill(snapshot.isOverBudget ? Color.red : Color.blue)
                                .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(snapshot.budgetPacePercentage))), height: 6)
                        }
                    }
                    .frame(height: 6)
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Right Column: Safe-to-Spend or Recent Activity
                VStack(alignment: .leading, spacing: 4) {
                    if snapshot.hasSafeToSpend {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.indigo)
                            Text("Safe-to-Spend")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(snapshot.formattedSafeToSpendToday ?? "-")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        if let days = snapshot.cycleDaysRemaining {
                            Text("\(days) days left until payday")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if let firstTx = snapshot.recentTransactions.first {
                        Text("Recent")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(firstTx.formattedAmount)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(firstTx.categoryName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Quick Actions")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Ready to track")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Configured limits. Not bank balance.")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Bottom Action Links
            HStack(spacing: 12) {
                Link(destination: URL(string: "expensetracker://add-expense")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Expense")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemFill))
                    .cornerRadius(8)
                }
                
                Link(destination: URL(string: "expensetracker://voice-capture")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                        Text("Voice Log")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemFill))
                    .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
    }
}

/// Lock Screen Circular Widget View
public struct AccessoryCircularBudgetView: View {
    public let snapshot: WidgetSnapshot
    
    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        ZStack {
            ProgressView(value: min(1.0, snapshot.budgetPacePercentage)) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 14))
            }
            .progressViewStyle(.circular)
        }
        .accessibilityLabel("Budget progress: \(Int(snapshot.budgetPacePercentage * 100)) percent spent")
    }
}

/// Lock Screen Rectangular Widget View
public struct AccessoryRectangularBudgetView: View {
    public let snapshot: WidgetSnapshot
    
    public init(snapshot: WidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "chart.pie.fill")
                    .font(.caption2)
                Text("Budget Left: \(snapshot.formattedBudgetRemaining)")
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
            }
            
            if snapshot.hasSafeToSpend, let sts = snapshot.formattedSafeToSpendToday {
                Text("Safe/Day: \(sts)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("Spent: \(snapshot.formattedSpent)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Text("Estimate • Not a bank balance")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
    }
}
