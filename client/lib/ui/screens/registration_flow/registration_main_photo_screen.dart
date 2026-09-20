import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/profile_photo_verification.dart';
import 'package:honest_dating/repositories/base/base_profile_photo_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration/bloc/profile_photo_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class RegistrationMainPhotoScreen extends StatelessWidget {
  const RegistrationMainPhotoScreen({
    super.key,
    required BaseProfileSetupRepository repository,
    required BaseProfilePhotoVerificationRepository verificationRepository,
  }) : _repository = repository,
       _verificationRepository = verificationRepository;

  final BaseProfileSetupRepository _repository;
  final BaseProfilePhotoVerificationRepository _verificationRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfilePhotoBloc>(
      create: (BuildContext context) => ProfilePhotoBloc(
        repository: _repository,
        verificationRepository: _verificationRepository,
      ),
      child: const _RegistrationMainPhotoView(),
    );
  }
}

class _RegistrationMainPhotoView extends StatelessWidget {
  const _RegistrationMainPhotoView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocConsumer<ProfilePhotoBloc, ProfilePhotoState>(
        listenWhen: (previous, current) =>
            previous.navigationRequest != current.navigationRequest,
        listener: (BuildContext context, ProfilePhotoState state) {
          final session = state.verificationSession;
          if (state.navigationRequest > 0 && session != null) {
            unawaited(_openValidation(context, session));
          }
        },
        builder: (BuildContext context, ProfilePhotoState state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'Your main photo',
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
                      const AppSetupProgress(currentStep: 4, totalSteps: 25),
                      const SizedBox(height: 42),
                      const Text(
                        'Choose your main photo',
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
                        'Your main profile photo is the photo shown on your profile card in Discover. We verify it against the face template created during the liveness check in the previous step. This helps ensure that your profile photo represents you. Please use a clear, recent photo of yourself where your face is clearly visible.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _MainPhotoPicker(
                        path: state.draft.mainPhotoPath,
                        isLoading: state.isBusy,
                        onPressed: () {
                          context.read<ProfilePhotoBloc>().add(
                            const ProfileMainPhotoRequested(),
                          );
                        },
                      ),
                      if (state.errorMessage
                          case final String errorMessage) ...[
                        const SizedBox(height: 16),
                        AppFeedbackCard(
                          message: errorMessage,
                          tone: AppFeedbackTone.error,
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: 'Continue',
                        isLoading: state.isUploading,
                        onPressed: state.canContinue
                            ? () {
                                context.read<ProfilePhotoBloc>().add(
                                  const ProfilePhotoContinueRequested(),
                                );
                              }
                            : null,
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

  Future<void> _openValidation(
    BuildContext context,
    ProfilePhotoVerificationSession session,
  ) async {
    final shouldReplaceMainPhoto = await Navigator.of(
      context,
    ).pushNamed<bool>(BaseRouter.profilePhotoValidation, arguments: session);
    if (context.mounted && shouldReplaceMainPhoto == true) {
      context.read<ProfilePhotoBloc>().add(const ProfileMainPhotoRequested());
    }
  }
}

class _MainPhotoPicker extends StatelessWidget {
  const _MainPhotoPicker({
    required this.path,
    required this.isLoading,
    required this.onPressed,
  });

  final String? path;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isLoading ? null : onPressed,
      child: AspectRatio(
        aspectRatio: 0.82,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.softCanvas,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: path == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.add_circled,
                        color: AppColors.coral,
                        size: 54,
                      ),
                      SizedBox(height: 14),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          'Choose main photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : Image.file(
                    File(path!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        CupertinoIcons.photo,
                        color: AppColors.mutedInk,
                        size: 44,
                      ),
                    ),
                  ),
          ),
        ),
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
