import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:honest_dating/config/app_colors.dart';
import 'package:honest_dating/models/chat_conversation.dart';
import 'package:honest_dating/repositories/base/base_messaging_repository.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_thread_bloc.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_thread_event.dart';
import 'package:honest_dating/ui/screens/main/messages/bloc/chat_thread_state.dart';
import 'package:honest_dating/ui/widgets/app_navigation_bar.dart';

class ChatThreadArguments {
  const ChatThreadArguments({
    required this.participantId,
    required this.participantName,
    this.participantPhotoUrl,
  });

  factory ChatThreadArguments.fromConversation(ChatConversation conversation) =>
      ChatThreadArguments(
        participantId: conversation.participantId,
        participantName: conversation.participantName,
        participantPhotoUrl: conversation.participantPhotoUrl,
      );

  final String participantId;
  final String participantName;
  final String? participantPhotoUrl;
}

class MessageThreadScreen extends StatefulWidget {
  const MessageThreadScreen({
    super.key,
    required this.repository,
    required this.arguments,
  });

  final BaseMessagingRepository repository;
  final ChatThreadArguments arguments;

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ChatThreadBloc>().add(ChatThreadMessageSubmitted(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatThreadBloc>(
      create: (_) => ChatThreadBloc(
        repository: widget.repository,
        participantId: widget.arguments.participantId,
      )..add(const ChatThreadStarted()),
      child: Builder(
        builder: (innerContext) => CupertinoPageScaffold(
          backgroundColor: AppColors.canvas,
          child: Column(
            children: [
              AppNavigationBar(
                title: widget.arguments.participantName,
                leading: _ChatBackButton(
                  onPressed: () => Navigator.of(innerContext).maybePop(),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: BlocBuilder<ChatThreadBloc, ChatThreadState>(
                        builder: (context, state) => Column(
                          children: [
                            if (state.errorMessage case final String message)
                              _ErrorBanner(message: message),
                            Expanded(
                              child: state.messages.isEmpty
                                  ? const _EmptyThread()
                                  : ListView.builder(
                                      reverse: true,
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        18,
                                        18,
                                        12,
                                      ),
                                      itemCount: state.messages.length,
                                      itemBuilder: (_, index) => _MessageBubble(
                                        message:
                                            state.messages[state
                                                    .messages
                                                    .length -
                                                1 -
                                                index],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: _Composer(
                  controller: _controller,
                  onSend: () => _send(innerContext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBackButton extends StatelessWidget {
  const _ChatBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size(48, 48),
    onPressed: onPressed,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          CupertinoIcons.chevron_back,
          color: AppColors.coral,
          size: 24,
        ),
      ),
    ),
  );
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'Say hello.',
      style: TextStyle(color: AppColors.mutedInk, fontSize: 17),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: message.isMine ? AppColors.coralSoft : AppColors.softCanvas,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.text,
        style: const TextStyle(color: AppColors.ink, fontSize: 16),
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.canvas,
      border: Border(top: BorderSide(color: AppColors.line)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Type your message…',
              maxLength: 1000,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.softCanvas,
                borderRadius: BorderRadius.circular(18),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 10),
            minimumSize: const Size(42, 42),
            onPressed: onSend,
            child: const Icon(
              CupertinoIcons.paperplane_fill,
              color: AppColors.coral,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.coralSoft,
    padding: const EdgeInsets.all(12),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.coral,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
