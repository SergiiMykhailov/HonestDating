import 'package:honest_dating/repositories/base/base_authentication_repository.dart';
import 'package:honest_dating/repositories/base/base_authenticated_account_repository.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:honest_dating/repositories/base/base_identity_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_messaging_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_photo_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

abstract interface class BaseRepositoriesFactory {
  BaseAuthenticatedAccountRepository makeAuthenticatedAccountRepository();

  BaseAuthenticationRepository makeAuthenticationRepository();

  BaseDiscoveryRepository makeDiscoveryRepository();

  BaseIdentityVerificationRepository makeIdentityVerificationRepository();

  BaseMessagingRepository makeMessagingRepository();

  BaseProfilePhotoVerificationRepository
  makeProfilePhotoVerificationRepository();

  BaseProfileSetupRepository makeProfileSetupRepository();
}
