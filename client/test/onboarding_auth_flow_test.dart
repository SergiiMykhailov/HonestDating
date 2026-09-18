import 'package:flutter_test/flutter_test.dart';
import 'package:honest_dating/models/authentication_provider.dart';
import 'package:honest_dating/models/authentication_start_result.dart';
import 'package:honest_dating/repositories/base/base_authentication_repository.dart';
import 'package:honest_dating/ui/screens/onboarding/bloc/onboarding_screen_bloc.dart';
import 'package:honest_dating/ui/screens/onboarding/bloc/onboarding_screen_event.dart';
import 'package:honest_dating/ui/screens/onboarding/bloc/onboarding_screen_state.dart';

void main() {
  group('OnboardingScreenBloc social authentication', () {
    test(
      'advances only after authentication and Firestore account access',
      () async {
        final bloc = OnboardingScreenBloc(
          repository: _AuthenticationRepositoryStub(
            const AuthenticationStartResult(
              provider: AuthenticationProvider.google,
              status: AuthenticationStartStatus.authenticated,
            ),
          ),
        );
        addTearDown(bloc.close);

        final states = bloc.stream.take(2).toList();
        bloc.add(
          const OnboardingSocialSignInRequested(AuthenticationProvider.google),
        );

        final emittedStates = await states;
        expect(emittedStates[0], isA<OnboardingSocialSignInInProgress>());
        expect(emittedStates[1], isA<OnboardingAuthenticated>());
      },
    );

    test(
      'does not advance when the authenticated account cannot use Firestore',
      () async {
        final bloc = OnboardingScreenBloc(
          repository: _AuthenticationRepositoryStub(
            const AuthenticationStartResult(
              provider: AuthenticationProvider.google,
              status: AuthenticationStartStatus.dataAccessFailed,
            ),
          ),
        );
        addTearDown(bloc.close);

        final states = bloc.stream.take(2).toList();
        bloc.add(
          const OnboardingSocialSignInRequested(AuthenticationProvider.google),
        );

        final emittedStates = await states;
        expect(emittedStates[0], isA<OnboardingSocialSignInInProgress>());
        expect(emittedStates[1], isA<OnboardingDataAccessFailure>());
      },
    );
  });
}

class _AuthenticationRepositoryStub implements BaseAuthenticationRepository {
  const _AuthenticationRepositoryStub(this._result);

  final AuthenticationStartResult _result;

  @override
  Future<AuthenticationStartResult> beginSocialAuthentication(
    AuthenticationProvider provider,
  ) async => _result;
}
