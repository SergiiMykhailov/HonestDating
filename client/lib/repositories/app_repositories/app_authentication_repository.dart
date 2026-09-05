import 'package:honest_dating/models/authentication_provider.dart';
import 'package:honest_dating/models/authentication_start_result.dart';
import 'package:honest_dating/repositories/base/base_authentication_repository.dart';

class AppAuthenticationRepository implements BaseAuthenticationRepository {
  @override
  Future<AuthenticationStartResult> beginSocialAuthentication(
    AuthenticationProvider provider,
  ) async {
    return AuthenticationStartResult(
      provider: provider,
      status: AuthenticationStartStatus.providerUnavailable,
    );
  }
}
