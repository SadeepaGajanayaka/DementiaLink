import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

class VideoThumbnailUtil {
  // Cache to store initialized video controllers
  static final Map<String, VideoPlayerController> _controllerCache = {};

  // Build a video thumbnail widget
  static Widget buildVideoThumbnail(String videoPath, {double? width, double? height}) {
    return FutureBuilder<VideoPlayerController>(
      future: _getVideoController(videoPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.value.isInitialized) {
          // Video controller is initialized, show the first frame
          return Stack(
            children: [
              // The video's first frame serves as a thumbnail
              SizedBox(
                width: width,
                height: height,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: snapshot.data!.value.size.width,
                    height: snapshot.data!.value.size.height,
                    child: VideoPlayer(snapshot.data!),
                  ),
                ),
              ),
              // Add a small video icon overlay to indicate it's a video
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          );
        } else {
          // Show loading or placeholder while initializing
          return _buildPlaceholder(width: width, height: height);
        }
      },
    );
  }

  // Helper method to get or create a video controller
  static Future<VideoPlayerController> _getVideoController(String videoPath) async {
    // Check if controller is already in cache
    if (_controllerCache.containsKey(videoPath) &&
        _controllerCache[videoPath]!.value.isInitialized) {
      return _controllerCache[videoPath]!;
    }

    // Verify file exists
    final file = File(videoPath);
    if (!await file.exists()) {
      throw Exception('Video file not found: $videoPath');
    }

    // Create and initialize a new controller
    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      // Pause immediately after initialization to ensure we just get the first frame
      await controller.seekTo(Duration.zero);
      controller.setVolume(0.0);

      // Store in cache
      _controllerCache[videoPath] = controller;
      return controller;
    } catch (e) {
      print('Error initializing video controller for $videoPath: $e');
      throw e;
    }
  }

  // Fallback placeholder when thumbnail can't be generated
  static Widget _buildPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  // Clean up resources
  static void dispose() {
    for (var controller in _controllerCache.values) {
      controller.dispose();
    }
    _controllerCache.clear();
  }

  // Dispose a specific controller
  static void disposeController(String videoPath) {
    if (_controllerCache.containsKey(videoPath)) {
      _controllerCache[videoPath]?.dispose();
      _controllerCache.remove(videoPath);
    }
  }
}