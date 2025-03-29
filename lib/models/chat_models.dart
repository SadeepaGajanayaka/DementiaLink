import 'package:flutter/foundation.dart' show immutable;
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final boldRegex = RegExp(r'\\(.?)\\*');

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