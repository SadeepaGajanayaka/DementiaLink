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
    imagePath: 'lib/assets/images/i1.png',
    audioPath: 'lib/assets/audio/track1.mp3',
  ),
  Song(
    title: 'Dementia Track-2',
    artist: 'Dementia_Link',
    imagePath: 'lib/assets/images/i2.png',
    audioPath: 'lib/assets/audio/track2.mp3',
  ),
  Song(
    title: 'Dementia Track-3',
    artist: 'Dementia_Link',
    imagePath: 'lib/assets/images/i3.png',
    audioPath: 'lib/assets/audio/track3.mp3',
  ),
  Song(
    title: 'Dementia Track-4',
    artist: 'Dementia_Link',
    imagePath: 'lib/assets/images/i4.png',
    audioPath: 'lib/assets/audio/track4.mp3',
  ),
  Song(
    title: 'Dementia special Track',
    artist: 'Meditational StateHealing Music',
    imagePath: 'lib/assets/images/i5.jpg',
    audioPath: 'lib/assets/audio/track5.mp3',
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {},
          ),
          const Expanded(
            child: Text(
              'PLAYLIST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            // margin: const EdgeInsets.only(top: 50),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/assets/images/brain_icon.png', // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, Song song, int index) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          song.imagePath,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        song.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(initialSongIndex: index),
          ),
        );
      },
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final int initialSongIndex;

  const PlayerScreen({
    Key? key,
    required this.initialSongIndex,
  }) : super(key: key);

  @override
  PlayerScreenState createState() => PlayerScreenState();
}

class PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  late int _currentIndex;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialSongIndex;
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() async {
    // Duration state
    _audioPlayer.positionStream.listen((pos) {
      setState(() => _position = pos);
    });
    _audioPlayer.durationStream.listen((dur) {
      setState(() => _duration = dur ?? Duration.zero);
    });
    // Playing state
    _audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
    // Load the initial song
    await _loadCurrentSong();
  }

  Future<void> _loadCurrentSong() async {
    try {
      await _audioPlayer.setAsset(songs[_currentIndex].audioPath);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _playNext() async {
    if (_currentIndex < songs.length - 1) {
      setState(() => _currentIndex++);
      await _loadCurrentSong();
    }
  }

  void _playPrevious() async {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      await _loadCurrentSong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A2B5C),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildAlbumArt(),
            const Spacer(),
            _buildSongInfo(),
            _buildProgressBar(),
            _buildControls(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Now Playing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                /*  fontWeight: FontWeight.w500,*/
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/brain_icon.png', // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      margin: const EdgeInsets.only(
        top: 65, // Increased top margin to move image down
        left: 24,
        right: 24,
        bottom: 24,
      ),
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          songs[_currentIndex].imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            songs[_currentIndex].title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            songs[_currentIndex].artist,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.purple,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
          ),
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble(),
            onChanged: (value) {
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
            onPressed: _playPrevious,
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
              onPressed: _playPause,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
            onPressed: _playNext,
          ),
        ],
      ),
    );
  }
}