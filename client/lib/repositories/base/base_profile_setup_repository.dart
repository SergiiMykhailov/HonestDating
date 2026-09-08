import 'package:honest_dating/models/profile_setup_draft.dart';

abstract interface class BaseProfileSetupRepository {
  ProfileSetupDraft get draft;

  Future<void> saveDraft(ProfileSetupDraft draft);
}
