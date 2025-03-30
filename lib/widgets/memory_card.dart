import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../models/media_type.dart';
import '../utils/video_thumbnail_util.dart';

class MemoryCard extends StatefulWidget {
  final List<Photo> photos;

  const MemoryCard({
    Key? key,
    required this.photos,
  }) : super(key: key);

  @override
  _MemoryCardState createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSlideshow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSlideshow() {
    if (widget.photos.isEmpty) return;

    // Start a timer to change photos every 3 seconds
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.photos.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width to calculate the height for a more square appearance
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate a height that's close to square but slightly shorter
    final cardHeight = screenWidth - 64; // Full width minus padding

    if (widget.photos.isEmpty) {
      return _buildEmptyMemory(cardHeight);
    }

    return Column(
      children: [
        Container(
          height: cardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.purple.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Display current photo or video thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: _buildMediaWidget(widget.photos[_currentIndex]),
                ),
              ),

              // Navigation controls
              Positioned.fill(
                child: Row(
                  children: [
                    // Left arrow for previous
                    Container(
                      width: 60,
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentIndex = (_currentIndex - 1) % widget.photos.length;
                            if (_currentIndex < 0) _currentIndex = widget.photos.length - 1;
                          });
                        },
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white.withOpacity(0.8),
                          size: 28,
                        ),
                      ),
                    ),

                    // Spacer
                    Expanded(child: Container()),

                    // Right arrow for next
                    Container(
                      width: 60,
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentIndex = (_currentIndex + 1) % widget.photos.length;
                          });
                        },
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.8),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Memory label at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Memory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Add a counter for larger collections
                      if (widget.photos.length > 1) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_currentIndex + 1}/${widget.photos.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Add button (top-right corner)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // Handle adding new photos to memories
                      // This could open your add media options
                    },
                  ),
                ),
              ),

              // Date or caption (optional)
              if (widget.photos[_currentIndex].note != null &&
                  widget.photos[_currentIndex].note!.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      widget.photos[_currentIndex].note!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build the appropriate widget for the media type
  Widget _buildMediaWidget(Photo media) {
    try {
      if (media.mediaType == MediaType.video) {
        // Use our updated VideoThumbnailUtil for videos
        return VideoThumbnailUtil.buildVideoThumbnail(
          media.path,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        // Regular image display
        return Image.file(
          File(media.path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Container(
              color: Colors.grey.shade800,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Invalid image data',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      print('Error displaying media: $e');
      return Container(
        color: Colors.grey.shade800,
        child: Center(
          child: Text(
            'Error loading media',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyMemory(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.purple.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_album,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Add photos to create memories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}