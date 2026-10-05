import 'package:honest_dating/models/chat_conversation.dart';

sealed class ChatListEvent {
  const ChatListEvent();
}

class ChatListStarted extends ChatListEvent {
  const ChatListStarted();
}

class ChatListUpdated extends ChatListEvent {
  const ChatListUpdated(this.conversations);

  final List<ChatConversation> conversations;
}

class ChatListFailed extends ChatListEvent {
  const ChatListFailed();
}
