import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/registration_flow/bloc/registration_profile_completion_bloc.dart';
import 'package:honest_dating/ui/widgets/app_action_button.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class RequiredProfileCompletionScreen extends StatelessWidget {
  const RequiredProfileCompletionScreen({
    super.key,
    required BaseProfileSetupRepository repository,
  }) : _repository = repository;

  final BaseProfileSetupRepository _repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationProfileCompletionBloc>(
      create: (BuildContext context) =>
          RegistrationProfileCompletionBloc(repository: _repository),
      child: const _RequiredProfileCompletionView(),
    );
  }
}

class _RequiredProfileCompletionView extends StatefulWidget {
  const _RequiredProfileCompletionView();

  @override
  State<_RequiredProfileCompletionView> createState() =>
      _RequiredProfileCompletionViewState();
}

class _RequiredProfileCompletionViewState
    extends State<_RequiredProfileCompletionView> {
  Future<void> _openAndRefresh(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) {
      context.read<RegistrationProfileCompletionBloc>().add(
        const RegistrationProfileCompletionRefreshed(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: BlocConsumer<RegistrationProfileCompletionBloc, RegistrationProfileCompletionState>(
        listenWhen: (previous, current) =>
            previous.isCompleted != current.isCompleted,
        listener: (BuildContext context, state) {
          if (state.isCompleted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              BaseRouter.home,
              (Route<dynamic> route) => false,
            );
          }
        },
        builder: (BuildContext context, state) {
          final hasCoreRegistration =
              state.draft.isRegistrationRequiredComplete;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNavigationBar(
                title: 'Complete profile',
                leading: _BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    children: [
                      const Text(
                        'One thing to do next: complete your profile.',
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
                        'To make your profile ready for others to discover, add at least 5 interests and 2 additional photos to your Gallery. Your interests help people discover you through shared interests and receive Target Me posts that fit what you are into. There are 33 categories to explore.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _CompletionRequirement(
                        title: 'Interests',
                        detail: '${state.draft.interests.length} of 5 selected',
                        isComplete:
                            state.draft.hasRequiredRegistrationInterests,
                        actionLabel: 'Add interests',
                        onPressed: () => _openAndRefresh(
                          BaseRouter.registrationInterestCategories,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _CompletionRequirement(
                        title: 'Gallery photos',
                        detail:
                            '${state.draft.galleryPhotoPaths.length} of 2 added',
                        isComplete:
                            state.draft.hasRequiredRegistrationGalleryPhotos,
                        actionLabel: 'Add gallery photos',
                        onPressed: () =>
                            _openAndRefresh(BaseRouter.profileBuilderGallery),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '100 Questions for Us is optional. You can always add more interests, photos, and answers later.',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (!hasCoreRegistration) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Some required registration details are missing. Go back and complete them first.',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      AppPrimaryButton(
                        label: 'Complete Profile',
                        isLoading: state.isCompleting,
                        onPressed: state.canComplete
                            ? () {
                                context
                                    .read<RegistrationProfileCompletionBloc>()
                                    .add(
                                      const RegistrationProfileCompletionRequested(),
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

class _CompletionRequirement extends StatelessWidget {
  const _CompletionRequirement({
    required this.title,
    required this.detail,
    required this.isComplete,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String detail;
  final bool isComplete;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  isComplete
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  color: isComplete ? AppColors.coral : AppColors.line,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              style: const TextStyle(color: AppColors.mutedInk, fontSize: 14),
            ),
            const SizedBox(height: 6),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 5),
              onPressed: onPressed,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: AppColors.coral,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
