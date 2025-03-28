import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
import '../models/photo_model.dart';
import 'photo_detail_screen.dart';
import '../models/media_type.dart'; // Make sure this import is added
import '../utils/video_thumbnail_util.dart'; // Make sure this import is added


class AllPhotosScreen extends StatelessWidget {
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
      future: storageProvider.getAllPhotos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        final allPhotos = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Photos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${allPhotos.length} photos',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: allPhotos.isEmpty
                    ? _buildEmptyState()
                    : _buildPhotoGrid(context, allPhotos),
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
            Icons.photo_library,
            color: Colors.white.withOpacity(0.5),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No photos yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Photos you add to albums will appear here',
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
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
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
              // Use the improved VideoThumbnailUtil for videos
              photo.mediaType == MediaType.video
                  ? VideoThumbnailUtil.buildVideoThumbnail(
                photo.path,
                width: double.infinity,
                height: double.infinity,
              )
                  : Image.file(
                File(photo.path),
                fit: BoxFit.cover,
              ),
              if (photo.isFavorite)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              // Show media type indicator for videos
              if (photo.mediaType == MediaType.video)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              // Show note indicator if the photo has a note
              if (photo.note != null && photo.note!.isNotEmpty)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.note,
                      color: Colors.white,
                      size: 12,
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