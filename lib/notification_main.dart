import 'dart:async';

import 'package:dementialink/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show immutable;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName:".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
      ProviderScope(
        child: const MyApp(),
      )
  );
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: StreamBuilder(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if(snapshot.data == null){
            return const LoginScreen();

          }
          return const HomeScreen();

        },
      ),
    );
  }
}
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language toggle button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    ref.read(languageProvider.notifier).toggleLanguage();
                  },
                  child: Text(
                    currentLanguage == AppLanguage.english ? 'සිංහල' : 'English',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        'assets/icons/brain.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const TranslatedText(
                      textKey: 'app_title',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const TranslatedText(
                      textKey: 'welcome_description',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(authProvider).signInWithGoogle();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/googlelogo.png',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 12),
                          const TranslatedText(
                            textKey: 'sign_in_with_google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _messageController;
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  bool isSpeaking = false;
  String? lastProcessedMessageId;
  bool isVoiceMode = false;
  String recognizedText = '';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _initializeVoiceAssistant();
  }

  @override
  void dispose() {
    _messageController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeVoiceAssistant() async {
    try {
      final currentLanguage = ref.read(languageProvider);
      final languageCode = currentLanguage == AppLanguage.english ? "en-US" : "si-LK";

      bool? isLanguageAvailable = await flutterTts.isLanguageAvailable(languageCode);
      debugPrint("Is language available: $isLanguageAvailable");

      await flutterTts.setLanguage(languageCode);
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);

      flutterTts.setStartHandler(() {
        debugPrint("TTS STARTED");
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => isSpeaking = true);
          });
        }
      });

      flutterTts.setCompletionHandler(() {
        debugPrint("TTS COMPLETED");
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => isSpeaking = false);
          });
        }
      });

      flutterTts.setErrorHandler((msg) {
        debugPrint("TTS ERROR: $msg");
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => isSpeaking = false);
          });
        }
      });

      flutterTts.setProgressHandler((text, start, end, word) {
        debugPrint("TTS PROGRESS: $text, $start, $end, $word");
      });

      await speech.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
    } catch (e) {
      debugPrint('Voice initialization error: $e');
    }
  }

  // Future<void> _startListening() async {
  //   if (!isListening) {
  //     if (isSpeaking) {
  //       await flutterTts.stop();
  //       setState(() {
  //         isSpeaking = false;
  //       });
  //     }
  //
  //     setState(() {
  //       isListening = true;
  //       isVoiceMode = true;
  //       recognizedText = '';
  //     });
  //
  //     try {
  //       final currentLanguage = ref.read(languageProvider);
  //       final localeId = currentLanguage == AppLanguage.english ? "en_US" : "si_LK";
  //
  //       await speech.listen(
  //         onResult: (result) {
  //           setState(() {
  //             recognizedText = result.recognizedWords;
  //             _messageController.text = recognizedText;
  //
  //             if (result.finalResult && recognizedText.trim().isNotEmpty) {
  //               isListening = false;
  //               _sendVoiceMessage();
  //             }
  //           });
  //         },
  //         listenFor: const Duration(seconds: 45), // Increased time for Sinhala
  //         pauseFor: const Duration(seconds: 5),  // Increased pause for Sinhala
  //         partialResults: true,
  //         listenMode: stt.ListenMode.confirmation,
  //         cancelOnError: true,
  //         localeId: localeId,
  //         // soundLevel: currentLanguage == AppLanguage.sinhala ? 0.3 : 0.5, // Adjusted for Sinhala
  //       );
  //     } catch (e) {
  //       debugPrint('Speech listen error: $e');
  //       setState(() => isListening = false);
  //     }
  //   }
  // }
  // Future<void> _startListening() async {
  //   if (!isListening) {
  //     if (isSpeaking) {
  //       await flutterTts.stop();
  //       setState(() {
  //         isSpeaking = false;
  //       });
  //     }
  //
  //     setState(() {
  //       isListening = true;
  //       isVoiceMode = true;
  //       recognizedText = '';
  //     });
  //
  //     try {
  //       final currentLanguage = ref.read(languageProvider);
  //       final localeId = currentLanguage == AppLanguage.english ? "en_US" : "si_LK";
  //
  //       await speech.listen(
  //         onResult: (result) {
  //           setState(() {
  //             recognizedText = result.recognizedWords;
  //             _messageController.text = recognizedText;
  //
  //             if (result.finalResult && recognizedText.trim().isNotEmpty) {
  //               isListening = false;
  //               _sendVoiceMessage();
  //             }
  //           });
  //         },
  //         listenFor: const Duration(minutes: 2), // Increased to 2 minutes
  //         pauseFor: const Duration(seconds: 3),  // Reduced pause threshold
  //         partialResults: true,
  //         listenMode: stt.ListenMode.dictation, // Changed to dictation mode
  //         cancelOnError: false, // Don't cancel on error
  //         localeId: localeId,
  //         soundLevel: currentLanguage == AppLanguage.english ? 0.5 : 0.2, // More sensitive for Sinhala
  //       );
  //
  //       // Additional settings for Sinhala
  //       if (currentLanguage == AppLanguage.sinhala) {
  //         await speech.setRecognitionParameters(
  //             androidParams: {
  //               'speech_timeout': '0', // No timeout
  //               'partial_results_stability': '0.3', // More stable partial results
  //               'maximum_speech_input_length': '120000', // 2 minutes in milliseconds
  //             },
  //             iosParams: {
  //               'deviceLanguage': 'si-LK',
  //               'requiresOnDeviceRecognition': true,
  //               'allowsOnDeviceSpeechDetection': true,
  //             }
  //         );
  //       }
  //
  //     } catch (e) {
  //       debugPrint('Speech listen error: $e');
  //       setState(() => isListening = false);
  //       // Show error to user
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('Voice recognition error: ${e.toString()}'),
  //             duration: const Duration(seconds: 3),
  //           ),
  //         );
  //       }
  //     }
  //   }
  // }
  Future<void> _startListening() async {
    if (!isListening) {
      if (isSpeaking) {
        await flutterTts.stop();
        setState(() {
          isSpeaking = false;
        });
      }

      setState(() {
        isListening = true;
        isVoiceMode = true;
        recognizedText = '';
      });

      try {
        final currentLanguage = ref.read(languageProvider);
        final localeId = currentLanguage == AppLanguage.english ? "en_US" : "si_LK";

        // Configure speech recognition with available options
        await speech.listen(
          onResult: (result) {
            setState(() {
              recognizedText = result.recognizedWords;
              _messageController.text = recognizedText;

              if (result.finalResult && recognizedText.trim().isNotEmpty) {
                isListening = false;
                _sendVoiceMessage();
              }
            });
          },
          listenFor: const Duration(minutes: 2), // Increased maximum listening time
          pauseFor: const Duration(seconds: 3),  // Reduced pause threshold
          partialResults: true,
          listenMode: stt.ListenMode.dictation, // Changed to dictation mode
          cancelOnError: false, // Don't cancel on error
          localeId: localeId,
          // Using available configuration options
          onSoundLevelChange: (level) {
            // Optional: handle sound level changes
            debugPrint('Sound level: $level');
          },
        );

      } catch (e) {
        debugPrint('Speech listen error: $e');
        setState(() => isListening = false);
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice recognition error: ${e.toString()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _stopListening() async {
    if (isListening) {
      await speech.stop();
      setState(() {
        isListening = false;
        if (recognizedText.trim().isNotEmpty) {
          _messageController.text = recognizedText;
          _sendVoiceMessage();
        }
      });
    }
  }

  void _handleNewMessage(message) {
    if (!message.isMine && message.id != lastProcessedMessageId) {
      debugPrint("Processing new message for speech: ${message.message}");
      lastProcessedMessageId = message.id;
      if (isVoiceMode && !_messageController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _speakResponse(message.message);
        });
      }
    }
  }

  Future<void> _speakResponse(String text) async {
    debugPrint("Speaking response: $text");
    if (!isVoiceMode || _messageController.text.isNotEmpty) {
      debugPrint("Not in voice mode or currently typing, skipping speech");
      return;
    }

    try {
      if (isSpeaking) {
        debugPrint("Stopping ongoing speech");
        await flutterTts.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (mounted) {
        setState(() {
          debugPrint("Setting isSpeaking to true");
          isSpeaking = true;
        });
      }

      List<String> sentences = text
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();

      for (int i = 0; i < sentences.length; i++) {
        if (isListening || !mounted || !isVoiceMode) {
          debugPrint("Speaking interrupted");
          await flutterTts.stop();
          break;
        }

        String sentence = sentences[i].trim();
        // sentence = sentence.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
        sentence = sentence.replaceAll(RegExp(r'\*\*'), '');  // Add this line here
        await flutterTts.awaitSpeakCompletion(true);
        int result = await flutterTts.speak(sentence);
        debugPrint("Speak result: $result");

        await Future.delayed(const Duration(milliseconds: 100));
        await flutterTts.awaitSpeakCompletion(true);
      }
    } catch (e) {
      debugPrint('Speech error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
      }
    }
  }

  Future<void> _sendVoiceMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _messageController.clear();
      final currentLanguage = ref.read(languageProvider);

      setState(() {
        isVoiceMode = true;
        recognizedText = '';
      });

      try {
        await ref.read(chatProvider).sendTextMessage(
          apiKey: apiKey,
          textPrompt: message,
          currentLanguage: currentLanguage,
        );
      } catch (e) {
        debugPrint('Error sending voice message: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TranslatedText(
                textKey: 'send_message_error',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final message = _messageController.text;
      final currentLanguage = ref.read(languageProvider);
      _messageController.clear();

      if (isListening) {
        await _stopListening();
      }
      if (isSpeaking) {
        await flutterTts.stop();
      }

      setState(() {
        isVoiceMode = false;
        isSpeaking = false;
        lastProcessedMessageId = null;
      });

      try {
        await ref.read(chatProvider).sendTextMessage(
          apiKey: apiKey,
          textPrompt: message,
          currentLanguage: currentLanguage,
        );
      } catch (e) {
        debugPrint('Error sending text message: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TranslatedText(
                textKey: 'send_message_error',
              ),
            ),
          );
        }
      }
    }
  }

  void _handleLanguageChange() async {
    ref.read(languageProvider.notifier).toggleLanguage();
    await _initializeVoiceAssistant();
  }

  Future<void> _showClearChatDialog(BuildContext context) async {
    final currentLanguage = ref.read(languageProvider);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: TranslatedText(textKey: 'clear_chat'),
          content: TranslatedText(textKey: 'clear_confirmation'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: TranslatedText(textKey: 'cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref.read(chatProvider).clearAllMessages();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TranslatedText(textKey: 'clear_success'),
                        backgroundColor: const Color(0xFF4A2B52),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: TranslatedText(textKey: 'clear_error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: TranslatedText(textKey: 'clear'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputBar() {
    final currentLanguage = ref.watch(languageProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isListening ? _stopListening : _startListening,
            icon: Icon(
              isListening ? Icons.mic_off : Icons.mic,
              color: isListening ? Colors.red : const Color(0xFF4A2B52),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: AppTranslations.getText(context, currentLanguage, 'input_hint'),
                hintStyle: const TextStyle(color: Colors.grey),
              ),
              onSubmitted: (_) => _sendTextMessage(),
              enabled: !isListening,
            ),
          ),
          IconButton(
            onPressed: _sendTextMessage,
            icon: const Icon(
              Icons.send,
              color: Color(0xFF4A2B52),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A2B52),
        title: const TranslatedText(
          textKey: 'app_title',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Text(
              currentLanguage == AppLanguage.english ? 'සිං' : 'EN',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _handleLanguageChange,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () => _showClearChatDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ref.read(authProvider).signout();
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: MessagesList(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                      onNewMessage: _handleNewMessage,
                      isVoiceMode: isVoiceMode,
                    ),
                  ),
                  _buildInputBar(),
                ],
              ),
            ),
            if (isListening)
              VoiceStatusOverlay(
                message: AppTranslations.getText(context, currentLanguage, 'listening'),
                backgroundColor: Colors.blue.withOpacity(0.9),
                icon: Icons.mic,
                recognizedText: recognizedText,
                onCancel: _stopListening,
              ),
            if (isSpeaking)
              VoiceStatusOverlay(
                message: AppTranslations.getText(context, currentLanguage, 'speaking'),
                backgroundColor: Color(0xFF4A2B52),
                icon: Icons.volume_up,
              ),
          ],
        ),
      ),
    );
  }
}
extension TimestampExtension on DateTime {
  Timestamp get toTimestamp => Timestamp.fromDate(this);
}

