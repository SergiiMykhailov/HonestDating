import 'package:honest_dating/repositories/app_repositories/app_authentication_repository.dart';
import 'package:honest_dating/repositories/app_repositories/app_authenticated_account_repository.dart';
import 'package:honest_dating/repositories/app_repositories/app_discovery_repository.dart';
import 'package:honest_dating/repositories/app_repositories/app_identity_verification_repository.dart';
import 'package:honest_dating/repositories/app_repositories/app_profile_setup_repository.dart';
import 'package:honest_dating/repositories/app_repositories/app_profile_photo_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_authentication_repository.dart';
import 'package:honest_dating/repositories/base/base_authenticated_account_repository.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/repositories/base/base_identity_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_photo_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_repositories_factory.dart';

class AppRepositoriesFactory implements BaseRepositoriesFactory {
  final BaseAuthenticatedAccountRepository _authenticatedAccountRepository =
      AppAuthenticatedAccountRepository();
  late final BaseProfileSetupRepository _profileSetupRepository =
      AppProfileSetupRepository(
        authenticatedAccountRepository: _authenticatedAccountRepository,
      );
  final BaseIdentityVerificationRepository _identityVerificationRepository =
      AppIdentityVerificationRepository();
  late final BaseProfilePhotoVerificationRepository
  _profilePhotoVerificationRepository = AppProfilePhotoVerificationRepository(
    identityVerificationRepository: _identityVerificationRepository,
  );

  @override
  BaseAuthenticatedAccountRepository makeAuthenticatedAccountRepository() {
    return _authenticatedAccountRepository;
  }

  @override
  BaseAuthenticationRepository makeAuthenticationRepository() {
    return AppAuthenticationRepository(
      authenticatedAccountRepository: _authenticatedAccountRepository,
    );
  }

  @override
  BaseDiscoveryRepository makeDiscoveryRepository() {
    return AppDiscoveryRepository();
  }

  @override
  BaseIdentityVerificationRepository makeIdentityVerificationRepository() {
    return _identityVerificationRepository;
  }

  @override
  BaseProfilePhotoVerificationRepository
  makeProfilePhotoVerificationRepository() {
    return _profilePhotoVerificationRepository;
  }

  @override
  BaseProfileSetupRepository makeProfileSetupRepository() {
    return _profileSetupRepository;
  }
}
