import 'package:flutter/material.dart';
import '../services/auth_service.dart';
//import 'custom_drawer.dart';

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
      print("Checking role for user: $userId");

      if (userId != null) {
        final userData = await _authService.getUserData(userId);
        print("User data retrieved: ${userData['role']}");

        setState(() {
          _isCaregiver = userData['role'] == 'caregiver';
          _isLoading = false;
        });

        print("User is caregiver: $_isCaregiver");
      } else {
        print("No user ID found");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _isLoading = false;
      });
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
                                  // Profile pic tap handler (removed functionality)
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
                                children: const [
                                  // All shortcuts with navigation removed
                                  ShortcutButton(
                                    imagePath: 'lib/assets/icons/journal_icon.png',
                                    label: 'Story/Memory\nJournal',
                                  ),
                                  SizedBox(width: 24),
                                  ShortcutButton(
                                    imagePath: 'lib/assets/icons/notification_icon.png',
                                    label: 'Notification &\nReminders',
                                  ),
                                  SizedBox(width: 24),
                                  ShortcutButton(
                                    imagePath: 'lib/assets/icons/location_icon.png',
                                    label: 'Location\nTracking',
                                  ),
                                  SizedBox(width: 24),
                                  ShortcutButton(
                                    imagePath: 'lib/assets/icons/music_icon.png',
                                    label: 'Music\nTherapy',
                                  ),
                                  SizedBox(width: 24),
                                  ShortcutButton(
                                    imagePath: 'lib/assets/icons/art_icon.png',
                                    label: 'Art\nTherapy',
                                  ),
                                  SizedBox(width: 24),
                                  ShortcutButton(
                                    imagePath: 'lib/assets/icons/feature1_icon.png',
                                    label: 'Feature 1',
                                  ),
                                  SizedBox(width: 24),
                                  ShortcutButton(
                                    imagePath: 'lib/assets/icons/feature2_icon.png',
                                    label: 'Feature 2',
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
                                  onPressed: () {
                                    // Emergency call button (functionality removed)
                                  },
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

                          // Dashboard items - all navigation removed
                          Column(
                            children: const [
                              Row(
                                children: [
                                  Expanded(
                                    child: DashboardCard(
                                      title: 'Notification &\nReminders',
                                      imagePath: 'lib/assets/notifications.png',
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: DashboardCard(
                                      title: 'Story/ Memory\nJournal',
                                      imagePath: 'lib/assets/journal.png',
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              DashboardCard(
                                title: 'Location Tracking',
                                imagePath: 'lib/assets/location.png',
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DashboardCard(
                                      title: 'Art Therapy',
                                      imagePath: 'lib/assets/art.png',
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: DashboardCard(
                                      title: 'Music Therapy',
                                      imagePath: 'lib/assets/music.png',
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DashboardCard(
                                      title: 'AI Chatbot',
                                      imagePath: 'lib/assets/feature1.png',
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: DashboardCard(
                                      title: 'Community Chat',
                                      imagePath: 'lib/assets/feature2.png',
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
               /* AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(-280 * (1 - _animationController.value), 0),
                      child: const CustomDrawer(),
                    );
                  },
                ),*/
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
                  } else if (imagePath.contains('chatbot')) {
                    iconData = Icons.star;
                  } else if (imagePath.contains('community chat')) {
                    iconData = Icons.lightbulb;
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
    return Container(
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
);
}
}