extension TextFormatting on String {
  String formatBoldText() {
    // Regular expression to match text between double asterisks
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');

    // Replace all matches with their SpanText widget equivalent
    return replaceAllMapped(boldRegex, (match) {
      final textBetweenAsterisks = match.group(1);
      if (textBetweenAsterisks != null && textBetweenAsterisks.isNotEmpty) {
        return textBetweenAsterisks;
      }
      return match.group(0) ?? '';
    });
  }
}

extension StringExtension on String {
  // Utility methods for strings
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    ).hasMatch(this);
  }

  String get capitalize {
    if (this.isEmpty) return this;
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}

extension DateTimeExtension on Timestamp {
  DateTime get toDateTime => this.toDate();

  String get formatted {
    final date = this.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}

extension GetImageMimeType on XFile{
  String getMimeTypeFromExtension(){
    final extenstion = path.split('.').last;
    switch(extenstion){
      case 'jpg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'application/octet-stream';
    }
  }

}
@immutable
class Message {
  final String id;
  final String message;
  final DateTime createdAt;
  final bool isMine;

  const Message({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isMine,
  });
  String get formattedMessage => message.formatBoldText();
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isMine': isMine,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      message: map['message'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isMine: map['isMine'] as bool,
    );
  }

  Message copyWith({
    String? id,
    String? message,
    DateTime? createdAt,
    bool? isMine,
  }) {
    return Message(
      id: id ?? this.id,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
    );
  }
}
final getAllMessagesProvider = StreamProvider.autoDispose.family<Iterable<Message>, String>(
      (ref, userId) {
    final controller = StreamController<Iterable<Message>>();
    final sub = FirebaseFirestore.instance
        .collection('conversations')
        .doc(userId)
        .collection('messages')
        .orderBy('createdAt',descending: true)
        .snapshots()
        .listen((snapshot){
      final messages = snapshot.docs.map(
            (messageData)=> Message.fromMap(
          messageData.data(),
        ),
      );
      controller.sink.add(messages);
    });
    ref.onDispose(() {
      sub.cancel();
      controller.close();
    });
    return controller.stream;
  },
);
enum AppLanguage { english, sinhala }

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english);

  void toggleLanguage() {
    state = state == AppLanguage.english ? AppLanguage.sinhala : AppLanguage.english;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
      (ref) => LanguageNotifier(),
);
final chatProvider = Provider(
      (ref) => ChatRepository(),

);
final authProvider = Provider(
      (ref) => AuthRepository(),
);
@immutable
class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async{
    final googleUser = await _googleSignIn.signIn();

