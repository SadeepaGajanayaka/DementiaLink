import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

import '../controllers/community_controller.dart';
import '../models/community_post.dart';
import '../models/story.dart';
import '../services/community_service.dart';

import 'search_ig_screen.dart';
import 'favourite_following.dart';
import 'dementia_profile.dart';
import 'message.dart';
import 'camera_screen.dart';

class CommunityFeedScreenImpl extends StatefulWidget {
  const CommunityFeedScreenImpl({Key? key}) : super(key: key);

  @override
  State<CommunityFeedScreenImpl> createState() => _CommunityFeedScreenImplState();
}

class _CommunityFeedScreenImplState extends State<CommunityFeedScreenImpl> {
  final CommunityService _communityService = CommunityService();
  final ImagePicker _picker = ImagePicker();
  String _currentUserName = '';

  // Current page index for each post
  final Map<String, int> _currentPageIndices = {};

  @override
  void initState() {
    super.initState();
    // Initialize the community controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityController>().initFeed();
    });
    _loadUserData();
  }

  // Get current index for a post
  int _getCurrentIndex(CommunityPost post) {
    return _currentPageIndices[post.id] ?? 0;
  }

  // Update index when page changes
  void _updateCurrentIndex(CommunityPost post, int index) {
    setState(() {
      _currentPageIndices[post.id] = index;
    });
  }

  void _loadUserData() async {
    try {
      final userId = _communityService.currentUser?.uid;
      if (userId != null) {
        final userData = await _communityService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _currentUserName = userData?['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Add a story from camera or gallery
  Future<void> _addStory(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // Since we don't have Firebase Storage, we'll use placeholder URLs
      // In a real app, you'd upload the image and get the URL
      final placeholderUrl = 'placeholder${math.Random().nextInt(5) + 1}';

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adding story...'))
      );

      // Add story
      await context.read<CommunityController>().addStory(placeholderUrl);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story added successfully!'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding story: $e'))
      );
    }
  }

  // Like or unlike a post
  Future<void> _toggleLike(BuildContext context, CommunityPost post) async {
    try {
      await context.read<CommunityController>().toggleLike(post.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
      );
    }
  }

  // View a story
  Future<void> _viewStory(BuildContext context, String userId, String storyId) async {
    try {
      await context.read<CommunityController>().viewStory(userId, storyId);
    } catch (e) {
      // Silently handle error
      print('Error viewing story: $e');
    }
  }

  // Display comments for a post
  void _showComments(BuildContext context, CommunityPost post) async {
    try {
      // Fetch comments
      final comments = await context.read<CommunityController>().getComments(post.id);

      if (!mounted) return;

      // Show comments in a modal bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFF503663),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(128),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Comments header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Comments list
                Expanded(
                  child: comments.isEmpty
                      ? const Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User avatar
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: comment.profileImageUrl != null
                                  ? NetworkImage(comment.profileImageUrl!)
                                  : null,
                              child: comment.profileImageUrl == null
                                  ? Icon(
                                Icons.person,
                                color: const Color(0xFF503663),
                                size: 16,
                              )
                                  : null,
                            ),

                            const SizedBox(width: 12),

                            // Comment content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Username and timestamp
                                  Row(
                                    children: [
                                      Text(
                                        comment.username,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _getTimeAgo(comment.createdAt),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  // Comment text
                                  Text(
                                    comment.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Add comment input
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(26),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withAlpha(26),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // User avatar
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF503663),
                          size: 16,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Comment text field
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white.withAlpha(179)),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (text) async {
                            if (text.trim().isEmpty) return;
                            Navigator.pop(context);

                            try {
                              await context.read<CommunityController>().addComment(
                                postId: post.id,
                                text: text.trim(),
                              );

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Comment added'))
                              );
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'))
                              );
                            }
                          },
                        ),
                      ),

                      // Post button
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e'))
      );
    }
  }

  // Helper to format time ago
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityController>(
        builder: (context, controller, child) {
          final isLoading = controller.isLoading;
          final posts = controller.posts;
          final stories = controller.stories;

          return Scaffold(
            backgroundColor: const Color(0xFF503663),
            body: isLoading && posts.isEmpty
                ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
                : SafeArea(
              child: Column(
                children: [
                  // App bar
                  _buildAppBar(),

                  // Content (stories + feed)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF503663),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: RefreshIndicator(
                        color: const Color(0xFF503663),
                        backgroundColor: Colors.white,
                        onRefresh: () async {
                          await controller.initFeed();
                        },
                        child: ListView(
                          children: [
                            // Stories row
                            _buildStories(stories),

                            // Posts
                            ...posts.map((post) => _buildPost(post)).toList(),

                            // If no posts, show message
                            if (posts.isEmpty && !isLoading)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    'No posts yet. Follow users or add your own post to see content.',
                                    style: TextStyle(color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                            // Loading indicator at bottom if loading more
                            if (isLoading && posts.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom navigation
                  _buildBottomNavigation(),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildAppBar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF503663),
          child: Row(
            children: [
              // Camera icon
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraScreen(),
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // App name
              Expanded(
                child: Center(
                  child: Text(
                    'Dementia Link',
                    style: GoogleFonts.lobster(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              // IGTV icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.tv,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // DM icon - navigate to MessageScreen
              IconButton(
                icon: const Icon(
                  Icons.send_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MessageScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Divider line right after the app bar
        Container(
          height: 0.5,
          color: Colors.white24,
        ),
      ],
    );
  }

  Widget _buildStories(List<UserStories> stories) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1, // +1 for "Your Story"
        itemBuilder: (context, index) {
          // Your Story option as first item
          if (index == 0) {
            return GestureDetector(
              onTap: () => _addStory(context),
              child: Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    // Story avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFDD2A7B),
                            Color(0xFFEEA863),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF503663), width: 2),
                          color: const Color(0xFFE0E0E0),
                        ),
                        child: const ClipOval(
                          child: Center(
                            child: Icon(
                              Icons.add,
                              color: Color(0xFF503663),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Username
                    const Text(
                      "Your Story",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // User stories
          final userStories = stories[index - 1];
          final hasUnviewed = userStories.hasUnviewedStories;

          return GestureDetector(
            onTap: () {
              // View story
              if (userStories.stories.isNotEmpty) {
                _viewStory(context, userStories.userId, userStories.stories.first.id);

                // Show story viewer
                // In a real app, you'd implement a proper story viewer
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing ${userStories.username}\'s story'))
                );
              }
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  // Story avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasUnviewed
                          ? const LinearGradient(
                        colors: [
                          Color(0xFFDD2A7B),
                          Color(0xFFEEA863),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF503663), width: 2),
                        color: const Color(0xFFE0E0E0),
                      ),
                      child: ClipOval(
                        child: userStories.hasUnviewedStories && userStories.stories.isNotEmpty && userStories.stories.first.userId == _communityService.currentUser?.uid
                            ? Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.person,
                                color: const Color(0xFF503663),
                                size: 32,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            : Center(
                          child: Icon(
                            Icons.person,
                            color: const Color(0xFF503663),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Username
                  Text(
                    userStories.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPost(CommunityPost post) {
    final currentUserIsAuthor = post.userId == _communityService.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      // Post header
      Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE0E0E0),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                color: const Color(0xFF503663),
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Username and location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    // Verified icon if applicable
                    if (post.displayName != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                  ],
                ),
                if (post.location != null && post.location!.isNotEmpty)
                  Text(
                    post.location!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // More options - horizontal dots
          GestureDetector(
            onTap: () {
              // Show options menu
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF503663),
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delete post option (only for author)
                    if (currentUserIsAuthor)
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.white),
                        title: const Text('Delete Post',
                            style: TextStyle(color: Colors.white)),
                        onTap: () async {
                          Navigator.pop(context);

                          // Confirm delete
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF503663),
                              title: const Text('Delete Post?',
                                  style: TextStyle(color: Colors.white)),
                              content: const Text(
                                'Are you sure you want to delete this post? This action cannot be undone.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    try {
                                      await context.read<CommunityController>().deletePost(post.id);

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Post deleted'))
                                      );
                                    } catch (e) {
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e'))
                                      );
                                    }
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // Report option
                    ListTile(
                      leading: const Icon(Icons.flag, color: Colors.white),
                      title: const Text('Report', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post reported'))
                        );
                      },
                    ),

                    // Cancel option
                    ListTile(
                      leading: const Icon(Icons.close, color: Colors.white),
                      title: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
            child: Row(
              children: List.generate(3, (index) =>
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    ),

    // Post image(s)
    SizedBox(
    height: 300,
    child: PageView.builder(
    itemCount: post.imageUrls.length,
    onPageChanged: (index) => _updateCurrentIndex(post, index),
    itemBuilder: (context, index) {
    // Use a placeholder container instead of loading from URLs
    return Container(
    color: const Color(0xFF77588D),
    child: Center(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(
    _getRandomIcon(),
    color: Colors.white.withAlpha(204),
    size: 48,
    ),
    const SizedBox(height: 16),
    Text(
    index == 0 ? post.caption : 'Swipe for more content',
    style: const TextStyle(
    color: Colors.white,
    fontSize: 16,
    ),
    textAlign: TextAlign.center,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    ),
    ],
    ),
    ),
    );
    },
    ),
    ),

    // Post actions
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
    children: [
    // Action icons row (heart, comment, etc.)
    Row(
    children: [
    IconButton(
    icon: Icon(
    post.isLiked ? Icons.favorite : Icons.favorite_border,
    color: post.isLiked ? Colors.red : Colors.white,
    size: 28,
    ),
    onPressed: () => _toggleLike(context, post),
    ),
    IconButton(
    icon: const Icon(
    Icons.chat_bubble_outline,
    color: Colors.white,
    size: 24,
    ),
    onPressed: () => _showComments(context, post),
    ),
    IconButton(
    icon: const Icon(
    Icons.send_outlined,
    color: Colors.white,
    size: 24,
    ),
    onPressed: () {},
    ),
    // Pagination dots aligned with action icons
    if (post.imageUrls.length > 1)
    Expanded(
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
    post.imageUrls.length,
    (index) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index == _getCurrentIndex(post)
            ? Colors.white
            : Colors.white.withAlpha(102),
      ),
    ),
    ),
    ),
    ),
      const Spacer(),
      IconButton(
        icon: const Icon(
          Icons.bookmark_border,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () {},
      ),
    ],
    ),
    ],
    ),
    ),

            // Likes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white),
                  children: [
                    const TextSpan(
                      text: 'Liked by ',
                      style: TextStyle(fontSize: 14),
                    ),
                    TextSpan(
                      text: post.likeCount > 0 ? 'users' : 'no one yet',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (post.likeCount > 0) ...[
                      const TextSpan(
                        text: ' and ',
                        style: TextStyle(fontSize: 14),
                      ),
                      TextSpan(
                        text: '${(post.likeCount - 1).toString()} others',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Caption
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(
                        text: post.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
              ),

            // View all comments
            if (post.commentCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GestureDetector(
                  onTap: () => _showComments(context, post),
                  child: Text(
                    'View all ${post.commentCount} comments',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            // Time ago
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                _getTimeAgo(post.createdAt),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
      ),
    );
  }

  IconData _getRandomIcon() {
    final icons = [
      Icons.photo,
      Icons.image,
      Icons.panorama,
      Icons.camera,
      Icons.person,
      Icons.psychology,
      Icons.health_and_safety,
      Icons.favorite,
      Icons.sentiment_satisfied,
      Icons.family_restroom,
    ];
    return icons[math.Random().nextInt(icons.length)];
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF503663),
        border: Border(
          top: BorderSide(
            color: Colors.white24,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(
              Icons.home,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white70,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchIGScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: Colors.white70,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.white70,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavouriteFollowingScreen(),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              // Navigate to the DementiaProfileScreen when profile icon is clicked
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DementiaProfileScreen(),
                ),
              );
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white70,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}