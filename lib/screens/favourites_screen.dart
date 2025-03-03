import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
import '../models/photo_model.dart';
import 'photo_detail_screen.dart';
import '../models/media_type.dart'; // Make sure this import is added
import '../utils/video_thumbnail_util.dart'; // Make sure this import is added


class FavoritesScreen extends StatelessWidget {
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

    return FutureBuilder<List<Photo>>(
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

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: favoritePhotos.isEmpty
                    ? _buildEmptyState()
                    : _buildPhotoGrid(context, favoritePhotos),
              ),
            ],
          ),
        );
      },
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
}