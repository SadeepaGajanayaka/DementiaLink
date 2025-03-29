import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import 'message_tile.dart';

class MessagesList extends ConsumerStatefulWidget {
  const MessagesList({
    super.key,
    required this.userId,
    required this.onNewMessage,
    this.isVoiceMode = false,
  });

  final String userId;
  final Function(Message) onNewMessage;
  final bool isVoiceMode;

  @override
  ConsumerState<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends ConsumerState<MessagesList> {
  String? lastProcessedMessageId;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _processNewMessage(Message message) {
    if (!message.isMine && message.id != lastProcessedMessageId) {
      lastProcessedMessageId = message.id;
      widget.onNewMessage(message);

      // Scroll to the bottom when a new message arrives
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesData = ref.watch(getAllMessagesProvider(widget.userId));

    return messagesData.when(
      data: (messages) {
        if (messages.isNotEmpty) {
          _processNewMessage(messages.first);
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages.elementAt(index);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: MessageTile(
                message: message,
                isOutgoing: message.isMine,
                isLastMessage: index == 0,
              ),
            );
          },
        );
      },
      error: (error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(getAllMessagesProvider(widget.userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}