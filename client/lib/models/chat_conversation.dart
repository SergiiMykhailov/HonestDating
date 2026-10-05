class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantPhotoUrl,
    required this.connectionKind,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final String participantId;
  final String participantName;
  final String? participantPhotoUrl;
  final ChatConnectionKind connectionKind;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

enum ChatConnectionKind { match, friendship }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime? sentAt;
}
