import 'package:flutter/cupertino.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/repositories/base/base_repositories_factory.dart';
import 'package:honest_dating/ui/screens/main/discover/discover_screen.dart';
import 'package:honest_dating/ui/screens/shared/placeholder_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required BaseRepositoriesFactory repositoriesFactory,
  }) : _repositoriesFactory = repositoriesFactory;

  final BaseRepositoriesFactory _repositoriesFactory;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: _RoundedOverlappingTabBar(
        height: 78,
        activeColor: AppColors.coral,
        inactiveColor: AppColors.mutedInk,
        backgroundColor: AppColors.canvas,
        border: const Border(top: BorderSide(color: AppColors.line)),
        items: [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.compass)),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart)),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2)),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_2)),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person)),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            switch (index) {
              case 0:
                return DiscoverScreen(
                  repository: _repositoriesFactory.makeDiscoveryRepository(),
                );
              case 1:
                return const PlaceholderScreen(
                  title: 'Likes',
                  message: 'Placeholder for future likes functionality.',
                );
              case 2:
                return const PlaceholderScreen(
                  title: 'Matches',
                  message: 'Placeholder for future match functionality.',
                );
              case 3:
                return const PlaceholderScreen(
                  title: 'Messages',
                  message: 'Placeholder for future conversations.',
                );
              default:
                return const PlaceholderScreen(
                  title: 'Profile',
                  message: 'Placeholder for future profile management.',
                );
            }
          },
        );
      },
    );
  }
}

class _RoundedOverlappingTabBar extends CupertinoTabBar {
  const _RoundedOverlappingTabBar({
    super.key,
    required super.items,
    super.onTap,
    super.currentIndex,
    super.backgroundColor,
    super.activeColor,
    super.inactiveColor,
    super.iconSize,
    super.height,
    super.border,
  });

  @override
  bool opaque(BuildContext context) => false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: super.build(context),
    );
  }

  @override
  CupertinoTabBar copyWith({
    Key? key,
    List<BottomNavigationBarItem>? items,
    Color? backgroundColor,
    Color? activeColor,
    Color? inactiveColor,
    double? iconSize,
    double? height,
    Border? border,
    int? currentIndex,
    ValueChanged<int>? onTap,
  }) {
    return _RoundedOverlappingTabBar(
      key: key ?? this.key,
      items: items ?? this.items,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      iconSize: iconSize ?? this.iconSize,
      height: height ?? this.height,
      border: border ?? this.border,
      currentIndex: currentIndex ?? this.currentIndex,
      onTap: onTap ?? this.onTap,
    );
  }
}
