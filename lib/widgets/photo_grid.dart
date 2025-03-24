import 'dart:io';
import 'package:flutter/material.dart';
import '../models/album_model.dart';

class PhotoGrid extends StatelessWidget {
  final List<Album> albums;

  const PhotoGrid({
    Key? key,
    required this.albums,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder images for empty albums
    final List<Widget> items = [];

    // Add album previews
    for (var album in albums) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              // Navigate to album details
              // You would implement navigation to the specific album here
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 180,
                height: 200,
                color: Colors.purple.shade300,
                child: album.photos.isNotEmpty
                    ? Image.file(
                  File(album.photos.first.path),
                  fit: BoxFit.cover,
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        album.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: items,
    );
  }
}
