enum IdentityVerificationOutcome {
  verified,
  cancelled,
  cameraPermissionDenied,
  initializationFailed,
  networkFailed,
  serviceFailed,
  cameraError,
  lockedOut,
  failed,
  unavailable,
}

class IdentityVerificationResult {
  const IdentityVerificationResult({required this.outcome});

  final IdentityVerificationOutcome outcome;
}
