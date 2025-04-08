import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/messaging_controller.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../services/community_service.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final UserProfile otherUser;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.otherUser,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CommunityService _communityService = CommunityService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initChat();

    // Add notification listener
    NotificationService().addListener(_handleNotification);
  }

  Future<void> _initChat() async {
    try {
      // Load messages for this conversation
      await context.read<MessagingController>().fetchMessagesForConversation(
        widget.conversationId,
      );

      // Scroll to bottom after messages are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print("Error initializing chat: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  // Handle incoming notifications
  void _handleNotification(String conversationId, String sender, String message) {
    // Only show notifications for other conversations while this screen is active
    if (conversationId != widget.conversationId && mounted) {
      // Show in-app notification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService.showInAppNotification(
            context,
            sender,
            message
        );
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await context.read<MessagingController>().sendMessage(
        conversationId: widget.conversationId,
        receiverId: widget.otherUser.id,
        text: text,
      );

      // Clear the input field
      _messageController.clear();

      // Scroll to the bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      // Today - show only time
      return DateFormat.jm().format(time); // 1:30 PM
    } else if (time.year == now.year && time.difference(now).inDays.abs() < 7) {
      // Within a week - show day of week
      return DateFormat('E, h:mm a').format(time); // Tue, 1:30 PM
    } else {
      // Older - show date and time
      return DateFormat('MMM d, h:mm a').format(time); // Jan 1, 1:30 PM
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      appBar: AppBar(
        backgroundColor: const Color(0xFF503663),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.otherUser.profileImageUrl != null
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              child: widget.otherUser.profileImageUrl == null
                  ? Icon(
                Icons.person,
                color: const Color(0xFF503663),
                size: 16,
              )
                  : null,
            ),
            const SizedBox(width: 8),

            // Username and last active
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName ?? widget.otherUser.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.otherUser.lastActive != null
                        ? 'Last active ${_formatTime(widget.otherUser.lastActive!)}'
                        : 'Offline',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              // Implement call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show more options
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: _buildMessagesList(),
            ),

            // Message input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<MessagingController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        // Get messages for this conversation
        final messages = controller.getMessagesForConversation(widget.conversationId);

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white.withOpacity(0.5),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message to start the conversation',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final String? currentUserId = _communityService.currentUser?.uid;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final bool isMe = message.senderId == currentUserId;
            final bool showTimestamp = index == 0 ||
                (index > 0 && messages[index].createdAt.difference(messages[index - 1].createdAt).inMinutes > 10);

            return Column(
              children: [
                if (showTimestamp) _buildTimestampDivider(message.createdAt),
                _buildMessageBubble(message, isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimestampDivider(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatTime(timestamp),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.white : const Color(0xFF77588D),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? const Color(0xFF503663) : Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.createdAt),
                  style: TextStyle(
                    color: isMe
                        ? const Color(0xFF503663).withOpacity(0.6)
                        : Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.read
                        ? Colors.blue
                        : const Color(0xFF503663).withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white),
            onPressed: () {
              // Show attachment options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attachment feature coming soon')),
              );
            },
          ),

          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          // Send button
          IconButton(
            icon: _isSending
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.send, color: Colors.white),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF503663),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text('Block User', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Block feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white),
              title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clear chat feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.white),
              title: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Remove notification listener
    NotificationService().removeListener(_handleNotification);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}