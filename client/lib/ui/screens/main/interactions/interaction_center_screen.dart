import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/main/interactions/bloc/interaction_center_bloc.dart';
import 'package:honest_dating/ui/screens/main/interactions/bloc/interaction_center_event.dart';
import 'package:honest_dating/ui/screens/main/interactions/bloc/interaction_center_state.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class InteractionCenterScreen extends StatelessWidget {
  const InteractionCenterScreen({
    super.key,
    required BaseDiscoveryRepository repository,
    this.initialSection = InteractionSection.matches,
  }) : _repository = repository;

  final BaseDiscoveryRepository _repository;
  final InteractionSection initialSection;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InteractionCenterBloc>(
      create: (_) => InteractionCenterBloc(
        repository: _repository,
        initialSection: initialSection,
      )..add(const InteractionCenterLoadRequested()),
      child: const _InteractionCenterView(),
    );
  }
}

class _InteractionCenterView extends StatelessWidget {
  const _InteractionCenterView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        children: [
          const AppNavigationBar(title: 'Connections'),
          Expanded(
            child: BlocBuilder<InteractionCenterBloc, InteractionCenterState>(
              builder: (context, state) {
                if (state is InteractionCenterLoading) {
                  return const Center(
                    child: CupertinoActivityIndicator(color: AppColors.coral),
                  );
                }
                if (state is InteractionCenterFailure) {
                  return Center(
                    child: CupertinoButton(
                      onPressed: () => context
                          .read<InteractionCenterBloc>()
                          .add(const InteractionCenterLoadRequested()),
                      child: const Text(
                        'Could not load connections. Try again.',
                      ),
                    ),
                  );
                }
                final loaded = state as InteractionCenterLoaded;
                return _LoadedCenter(state: loaded);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadedCenter extends StatelessWidget {
  const _LoadedCenter({required this.state});

  final InteractionCenterLoaded state;

  @override
  Widget build(BuildContext context) {
    final sections = state.mode == InteractionCenterMode.romance
        ? const [
            InteractionSection.matches,
            InteractionSection.likesReceived,
            InteractionSection.likesSent,
          ]
        : const [
            InteractionSection.friends,
            InteractionSection.offersReceived,
            InteractionSection.offersSent,
          ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: CupertinoSlidingSegmentedControl<InteractionCenterMode>(
            groupValue: state.mode,
            thumbColor: AppColors.coral,
            children: {
              for (final mode in InteractionCenterMode.values)
                mode: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 18,
                  ),
                  child: Text(
                    mode == InteractionCenterMode.romance
                        ? 'Romance'
                        : 'Friendship',
                    style: TextStyle(
                      color: state.mode == mode
                          ? AppColors.canvas
                          : AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            },
            onValueChanged: (mode) {
              if (mode != null) {
                context.read<InteractionCenterBloc>().add(
                  InteractionCenterModeChanged(mode),
                );
              }
            },
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final section = sections[index];
              final selected = state.section == section;
              return CupertinoButton(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                color: selected ? AppColors.coral : AppColors.softCanvas,
                borderRadius: BorderRadius.circular(18),
                onPressed: () => context.read<InteractionCenterBloc>().add(
                  InteractionCenterSectionChanged(section),
                ),
                child: Text(
                  '${_sectionTitle(section)}  ${state.count(section)}',
                  style: TextStyle(
                    color: selected ? AppColors.canvas : AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: state.visibleProfiles.isEmpty
              ? Center(
                  child: Text(
                    'No ${_sectionTitle(state.section).toLowerCase()} yet.',
                    style: const TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 17,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: state.visibleProfiles.length,
                  itemBuilder: (context, index) => _ConnectionCard(
                    profile: state.visibleProfiles[index],
                    section: state.section,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.profile, required this.section});

  final DiscoveryProfile profile;
  final InteractionSection section;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(BaseRouter.discoveryProfile, arguments: profile),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(profile.primaryPhotoUrl, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xD9000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.firstName}, ${profile.age}',
                    style: const TextStyle(
                      color: AppColors.canvas,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _sectionTitle(section),
                    style: const TextStyle(
                      color: AppColors.canvas,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _sectionTitle(InteractionSection section) => switch (section) {
  InteractionSection.matches => 'Matches',
  InteractionSection.likesReceived => 'Likes Received',
  InteractionSection.likesSent => 'Likes Sent',
  InteractionSection.friends => 'Friends',
  InteractionSection.offersReceived => 'Offers Received',
  InteractionSection.offersSent => 'Offers Sent',
};
