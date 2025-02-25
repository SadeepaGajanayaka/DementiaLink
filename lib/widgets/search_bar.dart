import 'package:flutter/material.dart';

class MySearchBar extends StatelessWidget { // This name should match what you used in home_screen.dart
  const MySearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: const [
          SizedBox(width: 16.0),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ......',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.search, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}