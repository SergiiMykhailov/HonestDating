import 'package:honest_dating/models/identity_verification_result.dart';

abstract interface class BaseIdentityVerificationRepository {
  /// An opaque, in-memory capability for the backend-owned liveness attempt.
  /// It is intentionally not a FaceTec identifier and is never persisted.
  String? get activeLivenessVerificationToken;

  Future<IdentityVerificationResult> startLivenessCheck();
}
