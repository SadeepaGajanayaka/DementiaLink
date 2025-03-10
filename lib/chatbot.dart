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