import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:honest_dating/config/backend_configuration.dart';
import 'package:honest_dating/models/discovery_profile.dart';
import 'package:honest_dating/repositories/base/base_discovery_repository.dart';
import 'package:http/http.dart' as http;

/// Reads Discover profiles, media metadata, and viewer-specific relationship
/// state from Firebase. Relationship transitions go through Cloud Run so both
/// users' Firestore projections are updated atomically.
class AppDiscoveryRepository implements BaseDiscoveryRepository {
  AppDiscoveryRepository({
    FirebaseAuth? authentication,
    FirebaseAppCheck? appCheck,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    http.Client? client,
  }) : _authentication = authentication ?? FirebaseAuth.instance,
       _appCheck = appCheck ?? FirebaseAppCheck.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _client = client ?? http.Client();

  final FirebaseAuth _authentication;
  final FirebaseAppCheck _appCheck;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final http.Client _client;
  final Map<String, DiscoveryProfile> _profiles = <String, DiscoveryProfile>{};

  @override
  Future<List<DiscoveryProfile>> loadProfiles() async {
    final snapshot = await _firestore
        .collectionGroup('profiles')
        .orderBy('displayOrder')
        .get();
    final profiles = await Future.wait(snapshot.docs.map(_profileFromSnapshot));
    for (final profile in profiles) {
      _profiles[profile.id] = profile;
    }
    return List<DiscoveryProfile>.unmodifiable(profiles);
  }

  @override
  Future<DiscoveryProfile> loadProfile(String profileId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(profileId)
        .collection('profiles')
        .doc('discovery')
        .get();
    if (!snapshot.exists) {
      throw StateError('This profile is no longer available.');
    }
    final profile = await _profileFromSnapshot(snapshot);
    _profiles[profile.id] = profile;
    return profile;
  }

  @override
  Future<List<DiscoveryProfile>> loadRelationshipProfiles() async {
    final viewerId = _authentication.currentUser?.uid;
    if (viewerId == null) {
      throw StateError('Please sign in again to view your connections.');
    }
    final snapshot = await _firestore
        .collection('users')
        .doc(viewerId)
        .collection('relationships')
        .get();
    final profiles = await Future.wait(
      snapshot.docs.map((document) => loadProfile(document.id)),
    );
    return List<DiscoveryProfile>.unmodifiable(profiles);
  }

  @override
  Future<DiscoveryProfile> sendLike({
    required String profileId,
    required String reason,
  }) async {
    _validateReason(reason);
    final profile = await loadProfile(profileId);
    final relationship = profile.relationship;

    if (relationship.friendship != DiscoveryFriendshipState.none) {
      throw StateError(
        'Romantic interest is unavailable because a friendship connection already exists or is pending.',
      );
    }

    switch (relationship.romantic) {
      case DiscoveryRomanticState.none:
        return _performRelationshipAction(
          profile.copyWith(
            relationship: relationship.copyWith(
              romantic: DiscoveryRomanticState.likeSent,
              outgoingLikeReason: reason.trim(),
            ),
          ),
          pathSuffix: 'likes',
          reason: reason,
        );
      case DiscoveryRomanticState.likeReceived:
        return _performRelationshipAction(
          profile.copyWith(
            relationship: relationship.copyWith(
              romantic: DiscoveryRomanticState.matched,
              outgoingLikeReason: reason.trim(),
            ),
          ),
          pathSuffix: 'likes',
          reason: reason,
        );
      case DiscoveryRomanticState.likeSent:
        throw StateError('You have already sent a Like to this person.');
      case DiscoveryRomanticState.matched:
        throw StateError('You are already matched with this person.');
      case DiscoveryRomanticState.unavailable:
        throw StateError('Romantic interest is unavailable for this profile.');
    }
  }

