import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_speech/flutter_speech.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

// Import needed classes from your existing files
// Assuming you've organized your code properly, adjust imports as needed
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../widgets/messages_list.dart';
import '../widgets/voice_status_overlay.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  late final TextEditingController _messageController;
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final FlutterTts flutterTts = FlutterTts();
  late SpeechRecognition _speech;
  bool isListening = false;
  bool isSpeaking = false;
  String? lastProcessedMessageId;
  bool isVoiceMode = false;
  String recognizedText = '';
  String _currentLocale = '';
  bool _speechRecognitionAvailable = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _initializeVoiceAssistant();
    _initSpeechRecognizer();

    print("API Key loaded: ${apiKey.isEmpty ? 'EMPTY KEY' : 'Key exists with length: ${apiKey.length}'}");
  }

  @override
  void dispose() {
    _messageController.dispose();
    flutterTts.stop();
    if (isListening) {
      _speech.cancel();
    }
    super.dispose();
  }

  Future<void> _initSpeechRecognizer() async {
    _speech = SpeechRecognition();

    _currentLocale = ref.read(languageProvider) == AppLanguage.english ? "en_US" : "si_LK";
    debugPrint("Initializing speech recognition with locale: $_currentLocale");

    // Request microphone permissions
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    _speech.setAvailabilityHandler(
          (bool result) {
        debugPrint("Speech recognition availability: $result");
        setState(() => _speechRecognitionAvailable = result);
      },
    );

    _speech.setRecognitionStartedHandler(
          () {
        debugPrint("Speech recognition started");
        setState(() => isListening = true);
      },
    );

    _speech.setRecognitionResultHandler(
          (String text) {
        debugPrint("Speech recognition interim result: $text");
        setState(() {
          recognizedText = text;
          _messageController.text = text;
        });
      },
    );

    _speech.setRecognitionCompleteHandler(
          (String text) {
        debugPrint("Speech recognition complete: $text");
        setState(() {
          isListening = false;
          if (text.trim().isNotEmpty) {
            recognizedText = text;
            _messageController.text = text;
            _sendVoiceMessage();
          }
        });
      },
    );

    // Try activating speech recognition
    try {
      bool result = await _speech.activate(_currentLocale);
      debugPrint("Speech recognition activation result: $result");
      setState(() => _speechRecognitionAvailable = result);
    } catch (e) {
      debugPrint("Error activating speech recognition: $e");
      setState(() => _speechRecognitionAvailable = false);
    }
  }

  Future<void> _initializeVoiceAssistant() async {
    try {
      final currentLanguage = ref.read(languageProvider);
      final languageCode = currentLanguage == AppLanguage.english ? "en-US" : "si-LK";

      var availableLanguages = await flutterTts.getLanguages;
      debugPrint("Available TTS languages: $availableLanguages");

      bool? isLanguageAvailable = await flutterTts.isLanguageAvailable(languageCode);
      debugPrint("Is language available: $isLanguageAvailable");

      // Use a fallback language if the requested one isn't available
      if (isLanguageAvailable != true) {
        debugPrint("Language not available, falling back to en-US");
        await flutterTts.setLanguage("en-US");
      } else {
        await flutterTts.setLanguage(languageCode);
      }

      // Get engines for debugging
      var engines = await flutterTts.getEngines;
      debugPrint("Available TTS engines: $engines");

      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);

      flutterTts.setStartHandler(() {
        debugPrint("TTS STARTED");
        if (mounted) {
          setState(() => isSpeaking = true);
        }
      });

      flutterTts.setCompletionHandler(() {
        debugPrint("TTS COMPLETED");
        if (mounted) {
          setState(() => isSpeaking = false);
        }
      });

      flutterTts.setErrorHandler((msg) {
        debugPrint("TTS ERROR: $msg");
        if (mounted) {
          setState(() => isSpeaking = false);
        }
      });

      flutterTts.setProgressHandler((text, start, end, word) {
        debugPrint("TTS PROGRESS: $text, $start, $end, $word");
      });

      // Optional test TTS
      // await flutterTts.speak("TTS initialization complete");
      debugPrint("TTS initialization completed");
    } catch (e) {
      debugPrint('Voice initialization error: $e');
    }
  }

  Future<void> _startListening() async {
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      // Show dialog explaining why mic is needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Microphone permission is required for voice input'),
          action: SnackBarAction(
            label: 'Grant',
            onPressed: () async {
              await Permission.microphone.request();
            },
          ),
        ),
      );
      return;
    }
    if (!isListening) {
      if (isSpeaking) {
        await flutterTts.stop();
        setState(() {
          isSpeaking = false;
        });
      }

      final currentLanguage = ref.read(languageProvider);
      _currentLocale = currentLanguage == AppLanguage.english ? "en_US" : "si_LK";

      setState(() {
        isListening = true;
        isVoiceMode = true;
        recognizedText = '';
      });

      try {
        if (_speechRecognitionAvailable) {
          // Just call listen without parameters
          await _speech.listen();
        } else {
          setState(() => isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Speech recognition not available'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Speech listen error: $e');
        setState(() => isListening = false);
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
      _speech.stop();
      setState(() {
        isListening = false;
        if (recognizedText.trim().isNotEmpty) {
          _messageController.text = recognizedText;
          _sendVoiceMessage();
        }
      });
    }
  }

  void _handleNewMessage(Message message) {
    debugPrint("_handleNewMessage called with message ID: ${message.id}");
    if (!message.isMine && message.id != lastProcessedMessageId) {
      debugPrint("Processing new message for speech: ${message.message}");
      lastProcessedMessageId = message.id;

      // Trigger speech with a delay to ensure UI is updated first
      if (isVoiceMode) {
        debugPrint("Voice mode active, will speak response");
        Future.delayed(Duration(milliseconds: 500), () {
          _speakResponse(message.message);
        });
      } else {
        debugPrint("Voice mode not active, skipping speech");
      }
    } else {
      debugPrint("Skipping message for speech (already processed or is mine)");
    }
  }

  Future<void> _speakResponse(String text) async {
    debugPrint("Speaking response: $text");

    if (!isVoiceMode) {
      debugPrint("Not in voice mode, skipping speech");
      return;
    }

    try {
      // Stop any ongoing speech
      if (isSpeaking) {
        await flutterTts.stop();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Set speaking state
      setState(() => isSpeaking = true);

      // Clean up text for speaking (remove markdown or any special formatting)
      text = text.replaceAll(RegExp(r'\\'), '')
          .replaceAll('•', '');

      // Simple sentence splitting for better speech pacing
      List<String> sentences = text.split(RegExp(r'(?<=[.!?])\s+'));

      // For debugging: print what's about to be spoken
      debugPrint("Will speak ${sentences.length} sentences");

      // Speak a simple test message first to ensure TTS is working
      await flutterTts.speak("I'll answer your question now.");
      await Future.delayed(const Duration(seconds: 2));

      // Try speaking the full text in one go instead of sentence by sentence
      int result = await flutterTts.speak(text);
      debugPrint("TTS speak result: $result");

      // Wait for speaking to complete
      await flutterTts.awaitSpeakCompletion(true);

    } catch (e) {
      debugPrint('Speech error: $e');
    } finally {
      if (mounted) {
        setState(() => isSpeaking = false);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
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
                backgroundColor: const Color(0xFF4A2B52),
                icon: Icons.volume_up,
              ),
          ],
        ),
      ),
    );
  }
}