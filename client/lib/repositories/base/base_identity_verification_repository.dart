import 'package:honest_dating/models/identity_verification_result.dart';

abstract interface class BaseIdentityVerificationRepository {
  Future<IdentityVerificationResult> startLivenessCheck();
}