    if(googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,


    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signout() async{
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();

  }

}
@immutable
class ChatRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _cleanupAIResponse(String text) {
    // Split text into lines
    List<String> lines = text.split('\n');

    // Process each line
    List<String> processedLines = lines.map((line) {
      // Remove standalone asterisks and hyphens
      var cleaned = line.replaceAll(RegExp(r'\s+[*-]\s+'), ' ');

      // Check if line starts with bullet point
      if (RegExp(r'^\s*[*-]').hasMatch(cleaned)) {
        // Remove the bullet point and any leading/trailing whitespace
        cleaned = cleaned.replaceAll(RegExp(r'^\s*[*-]\s*'), '');
        // Add our own bullet point
        cleaned = '• ' + cleaned;
      }

      // Remove multiple consecutive spaces
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      return cleaned;
    }).toList();

    // Join lines back together and trim any extra whitespace
    return processedLines.where((line) => line.isNotEmpty).join('\n').trim();
  }

  Future<void> _sendMessageToFirestore({
    required String messageText,
    required bool isMine,
  }) async {
    final userId = _auth.currentUser!.uid;
    final messageId = const Uuid().v4();

    final message = Message(
      id: messageId,
      message: messageText,
      createdAt: DateTime.now(),
      isMine: isMine,
    );

    await _firestore
        .collection('conversations')
        .doc(userId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());
  }

//   Future<void> _validateAndSendMessage({
//     required GenerativeModel model,
//     required String promptText,
//     required AppLanguage currentLanguage,
//   }) async {
//     await _sendMessageToFirestore(
//       messageText: promptText,
//       isMine: true,
//     );
//
//     if (!DementiaValidator.isDementiaRelated(promptText)) {
//       final validationMessage = AppTranslations.getTextNonUI(
//         currentLanguage,
//         'not_dementia_related',
//       );
//
//       await _sendMessageToFirestore(
//         messageText: validationMessage,
//         isMine: false,
//       );
//       return;
//     }
//
//     try {
//       // final promptTemplate = currentLanguage == AppLanguage.english
//       //     ? 'You are a dementia care expert chatbot. Respond only in English, providing clear and professional answers.\n\n'
//       //     'Question: $promptText\n\n'
//       //     'Guidelines:\n'
//       //     '- Provide information in clear, professional English\n'
//       //     '- Use appropriate medical terminology with explanations when needed\n'
//       //     '- Be concise but thorough\n'
//       //     '- Never switch to Sinhala\n\n'
//       //     'Please note: My responses provide general information and support.\n'
//       //     'Always consult healthcare professionals for medical advice.'
//       //     : 'ඔබ ඩිමෙන්ෂියා සත්කාර විශේෂඥ චැට්බෝට් කෙනෙකි. සිංහල භාෂාවෙන් පමණක් පිළිතුරු සපයන්න.\n\n'
//       //     'ප්‍රශ්නය: $promptText\n\n'
//       //     'මාර්ගෝපදේශ:\n'
//       //     '- සරල, තේරුම්ගත හැකි සිංහල භාෂාවෙන් තොරතුරු සපයන්න\n'
//       //     '- වෛද්‍ය යෙදුම් භාවිතා කරන විට වැඩිදුර පැහැදිලි කිරීම් සපයන්න\n'
//       //     '- ගෞරවනීය භාෂාවක් භාවිතා කරන්න\n'
//       //     '- කිසිවිටෙකත් ඉංග්‍රීසි භාෂාවට මාරු නොවන්න\n\n'
//       //     'සටහන: මගේ පිළිතුරු සාමාන්‍ය තොරතුරු සහ සහාය සපයයි.\n'
//       //     'සෑම විටම වෛද්‍ය උපදෙස් සඳහා සෞඛ්‍ය වෘත්තිකයන් හමුවන්න.';
//
//       final promptTemplate = currentLanguage == AppLanguage.english
//           ? '''You are a dementia care expert chatbot. Respond only in English, providing clear and professional answers.
//
// Question: $promptText
//
// Guidelines:
// - Provide information in clear, professional English
// - Use appropriate medical terminology with explanations when needed
// - Be concise but thorough
// - Never switch to Sinhala
//
// Please note: My responses provide general information and support.
// Always consult healthcare professionals for medical advice.'''
//           : '''ඔබ ඩිමෙන්ෂියා සත්කාර විශේෂඥ චැට්බෝට් කෙනෙකි. සිංහල භාෂාවෙන් පමණක් පිළිතුරු සපයන්න.
//
// ප්‍රශ්නය: $promptText
//
// මාර්ගෝපදේශ:
// - විස්තරාත්මක හා පැහැදිලි සිංහල භාෂාවෙන් තොරතුරු සපයන්න
// - සෑම කරුණක්ම ගැඹුරින් පැහැදිලි කරන්න
// - වෛද්‍ය යෙදුම් භාවිතා කරන විට සරල පැහැදිලි කිරීම් ද සපයන්න
// - සෑම ප්‍රශ්නයකටම අවම වශයෙන් පේළි 4-5ක විස්තරයක් සපයන්න
// - සෑම විටම උදාහරණ සහිතව පැහැදිලි කරන්න
// - ගෞරවනීය භාෂාවක් භාවිතා කරන්න
// - කිසිවිටෙකත් ඉංග්‍රීසි භාෂාවට මාරු නොවන්න
//
// සටහන: මගේ පිළිතුරු සාමාන්‍ය තොරතුරු සහ සහාය සපයයි.
// සෑම විටම වෛද්‍ය උපදෙස් සඳහා සෞඛ්‍ය වෘත්තිකයන් හමුවන්න.''';
//       final response = await model.generateContent([
//         Content.text(promptTemplate)
//       ]);
//
//       final responseText = response.text;
//
//       if (responseText != null && responseText.isNotEmpty) {
//         final cleanedResponse = _cleanupAIResponse(responseText);
//         await _sendMessageToFirestore(
//           messageText: cleanedResponse,
//           isMine: false,
//         );
//       } else {
//         throw Exception('Empty response from AI');
//       }
//     } catch (e) {
//       final errorMessage = AppTranslations.getTextNonUI(
//         currentLanguage,
//         'general_error',
//       );
//
//       await _sendMessageToFirestore(
//         messageText: errorMessage,
//         isMine: false,
//       );
//       throw Exception(e.toString());
//     }
//   }

