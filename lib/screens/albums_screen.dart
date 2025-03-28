import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/storage_provider.dart';
import '../models/album_model.dart';
import 'album_details_screen.dart';

class AlbumsScreen extends StatefulWidget {
  @override
  _AlbumsScreenState createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  List<Album> _filteredAlbums = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storageProvider = Provider.of<StorageProvider>(context);
    final allAlbums = storageProvider.albums;

    // Filter albums if search is active
    final albums = _isSearchVisible && _searchController.text.isNotEmpty
        ? allAlbums.where((album) =>
        album.title.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList()
        : allAlbums;

    if (!storageProvider.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search toggle
          Row(
            children: [
              Text(
                'Your Albums',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              // Search icon that toggles search bar visibility
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
              // IconButton(
              //   icon: Icon(
              //     Icons.more_vert,
              //     color: Colors.white,
              //   ),
              //   onPressed: () {
              //     _showMoreOptionsMenu(context);
              //   },
              // ),
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

          SizedBox(height: 16),

          // Album count indicator
          if (_isSearchVisible && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Found ${albums.length} albums',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),

          // Album grid or empty state
          Expanded(
            child: albums.isEmpty
                ? _buildEmptyState(context)
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                return _buildAlbumItem(context, albums[index]);
              },
            ),
          ),
          SizedBox(height: 16),
          _buildAddAlbumButton(context),
        ],
      ),
    );
  }

  // void _showMoreOptionsMenu(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext bottomSheetContext) => Container(
  //       color: Colors.grey.shade200,
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: Icon(Icons.delete),
  //             title: Text('Delete Albums'),
  //             trailing: Icon(Icons.delete),
  //             onTap: () {
  //               Navigator.of(bottomSheetContext).pop();
  //               // Implement your delete albums functionality here
  //               _showDeleteAlbumsDialog(context);
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  // void _showDeleteAlbumsDialog(BuildContext context) {
  //   // If you want to add a confirmation dialog before deleting
  //   showDialog(
  //     context: context,
  //     builder: (dialogContext) => AlertDialog(
  //       title: Text('Delete Albums'),
  //       content: Text('Are you sure you want to delete the selected albums? This action cannot be undone.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(dialogContext);
  //           },
  //           child: Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             // Add your actual delete logic here
  //             Navigator.pop(dialogContext);
  //             // Example: Provider.of<StorageProvider>(context, listen: false).deleteAlbum(albumId);
  //           },
  //           style: TextButton.styleFrom(
  //             foregroundColor: Colors.red,
  //           ),
  //           child: Text('Delete'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEmptyState(BuildContext context) {
    if (_isSearchVisible && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No albums match your search',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_album,
            color: Colors.white.withOpacity(0.5),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No albums yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _showAddAlbumDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Create Album'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumItem(BuildContext context, Album album) {
    return GestureDetector(
      onTap: () {
        _navigateToAlbumDetail(context, album);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Album preview
            album.photos.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(album.photos.first.path),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
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
              ),
            )
                : Center(
              child: Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 48,
              ),
            ),

            // Album info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8),
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
                      '${album.photos.length} Items',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Highlight search match if applicable
            if (_isSearchVisible &&
                _searchController.text.isNotEmpty &&
                album.title.toLowerCase().contains(_searchController.text.toLowerCase()))
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAlbumButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          _showAddAlbumDialog(context);
        },
        icon: Icon(Icons.add),
        label: Text('Add New Album'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
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
          autofocus: true,
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

  void _navigateToAlbumDetail(BuildContext context, Album album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailScreen(album: album),
      ),
    );
  }
}