// File: lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../models/storage_provider.dart';
import '../widgets/custom_tab_bar.dart';
import 'custom_drawer.dart';
import 'gallery_screen.dart';
import 'albums_screen.dart';
import 'favourites_screen.dart';
import 'all_photos_screen.dart';
import 'deleted_screen.dart';
import 'maps_screen.dart';
import '../services/auth_service.dart';
import 'drawing_app.dart';
import 'task_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chatbot_screen.dart';
import 'community_feed_screen.dart';
// Import the music player
import 'music_main.dart';

// Create a Journal screen that contains the GalleryScreen wrapped in the necessary providers
class JournalScreen extends StatelessWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Story Memory Journal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const ClipOval(
                      child: Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Gallery Screen
            Expanded(
              child: GalleryScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isDrawerOpen = false;

  // Added variables to handle user role check
  bool _isLoading = true;
  bool _isCaregiver = false;

  // Auth service for checking user role
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Check user role when dashboard initializes
    _checkUserRole();
  }

  // Method to check if the current user is a caregiver
  Future<void> _checkUserRole() async {
    try {
      final userId = _authService.currentUser?.uid;
      debugPrint("Checking role for user: $userId");

      if (userId != null) {
        final userData = await _authService.getUserData(userId);
        debugPrint("User data retrieved: ${userData['role']}");

        if (mounted) {
          setState(() {
            _isCaregiver = userData['role'] == 'caregiver';
            _isLoading = false;
          });
        }

        debugPrint("User is caregiver: $_isCaregiver");
      } else {
        debugPrint("No user ID found");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // Method to show the drawing app
  void navigateToDrawingApp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DrawingPage(),
      ),
    );
  }

  // Method to navigate to the music therapy screen
  void navigateToMusicTherapy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistScreen(), // Removed 'const' to fix the error
      ),
    );
  }

  // Method to navigate to location tracking
  void navigateToLocationTracking() {
    // Navigate to maps screen for all users (no role check)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapsScreen(),
      ),
    );
  }

  // Method to navigate to notification & reminders - using the TaskListScreen
  void navigateToNotificationsAndReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen(), // This uses the TaskListScreen class from task_list_screen.dart
      ),
    );
  }

  // Modified method to navigate to Story/Memory Journal
  void navigateToStoryMemoryJournal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => provider.ChangeNotifierProvider(
          create: (_) => StorageProvider(),
          child: const JournalScreen(), // Use the JournalScreen which contains the GalleryScreen
        ),
      ),
    );
  }

  // Method for AI Chatbot feature
  void navigateToAIChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatbotScreen(),
      ),
    );
  }

  // Method to navigate to Community Chat (CommunityFeedScreen)
  void navigateToCommunityChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityFeedScreen(),
      ),
    );
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
          : Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                          onPressed: _toggleDrawer,
                        ),
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Add your logo click handler here
                          },
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'lib/assets/111.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Color(0xFF503663),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Shortcuts section
                    const Text(
                      'Shortcuts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 130,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Updated Story/Memory Journal with navigation
                            GestureDetector(
                              onTap: navigateToStoryMemoryJournal,
                              child: const ShortcutButton(
                                imagePath: 'lib/assets/icons/journal_icon.png',
                                label: 'Story/Memory\nJournal',
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Connect Notification & Reminders shortcut to the Task List Screen
                            GestureDetector(
                              onTap: navigateToNotificationsAndReminders,
                              child: const ShortcutButton(
                                imagePath: 'lib/assets/icons/notification_icon.png',
                                label: 'Notification &\nReminders',
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Location tracking
                            GestureDetector(
                              onTap: navigateToLocationTracking,
                              child: const ShortcutButton(
                                imagePath: 'lib/assets/icons/location_icon.png',
                                label: 'Location\nTracking',
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: navigateToMusicTherapy,
                              child: const ShortcutButton(
                                imagePath: 'lib/assets/icons/music_icon.png',
                                label: 'Music\nTherapy',
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: navigateToDrawingApp,
                              child: const ShortcutButton(
                                imagePath: 'lib/assets/icons/art_icon.png',
                                label: 'Art\nTherapy',
                              ),
                            ),
                            const SizedBox(width: 24),
                            // AI Chatbot shortcut
                            GestureDetector(
                              onTap: navigateToAIChatbot,
                              child: const ShortcutButton(
                                imagePath: 'lib/assets/icons/feature1_icon.png',
                                label: 'AI\nChatbot',
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Community Chat shortcut - now connected to CommunityFeedScreen
                            GestureDetector(
                              onTap: navigateToCommunityChat,
                              child: const ShortcutButton(
                                imagePath: 'lib/assets/icons/feature2_icon.png',
                                label: 'Community\nChat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Emergency Call section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Contact your loved one. If you need any help.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF503663),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF503663),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF503663),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Emergency Call',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dashboard items
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DashboardCard(
                                title: 'Notification &\nReminders',
                                imagePath: 'lib/assets/notifications.png',
                                onTap: navigateToNotificationsAndReminders,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Updated Story/Memory Journal card with navigation
                            Expanded(
                              child: DashboardCard(
                                title: 'Story/ Memory\nJournal',
                                imagePath: 'lib/assets/journal.png',
                                onTap: navigateToStoryMemoryJournal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Location tracking card
                        DashboardCard(
                          title: 'Location Tracking',
                          imagePath: 'lib/assets/location.png',
                          onTap: navigateToLocationTracking,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DashboardCard(
                                title: 'Art Therapy',
                                imagePath: 'lib/assets/art.png',
                                onTap: navigateToDrawingApp,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DashboardCard(
                                title: 'Music Therapy',
                                imagePath: 'lib/assets/music.png',
                                onTap: navigateToMusicTherapy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Modified dashboard cards with updated navigation
                        Row(
                          children: [
                            Expanded(
                              child: DashboardCard(
                                title: 'AI Chatbot',
                                imagePath: 'lib/assets/feature1.png',
                                onTap: navigateToAIChatbot,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DashboardCard(
                                title: 'Community Chat',
                                imagePath: 'lib/assets/feature2.png',
                                onTap: navigateToCommunityChat,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Drawer Overlay
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black54,
              ),
            ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-280 * (1 - _animationController.value), 0),
                child: const CustomDrawer(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ShortcutButton extends StatelessWidget {
  final String imagePath;
  final String label;

  const ShortcutButton({
    Key? key,
    required this.imagePath,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon in case image is not found
                  IconData iconData;
                  if (imagePath.contains('journal')) {
                    iconData = Icons.book;
                  } else if (imagePath.contains('notification')) {
                    iconData = Icons.notifications;
                  } else if (imagePath.contains('location')) {
                    iconData = Icons.location_on;
                  } else if (imagePath.contains('music')) {
                    iconData = Icons.music_note;
                  } else if (imagePath.contains('art')) {
                    iconData = Icons.palette;
                  } else if (imagePath.contains('feature1')) {
                    iconData = Icons.chat_bubble_outline;
                  } else if (imagePath.contains('feature2')) {
                    iconData = Icons.forum;
                  } else {
                    iconData = Icons.image;
                  }
                  return Icon(
                    iconData,
                    color: const Color(0xFF503663),
                    size: 30,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.imagePath,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // This won't actually show, but it handles the error
            },
          ),
          color: const Color(0xFF77588D), // Fallback color if image fails to load
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}