  Future<void> _validateAndSendMessage({
    required GenerativeModel model,
    required String promptText,
    required AppLanguage currentLanguage,
  }) async {
    await _sendMessageToFirestore(
      messageText: promptText,
      isMine: true,
    );

    if (!DementiaValidator.isDementiaRelated(promptText)) {
      final validationMessage = AppTranslations.getTextNonUI(
        currentLanguage,
        'not_dementia_related',
      );

      await _sendMessageToFirestore(
        messageText: validationMessage,
        isMine: false,
      );
      return;
    }

    try {
      final promptTemplate = currentLanguage == AppLanguage.english
          ? '''You are a dementia care expert chatbot. Respond only in English, providing clear and professional answers.

Question: $promptText

Rules:
1. ALWAYS respond in English only
2. Be clear and professional
3. Use medical terms with explanations
4. Be thorough but concise
5. Never include any text in other languages

Note: My responses provide general information and support.
Always consult healthcare professionals for medical advice.'''
          : '''ඔබ ඩිමෙන්ෂියා සත්කාර විශේෂඥ චැට්බෝට් කෙනෙකි.

ප්‍රශ්නය: $promptText

නීති:
1. සෑම විටම සිංහලෙන් පමණක් පිළිතුරු දෙන්න
2. පැහැදිලි හා වෘත්තීය විය යුතුය
3. වෛද්‍ය යෙදුම් පැහැදිලි කිරීම් සමඟ භාවිතා කරන්න
4. සවිස්තරාත්මක නමුත් කෙටි විය යුතුය
5. කිසිවිටෙකත් වෙනත් භාෂාවල පෙළ ඇතුළත් නොකරන්න
6. සිංහල භාෂාවෙන් පමණක් පිළිතුරු සපයන්න

සටහන: මගේ පිළිතුරු සාමාන්‍ය තොරතුරු සහ සහාය සපයයි.
සෑම විටම වෛද්‍ය උපදෙස් සඳහා සෞඛ්‍ය වෘත්තිකයන් හමුවන්න.''';

      final response = await model.generateContent([
        Content.text(promptTemplate)
      ]);

      final responseText = response.text;

      if (responseText != null && responseText.isNotEmpty) {
        final cleanedResponse = _cleanupAIResponse(responseText);
        await _sendMessageToFirestore(
          messageText: cleanedResponse,
          isMine: false,
        );
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      final errorMessage = AppTranslations.getTextNonUI(
        currentLanguage,
        'general_error',
      );

      await _sendMessageToFirestore(
        messageText: errorMessage,
        isMine: false,
      );
      throw Exception(e.toString());
    }
  }

  Future<void> sendTextMessage({
    required String textPrompt,
    required String apiKey,
    required AppLanguage currentLanguage,
  }) async {
    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    await _validateAndSendMessage(
      model: model,
      promptText: textPrompt,
      currentLanguage: currentLanguage,
    );
  }

  Future<void> clearAllMessages() async {
    final userId = _auth.currentUser!.uid;
    final messagesRef = _firestore
        .collection('conversations')
        .doc(userId)
        .collection('messages');

    final snapshots = await messagesRef.get();
    final batch = _firestore.batch();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
class VoiceAssistantService {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  bool isSpeaking = false;
  AppLanguage currentLanguage = AppLanguage.english;

  Future<void> initialize() async {
    try {
      // Initialize TTS
      var languages = await flutterTts.getLanguages;
      debugPrint("Available TTS languages: $languages");

      await _setTTSLanguage();
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);

      // Initialize STT
      bool available = await speech.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );

      if (available) {
        var locales = await speech.locales();
        debugPrint("Available STT locales: $locales");
      }
    } catch (e) {
      debugPrint('Voice assistant initialization error: $e');
      rethrow;
    }
  }

  Future<void> _setTTSLanguage() async {
    try {
      String languageCode = currentLanguage == AppLanguage.english ? "en-US" : "si-LK";
      bool isLanguageAvailable = await flutterTts.isLanguageAvailable(languageCode);

      if (isLanguageAvailable) {
        await flutterTts.setLanguage(languageCode);
      } else {
        throw Exception('Language $languageCode not available');
      }
    } catch (e) {
      debugPrint('Error setting TTS language: $e');
      rethrow;
    }
  }

  Future<void> switchLanguage(AppLanguage newLanguage) async {
    currentLanguage = newLanguage;
    await _setTTSLanguage();
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!isListening) {
      if (isSpeaking) {
        await stopSpeaking();
      }

      isListening = true;
      String localeId = currentLanguage == AppLanguage.english ? "en_US" : "si_LK";

      try {
        await speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              onResult(result.recognizedWords);
              isListening = false;
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: localeId,
          cancelOnError: true,
        );
      } catch (e) {
        isListening = false;
        debugPrint('Speech recognition error: $e');
        rethrow;
      }
    }
  }

  Future<void> stopListening() async {
    if (isListening) {
      isListening = false;
      await speech.stop();
    }
  }

  Future<void> speak(String text) async {
    try {
      isSpeaking = true;
      await flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
      isSpeaking = false;
      rethrow;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await flutterTts.stop();
      isSpeaking = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
      rethrow;
    }
  }

  void dispose() {
    flutterTts.stop();
  }
}
class AppTranslations {
  static String getText(BuildContext? context, AppLanguage language, String key) {
    return _translations[key]?[language] ?? key;
  }

