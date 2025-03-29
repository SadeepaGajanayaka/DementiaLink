import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'lib/screens/login_screen.dart';

class LogoutService {
  static final AuthService _authService = AuthService();

  // Method to handle logout process with loading indicator
  static Future<void> logout(BuildContext context) async {
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

  // Method to show a confirmation dialog before logout
  static void confirmLogout(BuildContext context) {
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
                logout(context); // Perform logout
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
}

// Example of how to implement this in your custom_drawer.dart file:
// Replace the existing logout button in CustomDrawer with this:

/*
Padding(
  padding: const EdgeInsets.all(20.0),
  child: ElevatedButton(
    onPressed: () {
      // Call the confirm logout method
      LogoutService.confirmLogout(context);
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
*/