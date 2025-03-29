import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_models.dart';
import '../utils/translations.dart';

final chatProvider = Provider(
      (ref) => ChatRepository(),
);

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

class ChatRepository {
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
        // Use the most compatible model
        model: 'gemini-1.5-pro',
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
        cleaned = cleaned.replaceAll(RegExp(r'^\s*[-]\s'), '');
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
}