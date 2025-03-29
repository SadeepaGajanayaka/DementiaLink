import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Color(0xFF503663),
      ),
      child: Column(
        children: [
          const SizedBox(height: 100),
          // Profile Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF503663),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Anne',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Menu Items
          _buildMenuItem(Icons.person, 'User Account', () {
            // Navigate to user account screen
            Navigator.pop(context); // Close drawer first
            // Then navigate to the appropriate screen
          }),
          _buildMenuItem(Icons.privacy_tip, 'Privacy and policy', () {
            Navigator.pop(context);
            // Navigate to privacy policy screen
          }),
          _buildMenuItem(Icons.feedback, 'Feedback', () {
            Navigator.pop(context);
            // Navigate to feedback screen
          }),
          _buildMenuItem(Icons.info, 'About Us', () {
            Navigator.pop(context);
            // Navigate to about us screen
          }),
          const Spacer(),
          _buildMenuItem(Icons.settings, 'Settings', () {
            Navigator.pop(context);
            // Navigate to settings screen
          }),
          const SizedBox(height: 20),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close drawer first
                _confirmLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFF503663),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  // Method to show a confirmation dialog before logout
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _logout(context); // Perform logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF503663),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Method to handle logout process with loading indicator
  Future<void> _logout(BuildContext context) async {
    final AuthService _authService = AuthService();

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF503663),
                  ),
                  SizedBox(height: 16),
                  Text('Logging out...'),
                ],
              ),
            ),
          );
        },
      );

      // Perform logout operations
      await _authService.signOut();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Navigate to login screen and clear all previous routes
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
              (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      // Close loading dialog in case of error
      if (context.mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}