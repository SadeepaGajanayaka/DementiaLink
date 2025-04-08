import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/messaging_controller.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../services/community_service.dart';
import 'chat_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  String _searchQuery = '';
  List<Conversation> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  void _initializeMessages() async {
    try {
      await context.read<MessagingController>().initMessaging();
    } catch (e) {
      print('Error initializing messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _filterConversations(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _updateFilteredConversations();
    });
  }

  void _updateFilteredConversations() {
    final allConversations = context.read<MessagingController>().conversations;
    if (_searchQuery.isEmpty) {
      _filteredConversations = allConversations;
    } else {
      _filteredConversations = allConversations.where((conversation) {
        final userId = _communityService.currentUser?.uid ?? '';
        final otherUserName = conversation.getOtherUserName(userId).toLowerCase();
        return otherUserName.contains(_searchQuery);
      }).toList();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Today - show time only
      return DateFormat.jm().format(time); // e.g., 3:30 PM
    } else if (difference.inDays < 7) {
      // Within a week - show day of week
      return DateFormat('E').format(time); // e.g., Mon, Tue
    } else {
      // More than a week - show date
      return DateFormat('MM/dd').format(time); // e.g., 01/15
    }
  }

  void _navigateToChat(Conversation conversation) async {
    final userId = _communityService.currentUser?.uid;
    if (userId == null) return;

    final otherUserId = conversation.getOtherUserId(userId);

    try {
      // Get other user's profile
      final otherUserData = await _communityService.getUserProfile(otherUserId);
      if (otherUserData == null) {
        throw Exception('User profile not found');
      }

      if (!mounted) return;

      // Create UserProfile object
      final otherUser = UserProfile(
        id: otherUserId,
        username: otherUserData['username'] ?? 'user',
        displayName: otherUserData['displayName'],
        bio: otherUserData['bio'],
        profileImageUrl: otherUserData['profileImageUrl'],
        followers: otherUserData['followers'] ?? 0,
        following: otherUserData['following'] ?? 0,
        role: otherUserData['role'],
        createdAt: otherUserData['createdAt']?.toDate() ?? DateTime.now(),
        lastActive: otherUserData['lastActive']?.toDate(),
      );

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversation.id,
            otherUser: otherUser,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _buildAppBar(),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                ),
                onChanged: _filterConversations,
              ),
            ),

            // Messages list
            Expanded(
              child: _buildMessagesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF503663),
        child: const Icon(Icons.edit),
        onPressed: () {
          // Show new message dialog
          _showNewMessageDialog();
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),

          const Spacer(),

          // Title with count
          Consumer<MessagingController>(
            builder: (context, controller, child) {
              _updateFilteredConversations();
              int conversationCount = controller.conversations.length;
              return Text(
                conversationCount > 0
                    ? 'Messages ($conversationCount)'
                    : 'Messages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),

          const Spacer(),

          // Add new message button
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // Show new message dialog
              _showNewMessageDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<MessagingController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        _updateFilteredConversations();

        if (_filteredConversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message,
                  color: Colors.white.withOpacity(0.5),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : 'No messages yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showNewMessageDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Start a New Conversation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF503663),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final userId = _communityService.currentUser?.uid ?? '';

        return ListView.builder(
          itemCount: _filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = _filteredConversations[index];
            return _buildConversationItem(conversation, userId);
          },
        );
      },
    );
  }

  Widget _buildConversationItem(Conversation conversation, String userId) {
    final otherUserName = conversation.getOtherUserName(userId);
    final otherUserImage = conversation.getOtherUserImage(userId);
    final unreadCount = conversation.getUnreadCount(userId);
    final lastMessageText = conversation.lastMessageText ?? '';
    final lastMessageTime = conversation.lastMessageTime;
    final formattedTime = _formatTime(lastMessageTime);
    final isSender = conversation.lastMessageSenderId == userId;

    return InkWell(
      onTap: () => _navigateToChat(conversation),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              backgroundImage: otherUserImage != null
                  ? NetworkImage(otherUserImage)
                  : null,
              child: otherUserImage == null
                  ? Icon(
                Icons.person,
                color: const Color(0xFF503663),
                size: 30,
              )
                  : null,
            ),

            const SizedBox(width: 16),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isSender)
                        Text(
                          'You: ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          lastMessageText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Color(0xFF503663),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Camera icon
            IconButton(
              icon: Icon(
                Icons.camera_alt_outlined,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              onPressed: () {
                // Handle camera action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera feature coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewMessageDialog() async {
    try {
      // Get suggested users (people to message)
      final suggestions = await _communityService.getSuggestedUsers();

      if (!mounted) return;

      // Show user selection dialog
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF503663),
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'New Message',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search for people',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),

              // User list
              Expanded(
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final doc = suggestions[index];
                    final userData = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        backgroundImage: userData['profileImageUrl'] != null
                            ? NetworkImage(userData['profileImageUrl'])
                            : null,
                        child: userData['profileImageUrl'] == null
                            ? const Icon(
                          Icons.person,
                          color: Color(0xFF503663),
                        )
                            : null,
                      ),
                      title: Text(
                        userData['displayName'] ?? userData['username'] ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: userData['bio'] != null
                          ? Text(
                        userData['bio'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          : null,
                      onTap: () async {
                        Navigator.pop(context);

                        try {
                          // Create UserProfile object
                          final otherUser = UserProfile(
                            id: doc.id,
                            username: userData['username'] ?? 'user',
                            displayName: userData['displayName'],
                            bio: userData['bio'],
                            profileImageUrl: userData['profileImageUrl'],
                            followers: userData['followers'] ?? 0,
                            following: userData['following'] ?? 0,
                            role: userData['role'],
                            createdAt: userData['createdAt']?.toDate() ?? DateTime.now(),
                            lastActive: userData['lastActive']?.toDate(),
                          );

                          // Start conversation
                          final conversationId = await context.read<MessagingController>().startConversation(otherUser);

                          if (!mounted) return;

                          // Navigate to chat
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                conversationId: conversationId,
                                otherUser: otherUser,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error starting conversation: $e')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error showing new message dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contacts: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}