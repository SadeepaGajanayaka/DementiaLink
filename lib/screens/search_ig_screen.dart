import 'package:flutter/material.dart';
import 'community_feed_screen.dart';
import 'favourite_following.dart';
import 'dementia_profile.dart';
import 'camera_screen.dart';
import 'message.dart';
import 'dashboard_screen.dart';

class SearchIGScreen extends StatefulWidget {
  const SearchIGScreen({Key? key}) : super(key: key);

  @override
  State<SearchIGScreen> createState() => _SearchIGScreenState();
}

class _SearchIGScreenState extends State<SearchIGScreen> {
  // Initialize controller and state variables
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['IGTV', 'Shop', 'Style', 'Sports', 'Auto', 'Memory'];
  int _selectedCategoryIndex = 1; // Default to Shop (index 1)
  String _searchQuery = '';
  List<GridItem> _searchResults = [];
  List<GridItem> _currentItems = [];

  // Maps of content by category
  final Map<String, List<GridItem>> _categorizedContent = {
    'IGTV': [
      GridItem(icon: Icons.video_library, color: Color(0xFFA8D8FF), isVideo: true, title: 'Memory game tips'),
      GridItem(icon: Icons.ondemand_video, color: Color(0xFFB5EAD7), isVideo: true, title: 'Caregiver stories'),
      GridItem(icon: Icons.smart_display, color: Color(0xFFFFD3B5), isVideo: true, title: 'New exercises'),
      GridItem(icon: Icons.video_call, color: Color(0xFFFF9AA2), isVideo: true, title: 'Live session'),
      GridItem(icon: Icons.theaters, color: Color(0xFFD0A8FF), isVideo: true, title: 'Doctor Q&A'),
      GridItem(icon: Icons.videocam, color: Color(0xFFFFF1A8), isVideo: true, title: 'Daily routine'),
      GridItem(icon: Icons.video_settings, color: Color(0xFF98D7C2), isVideo: true, title: 'Tips & Tricks'),
      GridItem(icon: Icons.video_label, color: Color(0xFFFFBCA8), isVideo: true, title: 'Activity ideas'),
      GridItem(icon: Icons.video_file, color: Color(0xFFC2B0FF), isVideo: true, title: 'Expert advice'),
    ],
    'Shop': [
      GridItem(icon: Icons.shopping_bag, color: Color(0xFFA8D8FF), isShop: true, title: 'Memory aids'),
      GridItem(icon: Icons.shopping_cart, color: Color(0xFFB5EAD7), isShop: true, title: 'Organizers'),
      GridItem(icon: Icons.local_mall, color: Color(0xFFFFD3B5), isShop: true, title: 'Care packages'),
      GridItem(icon: Icons.card_giftcard, color: Color(0xFFFF9AA2), isShop: true, title: 'Gift ideas'),
      GridItem(icon: Icons.local_pharmacy, color: Color(0xFFD0A8FF), isShop: true, title: 'Health aids'),
      GridItem(icon: Icons.local_grocery_store, color: Color(0xFFFFF1A8), isShop: true, title: 'Supplements'),
      GridItem(icon: Icons.devices, color: Color(0xFF98D7C2), isShop: true, title: 'Tech gadgets'),
      GridItem(icon: Icons.shopping_basket, color: Color(0xFFFFBCA8), isShop: true, title: 'Daily essentials'),
      GridItem(icon: Icons.store, color: Color(0xFFC2B0FF), isShop: true, title: 'Specialty stores'),
      GridItem(icon: Icons.bookmark, color: Color(0xFFA8D8FF), isShop: true, title: 'Recommended books'),
      GridItem(icon: Icons.kitchen, color: Color(0xFFB5EAD7), isShop: true, title: 'Kitchen aids'),
      GridItem(icon: Icons.bed, color: Color(0xFFFFD3B5), isShop: true, title: 'Sleep products'),
    ],
    'Style': [
      GridItem(icon: Icons.checkroom, color: Color(0xFFA8D8FF), title: 'Easy clothing'),
      GridItem(icon: Icons.accessibility, color: Color(0xFFB5EAD7), title: 'Adaptive wear'),
      GridItem(icon: Icons.dry_cleaning, color: Color(0xFFFFD3B5), title: 'Care clothing'),
      GridItem(icon: Icons.color_lens, color: Color(0xFFFF9AA2), title: 'Color therapy'),
      GridItem(icon: Icons.self_improvement, color: Color(0xFFD0A8FF), title: 'Comfort wear'),
      GridItem(icon: Icons.local_offer, color: Color(0xFFFFF1A8), title: 'Special offers'),
      GridItem(icon: Icons.handyman, color: Color(0xFF98D7C2), title: 'Ergonomic designs'),
      GridItem(icon: Icons.watch, color: Color(0xFFFFBCA8), title: 'Assistive accessories'),
      GridItem(icon: Icons.lightbulb, color: Color(0xFFC2B0FF), title: 'Night visibility'),
    ],
    'Sports': [
      GridItem(icon: Icons.directions_walk, color: Color(0xFFA8D8FF), title: 'Gentle walking'),
      GridItem(icon: Icons.pool, color: Color(0xFFB5EAD7), title: 'Water exercises'),
      GridItem(icon: Icons.fitness_center, color: Color(0xFFFFD3B5), title: 'Seated strength'),
      GridItem(icon: Icons.self_improvement, color: Color(0xFFFF9AA2), title: 'Yoga adaptations'),
      GridItem(icon: Icons.elderly, color: Color(0xFFD0A8FF), title: 'Senior fitness'),
      GridItem(icon: Icons.favorite, color: Color(0xFFFFF1A8), title: 'Heart health'),
      GridItem(icon: Icons.extension, color: Color(0xFF98D7C2), title: 'Flexibility'),
      GridItem(icon: Icons.route, color: Color(0xFFFFBCA8), title: 'Safe routes'),
      GridItem(icon: Icons.group, color: Color(0xFFC2B0FF), title: 'Group activities'),
    ],
    'Auto': [
      GridItem(icon: Icons.directions_car, color: Color(0xFFA8D8FF), title: 'Car adaptations'),
      GridItem(icon: Icons.map, color: Color(0xFFB5EAD7), title: 'Route planners'),
      GridItem(icon: Icons.gps_fixed, color: Color(0xFFFFD3B5), title: 'GPS trackers'),
      GridItem(icon: Icons.drive_eta, color: Color(0xFFFF9AA2), title: 'Driving assistance'),
      GridItem(icon: Icons.directions_bus, color: Color(0xFFD0A8FF), title: 'Transport services'),
      GridItem(icon: Icons.alarm, color: Color(0xFFFFF1A8), title: 'Journey reminders'),
      GridItem(icon: Icons.two_wheeler, color: Color(0xFF98D7C2), title: 'Mobility scooters'),
      GridItem(icon: Icons.airport_shuttle, color: Color(0xFFFFBCA8), title: 'Special transports'),
      GridItem(icon: Icons.tram, color: Color(0xFFC2B0FF), title: 'Accessible travel'),
    ],
    'Memory': [
      GridItem(icon: Icons.psychology, color: Color(0xFFA8D8FF), title: 'Brain games'),
      GridItem(icon: Icons.sticky_note_2, color: Color(0xFFB5EAD7), title: 'Memory journals'),
      GridItem(icon: Icons.photo_album, color: Color(0xFFFFD3B5), title: 'Photo albums'),
      GridItem(icon: Icons.book, color: Color(0xFFFF9AA2), title: 'Story books'),
      GridItem(icon: Icons.music_note, color: Color(0xFFD0A8FF), title: 'Music therapy'),
      GridItem(icon: Icons.spa, color: Color(0xFFFFF1A8), title: 'Sensory activities'),
      GridItem(icon: Icons.brush, color: Color(0xFF98D7C2), title: 'Art therapy'),
      GridItem(icon: Icons.camera_alt, color: Color(0xFFFFBCA8), title: 'Photo prompts'),
      GridItem(icon: Icons.people, color: Color(0xFFC2B0FF), title: 'Social memory'),
      GridItem(icon: Icons.calendar_today, color: Color(0xFFA8D8FF), title: 'Date reminders'),
      GridItem(icon: Icons.directions, color: Color(0xFFB5EAD7), title: 'Orientation guides'),
      GridItem(icon: Icons.history_edu, color: Color(0xFFFFD3B5), title: 'Reminiscence'),
    ],
  };

