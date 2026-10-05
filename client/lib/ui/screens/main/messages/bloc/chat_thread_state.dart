import 'package:honest_dating/models/chat_conversation.dart';

class ChatThreadState {
  const ChatThreadState({
    this.messages = const <ChatMessage>[],
    this.isSending = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;

  ChatThreadState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) => ChatThreadState(
    messages: messages ?? this.messages,
    isSending: isSending ?? this.isSending,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
