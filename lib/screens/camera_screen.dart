import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'community_feed_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isProcessing = false;
  String _selectedMode = 'NORMAL';
  final List<String> _modes = ['TYPE', 'LIVE', 'NORMAL', 'BOOMERANG', 'SUPERZOOM'];
  bool _isFlashOn = false;
  bool _isRearCamera = true;

  Future<void> _takePicture() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Take picture using image_picker
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: _isRearCamera ? CameraDevice.rear : CameraDevice.front,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo captured successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo selected from gallery')),
      );
    }
  }

  void _toggleCamera() {
    setState(() {
      _isRearCamera = !_isRearCamera;
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    // Note: Flash control would require camera plugin
    // This is just updating the UI state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mock Camera Preview (a colored background instead of real camera feed)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _imageFile != null
                ? Image.file(_imageFile!, fit: BoxFit.cover)
                : Container(
              color: Colors.black87,
              child: const Center(
                child: Text(
                  'Camera Preview',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ),
            ),
          ),

          // We removed the duplicate status bar elements (time, battery, wifi, signal)
          // since they're already shown in the phone's system status bar

          // Close Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.2),
                  ),
                  padding: const EdgeInsets.all(4.0),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

          // Camera Controls (Bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              color: const Color(0xFF503663), // Purple background for bottom bar
              child: Column(
                children: [
                  // Camera Actions Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Gallery Button
                        GestureDetector(
                          onTap: _pickFromGallery,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Flash Button
                        GestureDetector(
                          onTap: _toggleFlash,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isFlashOn ? Colors.white.withOpacity(0.3) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Capture Button
                        GestureDetector(
                          onTap: _isProcessing ? null : _takePicture,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _isProcessing ? Colors.grey : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                          ),
                        ),

                        // Flip Camera Button
                        GestureDetector(
                          onTap: _toggleCamera,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                            child: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Effects Button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: const Icon(
                            Icons.emoji_emotions,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mode Selection Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _modes.map((mode) {
                        final isSelected = mode == _selectedMode;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMode = mode;
                              });
                            },
                            child: Text(
                              mode,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}