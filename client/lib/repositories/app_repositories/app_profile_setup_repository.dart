import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';

class AppProfileSetupRepository implements BaseProfileSetupRepository {
  ProfileSetupDraft _draft = const ProfileSetupDraft();

  @override
  ProfileSetupDraft get draft => _draft;

  @override
  Future<void> saveDraft(ProfileSetupDraft draft) async {
    _draft = draft;
  }
}
