import 'package:flutter/cupertino.dart';
import 'package:honest_dating/repositories/base/base_repositories_factory.dart';
import 'package:honest_dating/models/profile_photo_verification.dart';
import 'package:honest_dating/ui/localization/app_copy.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/main/discover/discover_screen.dart';
import 'package:honest_dating/ui/screens/main/main_shell.dart';
import 'package:honest_dating/ui/screens/onboarding/onboarding_screen.dart';
import 'package:honest_dating/ui/screens/registration/age_eligibility_screen.dart';
import 'package:honest_dating/ui/screens/registration/consent_screen.dart';
import 'package:honest_dating/ui/screens/registration/identity_verification_screen.dart';
import 'package:honest_dating/ui/screens/registration/legal_document_placeholder_screen.dart';
import 'package:honest_dating/ui/screens/registration/phone_verification_screen.dart';
import 'package:honest_dating/ui/screens/registration/bloc/profile_setup_bloc.dart';
import 'package:honest_dating/ui/screens/registration/profile_completion_screens.dart';
import 'package:honest_dating/ui/screens/registration/profile_photo_validation_screen.dart';
import 'package:honest_dating/ui/screens/registration/profile_setup_screen.dart';
import 'package:honest_dating/ui/screens/registration/verification_code_screen.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_attribute.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_attribute_screen.dart';
import 'package:honest_dating/ui/screens/registration_flow/bloc/registration_core_details_bloc.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_complete_screen.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_conditional_screens.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_core_details_screen.dart';
import 'package:honest_dating/ui/screens/registration_flow/registration_main_photo_screen.dart';
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
          case BaseRouter.phoneVerification:
            return const PhoneVerificationScreen();
          case BaseRouter.phoneVerificationCode:
            return const VerificationCodeScreen();
          case BaseRouter.ageEligibility:
            return AgeEligibilityScreen(
              profileSetupRepository: _repositoriesFactory
                  .makeProfileSetupRepository(),
            );
          case BaseRouter.consent:
            return const ConsentScreen();
          case BaseRouter.registrationCoreDetails:
            return RegistrationCoreDetailsScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
              step: settings.arguments is RegistrationCoreDetailsStep
                  ? settings.arguments! as RegistrationCoreDetailsStep
                  : RegistrationCoreDetailsStep.firstName,
            );
          case BaseRouter.identityVerification:
            return IdentityVerificationScreen(
              repository: _repositoriesFactory
                  .makeIdentityVerificationRepository(),
            );
          case BaseRouter.profileSetup:
            return ProfileSetupScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
              step: settings.arguments is ProfileSetupStep
                  ? settings.arguments! as ProfileSetupStep
                  : ProfileSetupStep.firstName,
            );
          case BaseRouter.profileSetupComplete:
            return const ProfileSetupCompletionScreen();
          case BaseRouter.profilePhoto:
            return ProfilePhotosScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
              verificationRepository: _repositoriesFactory
                  .makeProfilePhotoVerificationRepository(),
            );
          case BaseRouter.profilePhotoValidation:
            final session = settings.arguments;
            if (session is! ProfilePhotoVerificationSession) {
              return const PlaceholderScreen(
                title: 'Photo validation',
                message:
                    'Start again from your photos to validate your profile photo.',
              );
            }
            return ProfilePhotoValidationScreen(
              repository: _repositoriesFactory
                  .makeProfilePhotoVerificationRepository(),
              profileSetupRepository: _repositoriesFactory
                  .makeProfileSetupRepository(),
              session: session,
            );
          case BaseRouter.profileAboutMe:
            return ProfileAboutMeScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
              returnToBuilder:
                  settings.arguments is bool && (settings.arguments! as bool),
            );
          case BaseRouter.profileInterests:
            return ProfileInterestsScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
              returnToBuilder:
                  settings.arguments is bool && (settings.arguments! as bool),
            );
          case BaseRouter.profileReview:
            return ProfileReviewScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
            );
          case BaseRouter.registrationMainPhoto:
            return RegistrationMainPhotoScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
              verificationRepository: _repositoriesFactory
                  .makeProfilePhotoVerificationRepository(),
            );
          case BaseRouter.registrationAttribute:
            return RegistrationAttributeScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
              step: settings.arguments is RegistrationAttributeStep
                  ? settings.arguments! as RegistrationAttributeStep
                  : RegistrationAttributeStep.sexualOrientation,
            );
          case BaseRouter.registrationFriendshipOnlyConfirmation:
            return const RegistrationFriendshipOnlyConfirmationScreen();
          case BaseRouter.registrationReligiosity:
            return RegistrationReligiosityScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
            );
          case BaseRouter.registrationComplete:
            return RegistrationCompleteScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
            );
          case BaseRouter.profileBuilder:
            return ProfileBuilderScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
            );
          case BaseRouter.profileBuilderGallery:
            return ProfileBuilderGalleryScreen(
              repository: _repositoriesFactory.makeProfileSetupRepository(),
            );
          case BaseRouter.termsOfService:
            return const LegalDocumentPlaceholderScreen(
              title: AppCopy.consentTermsLabel,
              placeholder: AppCopy.termsOfServicePlaceholder,
            );
          case BaseRouter.privacyPolicy:
            return const LegalDocumentPlaceholderScreen(
              title: AppCopy.consentPrivacyLabel,
              placeholder: AppCopy.privacyPolicyPlaceholder,
            );
          case BaseRouter.onboarding:
          default:
            return OnboardingScreen(
              repository: _repositoriesFactory.makeAuthenticationRepository(),
            );
        }
      },
    );
  }
}
