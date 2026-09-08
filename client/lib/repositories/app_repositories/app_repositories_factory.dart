import 'package:honest_dating/repositories/app_repositories/app_authentication_repository.dart';
import 'package:honest_dating/repositories/app_repositories/app_discovery_repository.dart';
import 'package:honest_dating/repositories/app_repositories/app_identity_verification_repository.dart';
import 'package:honest_dating/repositories/app_repositories/app_profile_setup_repository.dart';
import 'package:honest_dating/repositories/base/base_authentication_repository.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/repositories/base/base_identity_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/repositories/base/base_repositories_factory.dart';

class AppRepositoriesFactory implements BaseRepositoriesFactory {
  final BaseProfileSetupRepository _profileSetupRepository =
      AppProfileSetupRepository();

  @override
  BaseAuthenticationRepository makeAuthenticationRepository() {
    return AppAuthenticationRepository();
  }

  @override
  BaseDiscoveryRepository makeDiscoveryRepository() {
    return AppDiscoveryRepository();
  }

  @override
  BaseIdentityVerificationRepository makeIdentityVerificationRepository() {
    return AppIdentityVerificationRepository();
  }

  @override
  BaseProfileSetupRepository makeProfileSetupRepository() {
    return _profileSetupRepository;
  }
}