  static String getTextNonUI(AppLanguage language, String key) {
    return _translations[key]?[language] ?? key;
  }
  static final Map<String, Map<AppLanguage, String>> _translations = {
    // Login Screen
    'app_title': {
      AppLanguage.english: 'DementiaLink ChatBot',
      AppLanguage.sinhala: 'ඩිමෙන්ෂියා ලින්ක් චැට්බෝට්',
    },
    'welcome_description': {
      AppLanguage.english: 'Ask whatever you need to know about dementia or anything related to it. We are here to help you.',
      AppLanguage.sinhala: 'ඩිමෙන්ෂියාව හෝ ඊට සම්බන්ධ ඕනෑම දෙයක් ගැන දැන ගැනීමට අවශ්‍ය දේ අසන්න. අපි ඔබට උදව් කිරීමට සූදානම්.',
    },
    'sign_in_with_google': {
      AppLanguage.english: 'Sign in with Google',
      AppLanguage.sinhala: 'ගූගල් සමඟ පුරන්න',
    },

    // Home Screen
    'input_hint': {
      AppLanguage.english: 'Ask your dementia-related question...',
      AppLanguage.sinhala: 'ඔබේ ඩිමෙන්ෂියා සම්බන්ධ ප්‍රශ්නය අසන්න...',
    },
    'listening': {
      AppLanguage.english: 'Listening...',
      AppLanguage.sinhala: 'සවන් දෙමින්...',
    },
    'speaking': {
      AppLanguage.english: 'Speaking...',
      AppLanguage.sinhala: 'කථා කරමින්...',
    },
    'clear_chat': {
      AppLanguage.english: 'Clear Chat History',
      AppLanguage.sinhala: 'චැට් ඉතිහාසය මකන්න',
    },
    'clear_confirmation': {
      AppLanguage.english: 'Are you sure you want to clear all chat messages? This action cannot be undone.',
      AppLanguage.sinhala: 'සියලුම චැට් පණිවිඩ මකා දැමීමට අවශ්‍ය බව ඔබට විශ්වාසද? මෙම ක්‍රියාව පසුව අවලංගු කළ නොහැක.',
    },
    'cancel': {
      AppLanguage.english: 'Cancel',
      AppLanguage.sinhala: 'අවලංගු කරන්න',
    },
    'clear': {
      AppLanguage.english: 'Clear',
      AppLanguage.sinhala: 'මකන්න',
    },
    'clear_success': {
      AppLanguage.english: 'Chat history cleared successfully',
      AppLanguage.sinhala: 'චැට් ඉතිහාසය සාර්ථකව මකා දමන ලදී',
    },
    'clear_error': {
      AppLanguage.english: 'Failed to clear chat history',
      AppLanguage.sinhala: 'චැට් ඉතිහාසය මකා දැමීමට අසමත් විය',
    },

    // Voice Assistant Messages
    'voice_init_error': {
      AppLanguage.english: 'Failed to initialize voice assistant',
      AppLanguage.sinhala: 'හඬ සහායක ආරම්භ කිරීමට අසමත් විය',
    },
    'lang_switch_english': {
      AppLanguage.english: 'Switched to English',
      AppLanguage.sinhala: 'ඉංග්‍රීසි භාෂාවට මාරු විය',
    },
    'lang_switch_sinhala': {
      AppLanguage.english: 'Switched to Sinhala',
      AppLanguage.sinhala: 'සිංහල භාෂාවට මාරු විය',
    },
    'lang_switch_error': {
      AppLanguage.english: 'Failed to switch language',
      AppLanguage.sinhala: 'භාෂාව මාරු කිරීමට අසමත් විය',
    },
    'voice_recognition_error': {
      AppLanguage.english: 'Voice recognition error',
      AppLanguage.sinhala: 'හඬ හඳුනා ගැනීමේ දෝෂයකි',
    },
    'voice_stop_error': {
      AppLanguage.english: 'Error stopping voice recognition',
      AppLanguage.sinhala: 'හඬ හඳුනා ගැනීම නැවැත්වීමේ දෝෂයකි',
    },
    'tts_error': {
      AppLanguage.english: 'Text-to-speech error',
      AppLanguage.sinhala: 'පෙළ-කථනය දෝෂයකි',
    },

    // Error Messages
    'general_error': {
      AppLanguage.english: 'An error occurred',
      AppLanguage.sinhala: 'දෝෂයක් ඇති විය',
    },
    'try_again': {
      AppLanguage.english: 'Please try again',
      AppLanguage.sinhala: 'කරුණාකර නැවත උත්සාහ කරන්න',
    },
    'network_error': {
      AppLanguage.english: 'Network connection error',
      AppLanguage.sinhala: 'ජාල සම්බන්ධතා දෝෂයකි',
    },
    'send_message_error': {
      AppLanguage.english: 'Error sending message. Please try again.',
      AppLanguage.sinhala: 'පණිවිඩය යැවීමේ දෝෂයකි. කරුණාකර නැවත උත්සාහ කරන්න.',
    },

    // Dementia Validator Messages
    'not_dementia_related': {
      AppLanguage.english: '''I am specifically designed to help with dementia-related questions. 
Please rephrase your question to focus on dementia, Alzheimer's disease, memory care, 
caregiving, or other aspects of cognitive health and elderly care.''',
      AppLanguage.sinhala: '''මම විශේෂයෙන් නිර්මාණය කර ඇත්තේ ඩිමෙන්ෂියාව සම්බන්ධ ප්‍රශ්න සඳහා පිළිතුරු සැපයීමටයි.
කරුණාකර ඔබේ ප්‍රශ්නය ඩිමෙන්ෂියාව, අල්සයිමර් රෝගය, මතක සත්කාරය,
රෝගී සත්කාරය, හෝ දැනුවත්භාවයේ සෞඛ්‍යය සහ වැඩිහිටි සත්කාරය පිළිබඳව යොමු කරන්න.''',
    },
    'example_questions': {
      AppLanguage.english: '''For example, you can ask about:
- Dementia symptoms and stages
- Caregiving tips and support
- Treatment options and medications
- Prevention and risk factors
- Daily care and management strategies
- Resources for families and caregivers''',
      AppLanguage.sinhala: '''උදාහරණ වශයෙන්, ඔබට මේවා ගැන විමසිය හැකිය:
- ඩිමෙන්ෂියා රෝග ලක්ෂණ සහ අවධි
- රෝගී සත්කාර උපදෙස් සහ සහාය
- ප්‍රතිකාර විකල්ප සහ ඖෂධ
- වැළැක්වීම සහ අවදානම් සාධක
- දෛනික සත්කාර සහ කළමනාකරණ ක්‍රමෝපායන්
- පවුල් සහ සත්කාරකයින් සඳහා සම්පත්''',
    },
  };
}
class DementiaValidator {
  static final List<String> _dementiaKeywords = [
    'ඩිමෙන්ෂියාව',
    'අල්සයිමර්',
    'මතක',
    'මතකය',
    'ස්මරණ',
    'මොළය',
    'රෝගය',
    'රෝගි',
    'ප්‍රතිකාර',
    'බෙහෙත්',
    'සුවය',
    'සත්කාර',
    'රැකවරණය',
    'වැඩිහිටි',
    'වයස්ගත',
    'මානසික',
    'චර්යා',
    'හැසිරීම්',
    'වෛද්‍ය',
    'රෝහල',
    'බෙහෙත්',
    'පවුල',
    'රැකබලා',
    'උපකාර',
    'සහය',
    'dementia',
    'alzheimer',
    'memory loss',
    'cognitive decline',
    'brain health',
    'caregiver',
    'caregiving',
    'aging',
    'elderly care',
    'mental health',
    'confusion',
    'forgetfulness',
    'neurological',
    'brain disease',
    'memory care',
    'cognitive impairment',
    'behavioral changes',
    'symptoms',
    'treatment',
    'diagnosis',
    'care',
    'support',
    'medicine',
    'therapy',
    'brain',
    'memory',
    'cognitive',
    'elder',
    'senior',
    'geriatric',
    'neurology',
    'brain function',
    'mental decline',
    'memory problems',
    'behavior changes',
    'mood changes',
    'daily living',
    'care facility',
    'nursing home',
    'medical history',
    'prevention',
    'risk factors',
    'stages',
    'progression',
    'early signs',
    'warning signs',
    'family history',
    'medication',
    'management',
    'research',
    'clinical trials',
    'brain scan',
    'mri',
    'ct scan',
    'pet scan',
    'diagnosis',
    'assessment',
  ];

