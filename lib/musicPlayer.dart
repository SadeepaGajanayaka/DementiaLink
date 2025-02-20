import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF503663),
        scaffoldBackgroundColor: const Color(0xFF503663),
      ),
      home: const PlaylistScreen(),
    );
  }
}
class Song {
  final String title;
  final String artist;
  final String imagePath;
  final String audioPath;

  Song({
    required this.title,
    required this.artist,
    required this.imagePath,
    required this.audioPath,
  });
}

final List<Song> songs = [
  Song(
    title: 'Dementia Track-1',
    artist: 'Dementia_Link',
    imagePath: 'assets/images/i1.png',
    audioPath: 'assets/audio/track1.mp3',
  ),
  Song(
    title: 'Dementia Track-2',
    artist: 'Dementia_Link',
    imagePath: 'assets/images/i2.png',
    audioPath: 'assets/audio/track2.mp3',
  ),
  Song(
    title: 'Dementia Track-3',
    artist: 'Dementia_Link',
    imagePath: 'assets/images/i3.png',
    audioPath: 'assets/audio/track3.mp3',
  ),
  Song(
    title: 'Dementia Track-4',
    artist: 'Dementia_Link',
    imagePath: 'assets/images/i4.png',
    audioPath: 'assets/audio/track4.mp3',
  ),
  Song(
    title: 'Dementia special Track',
    artist: 'Meditational StateHealing Music',
    imagePath: 'assets/images/i5.jpg',
    audioPath: 'assets/audio/track5.mp3',
  ),
];
class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  return _buildSongTile(context, songs[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
