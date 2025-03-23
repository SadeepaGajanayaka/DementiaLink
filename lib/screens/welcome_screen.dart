import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'assist_me.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'assist_loved.dart';

class WelcomeScreen extends StatefulWidget {
  final String userName;

  const WelcomeScreen({
    super.key,
    required this.userName,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _profileImage = File(pickedImage.path);
        });
        
      }
    } catch (e) {
      // Handle errors, such as when a user denies camera permissions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF503663),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF77588D),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF77588D),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF77588D), 
              Color(0xFF503663), 
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // App Logo and Sign Out row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), 
                      Image.asset(
                        'lib/assets/brain_logo.png',
                        width: 60,
                        height: 60,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () async {
                          await _authService.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DementiaLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // White Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        // Profile Image with Edit Option
                        Stack(
                          children: [
                            
                            GestureDetector(
                              onTap: _showImageSourceOptions,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF77588D).withOpacity(0.2),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: _profileImage != null
                                    ? Image.file(
                                        _profileImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'lib/assets/profile_setup.png',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF77588D),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _showImageSourceOptions,
                                  constraints: const BoxConstraints(
                                    minHeight: 40,
                                    minWidth: 40,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                       
                        Text(
                          'Welcome ${widget.userName}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF503663),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Support Question
                        const Text(
                          'Who would you like DementiaLink to help support?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Assist Me Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AssistMe(
                                    userName: widget.userName,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF77588D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Assist Me',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Assist a Loved One Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AssistLoved(
                                    userName: widget.userName,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF77588D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Assist a Loved One',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
