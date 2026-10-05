import 'package:honest_dating/models/chat_conversation.dart';

abstract interface class BaseMessagingRepository {
  Stream<List<ChatConversation>> watchConversations();

  Stream<ChatConversation?> watchConversation(String participantId);

  Stream<List<ChatMessage>> watchMessages(String participantId);

  Future<void> sendMessage({
    required String participantId,
    required String text,
  });

  Future<void> markConversationRead(String participantId);
}
