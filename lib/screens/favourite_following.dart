import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'community_feed_screen.dart';
import 'search_ig_screen.dart';
import 'camera_screen.dart';
import 'dementia_profile.dart';

class FavouriteFollowingScreen extends StatefulWidget {
  const FavouriteFollowingScreen({Key? key}) : super(key: key);

  @override
  State<FavouriteFollowingScreen> createState() => _FavouriteFollowingScreenState();
}

class _FavouriteFollowingScreenState extends State<FavouriteFollowingScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;
  bool _isLoading = true;
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final userData = await _authService.getUserData(userId);
        if (mounted) {
          setState(() {
            _currentUserName = userData['name'] ?? 'User';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF503663),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: AppBar(
            backgroundColor: const Color(0xFF503663),
            elevation: 0,
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              labelStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelColor: Colors.white,
              tabs: [
                Tab(text: "Following"),
                Tab(text: "You"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Following Tab
            _buildFollowingTab(),

            // You Tab
            _buildYouTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildFollowingTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Color(0xFF503663).withOpacity(0.7),
            child: Text(
              "Follow Requests",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Color(0xFF503663).withOpacity(0.9),
            child: Text(
              "New",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          _buildActivityItem(
            profileImage: "assets/avatar1.jpg",
            username: "karennne",
            activity: "liked your photo.",
            time: "1h",
            contentImage: "assets/post1.jpg",
            showMessage: false,
            showFollow: false,
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Color(0xFF503663).withOpacity(0.9),
            child: Text(
              "Today",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          _buildActivityItem(
            profileImage: "assets/avatar2.jpg",
            username: "kiero_d, zackjohn",
            activity: "and 26 others liked your photo.",
            time: "3h",
            contentImage: "assets/post1.jpg",
            showMessage: false,
            showFollow: false,
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Color(0xFF503663).withOpacity(0.9),
            child: Text(
              "This Week",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          _buildActivityItem(
            profileImage: "assets/avatar3.jpg",
            username: "craig_love",
            activity: "mentioned you in a comment: @jacob_w exactly..",
            time: "2d",
            contentImage: "assets/post2.jpg",
            showMessage: false,
            showFollow: false,
            showReply: true,
          ),

          _buildActivityItem(
            profileImage: "assets/avatar4.jpg",
            username: "martini_rond",
            activity: "started following you.",
            time: "3d",
            contentImage: null,
            showMessage: true,
            showFollow: false,
          ),

          _buildActivityItem(
            profileImage: "assets/avatar5.jpg",
            username: "maxjacobson",
            activity: "started following you.",
            time: "3d",
            contentImage: null,
            showMessage: true,
            showFollow: false,
          ),

          _buildActivityItem(
            profileImage: "assets/avatar6.jpg",
            username: "mis_potter",
            activity: "started following you.",
            time: "3d",
            contentImage: null,
            showMessage: false,
            showFollow: true,
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Color(0xFF503663).withOpacity(0.9),
            child: Text(
              "This Month",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTab() {
    return ListView(
      children: [
        _buildActivityItem(
          profileImage: "assets/avatar1.jpg",
          username: "karennne",
          activity: "liked 3 posts.",
          time: "3h",
          contentImage: "assets/multi_posts1.jpg",
          showMessage: false,
          showFollow: false,
          showMultipleImages: true,
        ),

        _buildActivityItem(
          profileImage: "assets/avatar2.jpg",
          username: "kiero_d, zackjohn",
          activity: "and craig_love liked joshua_l photo.",
          time: "3h",
          contentImage: "assets/post3.jpg",
          showMessage: false,
          showFollow: false,
        ),

        _buildActivityItem(
          profileImage: "assets/avatar2.jpg",
          username: "kiero_d",
          activity: "started following craig_love.",
          time: "3h",
          contentImage: null,
          showMessage: false,
          showFollow: false,
        ),

        _buildActivityItem(
          profileImage: "assets/avatar3.jpg",
          username: "craig_love",
          activity: "liked 8 posts.",
          time: "3h",
          contentImage: "assets/multi_posts2.jpg",
          showMessage: false,
          showFollow: false,
          showMultipleImages: true,
          hasMoreImages: true,
        ),

        _buildActivityItem(
          profileImage: "assets/avatar5.jpg",
          username: "maxjacobson",
          activity: "and zackjohn liked mis_potter's post.",
          time: "3h",
          contentImage: "assets/post4.jpg",
          showMessage: false,
          showFollow: false,
        ),

        _buildActivityItem(
          profileImage: "assets/avatar5.jpg",
          username: "maxjacobson",
          activity: "and craig_love liked martini_rond's post.",
          time: "3h",
          contentImage: "assets/post5.jpg",
          showMessage: false,
          showFollow: false,
        ),

        _buildActivityItem(
          profileImage: "assets/avatar1.jpg",
          username: "karennne",
          activity: "liked martini_rond's comment: @martini_rond Nice!",
          time: "3h",
          contentImage: "assets/post6.jpg",
          showMessage: false,
          showFollow: false,
        ),

        _buildActivityItem(
          profileImage: "assets/avatar5.jpg",
          username: "maxjacobson",
          activity: "liked 3 posts.",
          time: "3h",
          contentImage: "assets/multi_posts3.jpg",
          showMessage: false,
          showFollow: false,
          showMultipleImages: true,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String profileImage,
    required String username,
    required String activity,
    required String time,
    String? contentImage,
    required bool showMessage,
    required bool showFollow,
    bool showReply = false,
    bool showMultipleImages = false,
    bool hasMoreImages = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: Icon(
              Icons.person,
              color: const Color(0xFF503663),
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Activity Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: " $activity"),
                      TextSpan(
                        text: " $time",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                if (showReply)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Reply",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Content Image or Action Buttons
          if (contentImage != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFF77588D),
                borderRadius: BorderRadius.circular(4),
              ),
              child: showMultipleImages
                  ? Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (hasMoreImages)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          "+5",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              )
                  : Center(
                child: Icon(
                  Icons.image,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          else if (showMessage)
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.white30),
                ),
                minimumSize: Size(80, 30),
              ),
              child: Text(
                "Message",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            )
          else if (showFollow)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  minimumSize: Size(80, 30),
                ),
                child: Text(
                  "Follow",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
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
          // Home icon - navigate to Community Feed
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

          // Search icon - navigate to Search screen
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

          // Add/Post icon - navigate to Camera Screen
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

          // Favorite icon - already on this screen
          IconButton(
            icon: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              // Already on this screen
            },
          ),

          // Profile icon - navigate to Profile Screen
          GestureDetector(
            onTap: () {
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
                color: Colors.white70,
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: const Color(0xFF503663),
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