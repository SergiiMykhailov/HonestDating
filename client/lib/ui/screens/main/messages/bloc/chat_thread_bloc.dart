import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/chat_conversation.dart';
import 'package:honest_dating/repositories/base/base_messaging_repository.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_thread_event.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_thread_state.dart';

class ChatThreadBloc extends Bloc<ChatThreadEvent, ChatThreadState> {
  ChatThreadBloc({
    required BaseMessagingRepository repository,
    required String participantId,
  }) : _repository = repository,
       _participantId = participantId,
       super(const ChatThreadState()) {
    on<ChatThreadStarted>(_onStarted);
    on<ChatThreadMessagesUpdated>(_onMessagesUpdated);
    on<ChatThreadMessageSubmitted>(_onMessageSubmitted);
    on<ChatThreadFailed>(_onFailed);
  }

  final BaseMessagingRepository _repository;
  final String _participantId;
  StreamSubscription<List<ChatMessage>>? _subscription;

  Future<void> _onStarted(
    ChatThreadStarted event,
    Emitter<ChatThreadState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _repository
        .watchMessages(_participantId)
        .listen(
          (messages) => add(ChatThreadMessagesUpdated(messages)),
          onError: (_, __) => add(
            const ChatThreadFailed('We could not load this conversation.'),
          ),
        );
    try {
      await _repository.markConversationRead(_participantId);
    } catch (_) {
      // The conversation remains readable even if its unread counter cannot refresh.
    }
  }

  void _onMessagesUpdated(
    ChatThreadMessagesUpdated event,
    Emitter<ChatThreadState> emit,
  ) => emit(state.copyWith(messages: event.messages));

  Future<void> _onMessageSubmitted(
    ChatThreadMessageSubmitted event,
    Emitter<ChatThreadState> emit,
  ) async {
    if (state.isSending) return;
    emit(state.copyWith(isSending: true, clearError: true));
    try {
      await _repository.sendMessage(
        participantId: _participantId,
        text: event.text,
      );
      emit(state.copyWith(isSending: false));
    } catch (error) {
      final message = error is StateError
          ? error.message.toString()
          : 'The message could not be sent. Please try again.';
      emit(state.copyWith(isSending: false, errorMessage: message));
    }
  }

  void _onFailed(ChatThreadFailed event, Emitter<ChatThreadState> emit) {
    emit(state.copyWith(errorMessage: event.message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
