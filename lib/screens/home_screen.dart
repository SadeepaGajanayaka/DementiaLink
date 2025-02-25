import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/search_bar.dart'; // Make sure this path is correct

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A), // Deep purple background
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button, app name and profile logo
            const AppTopBar(),

            // Search bar - Make sure this matches the class name in your search_bar.dart file
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: MySearchBar(), // Rename this to match your actual class name
            ),

            // Placeholder for the rest of the UI
            Expanded(
              child: Center(
                child: Text(
                  'Additional components will be added next',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}