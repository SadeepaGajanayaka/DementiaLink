import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/community_controller.dart';
import '../services/auth_service.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'search_ig_screen.dart';
import 'favourite_following.dart';
import 'dementia_profile.dart';
import 'message.dart'; // Import the message screen
import 'camera_screen.dart'; // Import for camera screen
import 'community_feed_screen_impl.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final AuthService _authService = AuthService();
  String _currentUserName = '';
  final List<StoryItem> _stories = [];
  final List<PostItem> _posts = [];
  bool _isLoading = true;

  // Track current page index for each post
  final Map<String, int> _currentPageIndices = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _generateMockData();
  }

  // Get current index for a post
  int _getCurrentIndex(PostItem post) {
    return _currentPageIndices[post.username] ?? 0;
  }

  // Update index when page changes
  void _updateCurrentIndex(PostItem post, int index) {
    setState(() {
      _currentPageIndices[post.username] = index;
    });
  }

  void _loadUserData() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final userData = await _authService.getUserData(userId);
        if (mounted) {
          setState(() {
            _currentUserName = userData['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _generateMockData() {
    // Generate mock stories
    _stories.addAll([
      StoryItem(username: 'Your Story', isViewed: false, isLive: false),
      StoryItem(username: 'karenmme', isViewed: false, isLive: true),
      StoryItem(username: 'zackjohn', isViewed: true, isLive: false),
      StoryItem(username: 'kieron_d', isViewed: true, isLive: false),
      StoryItem(username: 'craig_lo', isViewed: false, isLive: false),
      StoryItem(username: 'joshua_l', isViewed: false, isLive: false),
    ]);

    // Generate mock posts
    _posts.addAll([
      PostItem(
        username: 'joshua_l',
        isVerified: true,
        location: 'Tokyo, Japan',
        images: [
          'placeholder1',
          'placeholder2',
          'placeholder3',
        ],
        caption: 'The game in Japan was amazing and I want to share some photos',
        likes: 44686,
        comments: 1253,
        timeAgo: '3 hours ago',
        likedBy: 'craig_love',
      ),
      PostItem(
        username: 'karenmme',
        isVerified: false,
        location: 'Memory Care Center',
        images: [
          'placeholder4',
        ],
        caption: 'Art therapy session today went amazing! #DementiaAwareness #Memories',
        likes: 1289,
        comments: 42,
        timeAgo: '5 hours ago',
        likedBy: 'joshua_l',
      ),
      PostItem(
        username: 'caregiver_daily',
        isVerified: true,
        location: 'Dementia Care Community',
        images: [
          'placeholder5',
          'placeholder6',
        ],
        caption: 'Sharing simple daily routines that help maintain cognitive function. Swipe for tips! #CaregiverTips',
        likes: 3215,
        comments: 87,
        timeAgo: '2 days ago',
        likedBy: 'memory_lane',
      ),
    ]);
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

  @override
  Widget build(BuildContext context) {
    // Initialize the community controller at the appropriate place
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Provider.of<CommunityController>(context, listen: false).posts.isEmpty &&
          !Provider.of<CommunityController>(context, listen: false).isLoading) {
        Provider.of<CommunityController>(context, listen: false).initFeed();
      }
    });

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
                    // Refresh data
                    await Provider.of<CommunityController>(context, listen: false).initFeed();
                  },
                  child: ListView(
                    children: [
                      // Stories row
                      _buildStories(),

                      // Posts
                      ..._posts.map((post) => _buildPost(post)).toList(),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  );
                },
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

              // DM icon - Updated to navigate to MessageScreen
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

  Widget _buildStories() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          return Container(
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
                    gradient: story.isViewed
                        ? null
                        : const LinearGradient(
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
                    child: ClipOval(
                      child: story.isLive
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
                Flexible(
                  child: Text(
                    story.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPost(PostItem post) {
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
                          if (post.isVerified)
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
                      if (post.location.isNotEmpty)
                        Text(
                          post.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // More options - horizontal dots
                Row(
                  children: List.generate(
                    3,
                        (index) => Container(
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
                const SizedBox(width: 12),
              ],
            ),
          ),

          // Post image(s)
          SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: post.images.length,
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
                          color: Colors.white.withOpacity(0.8),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          index == 0 ? post.caption.split('#')[0] : 'Swipe for more content',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (post.caption.contains('#'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              post.caption.split('#').skip(1).map((tag) => '#$tag').join(' '),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {},
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
                    if (post.images.length > 1)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            post.images.length,
                                (index) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _getCurrentIndex(post)
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
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
                    text: post.likedBy,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const TextSpan(
                    text: ' and ',
                    style: TextStyle(fontSize: 14),
                  ),
                  TextSpan(
                    text: '${(post.likes).toString()} others',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
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
          if (post.comments > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'View all ${post.comments} comments',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),

          // Time ago
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              post.timeAgo,
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

  Widget _buildBottomNavigation() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFF503663),
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
                image: DecorationImage(
                  image: NetworkImage(
                    'https://source.unsplash.com/random/150x150/?face&sig=${_currentUserName.hashCode}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoryItem {
  final String username;
  final bool isViewed;
  final bool isLive;

  StoryItem({
    required this.username,
    required this.isViewed,
    required this.isLive
  });
}

class PostItem {
  final String username;
  final bool isVerified;
  final String location;
  final List<String> images;
  final String caption;
  final int likes;
  final int comments;
  final String timeAgo;
  final String likedBy;

  PostItem({
    required this.username,
    this.isVerified = false,
    required this.location,
    required this.images,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.likedBy,
  });
}