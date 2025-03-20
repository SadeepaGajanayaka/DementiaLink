import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/storage_provider.dart';
import '../models/photo_model.dart';
import '../models/media_type.dart';
import '../utils/video_thumbnail_util.dart';
import 'photo_detail_screen.dart';

class DeletedScreen extends StatefulWidget {
  @override
  _DeletedScreenState createState() => _DeletedScreenState();
}

class _DeletedScreenState extends State<DeletedScreen> {
  bool _isSelecting = false;
  List<String> _selectedPhotoIds = [];
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storageProvider = Provider.of<StorageProvider>(context);

    if (!storageProvider.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return Column(
      children: [
        // Header with search and selection toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deleted Items',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Search icon
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearchVisible = !_isSearchVisible;
                        if (!_isSearchVisible) {
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  // Select icon
                  IconButton(
                    icon: Icon(
                      _isSelecting ? Icons.close : Icons.checklist,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSelecting = !_isSelecting;
                        if (!_isSelecting) {
                          _selectedPhotoIds.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_isSearchVisible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search in deleted items...',
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearchVisible = false;
                    });
                  },
                ),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) {
                // Filter results as user types
                setState(() {});
              },
            ),
          ),

        // Main content
        Expanded(
          child: FutureBuilder<List<Photo>>(
            future: storageProvider.getDeletedPhotos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

              final deletedPhotos = snapshot.data ?? [];

              // Apply search filter if search is active
              final displayPhotos = _isSearchVisible && _searchController.text.isNotEmpty
                  ? deletedPhotos.where((photo) =>
              (photo.note?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false))
                  .toList()
                  : deletedPhotos;

              if (displayPhotos.isEmpty) {
                return _buildEmptyState();
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Grid of deleted photos
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: displayPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = displayPhotos[index];
                          final isSelected = _selectedPhotoIds.contains(photo.id);

                          return GestureDetector(
                            onTap: () {
                              if (_isSelecting) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPhotoIds.remove(photo.id);
                                  } else {
                                    _selectedPhotoIds.add(photo.id);
                                  }
                                });
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PhotoDetailScreen(
                                      photo: photo,
                                      photos: displayPhotos,
                                      currentIndex: index,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Photo preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: photo.mediaType == MediaType.video
                                      ? VideoThumbnailUtil.buildVideoThumbnail(
                                    photo.path,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                      : Image.file(
                                    File(photo.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade800,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Selection indicator
                                if (_isSelecting)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.deepPurple : Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          isSelected ? Icons.check : Icons.circle_outlined,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Days remaining indicator
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${photo.getDaysUntilPermanentDeletion()} days',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                // Show media type indicator
                                if (photo.mediaType == MediaType.video)
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.videocam,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom action bar when selecting items
                    if (_isSelecting && _selectedPhotoIds.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              '${_selectedPhotoIds.length} selected',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _recoverSelectedItems(context),
                              icon: Icon(Icons.restore),
                              label: Text('Recover'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _confirmPermanentDeletion(context),
                              icon: Icon(Icons.delete_forever),
                              label: Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bottom info text about deletion policy
                    if (!_isSelecting || _selectedPhotoIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Photos and Videos show the days remaining before deletion. After that time, items will be permanently deleted. This may take up to 40 days.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Deleted photos will be kept here for 30 days before being permanently removed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _recoverSelectedItems(BuildContext context) async {
    if (_selectedPhotoIds.isEmpty) return;

    final storageProvider = Provider.of<StorageProvider>(context, listen: false);

    try {
      await storageProvider.recoverDeletedPhotos(_selectedPhotoIds);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedPhotoIds.length} items recovered successfully')),
      );

      setState(() {
        _selectedPhotoIds.clear();
        _isSelecting = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recovering items: ${e.toString()}')),
      );
    }
  }

  void _confirmPermanentDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete Items'),
        content: Text(
          'Are you sure you want to permanently delete ${_selectedPhotoIds.length} items? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permanentlyDeleteSelected(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _permanentlyDeleteSelected(BuildContext context) async {
    if (_selectedPhotoIds.isEmpty) return;

    final storageProvider = Provider.of<StorageProvider>(context, listen: false);

    try {
      await storageProvider.permanentlyDeletePhotos(_selectedPhotoIds);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedPhotoIds.length} items permanently deleted')),
      );

      setState(() {
        _selectedPhotoIds.clear();
        _isSelecting = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting items: ${e.toString()}')),
      );
    }
  }
}