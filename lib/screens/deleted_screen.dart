import 'package:flutter/material.dart';

class DeletedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // In a real app, you might implement a "trash" system where photos are marked as deleted
    // For now, this is just a placeholder screen

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deleted Items',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.white.withOpacity(0.5),
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Recycle Bin is Empty',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Deleted photos will be kept here for 30 days before being permanently removed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
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