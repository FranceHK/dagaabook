import 'package:flutter/foundation.dart';
import '../core/app_strings.dart';
import '../services/local_store.dart';

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.sw;

  AppLanguage get language => _language;
  bool get isSwahili => _language == AppLanguage.sw;

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await LocalStore.loadString(LocalStore.languageKey);
      if (saved != null) {
        _language = AppLanguage.values.byName(saved);
        notifyListeners();
      }
    } catch (_) {}
  }

  String t(String key) => AppStrings.get(_language, key);

  void toggle() {
    setLanguage(_language == AppLanguage.sw ? AppLanguage.en : AppLanguage.sw);
  }

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    LocalStore.saveString(LocalStore.languageKey, lang.name);
  }
}
