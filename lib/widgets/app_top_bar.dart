import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              // Handle back navigation
              Navigator.maybePop(context);
            },
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.0,
            ),
          ),

          const SizedBox(width: 16.0),

          // App Title with Brain Icon
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Story/ Memory Journal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),

          // User Profile Logo
          GestureDetector(
            onTap: () {
              // Handle profile tap - e.g., open profile page
              print('Profile icon tapped');
            },
            child: const CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16.0,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}