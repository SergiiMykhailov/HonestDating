import 'package:flutter/cupertino.dart';
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
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.compass),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.heart),
            label: 'Likes',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profile',
          ),
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
