import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/authentication_provider.dart';
import 'package:honest_dating/repositories/base/base_authentication_repository.dart';
import 'package:honest_dating/ui/localization/app_copy.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/onboarding/bloc/onboarding_screen_bloc.dart';
import 'package:honest_dating/ui/screens/onboarding/bloc/onboarding_screen_event.dart';
import 'package:honest_dating/ui/screens/onboarding/bloc/onboarding_screen_state.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required BaseAuthenticationRepository repository,
  }) : _repository = repository;

  final BaseAuthenticationRepository _repository;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.navy,
      child: BlocProvider<OnboardingScreenBloc>(
        create: (BuildContext context) =>
            OnboardingScreenBloc(repository: _repository),
        child: const _OnboardingView(),
      ),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    final welcomeArea = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 22, 24, 0),
          child: _BrandLockup(),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: _WelcomeCopy(),
        ),
        const SizedBox(height: 48),
      ],
    );

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (kDebugMode)
                      Expanded(
                        child: _TripleTapAdvance(
                          onTriggered: () {
                            Navigator.of(
                              context,
                            ).pushNamed(BaseRouter.phoneVerification);
                          },
                          child: welcomeArea,
                        ),
                      )
                    else
                      Expanded(child: welcomeArea),
                    const _AuthenticationPanel(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TripleTapAdvance extends StatefulWidget {
  const _TripleTapAdvance({required this.child, required this.onTriggered});

  final Widget child;
  final VoidCallback onTriggered;

  @override
  State<_TripleTapAdvance> createState() => _TripleTapAdvanceState();
}

class _TripleTapAdvanceState extends State<_TripleTapAdvance> {
  static const _tripleTapTimeout = Duration(milliseconds: 700);

  Timer? _tapTimeout;
  int _tapCount = 0;

  @override
  void dispose() {
    _tapTimeout?.cancel();
    super.dispose();
  }

  void _onTapUp(TapUpDetails details) {
    _tapTimeout?.cancel();
    _tapCount += 1;

    if (_tapCount == 3) {
      _tapCount = 0;
      widget.onTriggered();
      return;
    }

    _tapTimeout = Timer(_tripleTapTimeout, () {
      _tapCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _onTapUp,
      child: widget.child,
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.canvas.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.canvas.withValues(alpha: 0.16)),
          ),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                'HD',
                style: TextStyle(
                  color: AppColors.canvas,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        const Text(
          AppCopy.appName,
          style: TextStyle(
            color: AppColors.canvas,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppCopy.onboardingEyebrow,
          style: TextStyle(
            color: Color(0xFFFFC6D0),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Text(
          AppCopy.onboardingTitle,
          style: TextStyle(
            color: AppColors.canvas,
            fontSize: 38,
            height: 1.04,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        SizedBox(height: 14),
        Text(
          AppCopy.onboardingBody,
          style: TextStyle(
            color: Color(0xFFD2CEE9),
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _AuthenticationPanel extends StatelessWidget {
  const _AuthenticationPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
        child: BlocBuilder<OnboardingScreenBloc, OnboardingScreenState>(
          builder: (BuildContext context, OnboardingScreenState state) {
            final pendingProvider = state is OnboardingSocialSignInInProgress
                ? state.provider
                : null;
            final failure = switch (state) {
              OnboardingAuthenticationFailure(:final provider) =>
                'We could not start ${provider.label} sign-in. Please try again.',
              _ => null,
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppCopy.onboardingPanelTitle,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppCopy.onboardingPanelBody,
                  style: TextStyle(
                    color: AppColors.mutedInk,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                AppSocialSignInButton(
                  provider: AuthenticationProvider.google,
                  isLoading: pendingProvider == AuthenticationProvider.google,
                  onPressed: pendingProvider == null
                      ? () => context.read<OnboardingScreenBloc>().add(
                          const OnboardingSocialSignInRequested(
                            AuthenticationProvider.google,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                AppSocialSignInButton(
                  provider: AuthenticationProvider.apple,
                  isLoading: pendingProvider == AuthenticationProvider.apple,
                  onPressed: pendingProvider == null
                      ? () => context.read<OnboardingScreenBloc>().add(
                          const OnboardingSocialSignInRequested(
                            AuthenticationProvider.apple,
                          ),
                        )
                      : null,
                ),
                if (failure != null) ...[
                  const SizedBox(height: 16),
                  AppFeedbackCard(
                    message: failure,
                    tone: AppFeedbackTone.error,
                    onDismissed: () => context.read<OnboardingScreenBloc>().add(
                      const OnboardingFeedbackDismissed(),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  AppCopy.onboardingLegalNotice,
                  style: TextStyle(
                    color: AppColors.mutedInk,
                    fontSize: 12,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
