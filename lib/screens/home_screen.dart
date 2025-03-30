import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
import '../widgets/custom_tab_bar.dart';
import 'gallery_screen.dart';
import 'albums_screen.dart';
import 'favourites_screen.dart';
import 'all_photos_screen.dart';
import 'deleted_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    GalleryScreen(),
    AlbumsScreen(),
    FavoritesScreen(),
    AllPhotosScreen(),
    DeletedScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the storage provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StorageProvider>(context, listen: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            CustomTabBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            Expanded(
              child: _screens[_currentIndex],
            ),
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
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Handle back button press
            },
          ),
          SizedBox(width: 8),
          Text(
            'Story Memory Journal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(8),
            child: ClipOval(
              child: Image.asset('assets/logo.png'),
            ),
          ),
        ],
      ),
    );
  }
}