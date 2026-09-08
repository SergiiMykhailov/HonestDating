import 'package:flutter/services.dart';
import 'package:honest_dating/models/identity_verification_result.dart';
import 'package:honest_dating/repositories/base/base_identity_verification_repository.dart';

class AppIdentityVerificationRepository
    implements BaseIdentityVerificationRepository {
  static const MethodChannel _channel = MethodChannel(
    'com.honestdating/facetec-test',
  );

  @override
  Future<IdentityVerificationResult> startLivenessCheck() async {
    try {
      final response = await _channel.invokeMethod<Object?>(
        'startLivenessCheck',
      );
      final outcome = response is Map<Object?, Object?>
          ? response['outcome'] as String?
          : null;

      return IdentityVerificationResult(
        outcome: _outcomeFromPlatformValue(outcome),
      );
    } on MissingPluginException {
      return const IdentityVerificationResult(
        outcome: IdentityVerificationOutcome.unavailable,
      );
    } on PlatformException catch (error) {
      return IdentityVerificationResult(
        outcome: error.code == 'unsupported_platform'
            ? IdentityVerificationOutcome.unavailable
            : IdentityVerificationOutcome.failed,
      );
    }
  }

  IdentityVerificationOutcome _outcomeFromPlatformValue(String? value) {
    switch (value) {
      case 'verified':
        return IdentityVerificationOutcome.verified;
      case 'cancelled':
        return IdentityVerificationOutcome.cancelled;
      case 'cameraPermissionDenied':
        return IdentityVerificationOutcome.cameraPermissionDenied;
      case 'initializationFailed':
        return IdentityVerificationOutcome.initializationFailed;
      case 'networkFailed':
        return IdentityVerificationOutcome.networkFailed;
      case 'serviceFailed':
        return IdentityVerificationOutcome.serviceFailed;
      case 'cameraError':
        return IdentityVerificationOutcome.cameraError;
      case 'lockedOut':
        return IdentityVerificationOutcome.lockedOut;
      case 'unavailable':
        return IdentityVerificationOutcome.unavailable;
      default:
        return IdentityVerificationOutcome.failed;
    }
  }
}
