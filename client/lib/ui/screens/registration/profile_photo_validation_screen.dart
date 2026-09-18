import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/profile_photo_verification.dart';
import 'package:honest_dating/repositories/base/base_profile_photo_verification_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration/bloc/profile_photo_validation_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class ProfilePhotoValidationScreen extends StatelessWidget {
  const ProfilePhotoValidationScreen({
    super.key,
    required this.repository,
    required this.session,
  });

  final BaseProfilePhotoVerificationRepository repository;
  final ProfilePhotoVerificationSession session;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfilePhotoValidationBloc>(
      create: (BuildContext context) =>
          ProfilePhotoValidationBloc(repository: repository, session: session),
      child: const _ProfilePhotoValidationFlow(),
    );
  }
}

class _ProfilePhotoValidationFlow extends StatefulWidget {
  const _ProfilePhotoValidationFlow();

  @override
  State<_ProfilePhotoValidationFlow> createState() =>
      _ProfilePhotoValidationFlowState();
}

class _ProfilePhotoValidationFlowState
    extends State<_ProfilePhotoValidationFlow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfilePhotoValidationBloc>().add(
          const ProfilePhotoValidationStarted(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child:
          BlocConsumer<ProfilePhotoValidationBloc, ProfilePhotoValidationState>(
            listenWhen:
                (
                  ProfilePhotoValidationState previous,
                  ProfilePhotoValidationState current,
                ) => previous.navigationRequest != current.navigationRequest,
            listener:
                (BuildContext context, ProfilePhotoValidationState state) {
                  if (state.navigationRequest > 0) {
                    unawaited(
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(BaseRouter.profileAboutMe),
                    );
                  }
                },
            builder: (BuildContext context, ProfilePhotoValidationState state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppNavigationBar(
                    title: 'Photo validation',
                    leading: _BackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                        children: [
                          const AppSetupProgress(currentStep: 6, totalSteps: 6),
                          const SizedBox(height: 44),
                          Center(child: _StatusMark(status: state.status)),
                          const SizedBox(height: 28),
                          Text(
                            _titleFor(state.status),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 29,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _descriptionFor(state.status),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.mutedInk,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          if (state.status ==
                              ProfilePhotoVerificationStatus.pending) ...[
                            const SizedBox(height: 24),
                            const Center(
                              child: CupertinoActivityIndicator(
                                color: AppColors.coral,
                                radius: 13,
                              ),
                            ),
                          ],
                          if (state.errorMessage
                              case final String errorMessage) ...[
                            const SizedBox(height: 28),
                            AppFeedbackCard(
                              message: errorMessage,
                              tone: AppFeedbackTone.error,
                            ),
                          ],
                          const SizedBox(height: 34),
                          if (state.status ==
                              ProfilePhotoVerificationStatus.rejected)
                            AppPrimaryButton(
                              label: 'Replace main photo',
                              onPressed: () => Navigator.of(context).pop(true),
                            )
                          else if (state.status ==
                              ProfilePhotoVerificationStatus.unavailable)
                            AppPrimaryButton(
                              label: 'Retry',
                              isLoading: state.isChecking,
                              onPressed: () {
                                context.read<ProfilePhotoValidationBloc>().add(
                                  const ProfilePhotoValidationRetryRequested(),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  String _titleFor(ProfilePhotoVerificationStatus status) {
    switch (status) {
      case ProfilePhotoVerificationStatus.pending:
        return 'Validating your profile photo…';
      case ProfilePhotoVerificationStatus.approved:
        return 'Photo validated';
      case ProfilePhotoVerificationStatus.rejected:
        return 'Choose another main photo';
      case ProfilePhotoVerificationStatus.unavailable:
        return 'Photo validation is unavailable';
    }
  }

  String _descriptionFor(ProfilePhotoVerificationStatus status) {
    switch (status) {
      case ProfilePhotoVerificationStatus.pending:
        return 'This usually takes only a moment.';
      case ProfilePhotoVerificationStatus.approved:
        return 'Your registration can continue.';
      case ProfilePhotoVerificationStatus.rejected:
        return 'Choose a clear photo of yourself and we will check it again.';
      case ProfilePhotoVerificationStatus.unavailable:
        return 'Your photos are kept private. You can retry without uploading them again.';
    }
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.status});

  final ProfilePhotoVerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final isRejected = status == ProfilePhotoVerificationStatus.rejected;
    final isUnavailable = status == ProfilePhotoVerificationStatus.unavailable;
    final icon = isRejected || isUnavailable
        ? CupertinoIcons.exclamationmark
        : CupertinoIcons.check_mark;
    final color = isRejected || isUnavailable
        ? AppColors.coral
        : AppColors.plum;
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(icon, size: 42, color: color),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          CupertinoIcons.chevron_left,
          color: AppColors.coral,
          size: 24,
        ),
      ),
    );
  }
}