  @override
  Future<DiscoveryProfile> sendFriendshipOffer({
    required String profileId,
    required String reason,
  }) async {
    _validateReason(reason);
    final profile = await loadProfile(profileId);
    final relationship = profile.relationship;

    if (relationship.friendship != DiscoveryFriendshipState.none) {
      throw StateError('A friendship connection already exists or is pending.');
    }
    if (relationship.romantic == DiscoveryRomanticState.likeSent) {
      throw StateError(
        'You have already expressed romantic interest, so you cannot offer friendship at this time.',
      );
    }
    if (relationship.romantic == DiscoveryRomanticState.matched) {
      throw StateError('You are already matched with this person.');
    }

    return _performRelationshipAction(
      profile.copyWith(
        relationship: relationship.copyWith(
          romantic: DiscoveryRomanticState.unavailable,
          friendship: DiscoveryFriendshipState.offerSent,
          outgoingFriendshipReason: reason.trim(),
        ),
      ),
      pathSuffix: 'friendship-offers',
      reason: reason,
    );
  }

  @override
  Future<DiscoveryProfile> acceptFriendshipOffer(String profileId) async {
    final profile = await loadProfile(profileId);
    final relationship = profile.relationship;
    if (relationship.friendship != DiscoveryFriendshipState.offerReceived) {
      throw StateError('There is no friendship offer to accept.');
    }
    return _performRelationshipAction(
      profile.copyWith(
        relationship: relationship.copyWith(
          friendship: DiscoveryFriendshipState.friends,
          clearIncomingFriendshipReason: true,
        ),
      ),
      pathSuffix: 'friendship-offers/acceptance',
    );
  }

