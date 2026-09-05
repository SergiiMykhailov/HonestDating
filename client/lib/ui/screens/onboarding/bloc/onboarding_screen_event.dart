import 'package:honest_dating/models/authentication_provider.dart';

sealed class OnboardingScreenEvent {
  const OnboardingScreenEvent();
}

final class OnboardingSocialSignInRequested extends OnboardingScreenEvent {
  const OnboardingSocialSignInRequested(this.provider);

  final AuthenticationProvider provider;
}

final class OnboardingFeedbackDismissed extends OnboardingScreenEvent {
  const OnboardingFeedbackDismissed();
}
