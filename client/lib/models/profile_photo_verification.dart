enum ProfilePhotoVerificationStatus { pending, approved, rejected, unavailable }

class StagedProfilePhoto {
  const StagedProfilePhoto({
    required this.photoId,
    required this.localPath,
    required this.isMain,
  });

  final String photoId;
  final String localPath;
  final bool isMain;
}

class ProfilePhotoVerificationSession {
  const ProfilePhotoVerificationSession({
    required this.verificationToken,
    required this.status,
    required this.mainPhoto,
    required this.galleryPhotos,
  });

  final String verificationToken;
  final ProfilePhotoVerificationStatus status;
  final StagedProfilePhoto mainPhoto;
  final List<StagedProfilePhoto> galleryPhotos;
}

class ProfilePhotoVerificationException implements Exception {
  const ProfilePhotoVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
