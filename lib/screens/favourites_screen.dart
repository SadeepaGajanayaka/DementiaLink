import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/storage_provider.dart';
import '../models/photo_model.dart';
import 'photo_detail_screen.dart';
import '../models/media_type.dart';
import '../utils/video_thumbnail_util.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  List<Photo> _filteredPhotos = [];
  bool _isFilteringActive = false;

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

  void _filterPhotos(List<Photo> allPhotos, String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPhotos = [];
        _isFilteringActive = false;
      });
      return;
    }

    final List<Photo> filtered = allPhotos.where((photo) =>
    (photo.note?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        _dateMatchesSearch(photo.createdAt, query)
    ).toList();

    setState(() {
      _filteredPhotos = filtered;
      _isFilteringActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final storageProvider = Provider.of<StorageProvider>(context);

    if (!storageProvider.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return Column(
      children: [
        // Header with search
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorites',
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
                          _isFilteringActive = false;
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
            ],
          ),
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

        // Main content
        Expanded(
          child: FutureBuilder<List<Photo>>(
            future: storageProvider.getFavoritePhotos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

              final favoritePhotos = snapshot.data ?? [];
              final displayPhotos = _isFilteringActive ? _filteredPhotos : favoritePhotos;

              if (displayPhotos.isEmpty) {
                return _buildEmptyState(_isFilteringActive);
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPhotoGrid(context, displayPhotos),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isFiltering) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltering ? Icons.search_off : Icons.favorite_border,
            color: Colors.white.withOpacity(0.5),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            isFiltering ? 'No favorites match your search' : 'No favorite photos yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isFiltering
                ? 'Try a different search term'
                : 'Tap the heart icon on any photo to add it to favorites',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List<Photo> photos) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () {
            _navigateToPhotoDetail(context, photo, index, photos);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo.mediaType == MediaType.video
                    ? VideoThumbnailUtil.buildVideoThumbnail(
                  photo.path,
                  width: double.infinity,
                  height: double.infinity,
                )
                    : Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () {
                    Provider.of<StorageProvider>(context, listen: false)
                        .toggleFavorite(photo.id);
                  },
                ),
              ),
              // Show media type indicator
              if (photo.mediaType == MediaType.video)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              // Show note indicator if the photo has a note
              if (photo.note != null && photo.note!.isNotEmpty)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.note,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToPhotoDetail(BuildContext context, Photo photo, int index, List<Photo> photos) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDetailScreen(
          photo: photo,
          photos: photos,
          currentIndex: index,
        ),
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
  //             leading: Icon(Icons.favorite_border),
  //             title: Text('Remove all from favorites'),
  //             onTap: () {
  //               Navigator.of(bottomSheetContext).pop();
  //               _showRemoveAllConfirmation(context);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.filter_list),
  //             title: Text('Filter favorites'),
  //             onTap: () {
  //               Navigator.of(bottomSheetContext).pop();
  //               _showFilterOptions(context);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.share),
  //             title: Text('Share favorites'),
  //             onTap: () {
  //               Navigator.of(bottomSheetContext).pop();
  //               // Implement share functionality
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // void _showRemoveAllConfirmation(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Remove All from Favorites'),
  //       content: Text('Are you sure you want to remove all items from favorites? This action cannot be undone.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           child: Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             // Implement remove all functionality
  //           },
  //           style: TextButton.styleFrom(
  //             foregroundColor: Colors.red,
  //           ),
  //           child: Text('Remove All'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // void _showFilterOptions(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Filter Favorites'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: Icon(Icons.calendar_today),
  //             title: Text('By date'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               // Show date picker
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.videocam),
  //             title: Text('Videos only'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               // Filter to videos
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.image),
  //             title: Text('Photos only'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               // Filter to photos
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.note),
  //             title: Text('With notes only'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               // Filter to items with notes
  //             },
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //           child: Text('Cancel'),
  //         ),
  //       ],
  //     ),
  //   );
  //}
}