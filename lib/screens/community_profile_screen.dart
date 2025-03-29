import 'package:flutter/material.dart';

class CommunityProfileScreen extends StatefulWidget {
  const CommunityProfileScreen({Key? key}) : super(key: key);

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock user data
  final Map<String, dynamic> _userData = {
    'username': 'john_caregiver',
    'name': 'John Anderson',
    'bio': 'Caregiver for 5 years | Sharing tips and experiences to help others on this journey | Advocate for dementia awareness',
    'postsCount': 24,
    'followersCount': 348,
    'followingCount': 215,
    'profileImage': 'https://i.pravatar.cc/300?img=11',
    'isVerified': true,
    'highlights': [
      {'title': 'Tips', 'image': 'https://i.pravatar.cc/100?img=1'},
      {'title': 'Activities', 'image': 'https://i.pravatar.cc/100?img=2'},
      {'title': 'Resources', 'image': 'https://i.pravatar.cc/100?img=3'},
      {'title': 'Memories', 'image': 'https://i.pravatar.cc/100?img=4'},
    ],
  };

  // Mock posts data
  final List<Map<String, dynamic>> _posts = [
    {
      'imageUrl': 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22'
    },
    {'imageUrl': 'https://images.unsplash.com/photo-1556911220-bda9f7b2b187'},
    {
      'imageUrl': 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4'
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1507120878965-54b2d3939100'
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac'
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2'
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1541963463532-d68292c34b19'
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1488751045188-3c55bbf9a3fa'
    },
    {
      'imageUrl': 'https://images.unsplash.com/photo-1513759565286-20e9c5fad06b'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              _userData['username'],
              style: const TextStyle(
                color: Color(0xFF503663),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_userData['isVerified'])
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.verified,
                  color: Color(0xFF503663),
                  size: 16,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Color(0xFF503663)),
            onPressed: () {
              // Add new content
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF503663)),
            onPressed: () {
              // Show menu
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) {
          return [
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),
          ];
        },
        body: Column(
          children: [
            // Tab bar
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF503663),
              tabs: const [
                Tab(icon: Icon(Icons.grid_on, color: Color(0xFF503663))),
                Tab(icon: Icon(
                    Icons.bookmark_border, color: Color(0xFF503663))),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsGrid(),
                  _buildSavedGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture and stats
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_userData['profileImage']),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Posts', _userData['postsCount']),
                    _buildStatColumn('Followers', _userData['followersCount']),
                    _buildStatColumn('Following', _userData['followingCount']),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name and bio
          Text(
            _userData['name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userData['bio'],
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Edit profile
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Story highlights
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var highlight in _userData['highlights'])
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(highlight['image']),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          highlight['title'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return Image.network(
          _posts[index]['imageUrl'],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF503663),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.error,
                color: Colors.red,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedGrid() {
    // For demo purposes, we'll just show the same posts
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _posts.length > 3 ? 3 : _posts.length,
      // Showing fewer saved posts
      itemBuilder: (context, index) {
        return Image.network(
          _posts[index]['imageUrl'],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF503663),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.error,
                color: Colors.red,
              ),
            );
          },
        );
      },
    );
  }
}