import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
import '../widgets/custom_tab_bar.dart';
import 'custom_drawer.dart';
import 'gallery_screen.dart';
import 'albums_screen.dart';
import 'favourites_screen.dart';
import 'all_photos_screen.dart';
import 'deleted_screen.dart';
import 'art_therapy_overlay.dart';
// Import maps_screen for location tracking
import 'maps_screen.dart';
import '../services/auth_service.dart';
import 'gallery_screen.dart'; // Import the gallery screen directly
import '../models/storage_provider.dart'; // Use the correct path to your existing StorageProvider

// Import the PlaylistScreen
class Song {
  final String title;
  final String artist;
  final String imagePath;
  final String audioPath;

  Song({
    required this.title,
    required this.artist,
    required this.imagePath,
    required this.audioPath,
  });
}

final List<Song> songs = [
  Song(
    title: 'Dementia Track-1',
    artist: 'Dementia_Link',
    imagePath: 'lib/assets/images/i1.png',
    audioPath: 'lib/assets/audio/track1.mp3',
  ),
  Song(
    title: 'Dementia Track-2',
    artist: 'Dementia_Link',
    imagePath: 'lib/assets/images/i2.png',
    audioPath: 'lib/assets/audio/track2.mp3',
  ),
  Song(
    title: 'Dementia Track-3',
    artist: 'Dementia_Link',
    imagePath: 'lib/assets/images/i3.png',
    audioPath: 'lib/assets/audio/track3.mp3',
  ),
  Song(
    title: 'Dementia Track-4',
    artist: 'Dementia_Link',
    imagePath: 'lib/assets/images/i4.png',
    audioPath: 'lib/assets/audio/track4.mp3',
  ),
  Song(
    title: 'Dementia special Track',
    artist: 'Meditational StateHealing Music',
    imagePath: 'lib/assets/images/i5.jpg',
    audioPath: 'lib/assets/audio/track5.mp3',
  ),
];

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  return _buildSongTile(context, songs[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              'PLAYLIST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/assets/images/brain_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, Song song, int index) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          song.imagePath,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(initialSongIndex: index),
          ),
        );
      },
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final int initialSongIndex;

  const PlayerScreen({
    Key? key,
    required this.initialSongIndex,
  }) : super(key: key);

  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialSongIndex;
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() async {
    // Duration state
    _audioPlayer.positionStream.listen((pos) {
      setState(() => _position = pos);
    });
    _audioPlayer.durationStream.listen((dur) {
      setState(() => _duration = dur ?? Duration.zero);
    });
    // Playing state
    _audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
    // Load the initial song
    await _loadCurrentSong();
  }

  Future<void> _loadCurrentSong() async {
    try {
      await _audioPlayer.setAsset(songs[_currentIndex].audioPath);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _playNext() async {
    if (_currentIndex < songs.length - 1) {
      setState(() => _currentIndex++);
      await _loadCurrentSong();
    }
  }

  void _playPrevious() async {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      await _loadCurrentSong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A2B5C),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildAlbumArt(),
            const Spacer(),
            _buildSongInfo(),
            _buildProgressBar(),
            _buildControls(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Now Playing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/assets/images/brain_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      margin: const EdgeInsets.only(
        top: 65,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          songs[_currentIndex].imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            songs[_currentIndex].title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            songs[_currentIndex].artist,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.purple,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
          ),
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble(),
            onChanged: (value) {
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
            onPressed: _playPrevious,
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
              onPressed: _playPause,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
            onPressed: _playNext,
          ),
        ],
      ),
    );
  }
}

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
                    child: ClipOval(
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

  void showArtTherapyOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => ArtTherapyOverlay(
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Method to navigate to the music therapy screen
  void navigateToMusicTherapy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaylistScreen(),
      ),
    );
  }

  // FIXED: Updated method to navigate to location tracking
  // without role-based access control
  void navigateToLocationTracking() {
    // Navigate to maps screen for all users (no role check)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapsScreen(),
      ),
    );
  }

  // Modified method to navigate to Story/Memory Journal
  // Now directly goes to GalleryScreen wrapped in a StorageProvider
  void navigateToStoryMemoryJournal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => StorageProvider(),
          child: const JournalScreen(), // Use the JournalScreen which contains the GalleryScreen
        ),
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
                            const ShortcutButton(
                              imagePath: 'lib/assets/icons/notification_icon.png',
                              label: 'Notification &\nReminders',
                            ),
                            const SizedBox(width: 24),
                            // FIXED: Show location tracking and make functional for all users
                            GestureDetector(
                              onTap: navigateToLocationTracking, // Removed role-based condition
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
                              onTap: showArtTherapyOverlay,
                              child: const ShortcutButton(
                                imagePath: 'lib/assets/icons/art_icon.png',
                                label: 'Art\nTherapy',
                              ),
                            ),
                            const SizedBox(width: 24),
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
                        // FIXED: Show location tracking for all users
                        DashboardCard(
                          title: 'Location Tracking',
                          imagePath: 'lib/assets/location.png',
                          onTap: navigateToLocationTracking, // Removed role-based condition
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DashboardCard(
                                title: 'Art Therapy',
                                imagePath: 'lib/assets/art.png',
                                onTap: showArtTherapyOverlay,
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