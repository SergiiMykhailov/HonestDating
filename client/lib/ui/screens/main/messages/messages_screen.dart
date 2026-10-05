import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/chat_conversation.dart';
import 'package:honest_dating/repositories/base/base_messaging_repository.dart';
import 'package:honest_dating/ui/routing/base/base_router.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_list_bloc.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_list_event.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_list_state.dart';
import 'package:honest_dating/ui/screens/main/messages/message_thread_screen.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required BaseMessagingRepository repository})
    : _repository = repository;

  final BaseMessagingRepository _repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatListBloc>(
      create: (_) =>
          ChatListBloc(repository: _repository)..add(const ChatListStarted()),
      child: const CupertinoPageScaffold(
        backgroundColor: AppColors.canvas,
        child: Column(
          children: [
            AppNavigationBar(title: 'Chats'),
            Expanded(child: _MessagesBody()),
          ],
        ),
      ),
    );
  }
}

class _MessagesBody extends StatelessWidget {
  const _MessagesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatListBloc, ChatListState>(
      builder: (context, state) => switch (state) {
        ChatListLoading() => const Center(
          child: CupertinoActivityIndicator(color: AppColors.coral),
        ),
        ChatListFailure() => Center(
          child: CupertinoButton(
            onPressed: () =>
                context.read<ChatListBloc>().add(const ChatListStarted()),
            child: const Text('Could not load chats. Try again.'),
          ),
        ),
        ChatListLoaded(:final conversations) when conversations.isEmpty =>
          const _EmptyChats(),
        ChatListLoaded(:final conversations) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => const SizedBox(
            height: 1,
            child: ColoredBox(color: AppColors.line),
          ),
          itemBuilder: (context, index) =>
              _ConversationRow(conversation: conversations[index]),
        ),
      },
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 42),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 44,
            color: AppColors.mutedInk,
          ),
          SizedBox(height: 16),
          Text(
            'No chats yet.',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a conversation from one of your matches or friends.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedInk, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open chat with ${conversation.participantName}',
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed(
          BaseRouter.conversation,
          arguments: ChatThreadArguments.fromConversation(conversation),
        ),
        child: Row(
          children: [
            _Avatar(photoUrl: conversation.participantPhotoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.participantName,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage ?? 'Start the conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: AppColors.canvas,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: 52,
      height: 52,
      child: photoUrl == null
          ? const ColoredBox(
              color: AppColors.softCanvas,
              child: Icon(
                CupertinoIcons.person_fill,
                color: AppColors.mutedInk,
              ),
            )
          : Image.network(photoUrl!, fit: BoxFit.cover),
    ),
  );
}
