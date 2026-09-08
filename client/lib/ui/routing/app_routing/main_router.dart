import 'package:flutter/cupertino.dart';
import 'package:honest_dating/repositories/base/base_repositories_factory.dart';
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
import 'package:honest_dating/ui/screens/registration/verification_code_screen.dart';
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
            return const AgeEligibilityScreen();
          case BaseRouter.consent:
            return const ConsentScreen();
          case BaseRouter.identityVerification:
            return IdentityVerificationScreen(
              repository: _repositoriesFactory
                  .makeIdentityVerificationRepository(),
            );
          case BaseRouter.profileSetup:
            return const PlaceholderScreen(
              title: 'Profile setup',
              message:
                  'Your selfie check is complete. Profile setup will be added in the next approved slice.',
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
