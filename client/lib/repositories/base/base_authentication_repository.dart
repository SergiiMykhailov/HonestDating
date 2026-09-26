import 'package:honest_dating/models/authentication_provider.dart';
import 'package:honest_dating/models/authentication_start_result.dart';

abstract interface class BaseAuthenticationRepository {
  Future<AuthenticationStartResult> beginSocialAuthentication(
    AuthenticationProvider provider,
  );

  /// Debug-only preview authentication used by the onboarding triple-tap
  /// shortcut. Production entry remains social-provider only.
  Future<bool> beginDebugPreviewAuthentication();
}
