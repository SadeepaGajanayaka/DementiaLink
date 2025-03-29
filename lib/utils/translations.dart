import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../providers/language_provider.dart';

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