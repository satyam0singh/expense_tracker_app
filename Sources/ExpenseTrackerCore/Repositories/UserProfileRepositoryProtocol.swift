import Foundation

/// Repository contract for reading and updating user profile preferences.
public protocol UserProfileRepositoryProtocol: Sendable {
    func getProfile() async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws
    func completeOnboarding(
        currencyCode: String,
        displayName: String?,
        expectedIncomeMinor: Int64?,
        monthlyBudgetMinor: Int64?
    ) async throws -> UserProfile
}
