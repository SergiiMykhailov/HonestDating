import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration/bloc/profile_photo_bloc.dart';
import 'package:honest_dating/ui/screens/registration/bloc/registration_completion_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class ProfilePhotosScreen extends StatelessWidget {
  const ProfilePhotosScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfilePhotoBloc>(
      create: (BuildContext context) =>
          ProfilePhotoBloc(repository: repository),
      child: const _ProfilePhotosFlow(),
    );
  }
}

class _ProfilePhotosFlow extends StatelessWidget {
  const _ProfilePhotosFlow();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocConsumer<ProfilePhotoBloc, ProfilePhotoState>(
        listenWhen: (ProfilePhotoState previous, ProfilePhotoState current) =>
            previous.navigationRequest != current.navigationRequest,
        listener: (BuildContext context, ProfilePhotoState state) {
          if (state.navigationRequest > 0) {
            Navigator.of(context).pushNamed(BaseRouter.profileAboutMe);
          }
        },
        builder: (BuildContext context, ProfilePhotoState state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'Add photos',
                leading: _RegistrationBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    children: [
                      const AppSetupProgress(currentStep: 6, totalSteps: 6),
                      const SizedBox(height: 40),
                      const Text(
                        'Show your best self',
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
                        'Choose a clear main photo. You can add more photos too.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _MainPhotoCard(
                        path: state.draft.mainPhotoPath,
                        isLoading: state.isPicking,
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
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'More photos',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            onPressed: state.isPicking
                                ? null
                                : () {
                                    context.read<ProfilePhotoBloc>().add(
                                      const ProfileGalleryPhotosRequested(),
                                    );
                                  },
                            child: const Text(
                              'Add photos',
                              style: TextStyle(
                                color: AppColors.coral,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (state.draft.galleryPhotoPaths.isEmpty)
                        const Text(
                          'Optional — add photos from your gallery.',
                          style: TextStyle(
                            color: AppColors.mutedInk,
                            fontSize: 14,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: state.draft.galleryPhotoPaths
                              .map(
                                (String path) => _GalleryPhoto(
                                  path: path,
                                  onRemove: () {
                                    context.read<ProfilePhotoBloc>().add(
                                      ProfileGalleryPhotoRemoved(path),
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 28),
                      AppPrimaryButton(
                        label: 'Continue',
                        isLoading: state.isPicking,
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
}

class ProfileAboutMeScreen extends StatelessWidget {
  const ProfileAboutMeScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationCompletionBloc>(
      create: (BuildContext context) => RegistrationCompletionBloc(
        repository: repository,
        stage: RegistrationCompletionStage.aboutMe,
      ),
      child: const _ProfileAboutMeFlow(),
    );
  }
}

class _ProfileAboutMeFlow extends StatefulWidget {
  const _ProfileAboutMeFlow();

  @override
  State<_ProfileAboutMeFlow> createState() => _ProfileAboutMeFlowState();
}

class _ProfileAboutMeFlowState extends State<_ProfileAboutMeFlow> {
  final TextEditingController _controller = TextEditingController();
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      _controller.text = context
          .read<RegistrationCompletionBloc>()
          .state
          .draft
          .aboutMe;
      _seeded = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocConsumer<RegistrationCompletionBloc, RegistrationCompletionState>(
        listenWhen:
            (
              RegistrationCompletionState previous,
              RegistrationCompletionState current,
            ) => previous.navigationRequest != current.navigationRequest,
        listener: (BuildContext context, RegistrationCompletionState state) {
          if (state.navigationRequest > 0) {
            Navigator.of(context).pushNamed(BaseRouter.profileInterests);
          }
        },
        builder: (BuildContext context, RegistrationCompletionState state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'About you',
                leading: _RegistrationBackButton(
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
                      const SizedBox(height: 40),
                      const Text(
                        'Tell us about yourself',
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
                        'Write a few words about who you are and what you hope to find.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Padding(
                        padding: EdgeInsets.only(left: 14, bottom: 7),
                        child: Text(
                          'About Me',
                          style: TextStyle(
                            color: AppColors.mutedInk,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      CupertinoTextField(
                        controller: _controller,
                        autofocus: true,
                        maxLines: 6,
                        minLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        placeholder: 'Share something genuine',
                        padding: const EdgeInsets.all(16),
                        onChanged: (String value) {
                          context.read<RegistrationCompletionBloc>().add(
                            AboutMeChanged(value),
                          );
                        },
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppPrimaryButton(
                        label: 'Continue',
                        onPressed: state.canContinue
                            ? () {
                                context.read<RegistrationCompletionBloc>().add(
                                  const AboutMeContinueRequested(),
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
}

class ProfileInterestsScreen extends StatelessWidget {
  const ProfileInterestsScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationCompletionBloc>(
      create: (BuildContext context) => RegistrationCompletionBloc(
        repository: repository,
        stage: RegistrationCompletionStage.interests,
      ),
      child: const _ProfileInterestsFlow(),
    );
  }
}

class _ProfileInterestsFlow extends StatefulWidget {
  const _ProfileInterestsFlow();

  @override
  State<_ProfileInterestsFlow> createState() => _ProfileInterestsFlowState();
}

class _ProfileInterestsFlowState extends State<_ProfileInterestsFlow> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocConsumer<RegistrationCompletionBloc, RegistrationCompletionState>(
        listenWhen:
            (
              RegistrationCompletionState previous,
              RegistrationCompletionState current,
            ) => previous.navigationRequest != current.navigationRequest,
        listener: (BuildContext context, RegistrationCompletionState state) {
          if (state.navigationRequest > 0) {
            Navigator.of(context).pushNamed(BaseRouter.profileReview);
          }
        },
        builder: (BuildContext context, RegistrationCompletionState state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'Interests',
                leading: _RegistrationBackButton(
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
                      const SizedBox(height: 40),
                      const Text(
                        'What are you into?',
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
                        'Write anything you are interested in, separating interests with semicolons.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CupertinoTextField(
                        controller: _controller,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        placeholder: 'Hiking; jazz; cooking',
                        padding: const EdgeInsets.all(16),
                        onSubmitted: (_) => _addInterests(context),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          onPressed: () => _addInterests(context),
                          child: const Text(
                            'Add interests',
                            style: TextStyle(
                              color: AppColors.coral,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (state.draft.interests.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.draft.interests
                              .map(
                                (String interest) => _InterestTag(
                                  label: interest,
                                  onRemove: () {
                                    context
                                        .read<RegistrationCompletionBloc>()
                                        .add(InterestRemoved(interest));
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      AppPrimaryButton(
                        label: 'Continue',
                        onPressed: state.canContinue
                            ? () {
                                context.read<RegistrationCompletionBloc>().add(
                                  const InterestsContinueRequested(),
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

  void _addInterests(BuildContext context) {
    final value = _controller.text;
    if (value.trim().isEmpty) {
      return;
    }
    context.read<RegistrationCompletionBloc>().add(InterestsSubmitted(value));
    _controller.clear();
  }
}

class ProfileReviewScreen extends StatelessWidget {
  const ProfileReviewScreen({super.key, required this.repository});

  final BaseProfileSetupRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationCompletionBloc>(
      create: (BuildContext context) => RegistrationCompletionBloc(
        repository: repository,
        stage: RegistrationCompletionStage.review,
      ),
      child: const _ProfileReviewFlow(),
    );
  }
}

class _ProfileReviewFlow extends StatelessWidget {
  const _ProfileReviewFlow();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child:
          BlocConsumer<RegistrationCompletionBloc, RegistrationCompletionState>(
            listenWhen:
                (
                  RegistrationCompletionState previous,
                  RegistrationCompletionState current,
                ) => previous.isCompleted != current.isCompleted,
            listener:
                (BuildContext context, RegistrationCompletionState state) {
                  if (state.isCompleted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      BaseRouter.home,
                      (Route<void> route) => false,
                    );
                  }
                },
            builder: (BuildContext context, RegistrationCompletionState state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppNavigationBar(
                    title: 'Review profile',
                    leading: _RegistrationBackButton(
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
                          const SizedBox(height: 32),
                          if (state.draft.mainPhotoPath case final String path)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(path),
                                height: 260,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Text(
                            _nameFor(state.draft),
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _profileSummary(state.draft),
                            style: const TextStyle(
                              color: AppColors.coral,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _ReviewHeading('About Me'),
                          const SizedBox(height: 8),
                          Text(
                            state.draft.aboutMe,
                            style: const TextStyle(
                              color: AppColors.mutedInk,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _ReviewHeading('Interests'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: state.draft.interests
                                .map(
                                  (String interest) =>
                                      _InterestTag(label: interest),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 18),
                          AppPrimaryButton(
                            label: 'Finish registration',
                            onPressed: state.canContinue
                                ? () {
                                    context
                                        .read<RegistrationCompletionBloc>()
                                        .add(
                                          const RegistrationFinishRequested(),
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
}

class _MainPhotoCard extends StatelessWidget {
  const _MainPhotoCard({
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.softCanvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: SizedBox(
          height: 250,
          child: path == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.add_circled,
                      color: AppColors.coral,
                      size: 38,
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Choose main photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.coral,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(path!), fit: BoxFit.cover),
                      const Positioned(
                        left: 12,
                        bottom: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              'Main photo',
                              style: TextStyle(
                                color: AppColors.canvas,
                                fontSize: 13,
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
      ),
    );
  }
}

class _GalleryPhoto extends StatelessWidget {
  const _GalleryPhoto({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(path),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(28, 28),
              onPressed: onRemove,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: AppColors.coral,
                    size: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestTag extends StatelessWidget {
  const _InterestTag({required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 96;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.coralSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: onRemove == null ? 12 : 5,
            top: 7,
            bottom: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.plum,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 5),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(20, 20),
                  onPressed: onRemove,
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: AppColors.plum,
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewHeading extends StatelessWidget {
  const _ReviewHeading(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RegistrationBackButton extends StatelessWidget {
  const _RegistrationBackButton({required this.onPressed});

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

String _nameFor(ProfileSetupDraft draft) {
  final fullName = '${draft.firstName} ${draft.lastName}'.trim();
  if (draft.age case final int age) {
    return '$fullName, $age';
  }
  return fullName;
}

String _profileSummary(ProfileSetupDraft draft) {
  return [
    draft.orientation,
    draft.relationshipIntention,
  ].where((String value) => value.isNotEmpty).join(' · ');
}
