import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/storage_provider.dart';
//import '../widgets/album_category.dart';
import '../widgets/memory_card.dart';
import '../models/album_model.dart';
import '../models/media_type.dart';
import '../utils/video_thumbnail_util.dart';
import '../screens/album_details_screen.dart';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to check if a date matches the search query
  bool _dateMatchesSearch(DateTime date, String query) {
    if (query.isEmpty) return false;

    try {
      // Format the date in various ways to check against the search
      final DateFormat fullFormat = DateFormat('yyyy-MM-dd');
      final DateFormat monthYearFormat = DateFormat('MMM yyyy');
      final DateFormat monthFormat = DateFormat('MMMM');
      final DateFormat yearFormat = DateFormat('yyyy');

      final String fullDate = fullFormat.format(date);
      final String monthYear = monthYearFormat.format(date);
      final String month = monthFormat.format(date);
      final String year = yearFormat.format(date);

      query = query.toLowerCase();

      return fullDate.toLowerCase().contains(query) ||
          monthYear.toLowerCase().contains(query) ||
          month.toLowerCase().contains(query) ||
          year.contains(query);
    } catch (e) {
      return false;
    }
  }

  void _showMoreOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) => Container(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Albums'),
              trailing: Icon(Icons.edit),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                // Implement edit albums functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Albums'),
              trailing: Icon(Icons.add),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                _showAddAlbumDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Albums'),
              trailing: Icon(Icons.delete),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                // Implement delete albums functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAlbumDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Album'),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            hintText: 'Album title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Provider.of<StorageProvider>(context, listen: false)
                    .addAlbum(titleController.text.trim(), 'custom');
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    final storageProvider = Provider.of<StorageProvider>(context);

    // Show loading indicator if not initialized
    if (!storageProvider.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    // Get all albums (both system and custom)
    final allAlbums = storageProvider.albums;

    // Get all photos for memories
    final allPhotos = allAlbums.expand((album) => album.photos).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with search option
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Search icon
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                    // More options menu
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _showMoreOptionsMenu(context);
                      },
                    ),
                  ],
                ),
              ],
            ),

            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search albums, dates, notes...',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        // Clear the search text and close the search bar
                        _searchController.clear();
                        setState(() {
                          _isSearchVisible = false;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    // This will rebuild the UI with filtered results
                    setState(() {});
                  },
                ),
              ),
            // All Albums (single section that includes both system and custom albums)
            if (allAlbums.isNotEmpty) ...[
              Text(
                'My Albums',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allAlbums.length,
                  itemBuilder: (context, index) {
                    // If search is active, filter albums by title
                    if (_isSearchVisible && _searchController.text.isNotEmpty) {
                      if (!allAlbums[index].title.toLowerCase().contains(_searchController.text.toLowerCase())) {
                        return Container(); // Return empty container if doesn't match search
                      }
                    }
                    return _buildAlbumItem(context, allAlbums[index]);
                  },
                ),
              ),
              SizedBox(height: 24),
            ],

            // Memories Section
            Text(
              'Memories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            MemoryCard(
              photos: _isSearchVisible && _searchController.text.isNotEmpty
                  ? allPhotos.where((photo) =>
              (photo.note?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
                  _dateMatchesSearch(photo.createdAt, _searchController.text)
              ).toList()
                  : allPhotos,
            ),
            SizedBox(height: 24),
            _buildCustomizeButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumItem(BuildContext context, Album album) {
    return GestureDetector(
      onTap: () {
        // Navigate to album details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.purple.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Album preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildAlbumCover(album),
            ),

            // Album info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${album.photos.length} ${album.photos.length == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCover(Album album) {
    if (album.photos.isEmpty) {
      return Container(
        color: Colors.purple.shade300,
        child: Icon(
          Icons.photo_library,
          color: Colors.white,
          size: 48,
        ),
      );
    }

    final coverPhoto = album.photos.first;
    return FutureBuilder<bool>(
      future: File(coverPhoto.path).exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data == true) {
          if (coverPhoto.mediaType == MediaType.video) {
            return VideoThumbnailUtil.buildVideoThumbnail(
              coverPhoto.path,
              width: double.infinity,
              height: double.infinity,
            );
          } else {
            return Image.file(
              File(coverPhoto.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.purple.shade300,
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 48,
                  ),
                );
              },
            );
          }
        } else {
          return Container(
            color: Colors.purple.shade300,
            child: Icon(
              Icons.photo_library,
              color: Colors.white,
              size: 48,
            ),
          );
        }
      },
    );
  }

  Widget _buildCustomizeButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _showCustomizeOptions(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library,
              color: Colors.deepPurple,
            ),
            SizedBox(width: 8),
            Text(
              'Customize & Reorder',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) => Container(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add_photo_alternate),
              title: Text('Add photos and videos'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                // Implement add photos functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Title and Photos'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                // Implement edit functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.add_box),
              title: Text('Add Albums'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                _showAddAlbumDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Albums'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                // Implement delete albums functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.push_pin),
              title: Text('Pin'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                // Implement pin functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}