import 'package:honest_dating/repositories/app_repositories/app_repositories_factory.dart';
import 'package:honest_dating/ui/routing/app_routing/main_router.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/routing/base/router_factory.dart';

class AppRouterFactory implements RouterFactory {
  @override
  BaseRouter createMainRouter() {
    return MainRouter(repositoriesFactory: AppRepositoriesFactory());
  }
}
