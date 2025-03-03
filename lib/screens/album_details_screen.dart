import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/permission_service.dart';
import 'add_photo_screen.dart';

class AlbumDetailScreen extends StatelessWidget {
  final Album album;

  AlbumDetailScreen({
    Key? key,
    required this.album,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF503663),
      appBar: AppBar(
        title: Text(
          album.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF503663),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              _showEditAlbumDialog(context);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.white,
            ),
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${album.photos.length} media items',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: album.photos.isEmpty
                  ? _buildEmptyMediaState(context)
                  : _buildMediaGrid(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMediaOptions(context);
        },
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF503663),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyMediaState(BuildContext context) {
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
            'No photos or videos in this album yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Will implement photo addition in next commit
            },
            child: Text('Add Media'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF503663),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: album.photos.length,
      itemBuilder: (context, index) {
        final media = album.photos[index];
        return GestureDetector(
          onTap: () {
            // Will implement photo detail view later
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(media.path),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  void _showEditAlbumDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController(text: album.title);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit Album'),
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
              Navigator.pop(dialogContext);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty && newTitle != album.title) {
                // Update the album title in the storage provider
                Provider.of<StorageProvider>(context, listen: false)
                    .updateAlbumTitle(album.id, newTitle);
              }
              Navigator.pop(dialogContext);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Album'),
        content: Text(
          'Are you sure you want to delete "${album.title}"? This will remove all photos and videos in this album and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              _deleteAlbum(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAlbum(BuildContext context) async {
    final storageProvider = Provider.of<StorageProvider>(context, listen: false);
    await storageProvider.deleteAlbum(album.id);
    Navigator.pop(context); // Return to albums screen
  }
  void _showAddMediaOptions(BuildContext context) {
    final ImagePicker _picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_camera),
            title: Text('Take a photo'),
            onTap: () async {
              Navigator.of(bottomSheetContext).pop();

              try {
                bool hasPermission = await PermissionService.requestCameraPermission(context);
                if (!hasPermission) return;

                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                if (photo != null && context.mounted) {
                  _navigateToAddPhotoScreen(
                      context,
                      File(photo.path)
                  );
                }
              } catch (e) {
                print("Error taking photo: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error accessing camera: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose photo from gallery'),
            onTap: () async {
              Navigator.of(bottomSheetContext).pop();

              try {
                bool hasPermission = await PermissionService.requestStoragePermission(context);
                if (!hasPermission) return;

                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null && context.mounted) {
                  _navigateToAddPhotoScreen(
                      context,
                      File(image.path)
                  );
                }
              } catch (e) {
                print("Error picking photo from gallery: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error accessing gallery: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _navigateToAddPhotoScreen(BuildContext context, File imageFile) {
    // Verify that the file exists before navigating
    if (!imageFile.existsSync()) {
      print("Error: Media file doesn't exist: ${imageFile.path}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing the selected media file')),
      );
      return;
    }

    if (context.mounted) {
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPhotoScreen(
              albumId: album.id,
              imageFile: imageFile,
            ),
          ),
        );
      } catch (e) {
        print("Navigation error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to the photo screen')),
        );
      }
    }
  }
}