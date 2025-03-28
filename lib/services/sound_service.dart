// lib/services/sound_service.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  static SoundService get instance => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  late AudioSource _alarmSound;
  late AudioSource _notificationSound;

  SoundService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up sounds sources
      _alarmSound = _getAudioSource('task_alarm');
      _notificationSound = _getAudioSource('notification_sound');

      _isInitialized = true;
      print('SoundService: Initialized successfully');
    } catch (e) {
      print('SoundService: Failed to initialize - $e');
    }
  }

  AudioSource _getAudioSource(String soundName) {
    if (Platform.isAndroid) {
      // For Android, we use the raw resource
      return AudioSource.uri(Uri.parse('asset:///android/app/src/main/res/raw/$soundName.mp3'));
    } else if (Platform.isIOS) {
      // For iOS, we use the bundled resource
      return AudioSource.uri(Uri.parse('asset:///$soundName.aiff'));
    } else {
      // Fallback
      return AudioSource.asset('assets/sounds/$soundName.mp3');
    }
  }

  Future<void> playTaskAlarmSound() async {
    if (!_isInitialized) await initialize();

    try {
      await _audioPlayer.setAudioSource(_alarmSound);
      await _audioPlayer.play();
    } catch (e) {
      print('SoundService: Failed to play alarm sound - $e');
    }
  }

  Future<void> playNotificationSound() async {
    if (!_isInitialized) await initialize();

    try {
      await _audioPlayer.setAudioSource(_notificationSound);
      await _audioPlayer.play();
    } catch (e) {
      print('SoundService: Failed to play notification sound - $e');
    }
  }

  Future<void> stopSound() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.stop();
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}