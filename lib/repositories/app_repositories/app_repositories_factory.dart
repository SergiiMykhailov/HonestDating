import 'package:honest_dating/repositories/app_repositories/app_discovery_repository.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/repositories/base/base_repositories_factory.dart';

class AppRepositoriesFactory implements BaseRepositoriesFactory {
  @override
  BaseDiscoveryRepository makeDiscoveryRepository() {
    return AppDiscoveryRepository();
  }
}
