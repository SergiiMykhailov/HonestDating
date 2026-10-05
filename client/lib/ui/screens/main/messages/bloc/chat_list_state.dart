import 'package:honest_dating/models/chat_conversation.dart';

sealed class ChatListState {
  const ChatListState();
}

class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

class ChatListLoaded extends ChatListState {
  const ChatListLoaded(this.conversations);

  final List<ChatConversation> conversations;
}

class ChatListFailure extends ChatListState {
  const ChatListFailure();
}
