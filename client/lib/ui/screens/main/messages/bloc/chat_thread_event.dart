import 'package:honest_dating/models/chat_conversation.dart';

sealed class ChatThreadEvent {
  const ChatThreadEvent();
}

class ChatThreadStarted extends ChatThreadEvent {
  const ChatThreadStarted();
}

class ChatThreadMessagesUpdated extends ChatThreadEvent {
  const ChatThreadMessagesUpdated(this.messages);

  final List<ChatMessage> messages;
}

class ChatThreadMessageSubmitted extends ChatThreadEvent {
  const ChatThreadMessageSubmitted(this.text);

  final String text;
}

class ChatThreadFailed extends ChatThreadEvent {
  const ChatThreadFailed(this.message);

  final String message;
}
