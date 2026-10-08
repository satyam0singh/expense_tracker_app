import SwiftUI
import ExpenseTrackerCore

public struct BudgetProgressBar: View {
    public let percentUsed: Double?
    public let warningThresholdPercent: Int?
    public let isOverBudget: Bool
    
    public init(
        percentUsed: Double?,
        warningThresholdPercent: Int? = 80,
        isOverBudget: Bool = false
    ) {
        self.percentUsed = percentUsed
        self.warningThresholdPercent = warningThresholdPercent
        self.isOverBudget = isOverBudget
    }
    
    private var isWarningReached: Bool {
        guard let used = percentUsed, let threshold = warningThresholdPercent else { return false }
        return used >= Double(threshold) && !isOverBudget
    }
    
    private var progressValue: Double {
        guard let used = percentUsed else { return 0.0 }
        return min(max(used / 100.0, 0.0), 1.0)
    }
    
    private var barColor: Color {
        if isOverBudget {
            return .red
        } else if isWarningReached {
            return .orange
        } else {
            return .accentColor
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Visual Progress Track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor)
                        .frame(width: geometry.size.width * progressValue, height: 12)
                }
            }
            .frame(height: 12)
            
            // Accessible Status Indicators
            HStack {
                if let used = percentUsed {
                    Text(String(format: "%.0f%% used", used))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No limit set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isOverBudget {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.octagon.fill")
                        Text("Over Budget")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
                    .accessibilityLabel("Status: Exceeded monthly budget limit")
                } else if isWarningReached {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Approaching Limit")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Status: Approaching monthly budget limit warning threshold")
                } else if percentUsed != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("On Track")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .accessibilityLabel("Status: Spending is within budget")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
