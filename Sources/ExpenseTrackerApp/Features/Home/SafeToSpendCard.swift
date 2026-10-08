import SwiftUI
import ExpenseTrackerCore

public struct SafeToSpendCard: View {
    public let calculation: SafeToSpendCalculation
    
    @State private var showingDetails = false
    
    public init(calculation: SafeToSpendCalculation) {
        self.calculation = calculation
    }
    
    public var body: some View {
        Button {
            showingDetails = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available Until Payday")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(calculation.payCycle.displayTitle) • \(calculation.daysRemaining) days left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if calculation.isDeficit {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Cycle Deficit: \(CurrencyFormatter.format(amountMinor: calculation.deficitMinor, currencyCode: calculation.currency.code))")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.orange)
                    }
                    Text("Committed spending and bills exceed cycle budget pool.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(alignment: .firstTextBaseline) {
                        Text(CurrencyFormatter.format(amountMinor: calculation.safeToSpendTotalMinor, currencyCode: calculation.currency.code))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(CurrencyFormatter.format(amountMinor: calculation.dailyPaceMinor, currencyCode: calculation.currency.code))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.blue)
                            Text("per day")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Available until payday. Tap to view calculation assumptions.")
        .sheet(isPresented: $showingDetails) {
            NavigationStack {
                List {
                    Section(header: Text("Safe-to-Spend Breakdown")) {
                        HStack {
                            Text("Starting Pool (\(calculation.basis.displayName))")
                            Spacer()
                            Text(CurrencyFormatter.format(amountMinor: calculation.startingPoolMinor, currencyCode: calculation.currency.code))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Already Spent in Cycle")
                            Spacer()
                            Text("-\(CurrencyFormatter.format(amountMinor: calculation.postedSpendMinor, currencyCode: calculation.currency.code))")
                                .foregroundStyle(.orange)
                        }
                        
                        HStack {
                            Text("Upcoming Bills Before Payday")
                            Spacer()
                            Text("-\(CurrencyFormatter.format(amountMinor: calculation.upcomingCommitmentsMinor, currencyCode: calculation.currency.code))")
                                .foregroundStyle(.orange)
                        }
                        
                        HStack {
                            Text("Safe-to-Spend Total")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(CurrencyFormatter.format(amountMinor: calculation.safeToSpendTotalMinor, currencyCode: calculation.currency.code))
                                .font(.headline)
                                .foregroundStyle(calculation.isDeficit ? .orange : .blue)
                        }
                    }
                    
                    Section(header: Text("Daily Pace")) {
                        HStack {
                            Text("Days Remaining in Cycle")
                            Spacer()
                            Text("\(calculation.daysRemaining) days")
                        }
                        HStack {
                            Text("Daily Budget Target")
                            Spacer()
                            Text(CurrencyFormatter.format(amountMinor: calculation.dailyPaceMinor, currencyCode: calculation.currency.code))
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    Section(header: Text("Assumptions & Privacy")) {
                        Text(calculation.assumptionsText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Safe-to-Spend Model")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingDetails = false
                        }
                    }
                }
            }
        }
    }
}
