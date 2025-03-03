import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/storage_provider.dart';
import '../models/album_model.dart';
import '../models/photo_model.dart';
import '../models/media_type.dart';
import 'add_media_screen.dart';
import 'photo_detail_screen.dart';
import '../utils/video_thumbnail_util.dart';
import '../utils/permission_service.dart';

class AlbumDetailScreen extends StatelessWidget {
  final Album album;
  final ImagePicker _picker = ImagePicker();

  AlbumDetailScreen({
    Key? key,
    required this.album,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF503663), // The purple background color
      appBar: AppBar(
        title: Text(
          album.title,
          style: TextStyle(
            color: Colors.white, // Explicitly set title to white
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF503663),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Back arrow explicitly set to white
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white, // Edit icon set to white
            ),
            onPressed: () {
              _showEditAlbumDialog(context);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.white, // Delete icon set to white
            ),
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
        iconTheme: IconThemeData(
          color: Colors.white, // This sets all icons in AppBar to white by default
        ),
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
              _showAddMediaOptions(context);
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
            _navigateToMediaDetail(context, media, index);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: media.mediaType == MediaType.video
                    ? VideoThumbnailUtil.buildVideoThumbnail(
                  media.path,
                  width: double.infinity,
                  height: double.infinity,
                )
                    : Image.file(
                  File(media.path),
                  fit: BoxFit.cover,
                ),
              ),
              if (media.isFavorite)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              // Show media type indicator
              if (media.mediaType == MediaType.video)
                Positioned(
                  top: 4,
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
              // Show note indicator if the media has a note
              if (media.note != null && media.note!.isNotEmpty)
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

  void _showAddMediaOptions(BuildContext context) {
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
                  _navigateToAddMediaScreen(
                      context,
                      File(photo.path),
                      MediaType.image
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
                // Show loading indicator
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(child: CircularProgressIndicator()),
                  );
                }

                // Request permission and ensure it's granted
                bool hasPermission = await PermissionService.requestStoragePermission(context);

                // Hide loading indicator
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }

                if (!hasPermission) return;

                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null && context.mounted) {
                  _navigateToAddMediaScreen(
                      context,
                      File(image.path),
                      MediaType.image
                  );
                }
              } catch (e) {
                print("Error picking photo from gallery: $e");
                // Hide loading indicator if showing
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error accessing gallery: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.video_library),
            title: Text('Choose video from gallery'),
            onTap: () async {
              // Close the bottom sheet first
              Navigator.of(bottomSheetContext).pop();

              try {
                // Check for storage permission
                bool permissionGranted = await PermissionService.requestStoragePermission(context);
                if (!permissionGranted) return;

                final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                if (video != null && context.mounted) {
                  _navigateToAddMediaScreen(
                      context,
                      File(video.path),
                      MediaType.video
                  );
                }
              } catch (e) {
                print("Error picking video from gallery: $e");
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

  void _navigateToAddMediaScreen(BuildContext context, File mediaFile, MediaType mediaType) {
    // Verify that the file exists before navigating
    if (!mediaFile.existsSync()) {
      print("Error: Media file doesn't exist: ${mediaFile.path}");
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
            builder: (context) => AddMediaScreen(
              albumId: album.id,
              mediaFile: mediaFile,
              mediaType: mediaType,
            ),
          ),
        );
      } catch (e) {
        print("Navigation error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to the media screen')),
        );
      }
    }
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

  void _navigateToMediaDetail(BuildContext context, Photo media, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDetailScreen(
          photo: media,
          photos: album.photos,
          currentIndex: index,
        ),
      ),
    );
  }
}