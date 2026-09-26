import 'package:firebase_auth/firebase_auth.dart';
import 'package:honest_dating/models/profile_setup_draft.dart';
import 'package:honest_dating/repositories/base/base_authenticated_account_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_setup_repository.dart';
import 'package:image_picker/image_picker.dart';

class AppProfileSetupRepository implements BaseProfileSetupRepository {
  AppProfileSetupRepository({
    required BaseAuthenticatedAccountRepository authenticatedAccountRepository,
    FirebaseAuth? authentication,
  }) : _authenticatedAccountRepository = authenticatedAccountRepository,
       _authentication = authentication ?? FirebaseAuth.instance;

  ProfileSetupDraft _draft = const ProfileSetupDraft();
  final ImagePicker _imagePicker = ImagePicker();
  final BaseAuthenticatedAccountRepository _authenticatedAccountRepository;
  final FirebaseAuth _authentication;
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
    final userId = _authentication.currentUser?.uid;
    if (userId == null) {
      throw StateError('An authenticated account is required to register.');
    }
    await _authenticatedAccountRepository.ensureAccount(userId);
    await _authenticatedAccountRepository.completeMobileRegistration(userId);
    _isMobileRegistrationComplete = true;
  }
}
