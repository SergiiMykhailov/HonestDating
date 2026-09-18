import 'package:honest_dating/models/profile_photo_verification.dart';

abstract interface class BaseProfilePhotoVerificationRepository {
  /// Uploads private staging objects then starts an opaque server session.
  /// Image bytes never pass through the Cloud Run HTTP API.
  Future<ProfilePhotoVerificationSession> uploadAndStartVerification({
    required String mainPhotoPath,
    required List<String> galleryPhotoPaths,
  });

  /// Checks an existing server-owned session. Callers retain the token so a
  /// temporary network failure can retry without uploading again.
  Future<ProfilePhotoVerificationStatus> getVerificationStatus(
    String verificationToken,
  );
}