  static bool isDementiaRelated(String query) {
    query = query.toLowerCase();

    // If the query is too short, request more context
    if (query.split(' ').length < 3) {
      return false;
    }

    // Check if query contains any dementia-related keywords
    return _dementiaKeywords.any((keyword) => query.contains(keyword));
  }

  static String getValidationMessage() {
    return '''I am specifically designed to help with dementia-related questions. 
Please rephrase your question to focus on dementia, Alzheimer's disease, memory care, 
caregiving, or other aspects of cognitive health and elderly care. For example, you can ask about:

- Dementia symptoms and stages
- Caregiving tips and support
- Treatment options and medications
- Prevention and risk factors
- Daily care and management strategies
- Resources for families and caregivers''';
  }
}
Future displayDialog({
  required BuildContext context,
  required String message,
}) async {
  return showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('Gemini Says'),
        content: Text(message),
        actions: [
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Okay'),
          ),
        ],
      );
    },
  );
}
class MessageTile extends StatelessWidget {
  final Message message;
  final bool isOutgoing;
  final bool isLastMessage;

  const MessageTile({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isOutgoing ? const Color(0xFF503663) : Colors.grey[300],
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // child: Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     SelectableText(
          //       message.message,
          //       style: TextStyle(
          //         color: isOutgoing ? Colors.white : Colors.black,
          //         fontSize: 16.0,
          //       ),
          //     ),
          //     const SizedBox(height: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RichText(
              //   text: TextSpan(
              //     children: _buildFormattedText(message.message),
              //     style: TextStyle(
              //       color: isOutgoing ? Colors.white : Colors.black,
              //       fontSize: 16.0,
              //     ),
              //   ),
              // ),
              SelectableText.rich(
                TextSpan(
                  children: _buildFormattedText(message.message),
                  style: TextStyle(
                    color: isOutgoing ? Colors.white : Colors.black,
                    fontSize: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(message.createdAt),
                style: TextStyle(
                  color: isOutgoing ? Colors.white70 : Colors.black54,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  List<TextSpan> _buildFormattedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int currentPosition = 0;

    // Find all bold text matches
    for (Match match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
        ));
      }

      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1), // The text between ** **
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));

      currentPosition = match.end;
    }

