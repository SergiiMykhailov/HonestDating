import 'package:honest_dating/models/identity_verification_result.dart';

abstract interface class BaseIdentityVerificationRepository {
  /// An opaque, in-memory capability for the backend-owned liveness attempt.
  /// It is intentionally not a FaceTec identifier and is never persisted.
  String? get activeLivenessVerificationToken;

  /// Whether this device cannot run the native FaceTec capture.
  ///
  /// iOS simulators use the preview path so the registration flow remains
  /// navigable without a physical camera or the FaceTec SDK session UI.
  Future<bool> isLivenessCheckSkippedOnCurrentDevice();

  Future<IdentityVerificationResult> startLivenessCheck();
}