  @override
  void initState() {
    super.initState();
    // Initialize with the default category (Shop)
    _updateCurrentItems();
  }

  void _updateCurrentItems() {
    setState(() {
      if (_searchQuery.isNotEmpty) {
        // Search mode - gather results from all categories
        _searchResults = [];
        _categorizedContent.forEach((category, items) {
          for (var item in items) {
            if (item.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
              _searchResults.add(item);
            }
          }
        });
        _currentItems = _searchResults;
      } else if (_selectedCategoryIndex >= 0 && _selectedCategoryIndex < _categories.length) {
        // Category browsing mode
        String category = _categories[_selectedCategoryIndex];
        _currentItems = _categorizedContent[category] ?? [];
      } else {
        _currentItems = [];
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _updateCurrentItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            // Categories row
            _buildCategoriesRow(),

            // Grid of images
            Expanded(
              child: _buildImagesGrid(),
            ),

            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(51),  // 0.2 opacity = 51/255
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey, size: 16),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            )
                : null,
          ),
          onChanged: _performSearch,
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = index == _selectedCategoryIndex;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                  _updateCurrentItems();
                });
              },
              child: Chip(
                label: Row(
                  children: [
                    _getCategoryIcon(index),
                    SizedBox(width: _getCategoryIcon(index) != null ? 4 : 0),
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                backgroundColor: isSelected ? const Color(0xFF77588D) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getCategoryIcon(int index) {
    switch (index) {
      case 0: // IGTV
        return Icon(
          Icons.tv,
          size: 16,
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        );
      case 1: // Shop
        return Icon(
          Icons.shopping_bag,
          size: 16,
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        );
      case 2: // Style
        return Icon(
          Icons.checkroom,
          size: 16,
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        );
      case 3: // Sports
        return Icon(
          Icons.fitness_center,
          size: 16,
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        );
      case 4: // Auto
        return Icon(
          Icons.directions_car,
          size: 16,
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        );
      case 5: // Memory
        return Icon(
          Icons.psychology,
          size: 16,
          color: _selectedCategoryIndex == index ? Colors.white : Colors.black,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImagesGrid() {
    if (_currentItems.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_searchQuery"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _currentItems.length,
      itemBuilder: (context, index) {
        return _buildGridItem(_currentItems[index], index);
      },
    );
  }

  Widget _buildGridItem(GridItem item, int index) {
    return GestureDetector(
      onTap: () {
        _showItemDetails(item);
      },
      child: Container(
        color: item.color,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Center icon
            Center(
              child: Icon(
                item.icon,
                color: Colors.white,
                size: 32,
              ),
            ),

            // Item title
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // IGTV or Multi-image icon in the corner
            if (item.isVideo)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.tv,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            if (item.isMulti)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.collections,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            if (item.isShop)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(GridItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF503663),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(128),  // 0.5 opacity = 128/255
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryName(item),
                          style: TextStyle(
                            color: Colors.white.withAlpha(179),  // 0.7 opacity = 179/255
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white.withAlpha(26)),  // 0.1 opacity = 26/255

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getItemDescription(item),
                        style: TextStyle(
                          color: Colors.white.withAlpha(230),  // 0.9 opacity = 230/255
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (item.isVideo)
                        _buildVideoPreview(item)
                      else if (item.isShop)
                        _buildShopPreview(item)
                      else
                        _buildDefaultPreview(item),
                    ],
                  ),
                ),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF503663),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    item.isShop ? 'View Product' : 'View More',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(GridItem item) {
    for (var category in _categorizedContent.entries) {
      if (category.value.contains(item)) {
        return category.key;
      }
    }
    return '';
  }

  String _getItemDescription(GridItem item) {
    // Sample descriptions based on the category
    if (item.isVideo) {
      return 'This video provides valuable insights and guidance for caregivers and individuals with dementia. Learn techniques, exercises, and strategies to enhance memory and improve quality of life.';
    } else if (item.isShop) {
      return 'This product is specially designed to assist individuals with dementia in their daily activities. It provides support for memory enhancement, organizational assistance, and improved independence.';
    } else if (_getCategoryName(item) == 'Memory') {
      return 'This memory aid helps stimulate cognitive function through engaging activities, personalized reminiscence, and structured exercises designed by memory care specialists.';
    } else {
      return 'This resource offers valuable information and support for individuals with dementia and their caregivers. It includes practical advice, support strategies, and community connections.';
    }
  }

  Widget _buildVideoPreview(GridItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: item.color.withAlpha(179),  // 0.7 opacity = 179/255
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.person, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Expert Host',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            Spacer(),
            Text(
              '10:24',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShopPreview(GridItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              item.icon,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            Icon(Icons.star, color: Colors.amber, size: 16),
            Icon(Icons.star, color: Colors.amber, size: 16),
            Icon(Icons.star, color: Colors.amber, size: 16),
            Icon(Icons.star_half, color: Colors.amber, size: 16),
            SizedBox(width: 4),
            Text(
              '4.5 (128 reviews)',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '\$29.99',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'In Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultPreview(GridItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              item.icon,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.check_circle, 'Designed for ease of use'),
        _buildFeatureItem(Icons.check_circle, 'Supports memory enhancement'),
        _buildFeatureItem(Icons.check_circle, 'Recommended by care specialists'),
        _buildFeatureItem(Icons.check_circle, 'Positive community feedback'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
          // Home icon - navigate to Dashboard or Community Feed
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              color: Colors.white70,
              size: 28,
            ),
            onPressed: () {
              // First try to navigate back to Community Feed
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityFeedScreen(),
                ),
              );
            },
          ),
          // Search icon - already on search screen
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              // Already on search screen
            },
          ),
          // Add/Post icon - navigate to Camera screen
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
          // Favorites/Activity icon - navigate to Favourite Following screen
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
          // Profile icon - navigate to Profile screen
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
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Color(0xFF503663),
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

// Model class for grid items
class GridItem {
  final IconData icon;
  final Color color;
  final String title;
  final bool isVideo;
  final bool isMulti;
  final bool isShop;

  GridItem({
    required this.icon,
    required this.color,
    required this.title,
    this.isVideo = false,
    this.isMulti = false,
    this.isShop = false,
  });
}