    // Add any remaining text after the last bold part
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
      ));
    }

    return spans;
  }
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
class MessagesList extends ConsumerStatefulWidget {
  const MessagesList({
    super.key,
    required this.userId,
    required this.onNewMessage,
    this.isVoiceMode = false,
  });

  final String userId;
  final Function(Message) onNewMessage;
  final bool isVoiceMode;

  @override
  ConsumerState<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends ConsumerState<MessagesList> {
  String? lastProcessedMessageId;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _processNewMessage(Message message) {
    if (!message.isMine && message.id != lastProcessedMessageId) {
      lastProcessedMessageId = message.id;
      widget.onNewMessage(message);

      // Scroll to the bottom when a new message arrives
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesData = ref.watch(getAllMessagesProvider(widget.userId));

    return messagesData.when(
      data: (messages) {
        if (messages.isNotEmpty) {
          _processNewMessage(messages.first);
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages.elementAt(index);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: MessageTile(
                message: message,
                isOutgoing: message.isMine,
                isLastMessage: index == 0,
              ),
            );
          },
        );
      },
      error: (error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(getAllMessagesProvider(widget.userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
class TranslatedText extends ConsumerWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;

  const TranslatedText({
    super.key,
    required this.textKey,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    return Text(
      AppTranslations.getText(context, language, textKey),
      style: style,
      textAlign: textAlign,
    );
  }
}
class VoiceStatusOverlay extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final String? recognizedText;
  final VoidCallback? onCancel;

  const VoiceStatusOverlay({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    this.recognizedText,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (onCancel != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: onCancel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              if (recognizedText?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recognizedText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}