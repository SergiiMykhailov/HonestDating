import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:image_picker/image_picker.dart';

class AppProfileSetupRepository implements BaseProfileSetupRepository {
  ProfileSetupDraft _draft = const ProfileSetupDraft();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isMobileRegistrationComplete = false;

  @override
  ProfileSetupDraft get draft => _draft;

  @override
  bool get isMobileRegistrationComplete => _isMobileRegistrationComplete;

  @override
  Future<void> saveDraft(ProfileSetupDraft draft) async {
    _draft = draft;
  }

  @override
  Future<String?> selectMainPhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  @override
  Future<List<String>> selectGalleryPhotos() async {
    final images = await _imagePicker.pickMultiImage();
    return images.map((XFile image) => image.path).toList();
  }

  @override
  Future<void> completeMobileRegistration() async {
    _isMobileRegistrationComplete = true;
  }
}
