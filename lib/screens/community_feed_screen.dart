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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF503663)),
          onPressed: () {
            Navigator.pop(context);
          },
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
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle image loading error
                    print('Error loading user image: $exception');
                  },
                  backgroundColor: Colors.grey[300],
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
                    _showPostOptions(context, post);
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
                    _likePost(post);
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
                    _sharePost(context, post);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {
                    // Save post
                    _savePost(context, post);
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

  // Helper methods for post interactions

  void _likePost(Map<String, dynamic> post) {
    // In a real app, this would call an API
    setState(() {
      post['likes'] = post['likes'] + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You liked ${post['username']}\'s post'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _savePost(BuildContext context, Map<String, dynamic> post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post saved to your bookmarks'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sharePost(BuildContext context, Map<String, dynamic> post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPostOptions(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('Save Post'),
                onTap: () {
                  Navigator.pop(context);
                  _savePost(context, post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Post'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePost(context, post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Report Post'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post reported. Our team will review it.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// Placeholder implementations for the screens referenced in the tab navigation
// In a real app, these would be in their own files

class CommunitySearchScreen extends StatelessWidget {
  const CommunitySearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Search for caregivers, patients,\nand community groups',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityCreatePostScreen extends StatelessWidget {
  const CommunityCreatePostScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Post',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF503663),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts, experiences or questions...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo_library, color: Color(0xFF503663)),
                onPressed: () {
                  // Add photo
                },
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Color(0xFF503663)),
                onPressed: () {
                  // Take photo
                },
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF503663),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  // Post
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post created successfully!'),
                    ),
                  );
                },
                child: const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommunityNotificationsScreen extends StatelessWidget {
  const CommunityNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'user': 'sarah_caregiver',
        'action': 'liked your post',
        'time': '2 min ago',
        'userImage': 'https://i.pravatar.cc/150?img=1',
      },
      {
        'user': 'memory_lane',
        'action': 'commented on your post',
        'time': '45 min ago',
        'userImage': 'https://i.pravatar.cc/150?img=3',
      },
      {
        'user': 'alzheimer_support',
        'action': 'mentioned you in a comment',
        'time': '2 hours ago',
        'userImage': 'https://i.pravatar.cc/150?img=2',
      },
      {
        'user': 'dr_mind_health',
        'action': 'shared your post',
        'time': '1 day ago',
        'userImage': 'https://i.pravatar.cc/150?img=4',
      },
    ];

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(notification['userImage']!),
            onBackgroundImageError: (exception, stackTrace) {
              // Handle image loading error
            },
            backgroundColor: Colors.grey[300],
          ),
          title: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: notification['user'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' ${notification['action']}'),
              ],
            ),
          ),
          subtitle: Text(notification['time']!),
          onTap: () {
            // Navigate to the relevant content
          },
        );
      },
    );
  }
}

class CommunityProfileScreen extends StatelessWidget {
  const CommunityProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile header
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://i.pravatar.cc/300?img=5'),
            backgroundColor: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'John Doe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Caregiver | Dementia Advocate',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat('Posts', '24'),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildStat('Followers', '156'),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildStat('Following', '98'),
            ],
          ),
          const SizedBox(height: 24),
          // Edit profile button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF503663),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              // Edit profile
            },
            child: const Text('Edit Profile'),
          ),
          const SizedBox(height: 24),
          // Profile posts - simple grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 9, // Show 9 sample posts
            itemBuilder: (context, index) {
              return Image.network(
                'https://picsum.photos/500/500?random=${index + 10}',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
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
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class CommunityPostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const CommunityPostDetailScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample comments for the post
    final comments = [
      {
        'username': 'david_caregiver',
        'text': 'This is so helpful! I\'ve been trying to find ways to reduce my mom\'s anxiety.',
        'timeAgo': '1 hour ago',
        'userImage': 'https://i.pravatar.cc/150?img=7',
      },
      {
        'username': 'memory_center',
        'text': 'Nature therapy has shown great results in our center as well. We\'ve started a weekly garden program!',
        'timeAgo': '45 minutes ago',
        'userImage': 'https://i.pravatar.cc/150?img=8',
      },
      {
        'username': 'jane_family',
        'text': 'Where do you usually go for your walks? Any specific recommendations?',
        'timeAgo': '30 minutes ago',
        'userImage': 'https://i.pravatar.cc/150?img=9',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF503663)),
        title: const Text(
          'Post',
          style: TextStyle(
            color: Color(0xFF503663),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(post['userImage']),
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post['timeAgo'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Post image
                  Image.network(
                    post['imageUrl'],
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

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            // Like post
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post liked')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () {
                            // Focus comment field
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_outlined),
                          onPressed: () {
                            // Share post
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sharing coming soon')),
                            );
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border),
                          onPressed: () {
                            // Save post
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post saved')),
                            );
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

                  const Divider(),

                  // Comments
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Comments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Comment list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(comment['userImage']!),
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: comment['username'],
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: ' ${comment['text']}'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        comment['timeAgo']!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: () {
                                          // Like comment
                                        },
                                        child: Text(
                                          'Like',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: () {
                                          // Reply to comment
                                        },
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=5'),
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Post comment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comment posted!')),
                    );
                  },
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      color: Color(0xFF503663),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}