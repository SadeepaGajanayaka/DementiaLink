import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english);

  void toggleLanguage() {
    state = state == AppLanguage.english ? AppLanguage.sinhala : AppLanguage.english;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>(
      (ref) => LanguageNotifier(),
);