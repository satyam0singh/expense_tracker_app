import SwiftUI
import ExpenseTrackerCore

public struct OnboardingView: View {
    @State private var displayName: String = ""
    @State private var selectedCurrency: String = "INR"
    @State private var expectedIncomeMajorString: String = ""
    @State private var monthlyBudgetMajorString: String = ""
    @State private var isSaving: Bool = false
    
    public let onComplete: (UserProfile) -> Void
    private let profileRepository: UserProfileRepositoryProtocol
    
    public init(
        profileRepository: UserProfileRepositoryProtocol,
        onComplete: @escaping (UserProfile) -> Void
    ) {
        self.profileRepository = profileRepository
        self.onComplete = onComplete
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("A calm, private way to track your spending. All data stays offline on your device.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)
                    
                    // Section 1: Currency Preference
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Currency")
                            .font(.headline)
                        
                        Picker("Select Currency", selection: $selectedCurrency) {
                            Text("₹ INR (Indian Rupee)").tag("INR")
                            Text("$ USD (US Dollar)").tag("USD")
                            Text("€ EUR (Euro)").tag("EUR")
                            Text("£ GBP (British Pound)").tag("GBP")
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Select default currency")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Section 2: Planning Preferences (Optional)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Planning Context (Optional)")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Expected Monthly Income")
                                .font(.subheadline.weight(.medium))
                            
                            TextField("e.g. 50000", text: $expectedIncomeMajorString)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Expected monthly income planning figure")
                            
                            Text("Planning figure only. Never counted as actual received cash.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Monthly Budget Limit")
                                .font(.subheadline.weight(.medium))
                            
                            TextField("e.g. 30000", text: $monthlyBudgetMajorString)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Monthly budget limit")
                            
                            Text("Used to calculate budget remaining on Home. Can be adjusted anytime.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: saveAndContinue) {
                            Text("Get Started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .accessibilityLabel("Save preferences and get started")
                        .disabled(isSaving)
                        
                        Button(action: skipOnboarding) {
                            Text("Skip for Now")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        }
                        .accessibilityLabel("Skip onboarding with defaults")
                        .accessibilityHint("Proceed directly to Home using standard INR currency")
                    }
                    .padding(.top, 8)
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveAndContinue() {
        isSaving = true
        Task {
            let currency = CurrencyCode.from(code: selectedCurrency)
            let multiplier = Int64(CurrencyFormatter.pow10(currency.minorUnitExponent))
            
            let incomeMinor = Int64(expectedIncomeMajorString.trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0 > 0 ? $0 * multiplier : nil }
            
            let budgetMinor = Int64(monthlyBudgetMajorString.trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0 >= 0 ? $0 * multiplier : nil }
            
            do {
                let profile = try await profileRepository.completeOnboarding(
                    currencyCode: selectedCurrency,
                    displayName: displayName.isEmpty ? nil : displayName,
                    expectedIncomeMinor: incomeMinor,
                    monthlyBudgetMinor: budgetMinor
                )
                await MainActor.run {
                    onComplete(profile)
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
    
    private func skipOnboarding() {
        isSaving = true
        Task {
            do {
                let profile = try await profileRepository.completeOnboarding(
                    currencyCode: "INR",
                    displayName: nil,
                    expectedIncomeMinor: nil,
                    monthlyBudgetMinor: nil
                )
                await MainActor.run {
                    onComplete(profile)
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// Internal helper extension
extension CurrencyFormatter {
    static func pow10(_ n: Int) -> Int {
        var res = 1
        for _ in 0..<n {
            res *= 10
        }
        return res
    }
}
