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
import 'package:flutter_speech/flutter_speech.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:permission_handler/permission_handler.dart';

// Define the AppLanguage enum
enum AppLanguage { english, sinhala }

// Define the Message class
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

// Define Extensions
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

extension GetImageMimeType on XFile {
  String getMimeTypeFromExtension() {
    final extension = path.split('.').last;
    switch(extension) {
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
// Define Providers
final getAllMessagesProvider = StreamProvider.autoDispose.family<Iterable<Message>, String>(
      (ref, userId) {
    final controller = StreamController<Iterable<Message>>();
    final sub = FirebaseFirestore.instance
        .collection('conversations')
        .doc(userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map(
            (messageData) => Message.fromMap(
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

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english);

  void toggleLanguage() {
    state = state == AppLanguage.english ? AppLanguage.sinhala : AppLanguage.english;
  }
}
final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
      (ref) => LanguageNotifier(),
);

@immutable
class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signout() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}

final authProvider = Provider(
      (ref) => AuthRepository(),
);

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

// Future<void> sendTextMessage({
//   required String textPrompt,
//   required String apiKey,
//   required AppLanguage currentLanguage,
// }) async {
//   final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
//   await _validateAndSendMessage(
//     model: model,
//     promptText: textPrompt,
//     currentLanguage: currentLanguage,
//   );
// }
  Future<void> sendTextMessage({
    required String textPrompt,
    required String apiKey,
    required AppLanguage currentLanguage,
  }) async {
    try {
      // Debug log to check API key
      print("Using API Key: ${apiKey.substring(0, 5)}...");

      // Try with the updated model name format
      final model = GenerativeModel(
        // Try one of these model name variations:
        // model: 'gemini-pro',
        // model: 'models/gemini-pro',
        // model: 'gemini-1.0-pro',
        model: 'gemini-1.5-pro',  // Try this newer model
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );

      await _validateAndSendMessage(
        model: model,
        promptText: textPrompt,
        currentLanguage: currentLanguage,
      );
    } catch (e) {
      print("Detailed error in sendTextMessage: $e");
      rethrow;
    }
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

final chatProvider = Provider(
      (ref) => ChatRepository(),
);

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

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(
//       ProviderScope(
//         child: const MyApp(),
//       )
//   );
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['API_KEY'] ?? '';
  print("API Key loaded successfully: ${apiKey.isNotEmpty}");

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
}class LoginScreen extends ConsumerWidget {
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

      // Test TTS
      await flutterTts.speak("TTS initialization complete");
      debugPrint("TTS test completed");
    } catch (e) {
      debugPrint('Voice initialization error: $e');
    }
  }
  