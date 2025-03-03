import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
//import '../widgets/album_category.dart';
import '../widgets/memory_card.dart';
import '../models/album_model.dart';
import '../models/media_type.dart';
import '../utils/video_thumbnail_util.dart';
import '../screens/album_details_screen.dart';

class GalleryScreen extends StatelessWidget {
  @override
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

    // Get all albums
    final allAlbums = storageProvider.albums;

    // Get default system albums (Family and Friends)
    final systemAlbums = allAlbums.where((album) => album.type == 'system').toList();

    // Get custom albums (created by the user)
    final customAlbums = allAlbums.where((album) => album.type == 'custom').toList();

    // Get all photos for memories
    final allPhotos = allAlbums.expand((album) => album.photos).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Albums (Family | Friends)
            if (systemAlbums.isNotEmpty) ...[
              Text(
                'Family | Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: systemAlbums.length,
                  itemBuilder: (context, index) {
                    return _buildAlbumItem(context, systemAlbums[index]);
                  },
                ),
              ),
              SizedBox(height: 24),
            ],

            // Custom Albums
            if (customAlbums.isNotEmpty) ...[
              Text(
                'My Albums',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: customAlbums.length,
                  itemBuilder: (context, index) {
                    return _buildAlbumItem(context, customAlbums[index]);
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
              photos: allPhotos,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogOption(context, Icons.add, 'Add photos and videos'),
              Divider(),
              _buildDialogOption(context, Icons.edit, 'Edit Title and Photos'),
              Divider(),
              _buildDialogOption(context, Icons.add_box, 'Add Albums'),
              Divider(),
              _buildDialogOption(context, Icons.delete, 'Delete Albums'),
              Divider(),
              _buildDialogOption(context, Icons.push_pin, 'Pin'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          // Handle option tap based on text
          if (text == 'Add photos and videos') {
            // Navigate to add photos screen or show picker
          } else if (text == 'Add Albums') {
            _showAddAlbumDialog(context);
          } else if (text == 'Delete Albums') {
            // Show album deletion dialog
          }
        },
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            Spacer(),
            Icon(icon),
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
}