import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;

  const CustomVideoPlayer({
    Key? key,
    required this.videoPath,
    this.autoPlay = false,
  }) : super(key: key);

  @override
  _CustomVideoPlayerState createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: widget.autoPlay,
      looping: false,
      placeholder: Center(
        child: CircularProgressIndicator(),
      ),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'Error loading video: $errorMessage',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? Chewie(controller: _chewieController!)
        : Center(
      child: CircularProgressIndicator(),
    );
  }
}