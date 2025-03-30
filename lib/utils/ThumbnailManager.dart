import 'package:flutter/material.dart';
import '../utils/video_thumbnail_util.dart';

// This class helps manage the lifecycle of video thumbnails
class ThumbnailManager extends StatefulWidget {
  final Widget child;

  const ThumbnailManager({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ThumbnailManager> createState() => _ThumbnailManagerState();
}

class _ThumbnailManagerState extends State<ThumbnailManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up all video controllers when the app is closed
    VideoThumbnailUtil.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Free resources when app goes to background
      VideoThumbnailUtil.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}