abstract interface class BaseAuthenticatedAccountRepository {
  /// Creates the minimum owner-only account record, or refreshes its server
  /// timestamp when it already exists.
  Future<void> ensureAccount(String userId);
}
