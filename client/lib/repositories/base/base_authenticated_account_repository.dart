abstract interface class BaseAuthenticatedAccountRepository {
  /// Creates the minimum owner-only account record, or refreshes its server
  /// timestamp when it already exists.
  Future<void> ensureAccount(String userId);

  /// Creates the owner-only local-preview account used by the debug onboarding
  /// shortcut. The email is a fixed test identifier, not an Auth credential.
  Future<void> ensureDebugPreviewAccount(String userId);

  /// True only when the current persisted Firebase session owns an account
  /// whose mobile registration was completed.
  Future<bool> hasCompletedMobileRegistration();

  /// Marks the current authenticated account as having completed the mobile
  /// registration flow.
  Future<void> completeMobileRegistration(String userId);
}
