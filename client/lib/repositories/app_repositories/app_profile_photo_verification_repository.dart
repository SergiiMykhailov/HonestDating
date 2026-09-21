import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:honest_dating/config/backend_configuration.dart';
import 'package:honest_dating/models/profile_photo_verification.dart';
import 'package:honest_dating/repositories/base/base_identity_verification_repository.dart';
import 'package:honest_dating/repositories/base/base_profile_photo_verification_repository.dart';
import 'package:http/http.dart' as http;

class AppProfilePhotoVerificationRepository
    implements BaseProfilePhotoVerificationRepository {
  AppProfilePhotoVerificationRepository({
    FirebaseAuth? authentication,
    FirebaseAppCheck? appCheck,
    FirebaseStorage? storage,
    http.Client? client,
    required BaseIdentityVerificationRepository identityVerificationRepository,
  }) : _authentication = authentication ?? FirebaseAuth.instance,
       _appCheck = appCheck ?? FirebaseAppCheck.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _client = client ?? http.Client(),
       _identityVerificationRepository = identityVerificationRepository;

  final FirebaseAuth _authentication;
  final FirebaseAppCheck _appCheck;
  final FirebaseStorage _storage;
  final http.Client _client;
  final BaseIdentityVerificationRepository _identityVerificationRepository;
  final Random _random = Random.secure();
  final Set<String> _simulatorPreviewVerificationTokens = <String>{};

  @override
  Future<ProfilePhotoVerificationSession> uploadAndStartVerification({
    required String mainPhotoPath,
    required List<String> galleryPhotoPaths,
  }) async {
    final isSimulatorPreview = await _identityVerificationRepository
        .isLivenessCheckSkippedOnCurrentDevice();
    final livenessVerificationToken =
        _identityVerificationRepository.activeLivenessVerificationToken;
    if (!isSimulatorPreview &&
        (livenessVerificationToken == null ||
            livenessVerificationToken.isEmpty)) {
      throw const ProfilePhotoVerificationException(
        'Complete the selfie check before adding profile photos.',
      );
    }
    final mainPhoto = await _uploadPhoto(mainPhotoPath, isMain: true);
    final galleryPhotos = <StagedProfilePhoto>[];
    for (final photoPath in galleryPhotoPaths) {
      galleryPhotos.add(await _uploadPhoto(photoPath, isMain: false));
    }

    // A simulator has no trustworthy FaceTec liveness result. Keep its image
    // upload coverage, but never send a client-declared simulator bypass to
    // Cloud Run. The in-memory preview session advances only this local flow.
    if (isSimulatorPreview) {
      final token = 'simulator-preview-${_newPhotoID()}';
      _simulatorPreviewVerificationTokens.add(token);
      return ProfilePhotoVerificationSession(
        verificationToken: token,
        status: ProfilePhotoVerificationStatus.pending,
        mainPhoto: mainPhoto,
        galleryPhotos: List<StagedProfilePhoto>.unmodifiable(galleryPhotos),
      );
    }

    final response =
        await _post('/v1/profile-photo-verifications', <String, Object?>{
          'mainPhotoId': mainPhoto.photoId,
          'galleryPhotoIds': galleryPhotos
              .map((StagedProfilePhoto photo) => photo.photoId)
              .toList(),
          'livenessVerificationToken': livenessVerificationToken,
        });
    final token = response['verificationToken'];
    final status = _statusFromValue(response['status']);
    if (token is! String ||
        token.isEmpty ||
        status != ProfilePhotoVerificationStatus.pending) {
      throw const ProfilePhotoVerificationException(
        'We could not start your photo validation. Please try again.',
      );
    }
    return ProfilePhotoVerificationSession(
      verificationToken: token,
      status: status,
      mainPhoto: mainPhoto,
      galleryPhotos: List<StagedProfilePhoto>.unmodifiable(galleryPhotos),
    );
  }

  @override
  Future<ProfilePhotoVerificationStatus> getVerificationStatus(
    String verificationToken,
  ) async {
    if (_simulatorPreviewVerificationTokens.contains(verificationToken)) {
      return ProfilePhotoVerificationStatus.approved;
    }
    final encodedToken = Uri.encodeComponent(verificationToken);
    final response = await _get(
      '/v1/profile-photo-verifications/$encodedToken',
    );
    return _statusFromValue(response['status']);
  }

  Future<StagedProfilePhoto> _uploadPhoto(
    String localPath, {
    required bool isMain,
  }) async {
    final user = _authentication.currentUser;
    if (user == null) {
      throw const ProfilePhotoVerificationException(
        'Please sign in again before uploading photos.',
      );
    }
    final contentType = _contentTypeFor(localPath);
    if (contentType == null) {
      throw const ProfilePhotoVerificationException(
        'Choose a JPEG, PNG, WebP, HEIC, or HEIF photo.',
      );
    }

    final photo = StagedProfilePhoto(
      photoId: _newPhotoID(),
      localPath: localPath,
      isMain: isMain,
    );
    final file = File(localPath);
    if (!await file.exists()) {
      throw const ProfilePhotoVerificationException(
        'One of the selected photos is no longer available. Please choose it again.',
      );
    }
    await _storage
        .ref(
          'users/${user.uid}/profile-photo-staging/${photo.photoId}/original',
        )
        .putFile(file, SettableMetadata(contentType: contentType));
    return photo;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final uri = _endpoint(path);
    final response = await _client.post(
      uri,
      headers: await _authenticatedHeaders(),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = _endpoint(path);
    final response = await _client.get(
      uri,
      headers: await _authenticatedHeaders(),
    );
    return _decodeResponse(response);
  }

  Uri _endpoint(String path) {
    final endpoint = BackendConfiguration.endpoint(path);
    if (endpoint == null) {
      throw const ProfilePhotoVerificationException(
        'Photo validation is not configured in this build. Please try again later.',
      );
    }
    return endpoint;
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    final user = _authentication.currentUser;
    final idToken = await user?.getIdToken();
    final appCheckToken = await _appCheck.getToken();
    if (idToken == null ||
        idToken.isEmpty ||
        appCheckToken == null ||
        appCheckToken.isEmpty) {
      throw const ProfilePhotoVerificationException(
        'Your secure session has expired. Please sign in again and retry.',
      );
    }
    return <String, String>{
      'Authorization': 'Bearer $idToken',
      'X-Firebase-AppCheck': appCheckToken,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    final body = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfilePhotoVerificationException(
        _serverMessage(body['error']) ??
            'We could not reach photo validation. Please try again.',
      );
    }
    return body;
  }

  String? _serverMessage(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  ProfilePhotoVerificationStatus _statusFromValue(Object? value) {
    switch (value) {
      case 'pending':
        return ProfilePhotoVerificationStatus.pending;
      case 'approved':
        return ProfilePhotoVerificationStatus.approved;
      case 'rejected':
        return ProfilePhotoVerificationStatus.rejected;
      case 'unavailable':
      default:
        return ProfilePhotoVerificationStatus.unavailable;
    }
  }

  String _newPhotoID() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String? _contentTypeFor(String path) {
    final normalizedPath = path.toLowerCase();
    if (normalizedPath.endsWith('.jpg') || normalizedPath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalizedPath.endsWith('.png')) {
      return 'image/png';
    }
    if (normalizedPath.endsWith('.webp')) {
      return 'image/webp';
    }
    if (normalizedPath.endsWith('.heic')) {
      return 'image/heic';
    }
    if (normalizedPath.endsWith('.heif')) {
      return 'image/heif';
    }
    return null;
  }
}
