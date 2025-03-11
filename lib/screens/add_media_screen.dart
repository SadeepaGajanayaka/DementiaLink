import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/storage_provider.dart';
import '../models/photo_model.dart';
import '../models/media_type.dart';

class AddMediaScreen extends StatefulWidget {
  final String albumId;
  final File mediaFile;
  final MediaType mediaType;

  const AddMediaScreen({
    Key? key,
    required this.albumId,
    required this.mediaFile,
    required this.mediaType,
  }) : super(key: key);

  @override
  _AddMediaScreenState createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final TextEditingController _noteController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == MediaType.video) {
      _videoController = VideoPlayerController.file(widget.mediaFile)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleVideoPlayback() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF673AB7),
      appBar: AppBar(
        title: Text(widget.mediaType == MediaType.video ? 'Add Video' : 'Add Photo'),
        backgroundColor: Color(0xFF673AB7),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display selected media
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.mediaType == MediaType.video
                      ? _buildVideoPreview()
                      : Image.file(
                    widget.mediaFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Note input field
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add some note....',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Skip button
                  ElevatedButton(
                    onPressed: () {
                      _saveMediaToAlbum(context, null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('SKIP'),
                  ),

                  // Save button
                  ElevatedButton(
                    onPressed: () {
                      String? note = _noteController.text.isNotEmpty
                          ? _noteController.text.trim()
                          : null;
                      _saveMediaToAlbum(context, note);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('SAVE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _saveMediaToAlbum(BuildContext context, String? note) async {
    final storageProvider = Provider.of<StorageProvider>(context, listen: false);

    try {
      if (widget.mediaType == MediaType.video) {
        await storageProvider.addMediaWithNote(
          widget.albumId,
          widget.mediaFile,
          MediaType.video,
          note: note,
        );
      } else {
        await storageProvider.addMediaWithNote(
          widget.albumId,
          widget.mediaFile,
          MediaType.image,
          note: note,
        );
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.mediaType == MediaType.video
            ? 'Video added successfully'
            : 'Photo added successfully')),
      );

      // Return to previous screen
      Navigator.pop(context);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding media: ${e.toString()}')),
      );
    }
  }
}