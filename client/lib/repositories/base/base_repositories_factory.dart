import 'package:honest_dating/repositories/base/base_authentication_repository.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';

abstract interface class BaseRepositoriesFactory {
  BaseAuthenticationRepository makeAuthenticationRepository();

  BaseDiscoveryRepository makeDiscoveryRepository();
}
