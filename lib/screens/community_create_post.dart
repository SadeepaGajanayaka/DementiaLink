import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CommunityCreatePostScreen extends StatefulWidget {
  const CommunityCreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CommunityCreatePostScreen> createState() => _CommunityCreatePostScreenState();
}

class _CommunityCreatePostScreenState extends State<CommunityCreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;

  // Sample images for selected gallery
  final List<String> _galleryImages = [
    'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22',
    'https://images.unsplash.com/photo-1556911220-bda9f7b2b187',
    'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4',
    'https://images.unsplash.com/photo-1507120878965-54b2d3939100',
    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2',
    'https://images.unsplash.com/photo-1541963463532-d68292c34b19',
    'https://images.unsplash.com/photo-1488751045188-3c55bbf9a3fa',
    'https://images.unsplash.com/photo-1513759565286-20e9c5fad06b',
    'https://images.unsplash.com/photo-1524250502761-1ac6f2e30d43',
    'https://images.unsplash.com/photo-1516585427167-9f4af9627e6c',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF503663)),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF503663)),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPost() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 2));

      // Here you would typically upload the image and caption to your backend

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen or feed
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF503663)),
        title: const Text(
          'New Post',
          style: TextStyle(
            color: Color(0xFF503663),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _createPost,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF503663),
            ),
            child: _isUploading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Color(0xFF503663),
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Share',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview or selection
          if (_selectedImage == null)
            GestureDetector(
              onTap: _showImageSourceOptions,
              child: Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 60,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to select an image',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Stack(
              children: [
                Image.file(
                  _selectedImage!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

          // Caption input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Write a caption...',
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ),

          const Divider(),

          // Hashtags and suggestions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.tag, color: Color(0xFF503663)),
                const SizedBox(width: 8),
                const Text(
                  'Add hashtags:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildHashtagChip('#DementiaAwareness'),
                    _buildHashtagChip('#CaregiverSupport'),
                    _buildHashtagChip('#MemoryCare'),
                  ],
                ),
              ],
            ),
          ),

          // Gallery images
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Recent Gallery Images',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _galleryImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // For demo purposes, we'll just show a message
                          // In a real app, you'd select this image
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('To select gallery images, use the camera button'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Image.network(
                          _galleryImages[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF503663),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF503663),
        onPressed: _showImageSourceOptions,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildHashtagChip(String tag) {
    return GestureDetector(
      onTap: () {
        // Add hashtag to caption
        final currentText = _captionController.text;
        if (currentText.isEmpty || currentText.endsWith(' ')) {
          _captionController.text = '$currentText$tag ';
        } else {
          _captionController.text = '$currentText $tag ';
        }

        // Move cursor to end
        _captionController.selection = TextSelection.fromPosition(
          TextPosition(offset: _captionController.text.length),
        );
      },
      child: Chip(
        backgroundColor: const Color(0xFF503663).withOpacity(0.1),
        label: Text(
          tag,
          style: const TextStyle(
            color: Color(0xFF503663),
          ),
        ),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}