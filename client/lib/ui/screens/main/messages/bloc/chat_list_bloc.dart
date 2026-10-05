import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:honest_dating/models/chat_conversation.dart';
import 'package:honest_dating/repositories/base/base_messaging_repository.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_list_event.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  ChatListBloc({required BaseMessagingRepository repository})
    : _repository = repository,
      super(const ChatListLoading()) {
    on<ChatListStarted>(_onStarted);
    on<ChatListUpdated>(_onUpdated);
    on<ChatListFailed>((_, emit) => emit(const ChatListFailure()));
  }

  final BaseMessagingRepository _repository;
  StreamSubscription<List<ChatConversation>>? _subscription;

  Future<void> _onStarted(
    ChatListStarted event,
    Emitter<ChatListState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _repository.watchConversations().listen(
      (conversations) => add(ChatListUpdated(conversations)),
      onError: (_, __) => add(const ChatListFailed()),
    );
  }

  void _onUpdated(ChatListUpdated event, Emitter<ChatListState> emit) {
    emit(ChatListLoaded(event.conversations));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
