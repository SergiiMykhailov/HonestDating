import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_attribute.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class RegistrationFriendshipOnlyConfirmationScreen extends StatelessWidget {
  const RegistrationFriendshipOnlyConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: 'Friendship only',
            leading: _BackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppSetupProgress(currentStep: 6, totalSteps: 25),
                    const Spacer(),
                    const Icon(
                      CupertinoIcons.person_2,
                      color: AppColors.plum,
                      size: 62,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Are you sure you want to continue with Friendship Only?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You will not be available for romantic connections. This means you will not be able to send or receive romantic Likes, but Friendship Offers will remain available. You can change your Dating Intention later if you decide you want to date again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedInk,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    AppPrimaryButton(
                      label: 'Continue with Friendship Only',
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          BaseRouter.registrationAttribute,
                          arguments: RegistrationAttributeStep.height,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text(
                        'Change intention',
                        style: TextStyle(
                          color: AppColors.coral,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationReligiosityScreen extends StatelessWidget {
  const RegistrationReligiosityScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: 'Create profile',
            leading: _BackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  const AppSetupProgress(currentStep: 11, totalSteps: 25),
                  const SizedBox(height: 42),
                  const Text(
                    'How religious are you?',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap one option to choose it and continue.',
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...const <String>[
                    'Very Religious',
                    'Moderately Religious',
                    'Somewhat Religious',
                    'Not Religious',
                  ].map(
                    (String option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CupertinoButton(
                        onPressed: () async {
                          await repository.saveDraft(
                            repository.draft.copyWith(religiosity: option),
                          );
                          if (context.mounted) {
                            await Navigator.of(context).pushNamed(
                              BaseRouter.registrationAttribute,
                              arguments:
                                  RegistrationAttributeStep.socialOrientation,
                            );
                          }
                        },
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.coral,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(48, 48),
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            CupertinoIcons.chevron_back,
            color: AppColors.coral,
            size: 21,
          ),
        ),
      ),
    );
  }
}
