import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/ui/localization/app_copy.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class IdentityVerificationScreen extends StatelessWidget {
  const IdentityVerificationScreen({super.key});

  void _startMockSelfieCheck(BuildContext context) {
    Navigator.of(context).pushNamed(BaseRouter.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNavigationBar(
            title: AppCopy.identityVerificationNavigationTitle,
            leading: _BackButton(onPressed: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: const [
                  AppSetupProgress(currentStep: 4, totalSteps: 6),
                  SizedBox(height: 42),
                  Text(
                    AppCopy.identityVerificationTitle,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    AppCopy.identityVerificationBody,
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24),
                  AppFeedbackCard(message: AppCopy.identityVerificationPreview),
                  SizedBox(height: 40),
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.coralSoft,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 116,
                        height: 116,
                        child: Icon(
                          CupertinoIcons.person_crop_circle,
                          color: AppColors.coral,
                          size: 62,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: AppPrimaryButton(
                label: AppCopy.identityVerificationAction,
                onPressed: () => _startMockSelfieCheck(context),
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
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.line),
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
