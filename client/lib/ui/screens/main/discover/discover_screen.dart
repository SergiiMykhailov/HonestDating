import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discover_screen_bloc.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discover_screen_event.dart';
import 'package:honest_dating/ui/screens/main/discover/bloc/discover_screen_state.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key, required BaseDiscoveryRepository repository})
    : _repository = repository;

  final BaseDiscoveryRepository _repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiscoverScreenBloc>(
      create: (BuildContext context) =>
          DiscoverScreenBloc(repository: _repository)
            ..add(const DiscoverScreenLoadRequested()),
      child: const _DiscoverView(),
    );
  }
}

class _DiscoverView extends StatefulWidget {
  const _DiscoverView();

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Column(
        children: [
          const AppNavigationBar(title: 'Discover'),
          Expanded(
            child: BlocBuilder<DiscoverScreenBloc, DiscoverScreenState>(
              builder: (BuildContext context, DiscoverScreenState state) {
                if (state is DiscoverScreenLoading) {
                  return const Center(
                    child: CupertinoActivityIndicator(
                      color: AppColors.coral,
                      radius: 13,
                    ),
                  );
                }

                if (state is DiscoverScreenFailure) {
                  return _DiscoverFailure(
                    onRetry: () {
                      context.read<DiscoverScreenBloc>().add(
                        const DiscoverScreenLoadRequested(),
                      );
                    },
                  );
                }

                final loaded = state as DiscoverScreenLoaded;
                if (loaded.profiles.isEmpty) {
                  return _DiscoverEmptyState(
                    onRefresh: () {
                      context.read<DiscoverScreenBloc>().add(
                        const DiscoverScreenLoadRequested(),
                      );
                    },
                  );
                }

                return PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: loaded.profiles.length,
                  onPageChanged: (int index) {
                    context.read<DiscoverScreenBloc>().add(
                      DiscoverProfilePositionChanged(index),
                    );
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return _DiscoverProfileCard(
                      profile: loaded.profiles[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverProfileCard extends StatelessWidget {
  const _DiscoverProfileCard({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final tabBarInset = MediaQuery.paddingOf(context).bottom;
    return Semantics(
      button: true,
      label: 'Open ${profile.firstName}\'s profile',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(BaseRouter.discoveryProfile, arguments: profile);
          if (context.mounted) {
            context.read<DiscoverScreenBloc>().add(
              const DiscoverScreenLoadRequested(),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              profile.primaryPhotoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: AppColors.softCanvas),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x08000000),
                    Color(0xBA000000),
                  ],
                  stops: [0.38, 0.58, 1],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: tabBarInset + 22,
              child: _ProfileCardCaption(profile: profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCardCaption extends StatelessWidget {
  const _ProfileCardCaption({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_relationshipStatus(profile.relationship) case final status?) ...[
          _DiscoverRelationshipBadge(status: status),
          const SizedBox(height: 10),
        ],
        Text(
          '${profile.firstName}, ${profile.age}',
          style: const TextStyle(
            color: AppColors.canvas,
            fontSize: 31,
            height: 1.08,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${profile.distanceMiles} ${profile.distanceMiles == 1 ? 'mile' : 'miles'} away',
          style: const TextStyle(
            color: AppColors.canvas,
            fontSize: 17,
            height: 1.2,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

_DiscoverRelationshipStatus? _relationshipStatus(
  DiscoveryRelationship relationship,
) {
  if (relationship.friendship == DiscoveryFriendshipState.offerReceived) {
    return const _DiscoverRelationshipStatus(
      label: 'Friendship offer received',
      icon: CupertinoIcons.person_2_fill,
      color: AppColors.plum,
      isActionRequired: true,
    );
  }
  if (relationship.friendship == DiscoveryFriendshipState.offerSent) {
    return const _DiscoverRelationshipStatus(
      label: 'Friendship offer sent',
      icon: CupertinoIcons.person_2_fill,
      color: AppColors.plum,
    );
  }
  if (relationship.romantic == DiscoveryRomanticState.likeSent) {
    return const _DiscoverRelationshipStatus(
      label: 'Like sent',
      icon: CupertinoIcons.heart_fill,
      color: AppColors.coral,
    );
  }
  return null;
}

class _DiscoverRelationshipStatus {
  const _DiscoverRelationshipStatus({
    required this.label,
    required this.icon,
    required this.color,
    this.isActionRequired = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isActionRequired;
}

class _DiscoverRelationshipBadge extends StatelessWidget {
  const _DiscoverRelationshipBadge({required this.status});

  final _DiscoverRelationshipStatus status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.canvas.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, color: status.color, size: 16),
              const SizedBox(width: 6),
              Text(
                status.label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                status.isActionRequired
                    ? CupertinoIcons.chevron_right
                    : CupertinoIcons.check_mark,
                color: status.color,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverEmptyState extends StatelessWidget {
  const _DiscoverEmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 74,
                height: 74,
                child: Icon(
                  CupertinoIcons.compass,
                  color: AppColors.coral,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No profiles available right now',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'There is nobody new in your current Discover pool. Try refreshing, or adjust your filters when they are available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedInk,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              onPressed: onRefresh,
              child: const Text(
                'Refresh results',
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
    );
  }
}

class _DiscoverFailure extends StatelessWidget {
  const _DiscoverFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoButton(
        onPressed: onRetry,
        child: const Text(
          'We could not load Discover. Try again.',
          style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
