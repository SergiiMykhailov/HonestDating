import 'package:honest_dating/models/profile_setup_draft.dart';

abstract interface class BaseProfileSetupRepository {
  ProfileSetupDraft get draft;

  bool get isMobileRegistrationComplete;

  Future<void> saveDraft(ProfileSetupDraft draft);

  Future<String?> selectMainPhoto();

  Future<List<String>> selectGalleryPhotos();

  Future<void> completeMobileRegistration();
}
