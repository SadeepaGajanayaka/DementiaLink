import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
import '../models/album_model.dart';

class AlbumsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final storageProvider = Provider.of<StorageProvider>(context);
    final albums = storageProvider.albums;

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
          Text(
            'Your Albums',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
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

  Widget _buildEmptyState(BuildContext context) {
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
        // Navigate to album detail (will implement in next commit)
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
}