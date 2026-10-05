import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:honest_dating/config/backend_configuration.dart';
import 'package:honest_dating/models/chat_conversation.dart';
import 'package:honest_dating/repositories/base/base_messaging_repository.dart';
import 'package:http/http.dart' as http;

/// Owner-only Firestore reads paired with server-authoritative message writes.
class AppMessagingRepository implements BaseMessagingRepository {
  AppMessagingRepository({
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

  @override
  Stream<List<ChatConversation>> watchConversations() async* {
    final viewerId = _requiredViewerId();
    await for (final snapshot in _conversations(viewerId).snapshots()) {
      final conversations = await Future.wait(
        snapshot.docs.map(_conversationFromDocument),
      );
      conversations.sort((first, second) {
        final firstTime = first.lastMessageAt ?? DateTime(0);
        final secondTime = second.lastMessageAt ?? DateTime(0);
        return secondTime.compareTo(firstTime);
      });
      yield List<ChatConversation>.unmodifiable(conversations);
    }
  }

  @override
  Stream<ChatConversation?> watchConversation(String participantId) async* {
    final viewerId = _requiredViewerId();
    await for (final snapshot in _conversations(
      viewerId,
    ).where('participantUid', isEqualTo: participantId).limit(1).snapshots()) {
      if (snapshot.docs.isEmpty) {
        yield null;
      } else {
        yield await _conversationFromDocument(snapshot.docs.single);
      }
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String participantId) async* {
    final viewerId = _requiredViewerId();
    await for (final conversationSnapshot in _conversations(
      viewerId,
    ).where('participantUid', isEqualTo: participantId).limit(1).snapshots()) {
      if (conversationSnapshot.docs.isEmpty) {
        yield const <ChatMessage>[];
        continue;
      }
      final conversation = conversationSnapshot.docs.single;
      final messages = await conversation.reference
          .collection('messages')
          .orderBy('sentAt')
          .get();
      yield messages.docs
          .map((document) => _messageFromDocument(document, viewerId))
          .toList(growable: false);
    }
  }

  @override
  Future<void> sendMessage({
    required String participantId,
    required String text,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty || normalizedText.runes.length > 1000) {
      throw StateError('Write a message of up to 1,000 characters.');
    }
    await _post(
      '/v1/conversations/${Uri.encodeComponent(participantId)}/messages',
      <String, String>{'text': normalizedText},
    );
  }

  @override
  Future<void> markConversationRead(String participantId) {
    return _post(
      '/v1/conversations/${Uri.encodeComponent(participantId)}/read',
      const <String, String>{},
    );
  }

  CollectionReference<Map<String, dynamic>> _conversations(String viewerId) {
    return _firestore
        .collection('users')
        .doc(viewerId)
        .collection('conversations');
  }

  Future<ChatConversation> _conversationFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();
    final participantId = data['participantUid'];
    if (participantId is! String || participantId.isEmpty) {
      throw StateError('This conversation has an invalid participant.');
    }
    final profile = await _firestore
        .collection('users')
        .doc(participantId)
        .collection('profiles')
        .doc('discovery')
        .get();
    final profileData = profile.data();
    final name = profileData?['firstName'] as String? ?? 'Member';
    String? photoUrl;
    final mediaId = profileData?['primaryMediaId'];
    if (mediaId is String && mediaId.isNotEmpty) {
      final media = await profile.reference
          .collection('media')
          .doc(mediaId)
          .get();
      final storagePath = media.data()?['storagePath'];
      if (storagePath is String && storagePath.isNotEmpty) {
        photoUrl = await _storage.ref(storagePath).getDownloadURL();
      }
    }
    return ChatConversation(
      id: document.id,
      participantId: participantId,
      participantName: name,
      participantPhotoUrl: photoUrl,
      connectionKind: data['connectionKind'] == 'friendship'
          ? ChatConnectionKind.friendship
          : ChatConnectionKind.match,
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: _date(data['lastMessageAt']),
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  ChatMessage _messageFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    String viewerId,
  ) {
    final data = document.data();
    return ChatMessage(
      id: document.id,
      text: data['text'] as String? ?? '',
      isMine: data['senderUid'] == viewerId,
      sentAt: _date(data['sentAt']),
    );
  }

  DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;

  String _requiredViewerId() {
    final uid = _authentication.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Please sign in again to view messages.');
    }
    return uid;
  }

  Future<void> _post(String path, Map<String, String> body) async {
    final uri = BackendConfiguration.endpoint(path);
    if (uri == null) {
      throw StateError('Messages are temporarily unavailable.');
    }
    final response = await _client.post(
      uri,
      headers: await _authenticatedHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final decoded = jsonDecode(response.body);
    final message = decoded is Map<String, dynamic>
        ? decoded['error'] as String?
        : null;
    throw StateError(
      message ?? 'The message could not be sent. Please try again.',
    );
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
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
}
