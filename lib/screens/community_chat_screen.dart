import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import 'chat_detail_screen.dart';
import 'comment_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUserId = _authService.currentUser?.uid;

      if (_currentUserId != null) {
        Map<String, dynamic> userData = await _authService.getUserData(_currentUserId!);
        setState(() {
          _currentUserName = userData['name'] ?? 'User';
          _currentUserPhotoUrl = userData['photoUrl'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      )
          : SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Community',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat, color: Colors.white),
                    onPressed: () {
                      // Navigate to direct messages list
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatRoomsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'People'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Posts Tab
                  RefreshIndicator(
                    onRefresh: _refreshPosts,
                    color: const Color(0xFF77588D),
                    child: _buildPostsTab(),
                  ),

                  // People Tab
                  _buildPeopleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePostScreen(
                userId: _currentUserId!,
                userName: _currentUserName!,
                userPhotoUrl: _currentUserPhotoUrl,
              ),
            ),
          ).then((_) => _refreshPosts());
        },
        backgroundColor: const Color(0xFF77588D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('community_posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.post_add,
                  color: Colors.white70,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No posts yet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatePostScreen(
                          userId: _currentUserId!,
                          userName: _currentUserName!,
                          userPhotoUrl: _currentUserPhotoUrl,
                        ),
                      ),
                    ).then((_) => _refreshPosts());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF503663),
                  ),
                  child: const Text('Create your first post'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var post = snapshot.data!.docs[index];
            Map<String, dynamic> postData = post.data() as Map<String, dynamic>;

            DateTime timestamp = (postData['timestamp'] as Timestamp).toDate();
            String timeAgo = _getTimeAgo(timestamp);
            bool isLiked = (postData['likes'] as List<dynamic>?)?.contains(_currentUserId) ?? false;
            int likeCount = (postData['likes'] as List<dynamic>?)?.length ?? 0;
            int commentCount = postData['commentCount'] ?? 0;

            return _buildPostCard(
              context,
              postId: post.id,
              userId: postData['userId'],
              userName: postData['userName'],
              userPhotoUrl: postData['userPhotoUrl'],
              imageUrl: postData['imageUrl'],
              text: postData['text'],
              timeAgo: timeAgo,
              isLiked: isLiked,
              likeCount: likeCount,
              commentCount: commentCount,
            );
          },
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        // Filter out current user
        final users = snapshot.data!.docs
            .where((doc) => doc.id != _currentUserId)
            .toList();

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'No other users found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var userData = users[index].data() as Map<String, dynamic>;
            String userId = users[index].id;
            String userName = userData['name'] ?? 'User';
            String? photoUrl = userData['photoUrl'];
            String role = userData['role'] ?? 'Unknown';

            return _buildUserListTile(
              context,
              userId: userId,
              userName: userName,
              photoUrl: photoUrl,
              role: role,
            );
          },
        );
      },
    );
  }

  Widget _buildPostCard(
      BuildContext context, {
        required String postId,
        required String userId,
        required String userName,
        String? userPhotoUrl,
        String? imageUrl,
        required String text,
        required String timeAgo,
        required bool isLiked,
        required int likeCount,
        required int commentCount,
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header with user info
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF77588D),
              backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
              child: userPhotoUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(
              userName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF503663),
              ),
            ),
            subtitle: Text(
              timeAgo,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: userId == _currentUserId
                ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePost(postId);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Color(0xFF503663)),
            )
                : null,
          ),

          // Post content text
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            ),

          // Post image (if available)
          if (imageUrl != null && imageUrl.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF77588D),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[400],
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Like and comment counts
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Row(
              children: [
                Text(
                  '$likeCount likes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$commentCount comments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Like button
              TextButton.icon(
                onPressed: () {
                  _toggleLike(postId, isLiked);
                },
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey[700],
                ),
                label: Text(
                  'Like',
                  style: TextStyle(
                    color: isLiked ? Colors.red : Colors.grey[700],
                  ),
                ),
              ),

              // Comment button
              TextButton.icon(
                onPressed: () {
                  _navigateToComments(
                    context,
                    postId: postId,
                    postUserId: userId,
                    postUserName: userName,
                  );
                },
                icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[700]),
                label: Text(
                  'Comment',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserListTile(
      BuildContext context, {
        required String userId,
        required String userName,
        String? photoUrl,
        required String role,
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF77588D),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          userName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF503663),
          ),
        ),
        subtitle: Text(
          role == 'caregiver' ? 'Caregiver' : 'Patient',
          style: TextStyle(
            color: role == 'caregiver' ? Colors.blue[700] : Colors.green[700],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _startChat(userId, userName, photoUrl);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF77588D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Message'),
        ),
        onTap: () {
          _showUserProfile(context, userId, userName, photoUrl, role);
        },
      ),
    );
  }

  void _toggleLike(String postId, bool isCurrentlyLiked) async {
    try {
      if (_currentUserId == null) return;

      DocumentReference postRef = _firestore.collection('community_posts').doc(postId);

      if (isCurrentlyLiked) {
        // Remove like
        await postRef.update({
          'likes': FieldValue.arrayRemove([_currentUserId])
        });
      } else {
        // Add like
        await postRef.update({
          'likes': FieldValue.arrayUnion([_currentUserId])
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like status: $e')),
      );
    }
  }

  void _navigateToComments(
      BuildContext context, {
        required String postId,
        required String postUserId,
        required String postUserName,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          postId: postId,
          currentUserId: _currentUserId!,
          currentUserName: _currentUserName!,
          currentUserPhotoUrl: _currentUserPhotoUrl,
          postUserId: postUserId,
          postUserName: postUserName,
        ),
      ),
    );
  }

  void _deletePost(String postId) async {
    try {
      // Delete post document
      await _firestore.collection('community_posts').doc(postId).delete();

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }

  void _startChat(String userId, String userName, String? photoUrl) async {
    try {
      if (_currentUserId == null) return;

      // Create a unique chat room ID (alphabetically sorted user IDs)
      List<String> users = [_currentUserId!, userId];
      users.sort(); // Sort to ensure same ID regardless of who initiates
      String chatRoomId = users.join('_');

      // Check if chat room already exists
      DocumentSnapshot chatRoom = await _firestore.collection('chat_rooms').doc(chatRoomId).get();

      if (!chatRoom.exists) {
        // Create new chat room
        await _firestore.collection('chat_rooms').doc(chatRoomId).set({
          'users': users,
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'userInfo': {
            _currentUserId!: {
              'name': _currentUserName,
              'photoUrl': _currentUserPhotoUrl,
            },
            userId: {
              'name': userName,
              'photoUrl': photoUrl,
            },
          },
        });
      }

      // Navigate to chat detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatRoomId: chatRoomId,
            receiverId: userId,
            receiverName: userName,
            receiverPhotoUrl: photoUrl,
          ),
        ),
      );
    } catch (e) {
      print('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  void _showUserProfile(BuildContext context, String userId, String userName, String? photoUrl, String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),

            // Profile header
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF77588D),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 60)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF503663),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: role == 'caregiver' ? Colors.blue[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role == 'caregiver' ? 'Caregiver' : 'Patient',
                style: TextStyle(
                  color: role == 'caregiver' ? Colors.blue[700] : Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startChat(userId, userName, photoUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF77588D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.chat),
                      label: const Text('Message'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // User posts count (placeholder for future functionality)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<QuerySnapshot>(
                future: _firestore
                    .collection('community_posts')
                    .where('userId', isEqualTo: userId)
                    .get(),
                builder: (context, snapshot) {
                  int postCount = 0;
                  if (snapshot.hasData) {
                    postCount = snapshot.data!.docs.length;
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$postCount',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF503663),
                            ),
                          ),
                          const Text('Posts'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const Spacer(),

            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      appBar: AppBar(
        backgroundColor: const Color(0xFF503663),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _currentUserId == null
          ? const Center(
        child: Text(
          'Please log in to view messages',
          style: TextStyle(color: Colors.white),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chat_rooms')
            .where('users', arrayContains: _currentUserId)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white70,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF503663),
                    ),
                    child: const Text('Find people to chat with'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatRoom = snapshot.data!.docs[index];
              Map<String, dynamic> chatRoomData = chatRoom.data() as Map<String, dynamic>;

              List<dynamic> users = chatRoomData['users'] ?? [];
              String receiverId = users.firstWhere((id) => id != _currentUserId, orElse: () => '');

              if (receiverId.isEmpty) return const SizedBox();

              Map<String, dynamic>? userInfo = (chatRoomData['userInfo'] as Map<String, dynamic>?)?[receiverId] as Map<String, dynamic>?;

              if (userInfo == null) return const SizedBox();

              String receiverName = userInfo['name'] ?? 'User';
              String? receiverPhotoUrl = userInfo['photoUrl'];
              String lastMessage = chatRoomData['lastMessage'] ?? '';
              Timestamp? lastMessageTimestamp = chatRoomData['lastMessageTimestamp'] as Timestamp?;
              String timeAgo = lastMessageTimestamp != null ? _getTimeAgo(lastMessageTimestamp.toDate()) : '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF77588D),
                    backgroundImage: receiverPhotoUrl != null ? NetworkImage(receiverPhotoUrl) : null,
                    child: receiverPhotoUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    receiverName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF503663),
                    ),
                  ),
                  subtitle: Text(
                    lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chatRoomId: chatRoom.id,
                          receiverId: receiverId,
                          receiverName: receiverName,
                          receiverPhotoUrl: receiverPhotoUrl,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}