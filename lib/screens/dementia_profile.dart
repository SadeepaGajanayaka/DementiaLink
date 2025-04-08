import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'edit_profile.dart';
import 'community_feed_screen.dart';
import 'search_ig_screen.dart';
import 'camera_screen.dart';
import 'favourite_following.dart';

class DementiaProfileScreen extends StatefulWidget {
  const DementiaProfileScreen({Key? key}) : super(key: key);

  @override
  State<DementiaProfileScreen> createState() => _DementiaProfileScreenState();
}

class _DementiaProfileScreenState extends State<DementiaProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _username = 'jacob_w';
  String _fullName = 'Jacob West';
  String _bio = 'Digital goodies designer @pixsellz\nEverything is designed.';
  int _posts = 54;
  int _followers = 834;
  int _following = 162;

  // Mock data for highlighted stories
  final List<HighlightItem> _highlights = [
    HighlightItem(name: 'New', iconData: Icons.add),
    HighlightItem(name: 'Friends', imageUrl: 'lib/assets/highlight1.jpg'),
    HighlightItem(name: 'Sport', imageUrl: 'lib/assets/highlight2.jpg'),
    HighlightItem(name: 'Design', imageUrl: 'lib/assets/highlight3.jpg'),
  ];

  // Mock data for grid posts
  final List<String> _gridPosts = [
    'lib/assets/post1.jpg',
    'lib/assets/post2.jpg',
    'lib/assets/post3.jpg',
    'lib/assets/post4.jpg',
    'lib/assets/post5.jpg',
    'lib/assets/post6.jpg',
    'lib/assets/post7.jpg',
    'lib/assets/post8.jpg',
    'lib/assets/post9.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final userData = await _authService.getUserData(userId);
        if (mounted) {
          setState(() {
            // In a real app, you'd fetch and set user data here
            _isLoading = false;
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
        child: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildProfileHeader(),
                SliverToBoxAdapter(
                  child: _buildHighlightsRow(),
                ),
                SliverPersistentHeader(
                  delegate: _TabBarDelegate(),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              children: [
                // Grid view of posts
                _buildPostsGrid(),
                // Tagged view (empty in this example)
                _buildTaggedGrid(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  SliverAppBar _buildProfileHeader() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF503663),
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Icon(Icons.lock, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            _username,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.only(top: 60.0),
          child: Column(
            children: [
              // Profile picture and stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: AssetImage('lib/assets/profile_pic.jpg'),
                      onBackgroundImageError: (_, __) {},
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF503663),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Stats (Posts, Followers, Following)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(_posts.toString(), 'Posts'),
                          _buildStatColumn(_followers.toString(), 'Followers'),
                          _buildStatColumn(_following.toString(), 'Following'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Bio section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bio,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Edit Profile Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            initialUsername: _username,
                            initialFullName: _fullName,
                            initialBio: _bio,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsRow() {
    return Container(
      height: 90, // Reduced height to avoid potential overflow
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _highlights.length,
        itemBuilder: (context, index) {
          final highlight = _highlights[index];
          return Container(
            width: 70, // Reduce width further
            height: 70, // Reduce height further to prevent overflow
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Highlight Avatar - further reduced size
                Container(
                  width: 50, // Reduced from 60
                  height: 50, // Reduced from 60
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: highlight.imageUrl != null
                        ? Image.asset(
                      highlight.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          highlight.iconData ?? Icons.image,
                          color: Colors.white,
                          size: 24, // Reduced from 28
                        );
                      },
                    )
                        : Center(
                      child: Icon(
                        highlight.iconData ?? Icons.image,
                        color: Colors.white,
                        size: 24, // Reduced from 28
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 4
                // Highlight Name - container with constraints to prevent overflow
                Container(
                  constraints: BoxConstraints(maxHeight: 14), // Reduced from 16
                  child: Text(
                    highlight.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10, // Reduced from 11
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

  Widget _buildPostsGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _gridPosts.length,
      itemBuilder: (context, index) {
        return _buildGridItem(index);
      },
    );
  }

  Widget _buildTaggedGrid() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_pin_outlined,
            color: Colors.white.withOpacity(0.5),
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'No Photos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(int index) {
    // Using a placeholder color instead of actual images
    Color itemColor = Color(0xFF77588D);

    return Container(
      color: itemColor,
      child: Center(
        child: Icon(
          _getRandomIcon(index),
          color: Colors.white.withOpacity(0.7),
          size: 32,
        ),
      ),
    );
  }

  IconData _getRandomIcon(int index) {
    final List<IconData> icons = [
      Icons.photo_camera,
      Icons.landscape,
      Icons.people,
      Icons.computer,
      Icons.coffee,
      Icons.sports,
      Icons.music_note,
      Icons.pets,
      Icons.emoji_food_beverage,
    ];

    return icons[index % icons.length];
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
          // Home Icon - navigate to Community Feed
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              color: Colors.white70,
              size: 28,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityFeedScreen(),
                ),
              );
            },
          ),

          // Search Icon - navigate to Search Screen
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

          // Add Icon - navigate to Camera Screen
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

          // Favorites Icon - navigate to Favourite Following Screen
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

          // Profile Icon - already on the profile screen
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
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
        ],
      ),
    );
  }
}

// Tab bar delegate for sticky header
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF503663),
      child: TabBar(
        indicatorColor: Colors.white,
        tabs: [
          Tab(icon: Icon(Icons.grid_on, color: Colors.white)),
          Tab(icon: Icon(Icons.person_pin_outlined, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

// Model class for highlight items
class HighlightItem {
  final String name;
  final String? imageUrl;
  final IconData? iconData;

  HighlightItem({
    required this.name,
    this.imageUrl,
    this.iconData,
  });
}