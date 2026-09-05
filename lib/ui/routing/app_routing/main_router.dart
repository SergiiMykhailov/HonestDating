import 'package:flutter/cupertino.dart';
import 'package:honest_dating/repositories/base/base_repositories_factory.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/main/discover/discover_screen.dart';
import 'package:honest_dating/ui/screens/main/main_shell.dart';
import 'package:honest_dating/ui/screens/onboarding/onboarding_screen.dart';
import 'package:honest_dating/ui/screens/shared/placeholder_screen.dart';

class MainRouter implements BaseRouter {
  MainRouter({required BaseRepositoriesFactory repositoriesFactory})
    : _repositoriesFactory = repositoriesFactory;

  final BaseRepositoriesFactory _repositoriesFactory;

  @override
  Route<void> onGenerateRoute(RouteSettings settings) {
    return CupertinoPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) {
        switch (settings.name) {
          case BaseRouter.home:
            return MainShell(repositoriesFactory: _repositoriesFactory);
          case BaseRouter.discover:
            return DiscoverScreen(
              repository: _repositoriesFactory.makeDiscoveryRepository(),
            );
          case BaseRouter.likes:
            return const PlaceholderScreen(
              title: 'Likes',
              message: 'Likes will be introduced in a future product slice.',
            );
          case BaseRouter.matches:
            return const PlaceholderScreen(
              title: 'Matches',
              message: 'Matches will be introduced in a future product slice.',
            );
          case BaseRouter.messages:
            return const PlaceholderScreen(
              title: 'Messages',
              message: 'Messages will be introduced in a future product slice.',
            );
          case BaseRouter.profile:
            return const PlaceholderScreen(
              title: 'Profile',
              message:
                  'Profile management will be introduced in a future product slice.',
            );
          case BaseRouter.onboarding:
          default:
            return const OnboardingScreen();
        }
      },
    );
  }
}
