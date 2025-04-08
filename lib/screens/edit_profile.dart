import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialUsername;
  final String initialFullName;
  final String initialBio;
  final String? initialPhotoUrl;

  const EditProfileScreen({
    Key? key,
    required this.initialUsername,
    required this.initialFullName,
    required this.initialBio,
    this.initialPhotoUrl,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _websiteController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _gender;

  File? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFullName);
    _usernameController = TextEditingController(text: widget.initialUsername);
    _websiteController = TextEditingController();
    _bioController = TextEditingController(text: widget.initialBio);
    _emailController = TextEditingController(text: 'jacob.west@gmail.com');
    _phoneController = TextEditingController(text: '+1 202 555 0147');
    _gender = 'Male';

    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final userData = await _authService.getUserData(userId);
        if (mounted) {
          setState(() {
            // In a real app, you would set the data from userData
            // For now, we're using the passed initial values
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _profileImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would save the data to your backend
      await Future.delayed(const Duration(seconds: 1)); // Simulate network request

      // Create a map of the updated profile data
      final updatedProfileData = {
        'fullName': _nameController.text,
        'username': _usernameController.text,
        'website': _websiteController.text,
        'bio': _bioController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'gender': _gender,
        'profileImage': _profileImage,
      };

      if (mounted) {
        // Return updated data to the previous screen
        Navigator.pop(context, updatedProfileData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        leadingWidth: 70,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Photo
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _selectImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : widget.initialPhotoUrl != null
                          ? NetworkImage(widget.initialPhotoUrl!)
                          : const AssetImage('lib/assets/profile_pic.jpg') as ImageProvider,
                      onBackgroundImageError: (_, __) {},
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _selectImage,
                    child: const Text(
                      'Change Profile Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Fields
            _buildProfileField('Name', _nameController),
            _buildProfileField('Username', _usernameController),
            _buildProfileField('Website', _websiteController),
            _buildProfileField('Bio', _bioController, maxLines: 4),

            // Section divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Switch to Professional Account',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Private Information Header
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Private Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Private Information Fields
            _buildProfileField('Email', _emailController),
            _buildProfileField('Phone', _phoneController),
            _buildGenderSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: maxLines,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 80,
            child: Text(
              'Gender',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _gender,
                dropdownColor: const Color(0xFF503663),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                items: ['Male', 'Female', 'Prefer not to say']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _gender = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}