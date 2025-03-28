import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'community_create_post.dart';
import 'community_profile_screen.dart';
import 'community_search_screen.dart';
import 'community_notifications_screen.dart';
import 'community_post_detail.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  int _currentIndex = 0;

  // Mock data for posts
  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'sarah_caregiver',
      'userImage': 'https://i.pravatar.cc/150?img=1',
      'imageUrl': 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22',
      'caption': 'Enjoying a peaceful afternoon together. Found that nature walks really help with anxiety. #DementiaCare #NatureTherapy',
      'likes': 128,
      'comments': 24,
      'timeAgo': '2 hours ago'
    },
    {
      'username': 'alzheimer_support',
      'userImage': 'https://i.pravatar.cc/150?img=2',
      'imageUrl': 'https://images.unsplash.com/photo-1556911220-bda9f7b2b187',
      'caption': 'Today\'s memory activity was a huge success! Music from the 60s really sparked joy and recognition. #MusicTherapy #MemoryCare',
      'likes': 256,
      'comments': 42,
      'timeAgo': '5 hours ago'
    },
    {
      'username': 'memory_lane',
      'userImage': 'https://i.pravatar.cc/150?img=3',
      'imageUrl': 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4',
      'caption': 'Creating a memory box with old photos and memorabilia. These tactile reminders can be incredibly grounding. #DementiaAwareness #MemoryBox',
      'likes': 189,
      'comments': 35,
      'timeAgo': '1 day ago'
    },
    {
      'username': 'dr_mind_health',
      'userImage': 'https://i.pravatar.cc/150?img=4',
      'imageUrl': 'https://images.unsplash.com/photo-1507120878965-54b2d3939100',
      'caption': 'New research suggests regular social interaction may slow cognitive decline. Making time for social activities matters! #ResearchNews #BrainHealth',
      'likes': 320,
      'comments': 58,
      'timeAgo': '1 day ago'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'DementiaLink Community',
          style: TextStyle(
            color: Color(0xFF503663),
            fontWeight: FontWeight.bold,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Color(0xFF503663)),
            onPressed: () {
              // Navigate to direct messages
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Messages coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _getPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF503663),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildFeedPage();
      case 1:
        return const CommunitySearchScreen();
      case 2:
        return const CommunityCreatePostScreen();
      case 3:
        return const CommunityNotificationsScreen();
      case 4:
        return const CommunityProfileScreen();
      default:
        return _buildFeedPage();
    }
  }

  Widget _buildFeedPage() {
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header with user info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(post['userImage']),
                ),
                const SizedBox(width: 8),
                Text(
                  post['username'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Show post options
                  },
                ),
              ],
            ),
          ),

          // Post image
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityPostDetailScreen(post: post),
                ),
              );
            },
            child: Image.network(
              post['imageUrl'],
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF503663),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    // Like post
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityPostDetailScreen(post: post),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () {
                    // Share post
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {
                    // Save post
                  },
                ),
              ],
            ),
          ),

          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${post['likes']} likes',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: '${post['username']} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: post['caption']),
                ],
              ),
            ),
          ),

          // Comments link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityPostDetailScreen(post: post),
                  ),
                );
              },
              child: Text(
                'View all ${post['comments']} comments',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),

          // Post time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              post['timeAgo'],
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}