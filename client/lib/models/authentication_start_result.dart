import 'package:honest_dating/models/authentication_provider.dart';

enum AuthenticationStartStatus {
  authenticated,
  cancelled,
  providerConfigurationRequired,
  dataAccessFailed,
  failed,
}

class AuthenticationStartResult {
  const AuthenticationStartResult({
    required this.provider,
    required this.status,
  });

  final AuthenticationProvider provider;
  final AuthenticationStartStatus status;
}