  Future<DiscoveryProfile> _profileFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('This profile is no longer available.');
    }
    final media = await snapshot.reference
        .collection('media')
        .orderBy('displayOrder')
        .get();
    final mediaUrls = <String, String>{};
    for (final document in media.docs) {
      final storagePath = document.data()['storagePath'];
      if (storagePath is! String || storagePath.isEmpty) {
        throw StateError('This profile contains invalid media metadata.');
      }
      mediaUrls[document.id] = await _storage.ref(storagePath).getDownloadURL();
    }

    final primaryMediaId = _requiredString(data, 'primaryMediaId');
    final primaryPhotoUrl = mediaUrls[primaryMediaId];
    if (primaryPhotoUrl == null) {
      throw StateError('This profile has no primary photo.');
    }
    final userId = snapshot.reference.parent.parent?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('This profile has an invalid user reference.');
    }
    final relationship = await _loadRelationship(userId);

    return DiscoveryProfile(
      id: userId,
      firstName: _requiredString(data, 'firstName'),
      age: _requiredInt(data, 'age'),
      distanceMiles: _requiredInt(data, 'distanceMiles'),
      locationLabel: _requiredString(data, 'locationLabel'),
      primaryPhotoUrl: primaryPhotoUrl,
      headline: _requiredString(data, 'headline'),
      galleryPhotoUrls: <String>[
        for (final entry in mediaUrls.entries)
          if (entry.key != primaryMediaId) entry.value,
      ],
      details: _detailsFrom(data['details']),
      interests: _stringsFrom(data['interests']),
      questions: _questionsFrom(data['questions']),
      relationship: relationship,
    );
  }

  Future<DiscoveryRelationship> _loadRelationship(String profileId) async {
    final viewerId = _authentication.currentUser?.uid;
    if (viewerId == null) {
      throw StateError('Please sign in again to view Discover.');
    }
    final snapshot = await _firestore
        .collection('users')
        .doc(viewerId)
        .collection('relationships')
        .doc(profileId)
        .get();
    final data = snapshot.data();
    if (data == null) {
      return const DiscoveryRelationship();
    }
    return DiscoveryRelationship(
      romantic: _enumValue(
        DiscoveryRomanticState.values,
        data['romanticState'],
        DiscoveryRomanticState.none,
      ),
      friendship: _enumValue(
        DiscoveryFriendshipState.values,
        data['friendshipState'],
        DiscoveryFriendshipState.none,
      ),
      outgoingLikeReason: data['outgoingLikeReason'] as String?,
      incomingLikeReason: data['incomingLikeReason'] as String?,
      outgoingFriendshipReason: data['outgoingFriendshipReason'] as String?,
      incomingFriendshipReason: data['incomingFriendshipReason'] as String?,
    );
  }

  Future<DiscoveryProfile> _performRelationshipAction(
    DiscoveryProfile profile, {
    required String pathSuffix,
    String? reason,
  }) async {
    final uri = BackendConfiguration.endpoint(
      '/v1/relationships/${Uri.encodeComponent(profile.id)}/$pathSuffix',
    );
    if (uri == null) {
      throw StateError('Connections are temporarily unavailable.');
    }
    final response = await _client.post(
      uri,
      headers: await _authenticatedHeaders(),
      body: jsonEncode(
        reason == null
            ? const <String, Object?>{}
            : <String, Object?>{'reason': reason.trim()},
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] as String?
          : null;
      throw StateError(message ?? 'The connection could not be updated.');
    }
    return loadProfile(profile.id);
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    // A debug-preview registration can establish its Firebase session before
    // App Check has minted its first token. Force both token providers to
    // refresh at the point an interaction is submitted, rather than silently
    // treating an initial empty token as a sent request.
    final idToken = await _authentication.currentUser?.getIdToken(true);
    final appCheckToken = await _appCheck.getToken(true);
    if (idToken == null ||
        idToken.isEmpty ||
        appCheckToken == null ||
        appCheckToken.isEmpty) {
      throw StateError(
        'Your secure session has expired. Please sign in again.',
      );
    }
    return <String, String>{
      'Authorization': 'Bearer $idToken',
      'X-Firebase-AppCheck': appCheckToken,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  T _enumValue<T extends Enum>(List<T> values, Object? rawValue, T fallback) {
    if (rawValue is String) {
      for (final value in values) {
        if (value.name == rawValue) {
          return value;
        }
      }
    }
    return fallback;
  }

  String _requiredString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw StateError('This profile contains an invalid $field value.');
  }

  int _requiredInt(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw StateError('This profile contains an invalid $field value.');
  }

  List<String> _stringsFrom(Object? rawValues) {
    if (rawValues is! Iterable<Object?>) {
      return const <String>[];
    }
    return rawValues.whereType<String>().toList(growable: false);
  }

  List<DiscoveryProfileDetail> _detailsFrom(Object? rawDetails) {
    if (rawDetails is! Iterable<Object?>) {
      return const <DiscoveryProfileDetail>[];
    }
    return rawDetails
        .whereType<Map<Object?, Object?>>()
        .map(
          (Map<Object?, Object?> detail) => DiscoveryProfileDetail(
            label: detail['label'] as String? ?? '',
            value: detail['value'] as String? ?? '',
          ),
        )
        .where(
          (DiscoveryProfileDetail detail) =>
              detail.label.isNotEmpty && detail.value.isNotEmpty,
        )
        .toList(growable: false);
  }

  List<DiscoveryProfileQuestion> _questionsFrom(Object? rawQuestions) {
    if (rawQuestions is! Iterable<Object?>) {
      return const <DiscoveryProfileQuestion>[];
    }
    return rawQuestions
        .whereType<Map<Object?, Object?>>()
        .map(
          (Map<Object?, Object?> question) => DiscoveryProfileQuestion(
            question: question['question'] as String? ?? '',
            answer: question['answer'] as String? ?? '',
          ),
        )
        .where(
          (DiscoveryProfileQuestion question) =>
              question.question.isNotEmpty && question.answer.isNotEmpty,
        )
        .toList(growable: false);
  }

  void _validateReason(String reason) {
    final length = reason.trim().length;
    if (length < 50 || length > 500) {
      throw StateError(
        'Write a personal reason between 50 and 500 characters.',
      );
    }
  }
}
