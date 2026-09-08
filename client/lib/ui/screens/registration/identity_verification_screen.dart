import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/identity_verification_result.dart';
import 'package:honest_dating/repositories/base/base_identity_verification_repository.dart';
import 'package:honest_dating/ui/localization/app_copy.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration/bloc/identity_verification_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class IdentityVerificationScreen extends StatelessWidget {
  const IdentityVerificationScreen({super.key, required this.repository});

  final BaseIdentityVerificationRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IdentityVerificationBloc>(
      create: (BuildContext context) =>
          IdentityVerificationBloc(repository: repository),
      child: const _IdentityVerificationView(),
    );
  }
}

class _IdentityVerificationView extends StatelessWidget {
  const _IdentityVerificationView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocListener<IdentityVerificationBloc, IdentityVerificationState>(
        listener: (BuildContext context, IdentityVerificationState state) {
          if (state.phase == IdentityVerificationPhase.completed) {
            Navigator.of(context).pushReplacementNamed(BaseRouter.profileSetup);
          }
        },
        child: BlocBuilder<IdentityVerificationBloc, IdentityVerificationState>(
          builder: (BuildContext context, IdentityVerificationState state) {
            final isInProgress =
                state.phase == IdentityVerificationPhase.inProgress;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppNavigationBar(
                  title: AppCopy.identityVerificationNavigationTitle,
                  leading: _BackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      children: [
                        const AppSetupProgress(currentStep: 4, totalSteps: 6),
                        const SizedBox(height: 42),
                        const Text(
                          AppCopy.identityVerificationTitle,
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
                          AppCopy.identityVerificationBody,
                          style: TextStyle(
                            color: AppColors.mutedInk,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppFeedbackCard(
                          message: _feedbackMessage(state),
                          tone: _feedbackTone(state),
                        ),
                        const SizedBox(height: 40),
                        const Center(
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
                      label: isInProgress
                          ? AppCopy.identityVerificationStartingAction
                          : AppCopy.identityVerificationAction,
                      isLoading: isInProgress,
                      onPressed: isInProgress
                          ? null
                          : () {
                              context.read<IdentityVerificationBloc>().add(
                                const IdentityVerificationRequested(),
                              );
                            },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _feedbackMessage(IdentityVerificationState state) {
    switch (state.outcome) {
      case IdentityVerificationOutcome.cancelled:
        return AppCopy.identityVerificationCancelled;
      case IdentityVerificationOutcome.cameraPermissionDenied:
        return AppCopy.identityVerificationCameraPermissionDenied;
      case IdentityVerificationOutcome.initializationFailed:
        return AppCopy.identityVerificationInitializationFailed;
      case IdentityVerificationOutcome.networkFailed:
        return AppCopy.identityVerificationNetworkFailed;
      case IdentityVerificationOutcome.serviceFailed:
        return AppCopy.identityVerificationServiceFailed;
      case IdentityVerificationOutcome.cameraError:
        return AppCopy.identityVerificationCameraError;
      case IdentityVerificationOutcome.lockedOut:
        return AppCopy.identityVerificationLockedOut;
      case IdentityVerificationOutcome.unavailable:
        return AppCopy.identityVerificationUnavailable;
      case IdentityVerificationOutcome.failed:
        return AppCopy.identityVerificationFailed;
      case IdentityVerificationOutcome.verified:
      case null:
        return AppCopy.identityVerificationPreview;
    }
  }

  AppFeedbackTone _feedbackTone(IdentityVerificationState state) {
    return state.phase == IdentityVerificationPhase.needsRetry
        ? AppFeedbackTone.error
        : AppFeedbackTone.information;
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
