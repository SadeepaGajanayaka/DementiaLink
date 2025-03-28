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
        // Header with options menu only
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
              // Only keep the more options menu
            //   IconButton(
            //     icon: Icon(
            //       Icons.more_vert,
            //       color: Colors.white,
            //     ),
            //     // onPressed: () {
            //     //   _showMoreOptionsMenu(context);
            //     // },
            //   ),
             ],
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

              if (favoritePhotos.isEmpty) {
                return _buildEmptyState();
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPhotoGrid(context, favoritePhotos),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            color: Colors.white.withOpacity(0.5),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No favorite photos yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the heart icon on any photo to add it to favorites',
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
  //
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
 // }
}