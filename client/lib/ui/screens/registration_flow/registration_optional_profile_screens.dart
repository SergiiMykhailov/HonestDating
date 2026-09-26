import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/interest_catalog.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration_flow/bloc/registration_optional_profile_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_feedback_card.dart';
import 'package:honest_dating/ui/widgets/app_form_controls.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class RegistrationInterestsScreen extends StatelessWidget {
  const RegistrationInterestsScreen({
    super.key,
    required BaseProfileSetupRepository repository,
  }) : _repository = repository;

  final BaseProfileSetupRepository _repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationInterestsBloc>(
      create: (BuildContext context) =>
          RegistrationInterestsBloc(repository: _repository),
      child: const _RegistrationInterestsView(),
    );
  }
}

class _RegistrationInterestsView extends StatefulWidget {
  const _RegistrationInterestsView();

  @override
  State<_RegistrationInterestsView> createState() =>
      _RegistrationInterestsViewState();
}

class _RegistrationInterestsViewState
    extends State<_RegistrationInterestsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocConsumer<RegistrationInterestsBloc, RegistrationInterestsState>(
        listenWhen:
            (
              RegistrationInterestsState previous,
              RegistrationInterestsState current,
            ) => previous.navigationRequest != current.navigationRequest,
        listener: (BuildContext context, RegistrationInterestsState state) {
          Navigator.of(context).pushNamed(BaseRouter.registrationGalleryPhotos);
        },
        builder: (BuildContext context, RegistrationInterestsState state) {
          final interests = searchCatalogInterests(state.query);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'Interests',
                leading: _BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    children: [
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
                        'Add anything that helps people get to know you. This is optional and you can change it later.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppFormField(
                        label: 'Search interests',
                        placeholder: 'For example, hiking',
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (String value) {
                          context.read<RegistrationInterestsBloc>().add(
                            RegistrationInterestsQueryChanged(value),
                          );
                        },
                      ),
                      if (state.draft.interests.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          '${state.draft.interests.length} selected',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.draft.interests
                              .map(
                                (String interest) => AppChoiceChip(
                                  label: interest,
                                  isSelected: true,
                                  onPressed: () {
                                    context
                                        .read<RegistrationInterestsBloc>()
                                        .add(
                                          RegistrationInterestToggled(interest),
                                        );
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 26),
                      Text(
                        state.query.trim().isEmpty
                            ? 'Browse interests'
                            : 'Matching interests',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...interests.map(
                        (String interest) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InterestOption(
                            label: interest,
                            isSelected: state.draft.interests.contains(
                              interest,
                            ),
                            onPressed: () {
                              context.read<RegistrationInterestsBloc>().add(
                                RegistrationInterestToggled(interest),
                              );
                            },
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: state.draft.interests.isEmpty
                      ? _SkipForNowButton(
                          onPressed: () {
                            context.read<RegistrationInterestsBloc>().add(
                              const RegistrationInterestsContinueRequested(),
                            );
                          },
                        )
                      : AppPrimaryButton(
                          label: 'Continue',
                          onPressed: () {
                            context.read<RegistrationInterestsBloc>().add(
                              const RegistrationInterestsContinueRequested(),
                            );
                          },
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

class RegistrationGalleryPhotosScreen extends StatelessWidget {
  const RegistrationGalleryPhotosScreen({
    super.key,
    required BaseProfileSetupRepository repository,
  }) : _repository = repository;

  final BaseProfileSetupRepository _repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationGalleryPhotosBloc>(
      create: (BuildContext context) =>
          RegistrationGalleryPhotosBloc(repository: _repository),
      child: const _RegistrationGalleryPhotosView(),
    );
  }
}

class _RegistrationGalleryPhotosView extends StatelessWidget {
  const _RegistrationGalleryPhotosView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocConsumer<RegistrationGalleryPhotosBloc, RegistrationGalleryPhotosState>(
        listenWhen:
            (
              RegistrationGalleryPhotosState previous,
              RegistrationGalleryPhotosState current,
            ) => previous.navigationRequest != current.navigationRequest,
        listener: (BuildContext context, RegistrationGalleryPhotosState state) {
          Navigator.of(context).pushNamed(BaseRouter.registrationComplete);
        },
        builder: (BuildContext context, RegistrationGalleryPhotosState state) {
          final paths = state.draft.galleryPhotoPaths;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'Gallery photos',
                leading: _BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                    children: [
                      const Text(
                        'Add more of you',
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
                        'Gallery photos are optional. Add up to two now, or come back to them later.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (paths.isNotEmpty) ...[
                        _GalleryPreview(
                          paths: paths,
                          onRemove: (String path) {
                            context.read<RegistrationGalleryPhotosBloc>().add(
                              RegistrationGalleryPhotoRemoved(path),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (paths.length < 2)
                        _AddPhotoButton(
                          isLoading: state.isPicking,
                          onPressed: () {
                            context.read<RegistrationGalleryPhotosBloc>().add(
                              const RegistrationGalleryPhotosRequested(),
                            );
                          },
                        ),
                      if (state.errorMessage case final String message) ...[
                        const SizedBox(height: 16),
                        AppFeedbackCard(
                          message: message,
                          tone: AppFeedbackTone.error,
                        ),
                      ],
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: paths.isEmpty
                      ? _SkipForNowButton(
                          onPressed: () {
                            context.read<RegistrationGalleryPhotosBloc>().add(
                              const RegistrationGalleryPhotosContinueRequested(),
                            );
                          },
                        )
                      : AppPrimaryButton(
                          label: 'Continue',
                          onPressed: () {
                            context.read<RegistrationGalleryPhotosBloc>().add(
                              const RegistrationGalleryPhotosContinueRequested(),
                            );
                          },
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

class _InterestOption extends StatelessWidget {
  const _InterestOption({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.coral : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IgnorePointer(
                child: CupertinoSwitch(
                  value: isSelected,
                  activeTrackColor: AppColors.coral,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryPreview extends StatelessWidget {
  const _GalleryPreview({required this.paths, required this.onRemove});

  final List<String> paths;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final size = paths.length == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: paths
              .take(2)
              .map(
                (String path) => _GalleryPhotoTile(
                  path: path,
                  size: size,
                  onRemove: () => onRemove(path),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _GalleryPhotoTile extends StatelessWidget {
  const _GalleryPhotoTile({
    required this.path,
    required this.size,
    required this.onRemove,
  });

  final String path;
  final double size;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => SizedBox(
              width: size,
              height: size,
              child: const ColoredBox(color: AppColors.softCanvas),
            ),
          ),
        ),
        Positioned(
          top: -10,
          right: -10,
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
                  CupertinoIcons.xmark_circle_fill,
                  color: AppColors.coral,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        onPressed: isLoading ? null : onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isLoading
                ? const CupertinoActivityIndicator(color: AppColors.coral)
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.add,
                        color: AppColors.coral,
                        size: 19,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: AppColors.coral,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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

class _SkipForNowButton extends StatelessWidget {
  const _SkipForNowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: const Text(
          'Skip for now',
          style: TextStyle(
            color: AppColors.coral,
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
