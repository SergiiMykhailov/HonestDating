import 'package:honest_dating/models/authentication_provider.dart';

enum AuthenticationStartStatus { providerUnavailable }

class AuthenticationStartResult {
  const AuthenticationStartResult({
    required this.provider,
    required this.status,
  });

  final AuthenticationProvider provider;
  final AuthenticationStartStatus status;
}
