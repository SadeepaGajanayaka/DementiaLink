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