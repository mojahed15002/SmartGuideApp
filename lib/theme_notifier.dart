import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('ar');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  ThemeNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    final langCode = prefs.getString('language') ?? 'ar';
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    _locale = Locale(langCode);
    notifyListeners();
  }

  void toggleTheme() {
    setTheme(_themeMode == ThemeMode.light);
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
