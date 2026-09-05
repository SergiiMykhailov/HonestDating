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

final class OnboardingProviderUnavailable extends OnboardingScreenState {
  const OnboardingProviderUnavailable(this.provider);

  final AuthenticationProvider provider;
}

final class OnboardingAuthenticationFailure extends OnboardingScreenState {
  const OnboardingAuthenticationFailure(this.provider);

  final AuthenticationProvider provider;
}
