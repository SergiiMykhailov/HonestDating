import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/authentication_start_result.dart';
import 'package:honest_dating/repositories/base/base_authentication_repository.dart';
import 'package:honest_dating/ui/screens/onboarding/bloc/onboarding_screen_event.dart';
import 'package:honest_dating/ui/screens/onboarding/bloc/onboarding_screen_state.dart';

class OnboardingScreenBloc
    extends Bloc<OnboardingScreenEvent, OnboardingScreenState> {
  OnboardingScreenBloc({required BaseAuthenticationRepository repository})
    : _repository = repository,
      super(const OnboardingReady()) {
    on<OnboardingSocialSignInRequested>(_onSocialSignInRequested);
    on<OnboardingFeedbackDismissed>(_onFeedbackDismissed);
  }

  final BaseAuthenticationRepository _repository;

  Future<void> _onSocialSignInRequested(
    OnboardingSocialSignInRequested event,
    Emitter<OnboardingScreenState> emit,
  ) async {
    emit(OnboardingSocialSignInInProgress(event.provider));

    try {
      final result = await _repository.beginSocialAuthentication(
        event.provider,
      );
      switch (result.status) {
        case AuthenticationStartStatus.providerUnavailable:
          emit(OnboardingProviderUnavailable(result.provider));
      }
    } catch (_) {
      emit(OnboardingAuthenticationFailure(event.provider));
    }
  }

  void _onFeedbackDismissed(
    OnboardingFeedbackDismissed event,
    Emitter<OnboardingScreenState> emit,
  ) {
    emit(const OnboardingReady());
  }
}
