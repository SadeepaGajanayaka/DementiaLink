import 'dart:io';
import 'package:flutter/material.dart';
import '../models/album_model.dart';
import '../models/media_type.dart';
import '../utils/video_thumbnail_util.dart';
import '../screens/album_details_screen.dart';

class AlbumCategory extends StatelessWidget {
  final String title;
  final List<Album> albums;

  AlbumCategory({
    required this.title,
    required this.albums,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return GestureDetector(
                onTap: () {
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
                      // Album cover image or placeholder
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: album.photos.isNotEmpty
                            ? _buildAlbumCoverMedia(album)
                            : Container(
                          color: Colors.purple.shade300,
                          child: Center(
                            child: Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),

                      // Album info overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumCoverMedia(Album album) {
    final coverPhoto = album.photos.first;

    try {
      if (coverPhoto.mediaType == MediaType.video) {
        // Handle video preview
        return VideoThumbnailUtil.buildVideoThumbnail(
          coverPhoto.path,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        // Handle image preview
        return Image.file(
          File(coverPhoto.path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading album cover: $error');
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
    } catch (e) {
      print('Error displaying album cover: $e');
      return Container(
        color: Colors.purple.shade300,
        child: Icon(
          Icons.photo_album,
          color: Colors.white,
          size: 48,
        ),
      );
    }
  }
}