// // import 'package:flutter/foundation.dart';
// // import 'package:speech_to_text/speech_to_text.dart' as stt;
// // import 'package:flutter_tts/flutter_tts.dart';
// // import 'package:permission_handler/permission_handler.dart';
// //
// // class SpeechService {
// //   static final SpeechService _instance = SpeechService._internal();
// //
// //   factory SpeechService() => _instance;
// //
// //   SpeechService._internal();
// //
// //   stt.SpeechToText? _speech;
// //   FlutterTts? _flutterTts;
// //   bool _isListening = false;
// //   String _recognizedText = '';
// //
// //   Future<void> initialize() async {
// //     // Initialize speech to text
// //     _speech = stt.SpeechToText();
// //     await _speech?.initialize(
// //       onStatus: (status) {
// //         debugPrint('Speech status: $status');
// //         if (status == 'done') {
// //           _isListening = false;
// //         }
// //       },
// //       onError: (error) => debugPrint('Speech error: $error'),
// //     );
// //
// //     // Initialize text to speech
// //     _flutterTts = FlutterTts();
// //     await _flutterTts?.setLanguage('en-US');
// //     await _flutterTts?.setSpeechRate(0.5);
// //     await _flutterTts?.setVolume(1.0);
// //     await _flutterTts?.setPitch(1.0);
// //   }
// //
// //   // Check and request microphone permission
// //   Future<bool> checkPermission() async {
// //     var status = await Permission.microphone.status;
// //     if (status.isDenied) {
// //       status = await Permission.microphone.request();
// //     }
// //     return status.isGranted;
// //   }
// //
// //   Future<bool> startListening({
// //     required Function(String) onResult,
// //   }) async {
// //     if (!await checkPermission()) {
// //       speak("Microphone permission is required for voice search.");
// //       return false;
// //     }
// //
// //     if (_speech == null) {
// //       await initialize();
// //     }
// //
// //     _recognizedText = '';
// //
// //     if (!_isListening && _speech != null) {
// //       _isListening = await _speech!.listen(
// //         onResult: (result) {
// //           _recognizedText = result.recognizedWords;
// //           onResult(_recognizedText);
// //         },
// //         listenFor: const Duration(seconds: 10),
// //         pauseFor: const Duration(seconds: 5),
// //         partialResults: true,
// //         cancelOnError: true,
// //         listenMode: stt.ListenMode.confirmation,
// //       );
// //       return _isListening;
// //     }
// //     return false;
// //   }
// //
// //   Future<void> stopListening() async {
// //     if (_isListening && _speech != null) {
// //       _isListening = false;
// //       await _speech!.stop();
// //     }
// //   }
// //
// //   Future<void> speak(String text) async {
// //     if (_flutterTts != null) {
// //       await _flutterTts!.speak(text);
// //     }
// //   }
// //
// //   bool get isListening => _isListening;
// // }
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter_speech/flutter_speech.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class SpeechService {
//   static final SpeechService _instance = SpeechService._internal();
//
//   factory SpeechService() => _instance;
//
//   SpeechService._internal();
//
//   SpeechRecognition? _speech;
//   FlutterTts? _flutterTts;
//   bool _isListening = false;
//   String _recognizedText = '';
//
//   Future<void> initialize() async {
//     // Initialize speech recognition
//     _speech = SpeechRecognition();
//     await _speech?.activate();
//
//     // Configure speech recognition
//     _speech?.setRecognitionStartedHandler(() {
//       debugPrint('Speech recognition started');
//       _isListening = true;
//     });
//
//     _speech?.setRecognitionResultHandler((String text) {
//       debugPrint('Speech recognition result: $text');
//       _recognizedText = text;
//     });
//
//     _speech?.setRecognitionCompleteHandler(() {
//       debugPrint('Speech recognition completed');
//       _isListening = false;
//     });
//
//     // Initialize text to speech
//     _flutterTts = FlutterTts();
//     await _flutterTts?.setLanguage('en-US');
//     await _flutterTts?.setSpeechRate(0.5);
//     await _flutterTts?.setVolume(1.0);
//     await _flutterTts?.setPitch(1.0);
//   }
//
//   // Check and request microphone permission
//   Future<bool> checkPermission() async {
//     var status = await Permission.microphone.status;
//     if (status.isDenied) {
//       status = await Permission.microphone.request();
//     }
//     return status.isGranted;
//   }
//
//   Future<bool> startListening({
//     required Function(String) onResult,
//   }) async {
//     if (!await checkPermission()) {
//       speak("Microphone permission is required for voice search.");
//       return false;
//     }
//
//     if (_speech == null) {
//       await initialize();
//     }
//
//     _recognizedText = '';
//
//     try {
//       await _speech?.listen();
//       _isListening = true;
//
//       // Wait for recognition result
//       await Future.delayed(Duration(seconds: 5));
//
//       // Stop listening and return result
//       await _speech?.stop();
//
//       if (_recognizedText.isNotEmpty) {
//         onResult(_recognizedText);
//       }
//
//       return true;
//     } catch (e) {
//       debugPrint('Error during speech recognition: $e');
//       return false;
//     }
//   }
//
//   Future<void> stopListening() async {
//     if (_isListening && _speech != null) {
//       await _speech?.stop();
//       _isListening = false;
//     }
//   }
//
//   Future<void> speak(String text) async {
//     if (_flutterTts != null) {
//       await _flutterTts!.speak(text);
//     }
//   }
//
//   bool get isListening => _isListening;
// }

import 'package:flutter/foundation.dart';
import 'package:flutter_speech/flutter_speech.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();

  factory SpeechService() => _instance;

  SpeechService._internal();

  SpeechRecognition? _speech;
  FlutterTts? _flutterTts;
  bool _isListening = false;
  String _recognizedText = '';

  Future<void> initialize() async {
    // Initialize speech recognition
    _speech = SpeechRecognition();

    // Activate speech recognition with language
    await _speech?.activate("en_US");

    // Configure speech recognition handlers
    _speech?.setRecognitionStartedHandler(() {
      debugPrint('Speech recognition started');
      _isListening = true;
    });

    _speech?.setRecognitionResultHandler((text) {
      debugPrint('Speech recognition result: $text');
      _recognizedText = text;
    });

    _speech?.setRecognitionCompleteHandler((result) {
      debugPrint('Speech recognition completed: $result');
      _isListening = false;
    });

    // Initialize text to speech
    _flutterTts = FlutterTts();
    await _flutterTts?.setLanguage('en-US');
    await _flutterTts?.setSpeechRate(0.5);
    await _flutterTts?.setVolume(1.0);
    await _flutterTts?.setPitch(1.0);
  }

  // Check and request microphone permission
  Future<bool> checkPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<bool> startListening({
    required Function(String) onResult,
  }) async {
    if (!await checkPermission()) {
      speak("Microphone permission is required for voice search.");
      return false;
    }

    if (_speech == null) {
      await initialize();
    }

    _recognizedText = '';

    try {
      // Start listening
      _speech?.listen();
      _isListening = true;

      // Wait for recognition result
      await Future.delayed(Duration(seconds: 5));

      // Stop listening
      _speech?.stop();

      if (_recognizedText.isNotEmpty) {
        onResult(_recognizedText);
      }

      return true;
    } catch (e) {
      debugPrint('Error during speech recognition: $e');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening && _speech != null) {
      _speech?.stop();
      _isListening = false;
    }
  }

  Future<void> speak(String text) async {
    if (_flutterTts != null) {
      await _flutterTts!.speak(text);
    }
  }

  bool get isListening => _isListening;
}