import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  const CreatePostScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  }) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isPostValid = false;

  @override
  void initState() {
    super.initState();
    // Add listener to validate post
    _postController.addListener(_validatePost);
  }

  @override
  void dispose() {
    _postController.removeListener(_validatePost);
    _postController.dispose();
    super.dispose();
  }

  void _validatePost() {
    setState(() {
      _isPostValid = _postController.text.trim().isNotEmpty || _selectedImage != null;
    });
  }

  Future<void> _selectImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });

        // Validate post after selecting image
        _validatePost();
      }
    } catch (e) {
      print('Error selecting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });

        // Validate post after taking photo
        _validatePost();
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _submitPost() async {
    if (!_isPostValid) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        String filePath = 'community_posts/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(filePath);

        await ref.putFile(
          _selectedImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        imageUrl = await ref.getDownloadURL();
      }

      // Create post document
      await _firestore.collection('community_posts').add({
        'userId': widget.userId,
        'userName': widget.userName,
        'userPhotoUrl': widget.userPhotoUrl,
        'text': _postController.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'commentCount': 0,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );

        // Close the screen
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error creating post: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      appBar: AppBar(
        backgroundColor: const Color(0xFF503663),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isPostValid && !_isSubmitting ? _submitPost : null,
            child: Text(
              'Share',
              style: TextStyle(
                color: _isPostValid && !_isSubmitting ? Colors.white : Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and text input
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF77588D),
                    backgroundImage: widget.userPhotoUrl != null
                        ? NetworkImage(widget.userPhotoUrl!)
                        : null,
                    child: widget.userPhotoUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind?',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      minLines: 3,
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),

            // Selected image preview
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                        _validatePost();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Add photo/camera buttons
            if (_selectedImage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: _selectImage,
                    ),
                    _buildPhotoButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: _takePhoto,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}