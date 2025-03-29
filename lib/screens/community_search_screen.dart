import 'package:flutter/material.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({Key? key}) : super(key: key);

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  // Mock categories data
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Caregiver Tips', 'image': 'https://images.unsplash.com/photo-1516585427167-9f4af9627e6c'},
    {'name': 'Memory Activities', 'image': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b'},
    {'name': 'Success Stories', 'image': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac'},
    {'name': 'Nutrition', 'image': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352'},
    {'name': 'Research', 'image': 'https://images.unsplash.com/photo-1532094349884-543bc11b234d'},
    {'name': 'Support Groups', 'image': 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca'},
  ];

  // Mock trending posts data
  final List<Map<String, dynamic>> _trendingPosts = [
    {'imageUrl': 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22'},
    {'imageUrl': 'https://images.unsplash.com/photo-1556911220-bda9f7b2b187'},
    {'imageUrl': 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4'},
    {'imageUrl': 'https://images.unsplash.com/photo-1507120878965-54b2d3939100'},
    {'imageUrl': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac'},
    {'imageUrl': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2'},
    {'imageUrl': 'https://images.unsplash.com/photo-1541963463532-d68292c34b19'},
    {'imageUrl': 'https://images.unsplash.com/photo-1488751045188-3c55bbf9a3fa'},
    {'imageUrl': 'https://images.unsplash.com/photo-1513759565286-20e9c5fad06b'},
    {'imageUrl': 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e'},
    {'imageUrl': 'https://images.unsplash.com/photo-1517157837591-17b69085bfdc'},
    {'imageUrl': 'https://images.unsplash.com/photo-1469571486292-b53e58542fe5'},
  ];

  // Mock search results data
  final List<Map<String, dynamic>> _searchResults = [
    {
      'type': 'user',
      'username': 'caregiver_tips',
      'name': 'Daily Caregiver Tips',
      'image': 'https://i.pravatar.cc/150?img=12',
      'isVerified': true,
    },
    {
      'type': 'user',
      'username': 'memory_games',
      'name': 'Memory Activities & Games',
      'image': 'https://i.pravatar.cc/150?img=13',
      'isVerified': false,
    },
    {
      'type': 'hashtag',
      'name': '#dementiacare',
      'postsCount': 12453,
    },
    {
      'type': 'hashtag',
      'name': '#memorysupport',
      'postsCount': 8294,
    },
    {
      'type': 'user',
      'username': 'dr_johnson',
      'name': 'Dr. Emma Johnson - Neurologist',
      'image': 'https://i.pravatar.cc/150?img=14',
      'isVerified': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _isSearching
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                      });
                      FocusScope.of(context).unfocus();
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _isSearching = value.isNotEmpty;
                  });
                },
              ),
            ),

            // Content based on search state
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : _buildDiscoverContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF503663).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            category['image'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF503663),
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.error,
                                color: Colors.red,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Trending posts
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Popular Posts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(2),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: _trendingPosts.length,
            itemBuilder: (context, index) {
              return Image.network(
                _trendingPosts[index]['imageUrl'],
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
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Filter results based on search query for demo purposes
    final filteredResults = _searchResults.where((result) {
      if (result['type'] == 'user') {
        return result['username'].toString().contains(_searchQuery.toLowerCase()) ||
            result['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      } else {
        return result['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }
    }).toList();

    return ListView.builder(
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final result = filteredResults[index];

        if (result['type'] == 'user') {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(result['image']),
            ),
            title: Row(
              children: [
                Text(
                  result['username'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (result['isVerified'])
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(
                      Icons.verified,
                      color: Color(0xFF503663),
                      size: 14,
                    ),
                  ),
              ],
            ),
            subtitle: Text(result['name']),
            onTap: () {
              // Navigate to user profile
            },
          );
        } else {
          // Hashtag
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.tag,
                  color: Color(0xFF503663),
                ),
              ),
            ),
            title: Text(
              result['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${result['postsCount']} posts'),
            onTap: () {
              // Navigate to hashtag posts
            },
          );
        }
      },
    );
  }
}