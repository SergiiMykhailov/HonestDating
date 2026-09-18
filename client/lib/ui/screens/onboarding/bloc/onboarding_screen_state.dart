import 'package:honest_dating/models/authentication_provider.dart';

sealed class OnboardingScreenState {
  const OnboardingScreenState();
}

final class OnboardingReady extends OnboardingScreenState {
  const OnboardingReady();
}

final class OnboardingSocialSignInInProgress extends OnboardingScreenState {
  const OnboardingSocialSignInInProgress(this.provider);

  final AuthenticationProvider provider;
}

final class OnboardingAuthenticated extends OnboardingScreenState {
  const OnboardingAuthenticated(this.provider);

  final AuthenticationProvider provider;
}

final class OnboardingProviderConfigurationRequired
    extends OnboardingScreenState {
  const OnboardingProviderConfigurationRequired(this.provider);

  final AuthenticationProvider provider;
}

final class OnboardingDataAccessFailure extends OnboardingScreenState {
  const OnboardingDataAccessFailure(this.provider);

  final AuthenticationProvider provider;
}

final class OnboardingAuthenticationFailure extends OnboardingScreenState {
  const OnboardingAuthenticationFailure(this.provider);

  final AuthenticationProvider provider;
}
