import 'package:flutter/foundation.dart';
import '../core/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.sw;

  AppLanguage get language => _language;
  bool get isSwahili => _language == AppLanguage.sw;

  String t(String key) => AppStrings.get(_language, key);

  void toggle() {
    _language = _language == AppLanguage.sw ? AppLanguage.en : AppLanguage.sw;
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }
}
