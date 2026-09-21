import 'package:flutter/cupertino.dart';

abstract interface class BaseRouter {
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String likes = '/likes';
  static const String matches = '/matches';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String phoneVerification = '/registration/phone-verification';
  static const String phoneVerificationCode =
      '/registration/phone-verification-code';
  static const String ageEligibility = '/registration/age-eligibility';
  static const String consent = '/registration/consent';
  static const String identityVerification =
      '/registration/identity-verification';
  static const String profileSetup = '/registration/profile-setup';
  static const String profileSetupComplete =
      '/registration/profile-setup/complete';
  static const String profilePhoto = '/registration/profile-photo';
  static const String profilePhotoValidation =
      '/registration/profile-photo-validation';
  static const String profileAboutMe = '/registration/profile-about-me';
  static const String profileInterests = '/registration/profile-interests';
  static const String profileReview = '/registration/profile-review';
  static const String registrationCoreDetails = '/registration/core-details';
  static const String registrationMainPhoto = '/registration/main-photo';
  static const String registrationAttribute = '/registration/attribute';
  static const String registrationFriendshipOnlyConfirmation =
      '/registration/friendship-only-confirmation';
  static const String registrationReligiosity = '/registration/religiosity';
  static const String registrationComplete = '/registration/complete';
  static const String registrationInterestCategories =
      '/registration/interests/categories';
  static const String registrationInterestPicker =
      '/registration/interests/picker';
  static const String profileBuilder = '/profile-builder';
  static const String profileBuilderGallery = '/profile-builder/gallery';
  static const String termsOfService = '/legal/terms-of-service';
  static const String privacyPolicy = '/legal/privacy-policy';

  Route<void> onGenerateRoute(RouteSettings settings);
}
