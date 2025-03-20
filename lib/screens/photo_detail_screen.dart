import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/storage_provider.dart';
import '../models/photo_model.dart';
import '../models/media_type.dart';

class PhotoDetailScreen extends StatefulWidget {
  final Photo photo;
  final List<Photo> photos;
  final int currentIndex;

  const PhotoDetailScreen({
    Key? key,
    required this.photo,
    required this.photos,
    required this.currentIndex,
  }) : super(key: key);

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    if (widget.photo.mediaType == MediaType.video) {
      _videoController = VideoPlayerController.file(File(widget.photo.path));
      _videoController!.initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: true,
            looping: false,
            aspectRatio: _videoController!.value.aspectRatio,
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Text(
                  'Error loading video: $errorMessage',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Explicitly set to white
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.photo.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.photo.isFavorite ? Colors.red : Colors.white, // Favorite stays red when active
            ),
            onPressed: () {
              Provider.of<StorageProvider>(context, listen: false)
                  .toggleFavorite(widget.photo.id);
            },
          ),
          IconButton(
            icon: Icon(Icons.edit_note, color: Colors.white), // Edit icon in white
            onPressed: () {
              _showEditNoteDialog(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.share, color: Colors.white), // Share icon in white
            onPressed: () {
              // Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white), // Delete icon in white
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMediaViewer(),
          ),

          // Display note if available
          if (widget.photo.note != null && widget.photo.note!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.photo.note!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Media navigation bar
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: widget.currentIndex > 0
                      ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoDetailScreen(
                          photo: widget.photos[widget.currentIndex - 1],
                          photos: widget.photos,
                          currentIndex: widget.currentIndex - 1,
                        ),
                      ),
                    );
                  }
                      : null,
                ),
                Text(
                  '${widget.currentIndex + 1} / ${widget.photos.length}',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: widget.currentIndex < widget.photos.length - 1
                      ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoDetailScreen(
                          photo: widget.photos[widget.currentIndex + 1],
                          photos: widget.photos,
                          currentIndex: widget.currentIndex + 1,
                        ),
                      ),
                    );
                  }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaViewer() {
    if (widget.photo.mediaType == MediaType.video) {
      if (_chewieController != null) {
        return Chewie(controller: _chewieController!);
      } else {
        return Center(child: CircularProgressIndicator(color: Colors.white));
      }
    } else {
      // For images, use PhotoView
      return PhotoView(
        imageProvider: FileImage(File(widget.photo.path)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: BoxDecoration(
          color: Colors.black,
        ),
      );
    }
  }

  void _showEditNoteDialog(BuildContext context) {
    final TextEditingController noteController = TextEditingController(text: widget.photo.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note'),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            hintText: 'Add a note for this ${widget.photo.mediaType == MediaType.video ? 'video' : 'photo'}',
          ),
          maxLines: 3,
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
              String? note = noteController.text.trim().isEmpty ? null : noteController.text.trim();
              Provider.of<StorageProvider>(context, listen: false)
                  .updatePhotoNote(widget.photo.id, note);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // Replace the _showDeleteConfirmation method in photo_detail_screen.dart

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to Trash'),
        content: Text(
          'Are you sure you want to move this ${widget.photo.mediaType == MediaType.video ? 'video' : 'photo'} to trash? You can recover it from the Deleted Items section within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final storageProvider = Provider.of<StorageProvider>(context, listen: false);
              await storageProvider.deletePhoto(widget.photo.id);

              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Item moved to trash'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      // Recover the photo immediately if user changes mind
                      storageProvider.recoverDeletedPhotos([widget.photo.id]);
                    },
                  ),
                ),
              );

              // Return to previous screen
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Move to Trash'),
          ),
        ],
      ),
    );
  }
}