import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;
  void toggle() {
    _locale = _locale?.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    notifyListeners();
  }
}
